####################################################################################################################
####### Powershell Script to Validate the AIAD Deployments  ########################################################

## 1. Ensure you are replacing the ODL ID with the actual ODL ID you want to validate against ######################
## 2. Ensure to replace value of $stopsqlpooloncesuccessfull to Yes if you want to stop the sql pools once the #####
#      validation is passed                                                                                      ###
## 3. Ensure to replace value of $stopVMsoncesuccessfull to Yes if you want to stop the Vritual Machines once the ##
#      validation is passed                                                                                        #
####################################################################################################################  



#Connect-AzAccount
 $timer = (Get-Date) -replace "/", "-" `
-replace " ","" `
-replace ":", "-"




$odlId = "7137"  ## Replace with the ODL Id of the lab
$stopsqlpooloncesuccessfull = "No"  ## Allowed values "Yes" or "No"
$stopVMsoncesuccessfull = "yes"  ## Allowed values "Yes" or "No"



$filepathtosave = "C:\ODL" + $odlId + "-" + $timer + ".csv"

$subs = Get-AzSubscription | Where-Object { $_.Name -like "*Azure Labs C*" -or $_.Name -like "*Azure Labs D*" } | Sort-Object -Property Name
foreach($sub in $subs)
{
Select-AzSubscription -Subscription $sub.Id 

  Remove-Module aiadmodule
  Import-Module ".\aiadmodule"
 
 $rgs = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -like "Synapse-AIAD*" -and $_.Tags -ne $null -and $_.Tags["LaunchId"] -eq $odlId }
  
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

$global:pipelinesstatus = ""

$global:tokenTimes = [ordered]@{
        Synapse = (Get-Date -Year 1)
        SynapseSQL = (Get-Date -Year 1)
        Management = (Get-Date -Year 1)
}

$global:overallstatus = ""
   $global:count = 0
      $global:lscount = 0
$global:overallStateIsValid = "true"
$global:overallasalinkedStateIsValid = "Found"
$global:overallsparkpoolStateIsValid = "Found"
$global:overallworkspaceStateIsValid = "Found"

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
                "$uniqueId : Checking $($asaArtifactName) in $($asaArtifacts[$asaArtifactName]["Category"])"
                $result = Get-ASAObject -WorkspaceName $workspaceName -Category $asaArtifacts[$asaArtifactName]["Category"] -Name $asaArtifactName
                $asaArtifacts[$asaArtifactName]["Valid"] = $true
                "OK"
        }
        catch {
                 "Not found!"
                Write-Host $_
                $overallStateIsValid = "false"
                
                $lscount = $lscount + 1
        }
}
if ($lscount -gt 0){
$overallasalinkedStateIsValid = "$($lscount)" + "-LinkedServiceNotFound"

}

#Check spark pool
$sparkPool = Get-SparkPool -SubscriptionId $sub.SubscriptionId -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $workspaceName -SparkPoolName $sparkPoolName
if ($sparkPool -eq $null) {
          "$uniqueId The Spark pool $($sparkPoolName) was not found"
        $overallStateIsValid = "false"
        $overallsparkpoolStateIsValid = "NotFound"
}
else {
       $uniqueId  + " Spark pool " + $true
       
}

#Check workspace
$ws= Get-Workspace $sub.SubscriptionId $rg.ResourceGroupName $WorkspaceName
if ($ws -eq $null)
{
    $overallStateIsValid= "false"
    $overallworkspaceStateIsValid = "NotFound"
}

else
{
   $uniqueId  + " Synapse Workspace " + $true
   
}

