# {"WebhookName":"Alert1556104627331","RequestBody":"{\"schemaId\":\"azureMonitorCommonAlertSchema\",\"data\":{\"essentials\":{\"alertId\":\"/subscriptions/281a530a-b953-406d-beb7-59884b6efb86/providers/Microsoft.AlertsManagement/alerts/c8e3f7b8-96c8-4ea2-a9fe-4de4074036ce\",\"alertRule\":\"More than 2 seconds CPU\",\"severity\":\"Sev3\",\"signalType\":\"Metric\",\"monitorCondition\":\"Resolved\",\"monitoringService\":\"Platform\",\"alertTargetIDs\":[\"/subscriptions/281a530a-b953-406d-beb7-59884b6efb86/resourcegroups/gabc-azurealerts/providers/microsoft.web/sites/gabc-alerts-2019-api\"],\"originAlertId\":\"281a530a-b953-406d-beb7-59884b6efb86_GABC-AzureAlerts_microsoft.insights_metricAlerts_More than 2 seconds CPU_-1776721899\",\"firedDateTime\":\"2019-04-24T11:19:18.5412422Z\",\"resolvedDateTime\":\"2019-04-24T11:35:30.9540876Z\",\"description\":\"\",\"essentialsVersion\":\"1.0\",\"alertContextVersion\":\"1.0\"},\"alertContext\":{\"properties\":null,\"conditionType\":\"MultipleResourceMultipleMetricCriteria\",\"condition\":{\"windowSize\":\"PT1M\",\"allOf\":[{\"metricName\":\"CpuTime\",\"metricNamespace\":\"Microsoft.Web/sites\",\"operator\":\"GreaterThan\",\"threshold\":\"2\",\"timeAggregation\":\"Total\",\"dimensions\":[{\"name\":\"ResourceId\",\"value\":\"gabc-alerts-2019-api.azurewebsites.net\"}],\"metricValue\":0.0}],\"windowStartTime\":\"2019-04-24T11:31:06.226Z\",\"windowEndTime\":\"2019-04-24T11:32:06.226Z\"}}}}","RequestHeader":{"Expect":"100-continue","Host":"s2events.azure-automation.net","User-Agent":"IcMBroadcaster/1.0","X-CorrelationContext":"RkkKACgAAAACAAAAEACrIJytaX9KTKQ5ZjMD31scAQAQAIqkXYo7WQZCgYIDKYUu89w=","x-ms-request-id":"81d1d325-cb56-488a-8bd6-bec791f34aa7"}}

[OutputType("PSAzureOperationResponse")]
param ( 
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

$ErrorActionPreference = "stop"
if ($WebhookData) {
    $json = $WebhookData.RequestBody | ConvertFrom-Json
    $regexExpression = '\/(?:subscriptions)\/(?<SUBSCRIPTION>[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})\/(?:resourcegroups)\/(?<RESOURCEGROUP>[a-z\-0-9\.]*)\/(?:providers\/microsoft.web\/sites)\/(?<APPSERVICE>[a-z\-0-9\.]*)'
    $alertPattern = [Regex]::new($regexExpression)
    $matches = $alertPattern.Matches($json.data.essentials.alertTargetIDs)

    $subscription = $matches.Groups[1]
    $resourceGroupName = $matches.Groups[2]
    $appService = $matches.Groups[3]
	
    Write-output "Status is " $WebhookData.data.essentials.monitorCondition
    if ($WebhookData.data.essentials.monitorCondition -eq "Resolved") {	
        Exit 0
    }
    else {
        Write-Output $resourceGroupName
        Write-Output $appService
		
        if ($resourceGroupName -ne "") {
            # Authenticate to Azure by using the service principal and certificate. Then, set the subscription.
            Write-Verbose "Authenticating to Azure with service principal and certificate" -Verbose
            $ConnectionAssetName = "AzureRunAsConnection"
            Write-Verbose "Get connection asset: $ConnectionAssetName" -Verbose
            $Conn = Get-AutomationConnection -Name $ConnectionAssetName
            if ($null -eq $Conn) {
                throw "Could not retrieve connection asset: $ConnectionAssetName. Check that this asset exists in the Automation account."
            }
			
            Write-Verbose "Authenticating to Azure with service principal." -Verbose
            Add-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint | Write-Verbose
            Write-Verbose "Setting subscription to work against: $subscription" -Verbose
            Set-AzureRmContext -SubscriptionId $subscription -ErrorAction Stop | Write-Verbose
            Restart-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $appService
            write-output "==== WebApp restarted ====" $appService
        }
    }	
}