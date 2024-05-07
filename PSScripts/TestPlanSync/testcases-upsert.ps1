param (
    [string]$ADO_PAT = $env:ADO_PAT,
    [string]$ADO_ORG = $env:ADO_ORG,
    [string]$ADO_PROJ = $env:ADO_PROJ,
    [bool]$ADO_CLOSE_UNMATCHED_WORKITEMS = [System.Convert]::ToBoolean($env:ADO_CLOSE_UNMATCHED_WORKITEMS),
    [string]$ADO_BEARER_TOKEN = $env:ADO_BEARER_TOKEN,
    [string]$OUTPUT_DIR = "$($PSScriptRoot | Convert-Path)/obj",
    [string]$WORKING_DIR = "$($PSScriptRoot | Convert-Path)/"
)

<#
=============================================================
=============================================================

  Script setup

=============================================================
=============================================================
#>


Write-Host "Running testcases-upsert.ps1" -ForegroundColor Blue

# List of required parameters
$RequiredParameters = @("ADO_ORG", "ADO_PROJ")

# List to store errors
$Errors = @()

# Check if one of the authentication tokens is provided
if (-not $ADO_PAT -and -not $ADO_BEARER_TOKEN) {
    $Errors += "ERROR: Either ADO_PAT or ADO_BEARER_TOKEN must be provided."
}

# Check if required parameters are provided and validate ENV_LIST
foreach ($param in $RequiredParameters) {
    if (-not (Get-Variable -Name $param -ValueOnly)) {
        $Errors += "ERROR: Missing required parameter '$param'."
    }
}

if ($Errors.Count -gt 0) {
    Write-Host "Errors encountered:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Exit 1
}

$testCasesJsonPath = "$OUTPUT_DIR/testcases.json"
if (-Not (Test-Path -Path $testCasesJsonPath)) {
    throw "File does not exist: $testCasesJsonPath"
}

$jsonContent = Get-Content -Path $testCasesJsonPath -Raw
if ([string]::IsNullOrWhiteSpace($jsonContent)) {
    throw "JSON file is empty: $testCasesJsonPath"
}
$testCases = $jsonContent | ConvertFrom-Json
$testCasesCount = $testCases.Count
if ($testCasesCount -eq 0) {
    throw "No items found in the JSON file: $testCasesJsonPath"
}

# Your script logic here, using the provided variables

Write-Host "Azure DevOps Organization: $ADO_ORG"
Write-Host "Azure DevOps Project: $ADO_PROJ"
Write-Host "Close Unmatched Work Items: $ADO_CLOSE_UNMATCHED_WORKITEMS"
Write-Host "Test Cases data: $TESTCASES_JSON"
Write-Host "Working Directory: $WORKING_DIR"




$groupedTestCases = $testCases | Group-Object -Property { ($_.Path -join '.') }
$groupedTestCasesCount = $groupedTestCases.Count
$fieldNames = ($($testCases[0].Operations) | Where-Object { $_.path -match '^/fields/(.*)$' }).path -replace '^/fields/(.*)$', '$1'


$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

if($ADO_BEARER_TOKEN){
    $hidden = "*" * $ADO_BEARER_TOKEN.Length
    Write-Host  "Loaded bearer token ${hidden}"
    $headers.Add("Authorization", "Bearer ${ADO_BEARER_TOKEN}")
}
else {    
    $hidden = "*" * $ADO_PAT.Length
    Write-Host  "Loaded basic token (PAT)  ${hidden}"
    $B64Pat = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$ADO_PAT"))
    $headers.Add("Authorization", "Basic ${B64Pat}")
}

$headers.Add("Content-Type", "application/json")





<#
============================================================================================================
============================================================================================================

  Functions

============================================================================================================
============================================================================================================
#>



