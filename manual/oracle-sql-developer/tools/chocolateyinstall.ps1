$ErrorActionPreference = 'Stop';

$toolsDir = $(Split-Path -parent $MyInvocation.MyCommand.Definition)
Import-Module "$toolsDir/utils.psm1"

$pp = Get-PackageParameters

$zipFileName = 'sqldeveloper-18.4.0-376.1900-no-jre.zip'
$url = "https://download.oracle.com/otn/java/sqldeveloper/$zipFileName"
$sha1hash = '2536dad95e0390f7202f0c5962a1af99ee3de787'
$loginSubmit = 'https://login.oracle.com/oam/server/sso/auth_cred_submit'
$proxy = Get-ChocolateyProxy $url

$packageArgs = @{
  packageName   = $env:ChocolateyPackageName
  unzipLocation = $toolsDir
  url           = ''
  checksum      = $sha1hash
  checksumType  = 'sha1'
}

if(!$pp['Username'] -or !$pp['Password']) {
  throw @'
  An Oracle account is required to download SQL developer
  * Provide your Oracle credentials as package params to the installer and
    retry the installation:
    choco install oracle-sql-developer --params "'/Username:{userName} /Password:{password}'"
  * If you do not have an Oracle account, you can register for one here:
    https://profile.oracle.com/myprofile/account/create-account.jspx
'@
}

Write-Host 'Redirecting to Oracle Login...'
$loginPage = Invoke-WebRequest -Uri $url -SessionVariable session -Proxy $proxy.Addresss -ProxyCredential $proxy.Credentials

Write-Host 'Logging in...'

$licenseAcceptCookie = New-Object System.Net.Cookie -ArgumentList 'oraclelicense', 'accept-sqldev-cookie', '/', 'oracle.com'
$session.Cookies.Add($licenseAcceptCookie)

$loginFormFields = $loginPage.Forms['LoginForm'].Fields
$loginFormFields.ssousername = $pp['Username']
$loginFormFields.password = $pp['Password']

try {
  Invoke-WebRequest -Uri $loginSubmit -Method Post -WebSession $session -Body $loginFormFields -MaximumRedirection 2 -Proxy $proxy.Addresss -ProxyCredential $proxy.Credentials
}
catch {
  $msg = $_.ErrorDetails.Message
  if($msg -inotmatch 'AuthParam') {
    throw "Oracle login unsuccessful: $_"
  }
  $packageArgs.url = [regex]::Match($msg, '.*(http.*)\.').Groups[1].Value
  $packageArgs.url = $packageArgs.url.Replace('http', 'https')
}

Write-Host 'Oracle login successful'
Write-Debug "Authenticated download URL: $($packageArgs.url)"

Install-ChocolateyZipPackage @packageArgs
