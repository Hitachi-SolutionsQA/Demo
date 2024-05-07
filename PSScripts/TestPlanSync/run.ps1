param (
    [string]$ENV_LIST = $env:ENV_LIST,
    [string]$ADO_PAT = $env:ADO_PAT,
    [string]$ADO_ORG = $env:ADO_ORG,
    [string]$ADO_PROJ = $env:ADO_PROJ,
    [string]$ADO_PLAN_ID = $env:ADO_PLAN_ID,
    [string]$ADO_PARENT_SUITE_ID = $env:ADO_PARENT_SUITE_ID,
    [string]$DLL_FILEPATH = $env:DLL_FILEPATH,
    [bool]$ADO_CLOSE_UNMATCHED_WORKITEMS = [System.Convert]::ToBoolean($env:ADO_CLOSE_UNMATCHED_WORKITEMS),
    [bool]$ADO_CLOSE_UNMATCHED_TESTSUITES = [System.Convert]::ToBoolean($env:ADO_CLOSE_UNMATCHED_TESTSUITES),
    [string]$ADO_BEARER_TOKEN = $env:ADO_BEARER_TOKEN
)

#authorization main directory
$WorkingDirectory = Get-Location

#
# C:\dev\Authorization\Operations\Build\PsScripts\TestPlanSync\run.ps1 -ENV_LIST "Main" -ADO_PLAN_ID 114314 -ADO_PARENT_SUITE_ID 114315 -DLL_FILEPATH "Source\BH.Auth.Automation.Test\bin\Debug\net6.0\BH.Auth.Automation.Test.dll" -ADO_CLOSE_UNMATCHED_WORKITEMS $True -ADO_CLOSE_UNMATCHED_TESTSUITES $True
#


# List of required parameters
$RequiredParameters = @("ADO_ORG", "ADO_PROJ", "ADO_PLAN_ID", "DLL_FILEPATH", "ENV_LIST", "ADO_PARENT_SUITE_ID")

# List to store errors
$Errors = @()

# Check if one of the authentication tokens is provided
if (-not $ADO_PAT -and -not $ADO_BEARER_TOKEN) {
    $Errors += "ERROR: Either ADO_PAT or ADO_BEARER_TOKEN must be provided."
}

# Check if required parameters are provided and validate ENV_LIST
foreach ($param in $RequiredParameters) {
    if (-not (Get-Variable -Name $param -ValueOnly) -or (Get-Variable -Name $param -ValueOnly) -eq 0) {
        $Errors += "ERROR: Missing or invalid value for required parameter '$param'."
    }
    if ($param -eq "ENV_LIST") {
        $envListArray = $ENV_LIST -split ','
        if ($envListArray.Count -le 1) {
            $Errors += "ERROR: ENV_LIST must be an array separated by , (comma)."
        }
    }
}

# Check for errors
if ($Errors.Count -gt 0) {
    Write-Host "Errors encountered:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Exit 1
}

# Your script logic here, using the provided variables

Write-Host "Environment List: $($ENV_LIST -split ', ')"
Write-Host "Azure DevOps Organization: $ADO_ORG"
Write-Host "Azure DevOps Project: $ADO_PROJ"
Write-Host "Azure DevOps Plan ID: $ADO_PLAN_ID"
Write-Host "Azure DevOps Parent Test Suite ID: $ADO_PARENT_SUITE_ID"
Write-Host "DLL file Path: $DLL_FILEPATH"
Write-Host "Close Unmatched Work Items: $ADO_CLOSE_UNMATCHED_WORKITEMS"
Write-Host "Close Unmatched Test Suites: $ADO_CLOSE_UNMATCHED_TESTSUITES"
Write-Host "Working Directory: $WorkingDirectory"
Write-Host "`n`n`n"


$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$stopwatch.Start()
& "$PSScriptRoot\testcases-load.ps1" `
    -DLL_FILEPATH $DLL_FILEPATH `
    -OUTPUT_DIR "$WorkingDirectory/obj" `
    -WORKING_DIR $WorkingDirectory
$stopwatch.Stop()
Write-Host "[TESTCASE_LOAD] Time elapsed: $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green



$stopwatch.Reset()
$stopwatch.Start()
& "$PSScriptRoot\testcases-upsert.ps1" `
    -ADO_PAT $ADO_PAT `
    -ADO_BEARER_TOKEN $ADO_BEARER_TOKEN `
    -ADO_ORG $ADO_ORG `
    -ADO_PROJ $ADO_PROJ `
    -ADO_CLOSE_UNMATCHED_WORKITEMS $ADO_CLOSE_UNMATCHED_WORKITEMS `
    -TESTCASES_JSON "obj/testcases.json" `
    -WORKING_DIR $WorkingDirectory `
    -OUTPUT_DIR "$WorkingDirectory/obj"
$stopwatch.Stop()
Write-Host "[TESTCASE_UPSERT] Time elapsed: $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green




$stopwatch.Reset()
$stopwatch.Start()
& "$PSScriptRoot\testsuite-upsert.ps1" `
    -ADO_PAT $ADO_PAT `
    -ADO_BEARER_TOKEN $ADO_BEARER_TOKEN `
    -ADO_ORG $ADO_ORG `
    -ADO_PROJ $ADO_PROJ `
    -ADO_CLOSE_UNMATCHED_TESTSUITES $ADO_CLOSE_UNMATCHED_TESTSUITES `
    -TESTCASES_JSON "obj/testcases.json" `
    -ADO_PLAN_ID $ADO_PLAN_ID `
    -ADO_PARENT_SUITE_ID $ADO_PARENT_SUITE_ID `
    -WORKING_DIR $WorkingDirectory `
    -OUTPUT_DIR "$WorkingDirectory/obj" `
    -ENV_LIST $ENV_LIST
$stopwatch.Stop()
Write-Host "[TESTSUITE_UPSERT] Time elapsed: $($stopwatch.Elapsed.TotalSeconds) seconds" -ForegroundColor Green