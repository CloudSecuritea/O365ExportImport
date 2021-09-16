<#PSScriptInfo
.VERSION 0.1
.GUID 9ef7a4b3-c6bb-488c-8eb4-39278901d6a9
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
 This script will export all conditional access policies and named locations

.DESCRIPTION
 This script will export all conditional access policies and named locations

.PARAMETER client_Id
 Enter the client ID of the application created for this task

.PARAMETER client_Secret
 Enter the client Secret of the application created for this task

.PARAMETER tenant_Id
 Enter the tenant id

.PARAMETER location
 Enter the location to store the .JSON files

.EXAMPLE
 export-conditionalAccess.ps1 -client_Id <String> -client_Secret <string> -tenantName <String> -location <String>

.NOTES
 Version:        0.1
 Author:         Maarten Peeters
 Creation Date:  15/09/2021
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

#Conditional Access policies
$conditionalAccessPoliciesRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" -Method Get)
$conditionalAccessPolicies = $conditionalAccessPoliciesRequest.value

#Named locations
$namedLocationsRequest = (Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations" -Method Get)
$namedLocations = $namedLocationsRequest.value

##################
# Export to JSON #
##################

try{
  foreach($policy in $conditionalAccessPolicies){
    $filePath = "$($location)\Policy - $($policy.displayName).json"
    $policy | convertto-json -Depth 10 | out-file $filePath
    $Clean = Get-Content $filePath | Select-String -Pattern '"id":', '"createdDateTime":', '"modifiedDateTime":' -notmatch
    $Clean | Out-File -FilePath $filePath
    write-host "Exported policy: $($policy.displayName)" -ForegroundColor green
  }  
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

try{
  foreach($namedLocation in $namedLocations){
      $filePath = "$($location)\Location - $($namedLocation.displayName).json"
      $namedLocation | convertto-json -Depth 10 | out-file $filePath
      $Clean = Get-Content $filePath | Select-String -Pattern '"id":', '"createdDateTime":', '"modifiedDateTime":' -notmatch
      $Clean | Out-File -FilePath $filePath
      write-host "Exported location: $($namedLocation.displayName)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}