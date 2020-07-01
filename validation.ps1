#Replace launchid to the ODLID you are checking
#Replace global username and password with the account you are using to validate example:admin@msazurelabs.onmicrosoft.com
#Run the script in the path where you have downloaded AIAD module

Connect-AzAccount
$subs = Get-AzSubscription | Where-Object { $_.Name -like "*Azure Labs C*" -or $_.Name -like "*Azure Labs D*" } | Sort-Object -Property Name
foreach($sub in $subs)
{
  Select-AzSubscription -Subscription $sub.Id 

  Remove-Module aiadmodule
  Import-Module ".\aiadmodule"
 
 $rgs = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "Synapse-AIAD-*" -and $_.Tags -ne $null -and $_.Tags["LaunchId"] -eq "7137" } 
  foreach($rg in $rgs)
 {
   $uniqueId= $rg.Tags['DeploymentId']
   $global:userName="admin@msazurelabs.onmicrosoft.com"
   $global:password="Spektra@1234"

$clientId="1950a258-227b-4e31-a9cf-717495945fc2"
$global:sqlPassword = "password.1!!"

$subscriptionId = (Get-AzContext).Subscription.Id
$tenantId = (Get-AzContext).Tenant.Id

$templatesPath = ".\Automation\files\templates"
$datasetsPath = ".\Automation\files\datasets" 
$pipelinesPath = ".\Automation\files\pipelines"
$sqlScriptsPath = ".\Automation\files\sql"
$dataflowPath= ".\Automation\files\dataflows"
$workspaceName = "asaworkspace$($uniqueId)"
$dataLakeAccountName = "asadatalake$($uniqueId)"
$blobStorageAccountName = "asastore$($uniqueId)"
$sqlPoolName = "SQLPool01"
$integrationRuntimeName = "AzureIntegrationRuntime01"
$sparkPoolName = "SparkPool01"


$global:sqlEndpoint = "$($workspaceName).sql.azuresynapse.net"
$global:sqlUser = "asa.sql.admin"

$ropcBodyCore = "client_id=$($clientId)&username=$($userName)&password=$($password)&grant_type=password"
$global:ropcBodySynapse = "$($ropcBodyCore)&scope=https://dev.azuresynapse.net/.default"
$global:ropcBodyManagement = "$($ropcBodyCore)&scope=https://management.azure.com/.default"
$global:ropcBodySynapseSQL = "$($ropcBodyCore)&scope=https://sql.azuresynapse.net/.default"

$global:synapseToken = ""
$global:synapseSQLToken = ""
$global:managementToken = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

#Check linked services
$asaArtifacts = [ordered]@{

        "asadatalake01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "asastore01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "sqlpool01" = @{
                Category = "linkedServices"
                Valid = $false
        }
        "PowerBIWorkspace" = @{
                Category = "linkedServices"
                Valid = $false
        }
        
}

foreach ($asaArtifactName in $asaArtifacts.Keys) {
        try {
                 "Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts[$asaArtifactName]["Valid"] = $true
                "OK"
        }
        catch {
                 "Not found!"
                Write-Host $_
                $overallStateIsValid = $false
        }
}

#Check spark pool
$sparkPool = Get-SparkPool -SubscriptionId $sub.SubscriptionId -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName
if ($sparkPool -eq $null) {
          "$uniqueId The Spark pool $($sparkPoolName) was not found"
        $overallStateIsValid = $false
}
else {
       $uniqueId  + " Spark pool " + $true
       $overallStateIsValid = $true
}

#Check workspace
$ws= Get-Workspace $sub.SubscriptionId $rg.ResourceGroupName $WorkspaceName
if ($ws -eq $null)
{
    $overallStateIsValid= $false
}

else
{
   $uniqueId  + " Synapse Workspace " + $true
   $overallStateIsValid = $true
}

#Check sqlpool
$sqlPool = Get-SQLPool -SubscriptionId $sub.SubscriptionId -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlPool -eq $null) {
       "The SQL pool $($sqlPoolName) was not found"
        $overallStateIsValid = $false
}
 else {
      $uniqueId  + "sqlpool " + $true
      $overallStateIsValid = $true
      }
 
 
 #Check pipeline status
 $result=Run-pipeline -WorkspaceName $workspaceName

    $result.value | ForEach-Object -Process {

    if ( $_.status -eq "Succeeded") {

    Write-Output " " $workspacename $_.pipelineName  $_.status
    $overallStateIsValid = $true
    }
    else {

    Write-Output " " $workspacename $_.pipelineName  "Failed"
    $overallStateIsValid = $false
    } }
    
#Overallstate      
if ($overallStateIsValid -eq $true) {
     Write-Host "$uniqueId  Validation Passed" -ForegroundColor green
}
else {
    Write-Host "$uniqueId  Validation failed" -ForegroundColor red
}
 
 }}
