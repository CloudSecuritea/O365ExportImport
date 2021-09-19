<#PSScriptInfo
.VERSION 0.1
.GUID c70a2663-468a-49cc-bc4a-1efd971b78cd
.AUTHOR
 Maarten Peeters
.COMPANYNAME
 CloudSecuritea
.COPYRIGHT
.TAGS
.LICENSEURI
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.RELEASENOTES
 Version 0.1: Original published version.
#>

<#
.SYNOPSIS
 This script will import Intune policies

.DESCRIPTION
 This script will import Intune policies

.PARAMETER client_Id
 Enter the client ID of the application created for this task

.PARAMETER client_Secret
 Enter the client Secret of the application created for this task

.PARAMETER tenant_Id
 Enter the tenant id

.PARAMETER location
 Enter the location to store the .JSON files

.EXAMPLE
 import-intune.ps1 -client_Id <String> -client_Secret <string> -tenantName <String> -location <String>

.NOTES
 Version:        0.1
 Author:         Maarten Peeters
 Creation Date:  17/09/2021
 Purpose/Change: Init

 Version Changes: 
 0.1             Initial
#>

param(
  [Parameter(mandatory = $true)]
  [String]$client_Id,
  [Parameter(mandatory = $true)]
  [String]$client_Secret,
  [Parameter(mandatory = $true)]
  [String]$tenant_Id,
  [Parameter(mandatory = $true)]
  [String]$location
)

####################
# Connect to Graph #
####################
$Body = @{    
  Grant_Type    = "client_credentials"
  resource      = "https://graph.microsoft.com"
  client_id     = $client_Id
  client_secret = $client_Secret
  } 
  
  $ConnectGraph = Invoke-RestMethod -Uri "https://login.microsoft.com/$tenant_Id/oauth2/token?api-version=1.0" -Method POST -Body $Body 

########################
# Variable Collections #
########################

#Compliance policies
$compliancePolicies = Get-ChildItem -Path "$($location)\Compliance*"

#Configuration policies
$ConfigurationPolicies = Get-ChildItem -Path "$($location)\Configuration*"

#Endpoint Security policies
$endpointSecurityPolicies = Get-ChildItem -Path "$($location)\Endpoint Security*"

#Managed App policies
$managedAppPolicies = Get-ChildItem -Path "$($location)\Managed App*"

##################
# Export to JSON #
##################

$HeaderParams = @{
  'Content-Type'  = "application\json"
  'Authorization' = "Bearer $($ConnectGraph.access_token)"
}

#Compliance policies
try{
  foreach($policy in $compliancePolicies){
    $JSON = Get-Content $policy.fullName

    # If missing, adds a default required block scheduled action to the compliance policy request body, as this value is not returned when retrieving compliance policies.
    $scheduledActionsForRule = '"scheduledActionsForRule":[{"ruleName":"PasswordRequired","scheduledActionConfigurations":[{"actionType":"block","gracePeriodHours":0,"notificationTemplateId":"","notificationMessageCCList":[]}]}]'
    $JSON = $JSON.trimend("}")
    $JSON = $JSON.TrimEnd() + "," + "`r`n"
    $JSON = $JSON + $scheduledActionsForRule + "`r`n" + "}"

    $response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
    write-host "Imported policy: $(($JSON | convertfrom-json).displayname)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

#Configuration policies
try{
  foreach($policy in $ConfigurationPolicies){
    $JSON = Get-Content $policy.fullName
    $response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
    write-host "Imported policy: $(($JSON | convertfrom-json).displayname)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

#Endpoint Security policies
try{
  foreach($policy in $endpointSecurityPolicies){
    $JSON = Get-Content $policy.fullName
    $JSON_Convert = $JSON | ConvertFrom-Json
    $JSON_TemplateId = $JSON_Convert.templateId
    $response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/templates/$JSON_TemplateId/createInstance" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
    write-host "Imported policy: $(($JSON | convertfrom-json).displayname)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

#Managed App policies
try{
  foreach($policy in $managedAppPolicies){
    $JSON = Get-Content $policy.fullName
    $JSON_Convert = $JSON | ConvertFrom-Json
    $JSON_TemplateId = $JSON_Convert.templateId
    $response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
    write-host "Imported policy: $(($JSON | convertfrom-json).displayname)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}