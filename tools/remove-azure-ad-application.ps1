Param(
  [string]$objectId
)

# Login with your Azure Admin Account
# Add-AzureRmAccount

$obj = [GUID]$objectId
Write-Host  $obj
$result = Remove-AzureRmADServicePrincipal -ObjectId $obj
Write-Host $result