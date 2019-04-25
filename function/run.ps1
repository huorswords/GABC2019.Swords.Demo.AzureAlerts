# {"WebhookName":"Alert1556104627331","RequestBody":"{\"schemaId\":\"azureMonitorCommonAlertSchema\",\"data\":{\"essentials\":{\"alertId\":\"/subscriptions/281a530a-b953-406d-beb7-59884b6efb86/providers/Microsoft.AlertsManagement/alerts/c8e3f7b8-96c8-4ea2-a9fe-4de4074036ce\",\"alertRule\":\"More than 2 seconds CPU\",\"severity\":\"Sev3\",\"signalType\":\"Metric\",\"monitorCondition\":\"Resolved\",\"monitoringService\":\"Platform\",\"alertTargetIDs\":[\"/subscriptions/281a530a-b953-406d-beb7-59884b6efb86/resourcegroups/gabc-azurealerts/providers/microsoft.web/sites/gabc-alerts-2019-api\"],\"originAlertId\":\"281a530a-b953-406d-beb7-59884b6efb86_GABC-AzureAlerts_microsoft.insights_metricAlerts_More than 2 seconds CPU_-1776721899\",\"firedDateTime\":\"2019-04-24T11:19:18.5412422Z\",\"resolvedDateTime\":\"2019-04-24T11:35:30.9540876Z\",\"description\":\"\",\"essentialsVersion\":\"1.0\",\"alertContextVersion\":\"1.0\"},\"alertContext\":{\"properties\":null,\"conditionType\":\"MultipleResourceMultipleMetricCriteria\",\"condition\":{\"windowSize\":\"PT1M\",\"allOf\":[{\"metricName\":\"CpuTime\",\"metricNamespace\":\"Microsoft.Web/sites\",\"operator\":\"GreaterThan\",\"threshold\":\"2\",\"timeAggregation\":\"Total\",\"dimensions\":[{\"name\":\"ResourceId\",\"value\":\"gabc-alerts-2019-api.azurewebsites.net\"}],\"metricValue\":0.0}],\"windowStartTime\":\"2019-04-24T11:31:06.226Z\",\"windowEndTime\":\"2019-04-24T11:32:06.226Z\"}}}}","RequestHeader":{"Expect":"100-continue","Host":"s2events.azure-automation.net","User-Agent":"IcMBroadcaster/1.0","X-CorrelationContext":"RkkKACgAAAACAAAAEACrIJytaX9KTKQ5ZjMD31scAQAQAIqkXYo7WQZCgYIDKYUu89w=","x-ms-request-id":"81d1d325-cb56-488a-8bd6-bec791f34aa7"}}

# Get the input request
$in = Get-Content $req -Raw | ConvertFrom-Json
Write-Output "IN"
Write-Output $in
if ([bool]($in.PSobject.Properties.name -match "RequestBody")) {
    Write-Host 'From Native Alerts'
    $json = $in.RequestBody | ConvertFrom-Json
    $status = $json.data.essentials.monitorCondition
    
    $regexExpression = '\/(?:subscriptions)\/(?<SUBSCRIPTION>[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})\/(?:resourcegroups)\/(?<RESOURCEGROUP>[a-z\-0-9\.]*)\/(?:providers\/microsoft.web\/sites)\/(?<APPSERVICE>[a-z\-0-9\.]*)'
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