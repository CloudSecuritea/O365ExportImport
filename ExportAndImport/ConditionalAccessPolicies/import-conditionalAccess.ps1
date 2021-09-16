<#PSScriptInfo
.VERSION 0.1
.GUID 559d4445-fdcf-42e0-8f38-eacff1949a04
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
 This script will import all conditional access policies and named locations

.DESCRIPTION
 This script will import all conditional access policies and named locations

.PARAMETER client_Id
 Enter the client ID of the application created for this task

.PARAMETER client_Secret
 Enter the client Secret of the application created for this task

.PARAMETER tenant_Id
 Enter the tenant name

.PARAMETER location
 Enter the location where the JSON files have been stored

.EXAMPLE
 import-conditionalAccess.ps1 -client_Id <String> -client_Secret <string> -tenantName <String> -location <String>

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

#Conditional Access policies
$conditionalAccessPolicies = Get-ChildItem -Path "$($location)\Policy*"

#Named locations
$namedLocations = Get-ChildItem -Path "$($location)\Location*"

######################################
# Create Conditional Access policies #
######################################

$HeaderParams = @{
  'Content-Type'  = "application\json"
  'Authorization' = "Bearer $($ConnectGraph.access_token)"
}

try{
  foreach($policy in $conditionalAccessPolicies){
    $JSON = Get-Content $policy.fullName
    $response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
    write-host "Imported policy: $(($JSON | convertfrom-json).displayname)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}

try{
  foreach($namedLocation in $namedLocations){
    $JSON = Get-Content $namedLocation.fullName
    $response = Invoke-RestMethod -Headers $HeaderParams -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations" -UseBasicParsing -Method POST -ContentType "application/json" -Body $JSON
    write-host "Imported location: $(($JSON | convertfrom-json).displayname)" -ForegroundColor green
  }
}
catch{
  write-host "Error: $($_.Exception.Message)" -ForegroundColor red
}