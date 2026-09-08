# Define os caminhos
$PastaOrigem = "C:\temp\pre-formatacao"   # Pasta onde estão o Setup.ps1 e unattend.xml
$ArquivoISO  = "C:\temp\script.iso"        # Onde a ISO será salva

try {
    # Inicializa a API do sistema para criar imagem de disco
    $isoMaster = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
    $isoMaster.FreeMediaBlocks = 0
    
    # Adiciona os arquivos da pasta origem na raiz da ISO
    $isoMaster.Root.AddTree($PastaOrigem, $false)
    
    # Gera o resultado da imagem de disco
    $isoResult = $isoMaster.CreateResultImage()
    $imageStream = $isoResult.ImageStream

    # Copia o IStream do IMAPI diretamente para o arquivo de saída
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;

public static class ComStreamFileWriter
{
    [DllImport("shlwapi.dll", CharSet = CharSet.Unicode, PreserveSig = true)]
    private static extern int SHCreateStreamOnFileEx(
        string path, uint mode, uint attributes, bool create, IStream template, out IStream stream);

    public static void Save(object sourceObject, string path)
    {
        IntPtr sourcePointer = Marshal.GetIUnknownForObject(sourceObject);
        IStream source = (IStream)Marshal.GetTypedObjectForIUnknown(sourcePointer, typeof(IStream));

        IStream destination;
        int result = SHCreateStreamOnFileEx(path, 0x00001001, 0, true, null, out destination);
        if (result < 0)
        {
            Marshal.ThrowExceptionForHR(result);
        }

        source.CopyTo(destination, long.MaxValue, IntPtr.Zero, IntPtr.Zero);
        destination.Commit(0);
        Marshal.ReleaseComObject(destination);
        Marshal.Release(sourcePointer);
    }
}
"@
    [ComStreamFileWriter]::Save($imageStream, $ArquivoISO)

    Write-Host "[OK] ISO criada com sucesso em: $ArquivoISO" -ForegroundColor Green
}
catch {
    Write-Host "[ERRO] Falha ao criar a ISO: $_" -ForegroundColor Red
}