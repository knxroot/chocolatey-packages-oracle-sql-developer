# proxy determination from Chocolatey scripts
function Get-ChocolateyProxy {
  param(
    [string] $url
  )

  $proxy = $null
  $creds = [System.Net.CredentialCache]::DefaultCredentials

  $webclient = new-object System.Net.WebClient
  if ($creds -ne $null) {
    $webClient.Credentials = $creds
  }

  $explicitProxy = $env:chocolateyProxyLocation
  $explicitProxyUser = $env:chocolateyProxyUser
  $explicitProxyPassword = $env:chocolateyProxyPassword

  if ($explicitProxy -ne $null) {

	  $proxy = New-Object System.Net.WebProxy($explicitProxy, $true)
	  if ($explicitProxyPassword -ne $null) {
      $passwd = ConvertTo-SecureString $explicitProxyPassword -AsPlainText -Force
	    $proxy.Credentials = New-Object System.Management.Automation.PSCredential ($explicitProxyUser, $passwd)
	  }

 	  Write-Host "Using explicit proxy server '$explicitProxy'."
  }
  elseif ($webclient.Proxy -and !$webclient.Proxy.IsBypassed($url)) {
    if ($creds -eq $null) {
      Write-Debug "Default credentials were null. Attempting backup method"
      $creds = Get-Credential
    }

    $proxyaddress = $webclient.Proxy.GetProxy($url).Authority

    $proxy = New-Object System.Net.WebProxy($proxyaddress)
    if($creds.UserName) {
      $proxy.Credentials = $creds
    }

    Write-Host "Using system proxy server '$proxyaddress'."
  }

  return $proxy
}