#construct query to be used in Get-Query
function Get-QueryString { 
    param( [Parameter(Mandatory=$true)][String[]]$Tags )

    $query = @"
select [System.Id], 
       [System.WorkItemType], 
       [System.Title], 
       [Microsoft.VSTS.Common.Priority], 
       [System.AssignedTo], 
       [System.AreaPath] 
from WorkItems 
where [System.TeamProject] = @project 
  and [System.WorkItemType] in group 'Microsoft.TestCaseCategory'
"@
    foreach ($tag in $Tags) {
        $query += " and [System.Tags] contains '$tag'"
    }
    $query += " and not [System.State] in ('Closed')"
    return $query
}

#using tags, retrieve work items that match these tags from ADO 
function Get-Query {
    param( [Parameter(Mandatory=$true)][String[]]$Tags )
    $uri = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/wit/wiql?api-version=7.0"
    $body = @{
        query = Get-QueryString(@($Tags | Where-Object {$_.StartsWith("path_")}))
    } | ConvertTo-Json
    $queryRes = Invoke-RestMethod $uri -Method 'POST' -Headers $headers -Body $body
    return $queryRes
}

#get data for work items from ADO given a list of IDs and the fields  needeed
function Get-Worktems {
    param( [Parameter(Mandatory=$true)]$idsAndFields)
    $uri = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/wit/workitemsbatch?api-version=7.0"

    $body = $idsAndFields | ConvertTo-Json
    try{
        $workItems = Invoke-RestMethod $uri -Method 'POST' -Headers $headers -Body $body
        return $workItems.value
    }
    catch{
        Write-Host "$($idsAndFields | ConvertTo-Json -Depth 10)"
        throw
    }
}

#returns true if the work item from ADO defers from the test case in the DLL (tags, name, etc)
function Test-IfNeedUpdate {
    
    param(
        [Parameter(Mandatory=$true)] $testCase,
        [Parameter(Mandatory=$true)] $workItem
    )

    $valueDiffers = $false

    foreach ($fieldName in $fieldNames) {
        switch ($fieldName) {
            "Microsoft.VSTS.TCM.AutomatedTestId" {
                # No action needed for this field
                break
            }
            "System.Tags" {
                $expectedTags = $testCase.Tags | ForEach-Object { $_.Trim() }
                $existingTags = $workItem.fields.$fieldName -split ';' | ForEach-Object { $_.Trim() }
                $expectedTags = $expectedTags | Where-Object { $existingTags -notcontains $_ }
                $valueDiffers = $expectedTags.Count -gt 0
                if ($valueDiffers) {
                    break
                }
                
            }
            default {
                $valueDiffers = $workItem.fields.$fieldName -ne $(($testCase.Operations | Where-Object { $_.path -eq "/fields/$fieldName" } | Select-Object -First 1).value)
                if ($valueDiffers) {
                    break
                }
                
            }
        }
        if ($valueDiffers) {
            break
        }
    }

    return $valueDiffers
}

#method used to make operations in batch (used by others functions below)
function Send-BatchRequest {
    param (
        [Parameter(Mandatory=$true)] $batchItems
    )

    $content = ConvertTo-Json $batchItems -Depth 10
    $uri = "https://dev.azure.com/$ADO_ORG/_apis/wit/`$batch?api-version=7.0"
    try {
        $response = Invoke-RestMethod -Uri $uri -Method 'Patch' -Body $content -ContentType "application/json" -Headers $headers
        
        # Check the status code for each operation in the batch
        $response.value | ForEach-Object {
            if ($_.code -gt 400) {
                Write-Host "$($_ | ConvertTo-Json -Depth 10)" -ForegroundColor "Yellow"
                throw "Error performing one or more operations"
            }
        }

        return $response
    }
    catch {
        # Log errors
        Write-Host "Batch Content: $content" -ForegroundColor "Yellow"
        throw
    }
}

