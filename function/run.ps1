# Get the input request
$in = Get-Content $req -Raw | ConvertFrom-Json
Write-Output "IN"
Write-Output $in

$regexExpression = '\/(?:subscriptions)\/(?<SUBSCRIPTION>[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})\/(?:resourcegroups)\/(?<RESOURCEGROUP>[a-z\-0-9\.]*)\/(?:providers\/microsoft.web\/sites)\/(?<APPSERVICE>[a-z\-0-9\.]*)'
if ([bool]($in.PSobject.Properties.name -match "data")) {
    Write-Host 'From Native Alerts v2'
    $json = $in
    $status = $json.data.essentials.monitorCondition
    
    $alertPattern = [Regex]::new($regexExpression)
    $matches = $alertPattern.Matches($json.data.essentials.alertTargetIDs)

    $resourceGroupName = $matches.Groups[2]
    $appService = $matches.Groups[3]
}
else {
    Write-Host 'From AppInsights'
    $json = $in
    $status = $json.status
    $status = $json.status
    $resourceGroupName = $json.context.resourceGroupName
    $appService = $json.context.resourceName
}

Write-output "Status is $status"
if ($status -eq "Resolved") {
    Exit 0
}

if ($resourceGroupName -ne "") {
    # Application ID for our Azure Security Principal that we created and provided via Function Application Settings
    $username = $env:AzureAutomationAppID

    # Password for connection to Azure via Function Application Settings
    $pw = $env:AzureAutomationPWD
    $key = Get-Content 'D:\home\site\wwwroot\swords-reboot\gabc-alerts-2019.key'
    $password = $pw | ConvertTo-SecureString -key $key
    $credentials = New-Object System.Management.Automation.PSCredential $username, $password
    $AzureRMAccount = Add-AzureRmAccount -Credential $credentials -ServicePrincipal -TenantId $env:AzureAutomationTenantID
    If ($AzureRMAccount) { 
        Restart-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $appService
        write-output "==== WebApp restarted ====" $appService
    }
}