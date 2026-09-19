<#
TestEditing.ps1
Use this to bulk edit tests in HealthChecksUpdate.
See Readme.md for more information.

#>
######################
## Main Procedure
######################
#
# To enable scrips, Run powershell 'as admin' then type
# Set-ExecutionPolicy Unrestricted
#
# Put ITAutomator.psm1 in same folder as script
$scriptFullname = $PSCommandPath ; if (!($scriptFullname)) {$scriptFullname =$MyInvocation.InvocationName }
$scriptXML      = $scriptFullname.Substring(0, $scriptFullname.LastIndexOf('.'))+ ".xml"  ### replace .ps1 with .xml
$scriptDir      = Split-Path -Path $scriptFullname -Parent
$scriptName     = Split-Path -Path $scriptFullname -Leaf
$scriptBase     = $scriptName.Substring(0, $scriptName.LastIndexOf('.'))
$scriptVer      = "v"+(Get-Item $scriptFullname).LastWriteTime.ToString("yyyy-MM-dd")
$psm1="$($scriptDir)\ITAutomator.psm1";if ((Test-Path $psm1)) {Import-Module $psm1 -Force} else {write-output "Err 99: Couldn't find '$(Split-Path $psm1 -Leaf)'";Start-Sleep -Seconds 10;Exit(99)}
# Get-Command -module ITAutomator  ##Shows a list of available functions
######################

#######################
## Main Procedure Start
#######################
Write-Host "-----------------------------------------------------------------------------"
Write-Host "$($scriptName) $($scriptVer)       Computer:$($env:computername) User:$($env:username) PSver:$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host "Mode: $($mode)"
Write-Host ""
Write-Host "Reads a list (CSV) of filespecs to age test and calls programs when status changes."
Write-Host ""
Write-Host "To run from a command prompt:"
Write-Host "$($scriptName) -mode loop"
Write-Host "$($scriptName) -mode once"
Write-Host "-----------------------------------------------------------------------------"
# Load settings
$csvFile = "$($scriptDir)\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Default settings 
$settings_updated = $false
if ($null -eq $settings.API_key)            {$settings.API_key            = "API_key"; $settings_updated = $true}
if ($null -eq $settings.Server_Url)            {$settings.Server_Url            = "Server_Url"; $settings_updated = $true}
#
if ($settings_updated)
{
    $retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"
    Write-Host "You need to set the values in your settings file."
    Start-Process $csvFile
    exit
}
# Show Settings
Write-Host "                       File: $(Split-Path $csvFile -Leaf) [Your settings file - edit if needed]"
Write-Host "          API_key: " -NoNewline; Write-Host $settings.API_key -NoNewline -ForegroundColor Green; Write-Host " [API from HC]"
Write-Host "          Server_Url: " -NoNewline; Write-Host $settings.Server_Url -NoNewline -ForegroundColor Green; Write-Host " [https URL of HC]"
Write-Host "-----------------------------------------------------------------------------"
# Show a menu

