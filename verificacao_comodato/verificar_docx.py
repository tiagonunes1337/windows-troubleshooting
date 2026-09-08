import os
import re
import pandas as pd
from docx import Document

# Configuração de arquivos
caminho_csv = "VerificarComodatos.csv"
arquivo_saida = "Resultado_Comodatos_DOCX.csv"
pasta_raiz = "." # Pasta atual

print("Carregando CSV e aplicando filtros de exclusão...")
df_base = pd.read_csv(caminho_csv, sep=',')

# Filtro de Infraestrutura: Mantém apenas os não localizados e remove os marcados para "escritório"
df_filtrado = df_base[
    (df_base['Caminho do PDF Localizado'] == 'NÃO LOCALIZADO') & 
    (~df_base['Processador (Detectado no PDF)'].str.contains('escrit[oó]rio', case=False, na=False, regex=True))
].copy()

print(f"Total de máquinas na fila para busca em DOCX: {len(df_filtrado)}")

# 1. Varredura recursiva de arquivos .docx
print("\nIniciando leitura e indexação de todos os DOCX...")
banco_docx = {}
total_docx = 0

for raiz, subpastas, arquivos in os.walk(pasta_raiz):
    for arquivo in arquivos:
        # Ignora arquivos temporários ocultos do Word (começam com ~$)
        if arquivo.lower().endswith(".docx") and not arquivo.startswith("~$"):
            caminho_completo = os.path.join(raiz, arquivo)
            total_docx += 1
            
            try:
                # Abre o documento Word e extrai o texto de todos os parágrafos
                doc = Document(caminho_completo)
                texto_acumulado = " ".join([p.text for p in doc.paragraphs if p.text])
                
                caminho_relativo = os.path.relpath(caminho_completo, pasta_raiz)
                banco_docx[caminho_relativo] = texto_acumulado.upper()
                print(f"[OK] Lido: {caminho_relativo}")
            except Exception as erro:
                print(f"[ERRO] Falha ao ler documento {caminho_completo}: {erro}")

print(f"\nTotal de {total_docx} arquivos Word indexados no cache.")

# Regex para hardware
regex_cpu = re.compile(r'(I[3579]-?\d{4,5}[A-Z]{0,2}|INTEL\s+CORE\s+I[3579])', re.IGNORECASE)

# 2. Cruzamento dos patrimônios com o conteúdo extraído
print("\nBuscando padrões de hardware e patrimônio nos documentos...")
resultados = []

for _, linha in df_filtrado.iterrows():
    patrimonio = str(linha["Patrimônio"]).strip()
    serial = str(linha["Nº de série"]).strip().upper()
    
    docx_encontrados = []
    processadores_detectados = set()
    
    for caminho_docx, texto_docx in banco_docx.items():
        # Busca flexível por Service Tag ou menção de Patrimônio
        tag_encontrada = (serial in texto_docx) if len(serial) >= 4 else False
        patrimonio_encontrado = (
            f" {patrimonio} " in texto_docx or 
            f"PATRIMONIO {patrimonio}" in texto_docx or 
            f"PATRIMÔNIO {patrimonio}" in texto_docx
        )
        
        if tag_encontrada or patrimonio_encontrado:
            docx_encontrados.append(caminho_docx)
            matches = regex_cpu.findall(texto_docx)
            for m in matches:
                processadores_detectados.add(m.strip())

    # Estruturação para a nova planilha
    resultados.append({
        "Patrimônio": patrimonio,
        "Nº de série": serial,
        "Processador (Detectado no DOCX)": ", ".join(processadores_detectados) if processadores_detectados else "Não citado no doc",
        "DOCX Localizado": " | ".join(docx_encontrados) if docx_encontrados else "NÃO LOCALIZADO NO DOCX"
    })

# 3. Exportação do log final
df_final = pd.DataFrame(resultados)
df_final.to_csv(arquivo_saida, index=False, sep=",", encoding="utf-8-sig")
print(f"\n[SUCESSO] Processo finalizado! Relatório exportado para: {arquivo_saida}")