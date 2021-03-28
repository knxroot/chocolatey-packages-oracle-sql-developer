$ErrorActionPreference = 'Stop';

$packageDir = $env:ChocolateyPackageFolder
$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition

."$toolsDir/helpers.ps1"

$params = Get-PackageParameters

$version = '20.4.1'
$zipFileName = 'sqldeveloper-20.4.1.407.0006-no-jre.zip'
$url = "https://download.oracle.com/otn/java/sqldeveloper/$zipFileName"
$sha1hash = 'df90320a3a6e15df90fafb9d0c603317f3a68b84'
$loginSubmit = 'https://login.oracle.com/oam/server/auth_cred_submit'
$proxy = Get-ChocolateyProxy $url

# disable need to run Internet Explorer first launch configuration
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main" -Name "DisableFirstRunCustomize" -Value 2

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $packageDir
  url           = ''
  checksum      = $sha1hash
  checksumType  = 'sha1'
}

if(!$params['Username'] -or !$params['Password']) {
  throw @'
  An Oracle account is required to download SQL Developer

  * Provide your Oracle credentials as package params to the installer and
    retry the installation:

    choco install oracle-sql-developer --params "'/Username:{userName} /Password:{password}'"

  * If you do not have an Oracle account, you can register for one here (it's free):
    https://profile.oracle.com/myprofile/account/create-account.jspx

'@
}

Write-Host 'Redirecting to Oracle Login...'
$loginPage = Invoke-WebRequest -Uri $url -SessionVariable session @proxy

Write-Host 'Logging in...'

$licenseAcceptCookie = New-Object System.Net.Cookie -ArgumentList 'oraclelicense', 'accept-sqldev-cookie', '/', 'oracle.com'
$session.Cookies.Add($licenseAcceptCookie)

$loginFormFields = $loginPage.Forms['LoginForm'].Fields
$loginFormFields.ssousername = $params['Username']
$loginFormFields.password = $params['Password']

try {
  Invoke-WebRequest -Uri $loginSubmit -Method Post -WebSession $session -Body $loginFormFields -MaximumRedirection 2 @proxy
}
catch {
  $msg = $_.ErrorDetails.Message
  if($msg -inotmatch 'AuthParam') {
    throw "Oracle login unsuccessful: $_"
  }
  $packageArgs.url = [regex]::Match($msg, '.*(http.*)\.').Groups[1].Value
  $packageArgs.url = $packageArgs.url.Replace('https', 'http')
  $packageArgs.url = $packageArgs.url.Replace('http', 'https')
}

Write-Host 'Oracle login successful'
Write-Debug "Authenticated download URL: $($packageArgs.url)"

Install-ChocolateyZipPackage @packageArgs

Write-Host 'Setting JDK path in product config...'
Write-Debug "JDK Path: $(Get-JdkPath)"

$productConfDir = Join-Path "$($env:APPDATA)" "sqldeveloper/$version"
$productConfPath = Join-Path $productConfDir 'product.conf'
$templatePath = Join-Path $toolsDir 'product.conf'
$template = Get-Content -Path $templatePath -Raw
$template = $template.Replace('%JdkPath%', $(Get-JdkPath))
New-Item -ItemType Directory -Path $productConfDir -ErrorAction SilentlyContinue
try {
  $template | Out-File -FilePath $productConfPath -Encoding 'UTF8' -NoClobber
}
catch {
  Write-Warning @"
  Could not update SQL Developer product config file. It may already exist from a previous install or not be writable.
  Check the file to ensure the 'SetJavaHome' path is set correctly. If no file exists at this path, it will
  be created upon the first run of SQL Developer

  Path: $productConfPath

"@
}

Write-Host 'Creating shortcuts...'

$exePath = Join-Path $packageDir 'sqldeveloper/sqldeveloper.exe'
$desktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop)
$startMenu = [Environment]::GetFolderPath([Environment+SpecialFolder]::StartMenu)
$shortcut = 'Oracle SQL Developer.lnk'
Install-ChocolateyShortcut -ShortcutFilePath $(Join-Path $desktop $shortcut) -TargetPath $exePath
Install-ChocolateyShortcut -ShortcutFilePath $(Join-Path $startMenu "Programs/$shortcut") -TargetPath $exePath
