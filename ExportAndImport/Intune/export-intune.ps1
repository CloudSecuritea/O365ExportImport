<#PSScriptInfo
.VERSION 0.1
.GUID a7d9a727-03d3-4521-972a-0f46d7e21edc
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
 This script will export Intune policies

.DESCRIPTION
 This script will export Intune policies

.PARAMETER client_Id
 Enter the client ID of the application created for this task

.PARAMETER client_Secret
 Enter the client Secret of the application created for this task

.PARAMETER tenant_Id
 Enter the tenant id

.PARAMETER location
 Enter the location to store the .JSON files

.EXAMPLE
 export-intune.ps1 -client_Id <String> -client_Secret <string> -tenantName <String> -location <String>

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

$HeaderParams = @{
  'Content-Type'  = "application\json"
  'Authorization' = "Bearer $($ConnectGraph.access_token)"
}

#Compliance policies
$compliancePoliciesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies" -Method Get)
$compliancePolicies = $compliancePoliciesRequest.value

#Configuration policies
$configurationPoliciesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" -Method Get)
$configurationPolicies = $ConfigurationPoliciesRequest.value

#Endpoint Security policies
$endpointSecurityPoliciesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/intents" -Method Get)
$endpointSecurityPolicies = $endpointSecurityPoliciesRequest.value

$endpointSecurityTemplatesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/templates?`$filter=(isof(%27microsoft.graph.securityBaselineTemplate%27))" -Method Get)
$endpointSecurityTemplates = $endpointSecurityTemplatesRequest.value

#Managed app policies
$managedAppPoliciesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceAppManagement/managedAppPolicies" -Method Get)
$managedAppPolicies = $managedAppPoliciesRequest.value

##################
# Export to JSON #
##################

#Compliance policies
try{
  foreach($policy in $compliancePolicies){
    $filePath = "$($location)\Compliance - $($policy.displayName).json"
    $policy | convertto-json -Depth 10 | out-file $filePath
    write-host "Exported policy: $($policy.displayName)" -ForegroundColor green
  }  
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

#Configuration policies
try{
  foreach($policy in $ConfigurationPolicies){
    $filePath = "$($location)\Configuration - $($policy.displayName).json"
    $policy | convertto-json -Depth 10 | out-file $filePath
    $Clean = Get-Content $filePath | Select-String -Pattern '"id":', '"createdDateTime":', '"modifiedDateTime":', '"version":', '"supportsScopeTags":' -notmatch
    $Clean | Out-File -FilePath $filePath
    write-host "Exported policy: $($policy.displayName)" -ForegroundColor green
  }  
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

#Endpoint Security policies
try{
  foreach($policy in $endpointSecurityPolicies){
    $filePath = "$($location)\EndPoint Security - $($policy.displayName).json"
    
    # Creating object for JSON output
    $JSON = New-Object -TypeName PSObject

    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'displayName' -Value $policy.displayName
    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'description' -Value $policy.description
    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'roleScopeTagIds' -Value $policy.roleScopeTagIds
    $ES_Template = $endpointSecurityTemplates | ?  { $_.id -eq $policy.templateId }
    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'TemplateDisplayName' -Value $ES_Template.displayName
    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'TemplateId' -Value $ES_Template.id
    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'versionInfo' -Value $ES_Template.versionInfo

    # Getting all categories in specified Endpoint Security Template
    $categoriesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/templates/$($ES_Template.id)/categories" -Method Get)
    $categories = $categoriesRequest.value

    $settings = @()
    foreach($category in $Categories){
      $policyId = $policy.id
      $categoryId = $category.id
      $categorySettingsRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/beta/deviceManagement/intents/$policyId/categories/$categoryId/settings?`$expand=Microsoft.Graph.DeviceManagementComplexSettingInstance/Value" -Method Get)
      $Settings += $categorySettingsRequest.value
    }

    # Adding All settings to settingsDelta ready for JSON export
    Add-Member -InputObject $JSON -MemberType 'NoteProperty' -Name 'settingsDelta' -Value @($Settings)

    $JSON | convertto-json -depth 5 | out-file $filePath
    
    write-host "Exported policy: $($policy.displayName)" -ForegroundColor green
  }  
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

#Managed app policies
try{
  foreach($policy in $managedAppPolicies){
    $filePath = "$($location)\Managed App - $($policy.displayName).json"
    $policy | convertto-json -Depth 10 | out-file $filePath
    $Clean = Get-Content $filePath | Select-String -Pattern '"id":', '"createdDateTime":', '"lastModifiedDateTime":', '"version":' -notmatch
    $Clean | Out-File -FilePath $filePath
    write-host "Exported policy: $($policy.displayName)" -ForegroundColor green
  }  
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}