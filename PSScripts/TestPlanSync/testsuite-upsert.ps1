param (
    [string]$ADO_PAT = $env:ADO_PAT,
    [string]$ADO_ORG = $env:ADO_ORG,
    [string]$ADO_PROJ = $env:ADO_PROJ,
    [bool]$ADO_CLOSE_UNMATCHED_TESTSUITES = [System.Convert]::ToBoolean($env:ADO_CLOSE_UNMATCHED_TESTSUITES),
    [string]$ADO_BEARER_TOKEN = $env:ADO_BEARER_TOKEN,
    [string]$ADO_PLAN_ID = $env:ADO_PLAN_ID,
    [string]$ADO_PARENT_SUITE_ID = $env:ADO_PARENT_SUITE_ID,
    [string]$ENV_LIST = $env:ENV_LIST,
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

#region Script setup

Write-Host "Running testsuite-upsert.ps1" -ForegroundColor Blue

# List of required parameters
$RequiredParameters = @("ADO_ORG", "ADO_PROJ", "ADO_PLAN_ID", "ADO_PARENT_SUITE_ID", "ENV_LIST")

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
if ($testCases.Count -eq 0) {
    throw "No items found in the JSON file: $testCasesJsonPath"
}

$updatedTestCases = @()

if (Test-Path -Path "$OUTPUT_DIR/testcases-closed.json") {
    $newTestCases = Get-Content -Path "$OUTPUT_DIR/testcases-closed.json" -Raw | ConvertFrom-Json -Depth 10
    $pathsToRefresh = $newTestCases | ForEach-Object {
        $automatedTestName = $_.WorkItem.fields."Microsoft.VSTS.TCM.AutomatedTestName"
        $path = ($automatedTestName -split "Features\.")[1] -split "\." | Select-Object -SkipLast 1
        [PSCustomObject]@{
            OriginalObject = $_
            Path = $path
        }
    }
}
if (Test-Path -Path "$OUTPUT_DIR/testcases-new.json") {
    $updatedTestCases += Get-Content -Path "$OUTPUT_DIR/testcases-new.json" -Raw | ConvertFrom-Json -Depth 10
}
if (Test-Path -Path "$OUTPUT_DIR/testcases-updated.json") {
    $updatedTestCases += Get-Content -Path "$OUTPUT_DIR/testcases-updated.json" -Raw | ConvertFrom-Json -Depth 10
}

$pathsToRefresh = $updatedTestCases | ForEach-Object {$_.Path -join '.'} | Select-Object -Unique

# Your script logic here, using the provided variables
Write-Host "Working Directory: $WORKING_DIR"
Write-Host "Output Directory: $OUTPUT_DIR"

Write-Host "Azure DevOps Organization: $ADO_ORG"
Write-Host "Azure DevOps Project: $ADO_PROJ"
Write-Host "Azure DevOps Plan ID: $ADO_PLAN_ID"
Write-Host "Azure DevOps Parent Test Suite ID: $ADO_PARENT_SUITE_ID"

Write-Host "Close Unmatched Test Suites: $ADO_CLOSE_UNMATCHED_TESTSUITES"
Write-Host "Environment List: $ENV_LIST"
Write-Host "Test Suites to refresh count: $($pathsToRefresh.count * $ENV_LIST.Split(',').count)"


enum SuiteTypes {
    DynamicTestSuite
    StaticTestSuite
    RequirementTestSuite 
}


class TestSuite {
    [int]$Id
    [string]$Name
    [SuiteTypes]$SuiteType
    [string[]]$Path
    [string]$QueryString
    [string[]]$QueryTags
}

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

#endregion Script setup





<#
============================================================================================================
============================================================================================================

  Functions

============================================================================================================
============================================================================================================
#>




# used by Get-Suites to add a suite if it does not exist in the list
function Add-TestSuiteIfNotAdded {
    param (
        [TestSuite[]]$suitesParam,
        [TestSuite]$testSuite
    )
    
    if($null -eq $testSuite){
        throw "TestSuite must be provided"
    }
    $testSuitePath = $testSuite.Path -join "."
    # Check if there is already an existing suite with the same name and path
    $exists = $suitesParam | Where-Object {
        ($_.Name -eq $testSuite.Name) -and
        (($_.Path -join ".") -eq $testSuitePath)
    }
    
    # If not exists, add the test suite
    if ($exists.count -eq 0) {
        $suitesParam += $testSuite
    }
    return $suitesParam
}

#constructs the suites from the test cases (input object)
function Get-Suites{
    param(
        [object]$testCases
    )
    $suites = [TestSuite[]]@()

    $pathStrings = @()
    $pathStrings += $testCases | ForEach-Object { $_.Path -join "." } | Select-Object -Unique
    $paths = $pathStrings | ForEach-Object { ,($_.Split('.')) }
    $paths | ForEach-Object {
        $path = $_

        [string[]]$staticPath = @()
        $staticPath += $path | Select-Object -SkipLast 1
        $featureSuiteName = $path[-1]
        
        $staticPath | ForEach-Object {
            $index = $staticPath.IndexOf($_)
            $pathForSuite = if ($index -gt 0) { $staticPath[0..($index - 1)] } else { @() }
            $suite = [TestSuite]@{
                Name = $_
                SuiteType = [SuiteTypes]::StaticTestSuite
                Path = $pathForSuite
            }
            
            $suites = Add-TestSuiteIfNotAdded -testSuite $suite -suitesParam $suites
        }
       
        $featureSuite = [TestSuite]@{
            Name = $featureSuiteName
            SuiteType = [SuiteTypes]::DynamicTestSuite
            QueryTags = @("path_$($path -join '.')")
            Path = $staticPath
        }

        $suites = Add-TestSuiteIfNotAdded -testSuite $featureSuite -suitesParam $suites
    }

    return $suites
}

#get list of suites in the configured plan from ADO (Azure DevOps state)
function Get-ADOSuites{
    $url = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/test/Plans/$ADO_PLAN_ID/suites?api-version=5.0"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    return $response.value
}

#constructs the query string for any given suite
function Get-QueryString {
    param (
        [TestSuite]$suite
    )
    if ($null -eq $suite.QueryTags -or $suite.QueryTags.Count -eq 0) {
        throw "Query tags must be provided to query dynamic test suite"
    }

    $query = "select [System.Id], [System.WorkItemType], [System.Title], [Microsoft.VSTS.Common.Priority], [System.AssignedTo], [System.AreaPath] from WorkItems where [System.TeamProject] = @project and [System.WorkItemType] in group 'Microsoft.TestCaseCategory'"
    $pathTag = $suite.QueryTags | Where-Object { $_.StartsWith("path_") }
    if ($pathTag) {
        $query += " and [System.Tags] contains '$pathTag'"
    }
    else {
        foreach ($tag in $suite.QueryTags) {
            $query += " and [System.Tags] contains '$tag'"
        }    
    }
    $query += " and not [System.State] in ('Closed')"
    return $query
}

#removes a suite from ADO
function Remove-TestSuite{
    param (
        [object]$suite,
        [int]$suiteId
    )

    if($null -ne $suite) {
        $suiteId = $null -ne $suite.id ? $suite.id : $suite.Id
    }
    if($null -eq $suiteId -or $suiteId -le 0){
        throw "Suite ID must be provided to remove a suite"
    }

    $url = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/test/Plans/$ADO_PLAN_ID/suites/$($suiteId)?api-version=5.0"
    $null = Invoke-RestMethod -Uri $url -Method Delete -Headers $headers
}

# if new, it will be added. 
# if suite is not modifiable, it will be replaced with a new suite.
# if modifialbe it will be updated
function Send-UpsertSuite{
    param (
        [TestSuite]$suite,
        [int]$parentId,
        [PSCustomObject]$ado_suites
    )

    if($null -eq $parentId -or $parentId -le 0){
        throw "Parent ID must be provided to upsert a suite $($suite.Name) "
    }

    $ado_suite = $ado_suites | Where-Object { $_.name -eq $suite.Name -and $_.parent.id -eq $parentId }

    $url =       "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/test/Plans/$ADO_PLAN_ID/suites/$($ado_suite.id)?api-version=5.0"
    $parentUrl = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/test/Plans/$ADO_PLAN_ID/suites/$($parentId)?api-version=5.0"

    if($null -ne $ado_suite -and $ado_suite.suiteType -ne $suite.SuiteType.ToString())
    {
        Write-Host "replacing suite $($suite.Name) to new suite with type $($suite.SuiteType)"
        $response = Invoke-RestMethod -Uri $url -Method Delete -Headers $headers
        $ado_suite = $null
    }

    if($null -eq $ado_suite)
    {
        if($suite.SuiteType -eq [SuiteTypes]::DynamicTestSuite)
        {
            $body = @{
                name = $suite.Name
                queryString = (Get-QueryString -suite $suite)
                suiteType = "DynamicTestSuite"
            } | ConvertTo-Json -Depth 10
        }
        else
        {
            $body = @{
                name = $suite.Name
                suiteType = "StaticTestSuite"
            } | ConvertTo-Json -Depth 10
        }
        Write-Host "creating suite $($suite.Name) with type $($suite.SuiteType) url: $parentUrl"
        $response = Invoke-RestMethod -Uri $parentUrl -Method Post -Body $body -Headers $headers
        if($null -eq $response)
        {
            Write-Host "Body: `n$body" -ForegroundColor Yellow
            throw "Failed to create test suite: $($suite.Name)"
        }
        $ado_suite = $response.value[0]
    }
    else {

        if($suite.SuiteType -eq [SuiteTypes]::DynamicTestSuite)
        {
            $newQueryString = Get-QueryString -suite $suite
            if($ado_suite.queryString -ne $newQueryString)
            {
                Write-Host "updating suite $($suite.Name) with new query string"
                $body = @{
                    queryString = $newQueryString
                }
                $response = Invoke-RestMethod -Uri $url -Method Patch -Body $body -Headers $headers
                $ado_suite = $response.value[0]
            }
            
        }
    }
    $suite.Id = $ado_suite.id
    return $ado_suite
}

#this function is used to update the existing suites object from ado with individually updated suites
function Get-UpdatedADOSuites {
    param(
        [PSCustomObject]$ado_suites,
        [PSCustomObject]$resultingSuite
    )
    if($null -eq $resultingSuite){
        throw "Resulting suite must be provided"
    }
    if($null -eq $resultingSuite.id -or $resultingSuite.id -le 0)
    {
        Write-Host "Resulting suite: $($resultingSuite | ConvertTo-Json -Depth 10)"
        throw "Resulting suite must have an ID"
    }
    $index = -1
    $ado_suites | ForEach-Object -Begin {$i = 0} -Process {if ($_.id -eq $resultingSuite.id) {$index = $i}; $i++}
    if ($index -ne -1) {
        # Write-Host "[$($resultingSuite.name)] at index: $index"
        $ado_suites[$index] = $resultingSuite
    } else {
        # Write-Host "[$($resultingSuite.name)] added as new suite"
        $ado_suites += $resultingSuite
    }
    return $ado_suites
}

#given a suite, gets the entire tree under it (children and it's children's children etc.) as a flat array (not a tree structure)
function Get-SuiteAllUnderTree {
    param (
        [string]$parentId,
        [array]$ado_suites
    )

    if($null -eq $parentId) {
        throw "Resulting suite must have an ID"
    }

    $children = $ado_suites | Where-Object { $_.parent.id -eq $parentId }
    $tree = @()

    foreach ($child in $children) {
        $tree += $child
        # Recursive call to find children of the current child
        $childTree = Get-SuiteAllUnderTree -parentId $child.Id -ado_suites $ado_suites
        $tree += $childTree

    }

    return $tree
}

function Update-TestSuiteCache {
    param (
        [TestSuite]$suite
    )

    $url = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/testplan/Plans/$ADO_PLAN_ID/Suites/$($suite.Id)/TestPoint?continuationToken=-2147483648%3B25&returnIdentityRef=true&includePointDetails=false&isRecursive=false"
    
    $continuationTestPointId=0;
    $testPoints = @()
    do 
    {
        $batchSize = 5000
        $url = "https://dev.azure.com/$ADO_ORG/$ADO_PROJ/_apis/testplan/Plans/$ADO_PLAN_ID/Suites/$($suite.Id)/TestPoint?continuationToken=$continuationTestPointId%3B$batchSize&returnIdentityRef=true&includePointDetails=false&isRecursive=false"
        $pointsRes = Invoke-RestMethod $url -Method 'GET' -Headers $headers -ResponseHeadersVariable responseHeaders
        $testPoints += $pointsRes.value
        $isContinuationTokenPresent = $responseHeaders.ContainsKey("X-Ms-Continuationtoken")
        if($isContinuationTokenPresent)
        {
            $continuationTestPointId = $responseHeaders["X-Ms-Continuationtoken"].Split(";")[0]
            Write-Output "continuation : $continuationTestPointId" 

        }

    } while ($isContinuationTokenPresent )
}




<#
============================================================================================================
============================================================================================================

  Iterate through each environment and create an identical suite for each environment
  each suite is create but with each path part as parent conforming a tree structure in ADO

============================================================================================================
============================================================================================================
#>





$suites = Get-Suites -testCases $testCases

$jsonOutput = $suites | ConvertTo-Json -Depth 10
$filePath = "$OUTPUT_DIR/suites.json"
New-Item -Path $filePath -ItemType File -Force
$jsonOutput | Out-File -FilePath $filePath

$ado_suites = @()
$ado_suites += Get-ADOSuites
$allSuites= [TestSuite[]]@()

foreach ($env in $ENV_LIST.Split(',') | ForEach-Object {$_.Trim()})
{
    if(-not $env)
    {
        continue;
    }
    $envSuite = [TestSuite]@{
        Name = $env
        SuiteType = [SuiteTypes]::StaticTestSuite
    }

    $resultingSuite = Send-UpsertSuite -suite $envSuite -parentId $ADO_PARENT_SUITE_ID -ado_suites $ado_suites
    $ado_suites = Get-UpdatedADOSuites -ado_suites $ado_suites -resultingSuite $resultingSuite
    
    Write-Host "Current Environment: $($envSuite.Name)"
    $envSuites = [TestSuite[]]($suites | ConvertTo-Json -Depth 10 | ConvertFrom-Json)
    foreach($suite in $envSuites)
    {
        $parentSuite = $envSuite

        if($null -ne $suite.Path -and $suite.Path.Count -gt 0)
        {
            foreach ($part in $suite.Path)
            {
                $partSuite = $envSuites 
                    | Where-Object { $_.Name -eq $part -and ($_.Path | Select-Object -SkipLast 1) -Join '.' -eq $parentSuite.Path -Join '.'}

                $resultingSuite = Send-UpsertSuite -suite $partSuite -parentId $parentSuite.Id -ado_suites $ado_suites
                $parentSuite = $partSuite
                $ado_suites = Get-UpdatedADOSuites -ado_suites $ado_suites -resultingSUite $resultingSuite

            }
        }
        $resultingSuite = Send-UpsertSuite -suite $suite -parentId $parentSuite.Id -ado_suites $ado_suites
        $ado_suites = Get-UpdatedADOSuites -ado_suites $ado_suites -resultingSUite $resultingSuite
    }
    
    $envrironmentTree = Get-SuiteAllUnderTree -parentId $envSuite.Id -ado_suites $ado_suites
    $matchedIds = $envSuites | ForEach-Object { $($_.Id) }
    $unmatchedSuites = $envrironmentTree | Where-Object { $matchedIds -notcontains $_.id }
    if($null -ne $unmatchedSuites -and $ADO_CLOSE_UNMATCHED_TESTSUITES -eq $true)
    {
        [Array]::Reverse($unmatchedSuites)
        $unmatchedSuites | ForEach-Object { Remove-TestSuite -suite $_ }
    }
    $allSuites += $envSuites
}

Write-Host "Total Suites found in ADO count: $($ado_suites.count)"
Write-Host "Total Suites to refresh count: $($pathsToRefresh.count)"


$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopwatch.Start()
foreach($fullName in $pathsToRefresh)
{
    Write-Host "Refreshing ADO Cache for $fullName"
    $parts = $fullName -split "\."
    $featureName = $parts[-1]
    $path = ($parts | Select-Object -SkipLast 1) -join '.'
    $suiteMatches = $allSuites | Where-Object { ($_.Name -eq $featureName) -and (($_.Path -join '.') -eq $path)}

    foreach($match in $suiteMatches)
    {
        Update-TestSuiteCache -suite $match
    }
}
$stopwatch.Stop()
Write-Host "Time taken to update cache: $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Yellow
