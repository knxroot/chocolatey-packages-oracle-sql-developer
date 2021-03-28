# this script should be located on the Windows Host in directory C:\SandboxScripts
Write-Verbose "Install Chocolatey" -Verbose

# This fixes an issue with the extended type system wrapping the array entries with Value and Count properties.
# Required for interoperability with 5.1 and 7
# See https://stackoverflow.com/questions/20848507
Remove-TypeData System.Array

Set-ExecutionPolicy Bypass -Scope Process -Force
# Engages TLS 1.2, required for chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))