#close work items in ADO (set status=closed)
function Close-WorkItems{
    param(
        [Parameter(Mandatory=$true)] $testCases
    )


    Write-Host "Closing work items" -ForegroundColor "yellow"

    $batchItems = $testCases | ForEach-Object {
        @{
            uri = "/_apis/wit/workitems/$($_.WorkItem.id)?api-version=7.0"
            body = @(
                @{
                    op = "add"
                    path = "/fields/System.State"
                    value = "Closed"
                }
            )
            method = "Patch"
            headers = @{ "Content-Type" = "application/json-patch+json" }
        }
    }

    $batchSize = 200
    for ($i = 0; $i -lt $testCasesCount; $i += $batchSize) {
        Write-Host "Processing batch $i" -ForegroundColor "yellow"
        $batch = $batchItems[$i..($i + $batchSize - 1)]
        $null = Send-BatchRequest $batch
    }
}

#updates work items in ADO
function Update-WorkItems{
    param(
        [Parameter(Mandatory=$true)] $testCases
    )

    
    Write-Host "Updating work items" -ForegroundColor "yellow"

    $batchItems = $testCases | ForEach-Object {
        @{
            uri = "/_apis/wit/workitems/$($_.WorkItem.id)?api-version=7.0"
            body = $_.Operations
            method = "Patch"
            headers = @{ "Content-Type" = "application/json-patch+json" }
        }
    }

    $batchSize = 200
    for ($i = 0; $i -lt $testCasesCount; $i += $batchSize) {
        Write-Host "Processing batch $i" -ForegroundColor "yellow"
        $stopwatch.Reset()
        $stopwatch.Start()

        $batch = $batchItems[$i..($i + $batchSize - 1)]
        $null = Send-BatchRequest $batch

        $stopwatch.Stop()
        Write-Host "Processing batch $i took $($stopwatch.Elapsed.TotalSeconds) seconds." -ForegroundColor "yellow"
    }

}

#creates new work items in ADO
function Add-WorkItemsToADO{
    param(
        [Parameter(Mandatory=$true)] $testCases
    )
    $testCasesCount = $testCases.Count
    Write-Host "Creating new work items count: $($testCasesCount)" -ForegroundColor "yellow"

    $batchItems = @()
    for ($index = 0; $index -lt $testCasesCount; $index++) {
        $testCase = $testCases[$index]
        
        $batchItems += @{
            uri = "/$ADO_PROJ/_apis/wit/workitems/`$Test%20Case?api-version=7.0"
            body = $testCase.Operations + @{
                op= "add"
                path= "/id"
                value= "$(-($index+1))"
            } 
            method = "patch"
            headers = @{ "Content-Type" = "application/json-patch+json" }
        }
    }
    
    $batchSize = 200
    for ($i = 0; $i -lt $testCasesCount; $i += $batchSize) {
        Write-Host "Processing batch $i" -ForegroundColor "yellow"
        $batch = $batchItems[$i..($i + $batchSize - 1)]
        $null = Send-BatchRequest $batch
    }
}





<#
============================================================================================================
============================================================================================================

  Script: Iterate through each group of test cases (feature) and upsert them

============================================================================================================
============================================================================================================
#>




Write-Host "Test case Group Count: $($groupedTestCasesCount)"
$errors = @()
$testCasesTobeUpdated = @()
$testCasesTobeClosed = @()
$workItems = @()

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