Do { # Main Menu Loop
# Show Settings
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "Current Settings:"
    Write-Host " API_key: " -NoNewline
    # show only the first 3 characters followed by ...
    Write-Host "$($settings.API_key.Substring(0,3))..." -ForegroundColor Green
    Write-Host " Server_Url: " -NoNewline
    Write-Host $settings.Server_Url -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------------------"
    Write-Host "--------------- Choices  ------------------"
    Write-Host "[E] Export a dated test list, including an Action column (default is None)"
    Write-Host "[O] Open the latest exported test test list to edit Actions"
    Write-Host "[U] Update tests using the latest export to apply Actions"
    Write-Host "[S] ettings.csv Edit"
    Write-Host "[X] Exit"
    Write-Host "-------------------------------------------"
    $choice = PromptForString "Choice [blank to exit]"
    $choice_desc = $choice
    Write-Host "You chose: " -NoNewline
    Write-Host $choice_desc -ForegroundColor Green
    if (($choice -eq "") -or ($choice -eq "X")) {
        Break # Exit
    } # Exit
    if ($choice -eq "S")
    { # Settings CSV
        Start-Process $csvFile
        PressEnterToContinue "Returned from editing settings. Press Enter to load the new settings." -ForegroundColor Green
        $settings = CSVSettingsLoad $csvFile
    } # Settings CSV
    if ($choice -eq "E")
    { # export
        PressEnterToContinue "About to Export a dated test list <Press Enter>" -ForegroundColor Green
        #region: Export Dated Test List

        # Export to a folder called "Exports" within the script directory
        if (-not (Test-Path "$scriptDir\Exports")) {
            New-Item -ItemType Directory -Path "$scriptDir\Exports" | Out-Null
        }
        $exportFile = "$($scriptDir)\Exports\$($scriptBase) Export $(Get-Date -Format 'yyyy-MM-dd_HH-mm').csv"
        Write-Host "Exporting to $(split-path $exportFile -leaf)" -ForegroundColor Green
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        } catch { }

        $baseUrl = $settings.Server_Url.TrimEnd('/')
        $headers = @{ 'X-Api-Key' = $settings.API_key }

        $checks = @()
        try {
            $response = Invoke-RestMethod -Uri "$baseUrl/api/v3/checks/" -Headers $headers -Method Get -TimeoutSec 60
            $checks = @($response.checks)
        } catch {
            Write-Host "Err: Failed to retrieve tests from $baseUrl - $($_.Exception.Message)" -ForegroundColor Red
        }

        if ($checks.Count -eq 0) {
            Write-Host "No tests were returned. Nothing to export." -ForegroundColor Yellow
        } else {
            $rows = foreach ($check in $checks) {
                [pscustomobject][ordered]@{
                    Action        = "None"
                    Name          = [string]$check.name
                    Slug          = [string]$check.slug
                    Tags          = [string]$check.tags
                    Status        = [string]$check.status
                    PeriodSeconds = $check.timeout
                    GraceSeconds  = $check.grace
                    CronSchedule  = [string]$check.schedule
                    TimeZone      = [string]$check.tz
                    LastPing      = [string]$check.last_ping
                    Uuid          = [string]$check.uuid
                    UniqueKey     = [string]$check.unique_key
                }
            }
            $rows | Sort-Object Name | Export-Csv -LiteralPath $exportFile -NoTypeInformation -Encoding UTF8
            Write-Host "Exported $($rows.Count) test(s) to $(split-path $exportFile -leaf)" -ForegroundColor Green
            PressEnterToContinue "Export complete. Press Enter to continue." -ForegroundColor Green
        }
        #endregion
    } # expxort
    if ($choice -eq "O")
    { # open
        #region: Open Latest Export
        $latestExport = $null
        if (Test-Path "$scriptDir\Exports") {
            $latestExport = Get-ChildItem -Path "$scriptDir\Exports" -Filter "$scriptBase Export *.csv" |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1
        }
        if ($null -eq $latestExport) {
            Write-Host "No exported test list found. Use [E] to export one first." -ForegroundColor Yellow
        } else {
            Write-Host "Opening $($latestExport.Name)" -ForegroundColor Green
            Write-Host "----------------------------------------"
            Write-Host "Update these columns as needed before continuing."
            Write-Host "Action Name PeriodSeconds GraceSeconds" -ForegroundColor Cyan
            Write-Host "----------------------------------------"
            Write-Host "Action: None, Delete, Update"
            Write-Host "  None: No action will be taken on the test."
            Write-Host "  Delete: Marks the test for deletion."
            Write-Host "Update will update any changes found in these columns:"
            Write-Host "  Name: The name of the test."
            Write-Host "  PeriodSeconds: Time between expected pings."
            Write-Host "  GraceSeconds: Time allowed after a missed ping before marking as failed."
            Write-Host "----------------------------------------"
            Start-Process $latestExport.FullName
            PressEnterToContinue "Edit the Action column and save the file. Press Enter when done." -ForegroundColor Green
        }
        #endregion
    } # open
    if ($choice -eq "U")
    { # update
        #region: Update Tests From Latest Export
        $latestExport = $null
        if (Test-Path "$scriptDir\Exports") {
            $latestExport = Get-ChildItem -Path "$scriptDir\Exports" -Filter "$scriptBase Export *.csv" |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        }
        if ($null -eq $latestExport) {
            Write-Host "No exported test list found. Use [E] to export one first." -ForegroundColor Yellow
        } else {
            Write-Host "Using $($latestExport.Name) [will prompt for confirmation]" -ForegroundColor Green
            $rows = @(Import-Csv -LiteralPath $latestExport.FullName)

            $toDelete = @($rows | Where-Object { $_.Action -eq "Delete" })
            $toUpdate = @($rows | Where-Object { $_.Action -eq "Update" })
            $unknown  = @($rows | Where-Object { $_.Action -notin @("None", "Delete", "Update") })

            foreach ($row in $unknown) {
                Write-Host "Warn: Unrecognized Action '$($row.Action)' for '$($row.Name)' - skipping." -ForegroundColor Yellow
            }

            if (($toDelete.Count -eq 0) -and ($toUpdate.Count -eq 0)) {
                Write-Host "No rows are marked Delete or Update. Nothing to do." -ForegroundColor Yellow
            } else {
                Write-Host "----------------------------------------"
                Write-Host "$($toDelete.Count) test(s) marked for Delete, $($toUpdate.Count) test(s) marked for Update."
                foreach ($row in $toDelete) { Write-Host "  Delete: $($row.Name)" -ForegroundColor Red }
                foreach ($row in $toUpdate) { Write-Host "  Update: $($row.Name)" -ForegroundColor Cyan }
                Write-Host "----------------------------------------"
                if (-not (AskForChoice "Apply these changes?")) {
                    Write-Host "Cancelled - no changes were made." -ForegroundColor Yellow
                } else {
                    try {
                        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                    } catch { }

                    $baseUrl = $settings.Server_Url.TrimEnd('/')
                    $headers = @{ 'X-Api-Key' = $settings.API_key }

                    foreach ($row in $toDelete) {
                        if ([string]::IsNullOrWhiteSpace($row.Uuid)) {
                            Write-Host "Err: '$($row.Name)' has no Uuid (read-only key was used for export?) - cannot delete." -ForegroundColor Red
                            continue
                        }
                        try {
                            Invoke-RestMethod -Uri "$baseUrl/api/v3/checks/$($row.Uuid)" -Headers $headers -Method Delete -TimeoutSec 60 | Out-Null
                            Write-Host "Deleted: $($row.Name)" -ForegroundColor Green
                        } catch {
                            Write-Host "Err: Failed to delete '$($row.Name)' - $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }

                    foreach ($row in $toUpdate) {
                        if ([string]::IsNullOrWhiteSpace($row.Uuid)) {
                            Write-Host "Err: '$($row.Name)' has no Uuid (read-only key was used for export?) - cannot update." -ForegroundColor Red
                            continue
                        }
                        $body = @{}
                        if (-not [string]::IsNullOrWhiteSpace($row.Name))          { $body.name    = $row.Name }
                        if (-not [string]::IsNullOrWhiteSpace($row.PeriodSeconds)) { $body.timeout = [int]$row.PeriodSeconds }
                        if (-not [string]::IsNullOrWhiteSpace($row.GraceSeconds))  { $body.grace   = [int]$row.GraceSeconds }
                        try {
                            Invoke-RestMethod -Uri "$baseUrl/api/v3/checks/$($row.Uuid)" -Headers $headers -Method Post -ContentType 'application/json' -Body ($body | ConvertTo-Json) -TimeoutSec 60 | Out-Null
                            Write-Host "Updated: $($row.Name)" -ForegroundColor Green
                        } catch {
                            Write-Host "Err: Failed to update '$($row.Name)' - $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                }
            }
        }
        PressEnterToContinue "Finished updating tests using the latest export [Press Enter]" -ForegroundColor Green
        #endregion
    } # update
} until (($choice -eq "") -or ($choice -eq "X")) # Main Menu Loop
Start-Sleep .5
