Param(
  [string]$Url,
  [string]$KeyFileName,
  [String]$Secret  
)

Function Get-EncryptedPassword
{
  param (
    [Parameter(Mandatory=$true,HelpMessage='Please specify the key file path')][String]$KeyPath,
    [Parameter(Mandatory=$true,HelpMessage='Please specify password in clear text')][ValidateNotNullOrEmpty()][String]$Password
  )
  
  Write-Host "> KeyPath: " $KeyPath
  Write-Host "> Pass: " $Password
  
  $AESKey = New-Object Byte[] 32
  [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
  
  Write-Host "> AES: " $AESKey
  
  # file to output the encrypted key too
  Set-Content $KeyPath $AESKey
  
  $secPw = ConvertTo-SecureString -AsPlainText $Password -Force
  $encryptedpass = ConvertFrom-SecureString $secPw -Key $AESKey
  
  Write-Host "> Encrypted pass: " $encryptedpass
  
  $d = [ordered]@{Encrypted=$encryptedpass; Secured=$secPw}
  $obj = New-Object PSObject
  Add-Member -InputObject $obj NotePropertyMembers $d -TypeName Password
  return $obj
}

## CONFIGURATION
if ($Url -eq "") {
	$Url = "https://gabc-alerts-2019-api.azurewebsites.net"
}

if ($Secret -eq "") {
	$Secret = "gabc-alerts-2019"
}

if ($KeyFileName -eq "") {
  $KeyFileName = "gabc-alerts-2019"
}

$path = "$KeyFileName.key"

$encryptedpass = Get-EncryptedPassword -KeyPath $path -Password $Secret

# Login with your Azure Admin Account
Add-AzureRmAccount

# Create an App that will be used by the Azure Automation Function App
$app = New-AzureRmADApplication -DisplayName "$url Function App" -HomePage $url -IdentifierUris $url -Password $encryptedpass.NotePropertyMembers["Secured"]

# Create the App Service Principal
New-AzureRmADServicePrincipal -ApplicationId $app.ApplicationId

# wait for replication
Start-Sleep 30

# Assign Role DevTest Labs User which provides the ability to view everything and connect, start, restart, and shutdown virtual machines
New-AzureRmRoleAssignment -RoleDefinitionName 'Website Contributor' -ServicePrincipalName $app.ApplicationId

# Get the TenantID (I only have one)
$tenant = (Get-AzureRmSubscription).TenantId

Write-Host "AzureObjectId" $app.ObjectId
Write-Host "AzureAutomationTenantID: " $tenant[0] 
Write-Host "AzureAutomationAppID: " $app.ApplicationId.Guid
Write-Host "AzureAutomationPWD: " $encryptedpass.NotePropertyMembers["Encrypted"]
Write-Host "AzureAutomationSecured: " $encryptedpass.NotePropertyMembers["Secured"]

## TEST
# Application ID for our Azure Security Principal that we created and provided via Function Application Settings
# Create PS Creds
$credentials = New-Object System.Management.Automation.PSCredential $app.ApplicationId.Guid, $encryptedpass.NotePropertyMembers["Secured"]

# Login
$AzureRMAccount = Add-AzureRmAccount -Credential $credentials -ServicePrincipal -TenantId $tenant[0]
Write-Host $AzureRMAccount

return $app.ObjectId