#Check sqlpool
$sqlPool = Get-SQLPool -SubscriptionId $sub.SubscriptionId -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlPool -eq $null) {
       "The SQL pool $($sqlPoolName) was not found"
        $overallStateIsValid = "false"
        $sqlpoolstatus.properties.status = "NotFound"
}
 else {
      
      $uniqueId  + "sqlpool" + $true
      
      
 
 #Checksqlpool status
 $sqlpoolstatus = Get-SQLPool -SubscriptionId $sub.SubscriptionId -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName
if ($sqlpoolstatus.properties.status -ne "Online")
{
   Write-Host "$uniqueId : SQLPOOL is paused" -ForegroundColor yellow

}

else{
   Write-Host "$uniqueId : SQLPOOL is $($sqlpoolstatus.properties.status) " -ForegroundColor yellow

}
}
 #Check pipeline status
 $pipelineresult=Run-pipeline -WorkspaceName $workspaceName

         $ExpectedPipelineName = (
            'Import WWI Data',
            'Import WWI Data - Fact Sale Full',
            'Import WWI Perf Data - Fact Sale Fast',
            'Import WWI Perf Data - Fact Sale Slow'
    )
    $count = 0

    $pipelineresult.value | ForEach-Object -Process {
    
   
        if ( ($_.status -eq "Succeeded") -and ($ExpectedPipelineName -contains $_.pipelineName ) ) {

            Write-Output " " $workspacename $_.pipelineName  $_.status
            $count = $count + 1; 
    
        }
        elseif ( $_.status -eq "InProgress"){

            Write-Output " " $workspacename $_.pipelineName  $_.status
            $pipelinesstatus = "Pending"
     
        }
        
        else{

            Write-Output " " $workspacename $_.pipelineName  $_.status
           
      
        }

    }
     if ($pipelineresult.value.Count -eq 0 ){
         $overallpipelinestatus = "NotInitiated"
 
    }
    elseif (($count -ne 4) -and ($pipelinesstatus -ne "Pending")){
         $overallpipelinestatus = "Failed"

    }
     elseif (($count -ne 4) -and ($pipelinesstatus -eq "Pending")){
         $overallpipelinestatus = "Pending"

    }

    ## Absolute True Condition
    elseif ($count -eq 4 ){
         $overallpipelinestatus = "Success"
    }


#Overallstate  



    
    ## Absolute True Condition
    if (($overallStateIsValid -eq "true") -and ($overallpipelinestatus -eq "Success")  ) {

        Write-Host "$uniqueId  Validation Passed" -ForegroundColor green
        $overallstatus = "Passed"
        $overallstatus

        if (($sqlpoolstatus.properties.status -eq "Online") -and ($stopsqlpooloncesuccessfull -eq "Yes")){
            Write-Host "$uniqueId : Pausing SQLPOOL" -ForegroundColor yellow
            Control-SQLPool -SubscriptionId $sub.SubscriptionId -ResourceGroupName $rg.ResourceGroupName -WorkspaceName $workspaceName -SQLPoolName $sqlPoolName -Action pause
            
        }
        $vmrgname = "lab-ti-" + $uniqueId
        $vmName = "labvm-"+ $uniqueId

        if ($stopVMsoncesuccessfull -eq "No"){
        ##Stopping VMs
        $vmstatus= Stop-AzVM -ResourceGroupName $vmrgname -Name $vmName -Force
        }
    }
    elseif (($overallpipelinestatus -eq "Pending") -and ($overallStateIsValid -eq "true")) {
            $overallstatus = "PipelingRunning"
            Write-Host "$uniqueId  Validation Pending - Pipeline is running" -ForegroundColor yellow
            $overallstatus
        }

         elseif (($overallpipelinestatus -eq "NotInitiated") -and ($overallStateIsValid -ne "false") ){
                 $overallstatus = "PipelineNotIniated"
            Write-Host "$uniqueId  Validation Pending - Pipeline Not Initiated Yet" -ForegroundColor yellow
            $overallstatus
                }   
    else{
            $overallstatus = "Failed"
            Write-Host "$uniqueId  Validation failed" -ForegroundColor red
            $overallstatus
        
        } 

                $finalresult = $pipelineresult | Select-Object -Property @{l="DeploymentId";e={$uniqueId}}, @{l="ValidationStatus";e={$overallstatus}}, @{l="LinkedServiceStatus";e={$overallasalinkedStateIsValid}}, @{l="SparkPoolStatus";e={$overallsparkpoolStateIsValid}}, @{l="PipelineStatus";e={$overallpipelinestatus}}, @{l="SQLPoolStatus";e={$sqlpoolstatus.properties.status}}, @{l="Workspace Status";e={$overallworkspaceStateIsValid}},@{l="VM Stop Status";e={$vmstatus}}

 $finalresult | Export-Csv -Path $filepathtosave -NoTypeInformation -Append

    }
 }
 



 $showastable = Import-Csv -Path $filepathtosave

 $showastable | Format-Table

