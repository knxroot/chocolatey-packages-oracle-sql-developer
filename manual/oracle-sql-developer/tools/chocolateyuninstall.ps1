$ErrorActionPreference = 'Stop';

Write-Host 'Removing shortcuts...'

$desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
$startMenu = [Environment]::GetFolderPath([Environment+SpecialFolder]::StartMenu)
$shortcut = 'Oracle SQL Developer.lnk'

Remove-Item -Path $(Join-Path $desktop $shortcut) -Force -ErrorAction Ignore
Remove-Item -Path $(Join-Path $startMenu "Programs/$shortcut") -Force -ErrorAction Ignore
