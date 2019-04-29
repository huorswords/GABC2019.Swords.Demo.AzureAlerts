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
	
    Write-output "Status is " $json.data.essentials.monitorCondition
    if ($json.data.essentials.monitorCondition -eq "Resolved") {	
        Exit 0
    }
        
    if ($resourceGroupName -ne "") {
        Write-Output $resourceGroupName
        Write-Output $appService
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