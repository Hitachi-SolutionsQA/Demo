param (
    [string]$DLL_FILEPATH = $env:DLL_FILEPATH,
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

Write-Host "Running testcases-load.ps1" -ForegroundColor Blue

# List of required parameters
$RequiredParameters = @("DLL_FILEPATH")
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

Write-Host "DLL file Path: $DLL_FILEPATH"
Write-Host "Working Directory: $WORKING_DIR"



<#
=============================================================
=============================================================

  Load test cases from the DLL 

=============================================================
=============================================================
#>


class TestCase {
    [string]$Name
    [string]$MethodFullName
    [string[]]$Tags
    [string]$FeatureTitle
    [string[]]$Path
    [object[]]$Operations
    [object]$WorkItem
}

# List to store test cases
$TestCases = New-Object System.Collections.Generic.List[object]

# Load the assembly
$Assembly = [System.Reflection.Assembly]::LoadFrom((Join-Path $WORKING_DIR $DLL_FILEPATH))
$AssemblyName = $Assembly.GetName().Name

# Get all types from the assembly
$Types = $Assembly.GetTypes()

# Remove the assembly reference to unload it
Remove-Variable -Name Assembly -ErrorAction SilentlyContinue

foreach ($Type in $Types) {
    $Methods = $Type.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::DeclaredOnly)
    foreach ($Method in $Methods) {
        $Attributes = $Method.GetCustomAttributesData()
        $IsTestMethod = $Attributes | Where-Object { $_.AttributeType.FullName -eq 'Microsoft.VisualStudio.TestTools.UnitTesting.TestMethodAttribute' }

        if ($IsTestMethod) {
            $FeatureTitle = $null
            $FeatureTitleAttribute = $Attributes | 
            Where-Object { $_.AttributeType.FullName -eq 'Microsoft.VisualStudio.TestTools.UnitTesting.TestPropertyAttribute' -and $_.ConstructorArguments[0].Value -eq 'FeatureTitle' }
            
            if ($FeatureTitleAttribute) {
                $FeatureTitle = $FeatureTitleAttribute.ConstructorArguments[1].Value
            }
            else {
                continue
            }

            $title = ($Attributes | Where-Object { $_.AttributeType.FullName -eq 'Microsoft.VisualStudio.TestTools.UnitTesting.DescriptionAttribute' } | Select-Object -First 1).ConstructorArguments[0].Value

            $Tags = @()
            $Tags += $Attributes | Where-Object { $_.AttributeType.FullName -eq 'Microsoft.VisualStudio.TestTools.UnitTesting.TestCategoryAttribute' } | ForEach-Object {
                $_.ConstructorArguments[0].Value
            } | Where-Object { $_ -notlike '*browser*' }
            $TestCase = [TestCase]::new()
            $TestCase.Name = $title
            $TestCase.MethodFullName = $Type.FullName + "." + $Method.Name
            $TestCase.FeatureTitle = $FeatureTitle
            $TestCase.Path = $Type.FullName.Replace("$AssemblyName.Features.", "").Split(".")
            $Tags +="path_$($TestCase.Path -join '.')"
            $TestCase.Tags = $Tags
            $TestCase.Operations = @(
                @{
                    op = "add"
                    path = "/fields/System.Title"
                    value = $TestCase.Name
                },
                @{
                    op = "replace"
                    path = "/fields/System.Tags"
                    value = ($TestCase.Tags -join "; ")
                },
                @{
                    op = "add"
                    path = "/fields/Microsoft.VSTS.TCM.AutomatedTestName"
                    value = "$($TestCase.MethodFullName)"
                },
                @{
                    op = "add"
                    path = "/fields/Microsoft.VSTS.TCM.AutomatedTestStorage"
                    value = "$AssemblyName.dll"
                },
                @{
                    op = "add"
                    path = "/fields/Microsoft.VSTS.TCM.AutomatedTestId"
                    value = [Guid]::NewGuid().ToString()
                },
                @{
                    op = "add"
                    path = "/fields/Microsoft.VSTS.TCM.AutomationStatus"
                    value = "Automated"
                }
            )
            $TestCases.Add($TestCase)
        }
    }
}


#
# Validate DAO limit for test case fullname field is not exceeded
#
$testCases | Where-Object { $_.MethodFullName.Length -gt 256 } | ForEach-Object {
   $description = "feature: $($_.FeatureTitle)`nTest Name: $($_.Name)"
   $errorMessage = "max length (256) exceeded in Test Case: $description"
   $Errors += $errorMessage

}
if ($Errors.Count -gt 0) {
    Write-Host "Errors encountered:" -ForegroundColor Red
    $Errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    Exit 1
}


#
# Write output to json file
#

$jsonOutput = $TestCases | ConvertTo-Json -Depth 10
$filePath = "$OUTPUT_DIR/testcases.json"
New-Item -Path $filePath -ItemType File -Force
$jsonOutput | Out-File -FilePath $filePath


# Output total count
Write-Host "Total Test Cases: $($TestCases.Count) in $AssemblyName"
