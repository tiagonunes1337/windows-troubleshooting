import os
import re
import pandas as pd
from pypdf import PdfReader

# Arquivo CSV base com os dados das máquinas
caminho_csv = "VerificarComodatos.csv"
arquivo_saida = "Resultado_Comodatos_Verificados.csv"

# Diretório raiz (pasta atual onde estão as pastas 2017, 2018... 2026, Antigos)
pasta_raiz = "."

print("Carregando CSV base...")
df_base = pd.read_csv(caminho_csv)

# 1. Varredura recursiva de todas as pastas e subpastas de anos
print("Iniciando leitura e indexação de todos os PDFs nas pastas dos anos...")
banco_pdfs = {}

total_pdfs = 0
for raiz, subpastas, arquivos in os.walk(pasta_raiz):
    for arquivo in arquivos:
        if arquivo.lower().endswith(".pdf"):
            caminho_completo = os.path.join(raiz, arquivo)
            total_pdfs += 1
            texto_acumulado = ""
            try:
                reader = PdfReader(caminho_completo)
                for pagina in reader.pages:
                    texto_extraido = pagina.extract_text() or ""
                    texto_acumulado += " " + texto_extraido
                
                # Guarda o caminho relativo do PDF e o conteúdo em maiúsculas
                caminho_relativo = os.path.relpath(caminho_completo, pasta_raiz)
                banco_pdfs[caminho_relativo] = texto_acumulado.upper()
                print(f"[OK] Lido: {caminho_relativo}")
            except Exception as erro:
                print(f"[ERRO] Falha ao ler {caminho_completo}: {erro}")

print(f"\nTotal de {total_pdfs} arquivos PDF indexados com sucesso.")

# Expressão regular para capturar padrões de processadores Intel Core
regex_cpu = re.compile(r'(I[3579]-?\d{4,5}[A-Z]{0,2}|INTEL\s+CORE\s+I[3579])', re.IGNORECASE)

# 2. Cruzamento dos dados do CSV com o conteúdo lido dos PDFs
print("Cruzando patrimônios e seriais com os documentos encontrados...")
resultados = []

for _, linha in df_base.iterrows():
    patrimonio = str(linha["Patrimônio"]).strip()
    serial = str(linha["Nº de série"]).strip().upper()
    nf = str(linha["Nota fiscal"]).strip()
    proc_csv = str(linha["Processador"]).strip()
    
    pdfs_encontrados = []
    processadores_detectados = set()
    
    for caminho_pdf, texto_pdf in banco_pdfs.items():
        # Busca exata pelo Serial/Service Tag ou pelo número do Patrimônio
        tag_encontrada = (serial in texto_pdf) if len(serial) >= 4 else False
        patrimonio_encontrado = (
            f" {patrimonio} " in texto_pdf or 
            f"PATRIMONIO {patrimonio}" in texto_pdf or 
            f"PATRIMÔNIO {patrimonio}" in texto_pdf
        )
        
        if tag_encontrada or patrimonio_encontrado:
            pdfs_encontrados.append(caminho_pdf)
            matches = regex_cpu.findall(texto_pdf)
            for m in matches:
                processadores_detectados.add(m.strip())

    # Formatação dos resultados
    caminho_pdf_str = " | ".join(pdfs_encontrados) if pdfs_encontrados else "NÃO LOCALIZADO"
    proc_pdf_str = ", ".join(processadores_detectados) if processadores_detectados else "Não identificado no PDF"
    
    if not pdfs_encontrados:
        status_validacao = "Pendente - PDF Ausente"
    elif any(proc_csv.upper().startswith(p.upper()) for p in processadores_detectados):
        status_validacao = "Conferido (Compatível)"
    else:
        status_validacao = "Revisar (Possível Divergência)"

    resultados.append({
        "Patrimônio": patrimonio,
        "Nº de série": serial,
        "Nota fiscal": nf,
        "Processador (CSV)": proc_csv,
        "Processador (Detectado no PDF)": proc_pdf_str,
        "Caminho do PDF Localizado": caminho_pdf_str,
        "Status Validação": status_validacao
    })

# 3. Exporta o relatório consolidado para Excel/CSV
df_final = pd.DataFrame(resultados)
df_final.to_csv(arquivo_saida, index=False, sep=";", encoding="utf-8-sig")

print(f"\n[FINALIZADO] Planilha gerada com sucesso: {arquivo_saida}")