for ($featureIndex = 0; $featureIndex -lt $groupedTestCasesCount; $featureIndex++) {
    $featureGroup = $groupedTestCases[$featureIndex]
    $color = if ($featureIndex % 2 -eq 0) { "Blue" } else { "Green" }
    $groupKey = $featureGroup.Name
    $testCasesDictionary =  @{}
    $featureGroup.Group | ForEach-Object { $testCasesDictionary.Add($_.MethodFullName, $_) }


    Write-Host "`n[$groupKey] Starting work item fetch" -ForegroundColor $color

    $res = Get-Query($featureGroup.Group[0].Tags)
    $workItemIds = @()
    $workItemIds += $res.workItems | Select-Object -ExpandProperty id
    Write-Host "[$groupKey] found $($workItemIds.Count) test cases"
    $batchSize = 200
    $totalItems = $workItemIds.Count

    for ($i = 0; $i -lt $totalItems; $i += $batchSize) {
        $batch = @()
        $batch += $workItemIds[$i..($i + $batchSize - 1)]

        # Process the current batch of work item IDs
        $batchBody = @{
            ids = $batch
            fields = $fieldNames
        }
        try{
            $workItemsBatch = Get-Worktems($batchBody)
        } 
        catch{
            Write-Host "failed: $($workItemIds | ConvertTo-Json -Depth 10)" 
            throw
        }
        foreach ($workItem in $workItemsBatch) {
            $name = $workItem.fields."System.Title"
            $testName = $workItem.fields."Microsoft.VSTS.TCM.AutomatedTestName"
            
            if ($testCasesDictionary.ContainsKey($testName)) {
                $existingTC = $testCasesDictionary[$testName]
            } else {
                $existingTC = $null
            }
            if ($null -eq $existingTC ) {
                if ($ADO_CLOSE_UNMATCHED_WORKITEMS) {
                    $testCasesTobeClosed += @{ WorkItem = $workItem }
                    Write-Host "[$groupKey] added to close list: $name" -ForegroundColor $color
                    continue
                }
                else {
                    $errors += "Error finding locally (must be closed in ADO or added locally): `nTestCase name: $name`n  MSTest name: $testName"
                    continue
                }
            }
        
            if($null -eq $existingTC.WorkItem) {
                $existingTC.WorkItem = $workItem
            }
            else {
                Write-Host "[$groupKey] Duplicate added to close list: $name" -ForegroundColor $color
                $testCasesTobeClosed += @{ WorkItem = $workItem }
            }
            
            if (Test-IfNeedUpdate $existingTC $workItem) {
                $testCasesToBeUpdated += $existingTC
            }
        }
        # Add the processed batch to the list of work items
        $workItems += $workItemsBatch
    }
    Write-Host "[$groupKey] Processed`n" -ForegroundColor $color

}
$stopwatch.Stop()
Write-Host "Fetching workitems from Azure Devops Took a total of $($stopwatch.Elapsed.TotalSeconds) seconds."

if ($errors.Count -gt 0) {
    Write-Output "$($errors | ConvertTo-Json)"
    Write-Output "Error Count: $($errors.Count)"
    exit 1
}






<#
============================================================================================================
============================================================================================================

  Process and save output in JSON files

============================================================================================================
============================================================================================================
#>






$testCasesToBeCreated = $testCases | Where-Object {$_.WorkItem -eq $null}
Write-Host "Test cases to be created count: $($testCasesToBeCreated.Count)" -ForegroundColor "green"
if ($testCasesToBeCreated.Count -gt 0) {
    Add-WorkItemsToADO $testCasesToBeCreated

    $createdJson = $testCasesToBeCreated | ConvertTo-Json -Depth 10
    $filePath = "$OUTPUT_DIR/testcases-new.json"
    New-Item -Path $filePath -ItemType File -Force
    $createdJson | Out-File -FilePath $filePath
}

Write-Host "Test cases to be closed count: $($testCasesTobeClosed.Count)" -ForegroundColor "green"
if ($testCasesTobeClosed.Count -gt 0) {
    Close-WorkItems $testCasesTobeClosed

    $closedJson = $testCasesTobeClosed | ConvertTo-Json -Depth 10
    $filePath = "$OUTPUT_DIR/testcases-closed.json"
    New-Item -Path $filePath -ItemType File -Force
    $closedJson | Out-File -FilePath $filePath
}

Write-Host "Test cases to be updated count: $($testCasesTobeUpdated.Count)" -ForegroundColor "green"
if ($testCasesTobeUpdated.Count -gt 0) {
    Update-WorkItems $testCasesTobeUpdated

    $updatedTestCasesJson = $testCasesTobeUpdated | ConvertTo-Json -Depth 10
    $filePath = "$OUTPUT_DIR/testcases-updated.json"
    New-Item -Path $filePath -ItemType File -Force
    $updatedTestCasesJson | Out-File -FilePath $filePath

}
