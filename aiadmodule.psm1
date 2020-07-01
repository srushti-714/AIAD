function Assign-SynapseRole {

    param(    
    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $RoleId,

    [parameter(Mandatory=$true)]
    [String]
    $PrincipalId
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/rbac/roleAssignments?api-version=2020-02-01-preview"
    $method = "POST"

    $id = $RoleId + "-" + $PrincipalId
    $body = "{ id: ""$id"", roleId: ""$RoleId"", principalId: ""$PrincipalId"" }"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method $method -Body $body -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"

return $result
}
function Refresh-Token {
    param(
    [parameter(Mandatory=$true)]
    [String]
    $TokenType
    )

    if ($TokenType -eq "Synapse") {
        $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
            -Method POST -Body $global:ropcBodySynapse -ContentType "application/x-www-form-urlencoded"
        $global:synapseToken = $result.access_token
    } elseif ($TokenType -eq "SynapseSQL") {
        $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
            -Method POST -Body $global:ropcBodySynapseSQL -ContentType "application/x-www-form-urlencoded"
        $global:synapseSQLToken = $result.access_token
    } elseif ($TokenType -eq "Management") {
        $result = Invoke-RestMethod  -Uri "https://login.microsoftonline.com/msazurelabs.onmicrosoft.com/oauth2/v2.0/token" `
            -Method POST -Body $global:ropcBodyManagement -ContentType "application/x-www-form-urlencoded"
        $global:managementToken = $result.access_token
    } else {
        throw "The token type $($TokenType) is not supported."
    }
}

function Ensure-ValidTokens {

    for ($i = 0; $i -lt $tokenTimes.Count; $i++) {
        Ensure-ValidToken $($tokenTimes.Keys)[$i]
    }
}

function Ensure-ValidToken {
    param(
        [parameter(Mandatory=$true)]
        [String]
        $TokenName
    )

    $refTime = Get-Date

    if (($refTime - $tokenTimes[$TokenName]).TotalMinutes -gt 30) {
        Write-Information "Refreshing $($TokenName) token."
        Refresh-Token $TokenName
        $tokenTimes[$TokenName] = $refTime
    }
}
function Get-SparkPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SparkPoolName
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/bigDataPools/$($SparkPoolName)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"

    return $result
}

function Get-SQLPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/sqlPools/$($SQLPoolName)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"

    return $result
}
function Get-ASAObject {
    
    param(
   
    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Category,

    [parameter(Mandatory=$true)]
    [String]
    $Name
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/$($Category)/$($Name)?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    
    return $result
}
function List-StorageAccountKeys {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $Name
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Storage/storageAccounts/$($Name)/listKeys?api-version=2015-05-01-preview"

    Write-Debug "Calling endpoint $uri"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method POST -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"
 
    Write-Debug $result

    return $result.key1
}
function Get-Workspace {
    
    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)?api-version=2019-06-01-preview"

    Ensure-ValidTokens

    try {
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $managementToken" }  
        return $result  
    }
    catch {
        return $null
    }
}
function Get-Pipeline {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $Name,
   
    [parameter(Mandatory=$true)]
    [String]
    $RunId
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/pipelines/$($Name)/$($RunId)?api-version=2018-06-01"

    Ensure-ValidTokens
   
try {   
 $result = $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    
    return $result 
}
catch{
return $null
    }
}
function Get-PipelineRun {

    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName
    )

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/pipelineruns/queryPipelineRuns?api-version=2019-06-01-preview"

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method PUT -Body $item -Headers @{ Authorization="Bearer $synapseToken" } -ContentType "application/json"

    
    return $result   
}

function Wait-ForPipelineRun {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $RunId
    )

    Write-Information "Waiting for any pending operation to be properly triggered..."
    Start-Sleep -Seconds 20

    $result = Get-PipelineRun -WorkspaceName $WorkspaceName -RunId $RunId

    while ($result.status -eq "InProgress") {
        
        Write-Information "Waiting for operation to complete..."
        Start-Sleep -Seconds 10
        $result = Get-PipelineRun -WorkspaceName $WorkspaceName -RunId $RunId
    }

    return $result
}
function Run-Pipeline {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName
)

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/queryPipelineRuns?api-version=2019-06-01"
 $result = Invoke-RestMethod  -Uri $uri -Method POST -Headers @{ Authorization="Bearer $synapseToken" }
    Ensure-ValidTokens
   
    return $result
}

function Wait-ForOperation {
    
    param(

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$false)]
    [String]
    $OperationId
    )

    if ([string]::IsNullOrWhiteSpace($OperationId)) {
        Write-Information "Cannot wait on an empty operation id."
        return
    }

    $uri = "https://$($WorkspaceName).dev.azuresynapse.net/operationResults/$($OperationId)?api-version=2019-06-01-preview"
    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }

    while ($result.status -ne $null) {
        
        if ($result.status -eq "Failed") {
            throw $result.error
        }

        Write-Information "Waiting for operation to complete (status is $($result.status))..."
        Start-Sleep -Seconds 10
        Ensure-ValidTokens
        $result = Invoke-RestMethod  -Uri $uri -Method GET -Headers @{ Authorization="Bearer $synapseToken" }
    }

    return $result
}
function Control-SQLPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$true)]
    [String]
    $Action,

    [parameter(Mandatory=$false)]
    [String]
    $SKU
    )

    $uri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourcegroups/$($ResourceGroupName)/providers/Microsoft.Synapse/workspaces/$($WorkspaceName)/sqlPools/$($SQLPoolName)#ACTION#?api-version=2019-06-01-preview"
    $method = "POST"
    $body = $null

    if (($Action.ToLowerInvariant() -eq "pause") -or ($Action.ToLowerInvariant() -eq "resume")) {

        $uri = $uri.Replace("#ACTION#", "/$($Action)")

    } elseif ($Action.ToLowerInvariant() -eq "scale") {
        
        $uri = $uri.Replace("#ACTION#", "")
        $method = "PATCH"
        $body = "{""sku"":{""name"":""$($SKU)""}}"

    } else {
        
        throw "The $($Action) control action is not supported."

    }

    Ensure-ValidTokens
    $result = Invoke-RestMethod  -Uri $uri -Method $method -Body $body -Headers @{ Authorization="Bearer $managementToken" } -ContentType "application/json"

    return $result
}



function Wait-ForSQLPool {

    param(
    [parameter(Mandatory=$true)]
    [String]
    $SubscriptionId,

    [parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,

    [parameter(Mandatory=$true)]
    [String]
    $WorkspaceName,

    [parameter(Mandatory=$true)]
    [String]
    $SQLPoolName,

    [parameter(Mandatory=$false)]
    [String]
    $TargetStatus
    )

    Write-Information "Waiting for any pending operation to be properly triggered..."
    Start-Sleep -Seconds 20

    $result = Get-SQLPool -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName

    if ($TargetStatus) {
        while ($result.properties.status -ne $TargetStatus) {
            Write-Information "Current status is $($result.properties.status). Waiting for $($TargetStatus) status..."
            Start-Sleep -Seconds 10
            $result = Get-SQLPool -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -WorkspaceName $WorkspaceName -SQLPoolName $SQLPoolName
        }
    }

    Write-Information "The SQL pool has now the $($TargetStatus) status."
    return $result
}
Export-ModuleMember -Function Assign-SynapseRole
Export-ModuleMember -Function Refresh-Token
Export-ModuleMember -Function Ensure-ValidTokens
Export-ModuleMember -Function Ensure-ValidToken
Export-ModuleMember -Function Get-PipelineRun
Export-ModuleMember -Function Get-SQLPool
Export-ModuleMember -Function Get-SparkPool
Export-ModuleMember -Function Get-ASAObject
Export-ModuleMember -Function List-StorageAccountKeys
Export-ModuleMember -Function Get-Workspace
Export-ModuleMember -Function Get-Pipeline
Export-ModuleMember -Function Wait-ForPipelineRun
Export-ModuleMember -Function Run-Pipeline 
Export-ModuleMember -Function Wait-ForOperation
Export-ModuleMember -Function Control-SQLPool
Export-ModuleMember -Function Wait-ForSQLPool
