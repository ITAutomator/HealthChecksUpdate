<#
PingTester.ps1
Use this to send test pings to a list of hostnames / ips.
Ping results are passed to a command line of another script that gets launched, either every pass or only when the status changes.

See Readme.md for more information.

Usage:
PingTester.ps1 -mode once
PingTester.ps1 -mode loop
#>
Param( 
      [string] $mode = "loop"         # loop or once
    )  

Function NameCleanUp ($Name="")
{
    $Name = $Name.Replace(" ","-")
    $Name = $Name.Replace(".","-")
    $Name = $Name.Replace("\","_")
    $Name = $Name.Replace("/","_")
    Return $Name
}
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
Write-Host "Pings a list (CSV) and calls programs when status changes."
Write-Host ""
Write-Host "To run from a command prompt:"
Write-Host "$($scriptName) -mode loop"
Write-Host "$($scriptName) -mode once"
Write-Host "-----------------------------------------------------------------------------"
# Load settings
$csvFile = "$($scriptDir)\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Default settings - These are appropriate for HealthChecksUpdate.ps1, but can be customized in the CSV after first run
$settings_updated = $false
if ($null -eq $settings.ping_every_n_mins)            {$settings.ping_every_n_mins            = "10"; $settings_updated = $true}
if ($null -eq $settings.last_test_time)               {$settings.last_test_time               = ""; $settings_updated = $true}
if ($null -eq $settings.launcher_active)              {$settings.launcher_active              = "True"; $settings_updated = $true}
if ($null -eq $settings.launcher_hidewindow)          {$settings.launcher_hidewindow          = "False"; $settings_updated = $true}
if ($null -eq $settings.launcher_onlyonstatuschange)  {$settings.launcher_onlyonstatuschange  = "False"; $settings_updated = $true}
if ($null -eq $settings.launcher_on_ok)               {$settings.launcher_on_ok               = "True"; $settings_updated = $true}
if ($null -eq $settings.launcher_on_fail)             {$settings.launcher_on_fail             = "False"; $settings_updated = $true}
if ($null -eq $settings.launch_ps1)                   {$settings.launch_ps1  = "C:\HealthChecksUpdate\HealthChecksUpdate.ps1"; $settings_updated = $true}
#
if ($null -eq $settings.launch_param1_name)  {$settings.launch_param1_name  = "mode"; $settings_updated = $true}
if ($null -eq $settings.launch_param1_value) {$settings.launch_param1_value = "ping"; $settings_updated = $true}
#
if ($null -eq $settings.launch_param2_name)  {$settings.launch_param2_name  = "create"; $settings_updated = $true}
if ($null -eq $settings.launch_param2_value) {$settings.launch_param2_value = "TRUE"; $settings_updated = $true}
#
if ($null -eq $settings.launch_param3_name)  {$settings.launch_param3_name  = "hc_test"; $settings_updated = $true}
if ($null -eq $settings.launch_param3_value) {$settings.launch_param3_value = "$($scriptBase)-%TestName%"; $settings_updated = $true}
#
if ($null -eq $settings.launch_param4_name)  {$settings.launch_param4_name  = "hc_msg"; $settings_updated = $true}
if ($null -eq $settings.launch_param4_value) {$settings.launch_param4_value = "Ping %TestPing% From $($scriptBase)"; $settings_updated = $true}
#
if ($null -eq $settings.launch_param5_name)  {$settings.launch_param5_name  = "hc_action"; $settings_updated = $true}
if ($null -eq $settings.launch_param5_value) {$settings.launch_param5_value = "%TestResult%"; $settings_updated = $true}
#
if ($null -eq $settings.launch_param6_name)  {$settings.launch_param6_name  = ""; $settings_updated = $true}
if ($null -eq $settings.launch_param6_value) {$settings.launch_param6_value = ""; $settings_updated = $true}
#
if ($null -eq $settings.launch_param7_name)  {$settings.launch_param7_name  = ""; $settings_updated = $true}
if ($null -eq $settings.launch_param7_value) {$settings.launch_param7_value = ""; $settings_updated = $true}
#
if ($null -eq $settings.launch_param8_name)  {$settings.launch_param8_name  = ""; $settings_updated = $true}
if ($null -eq $settings.launch_param8_value) {$settings.launch_param8_value = ""; $settings_updated = $true}
#
if ($null -eq $settings.launch_param9_name)  {$settings.launch_param9_name  = ""; $settings_updated = $true}
if ($null -eq $settings.launch_param9_value) {$settings.launch_param9_value = ""; $settings_updated = $true}
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
Write-Host "          ping_every_n_mins: " -NoNewline; Write-Host $settings.ping_every_n_mins -NoNewline -ForegroundColor Green; Write-Host " [Minutes between tests, Use 0 (or mode -once) to run and exit, which is suitable when running via a scheduled task]"
Write-Host "             last_test_time: " -NoNewline; Write-Host $settings.last_test_time -NoNewline -ForegroundColor Green; Write-Host ""
Write-Host "            launcher_active: " -NoNewline; Write-Host $settings.launcher_active -NoNewline -ForegroundColor Green; Write-Host " [True=Run launcher, False=Don't run launchers]"
Write-Host "launcher_onlyonstatuschange: " -NoNewline; Write-Host $settings.launcher_onlyonstatuschange -NoNewline -ForegroundColor Green; Write-Host " [True=Run programs only when status changes, False=Run programs every time]"
Write-Host "-----------------------------------------------------------------------------"
# Load CSV Tests
$csvTests = "$($scriptDir)\$($scriptBase).csv"
if (-not (Test-Path $csvTests)) {
    Write-Host "You need to have a CSV file (creating one): $(Split-Path $csvTests -Leaf)"
    $lines=@()
    $lines += "Ping,TestName,Status-Current,Date-Current,Status-Prior,Date-Prior,Disabled,Silenced"
    $lines += "www.google.com,google,,,,,,"
    $lines += "internetbeacon.msedge.net,microsoft_beacon,,,,,,"
    $lines += "8.8.8.8,google_dns,,,,,,"
    ForEach ($line in $lines) {
        Add-Content -Path $csvTests -Value $line
    } # each line
    PressEnterToContinue
    Start-Process $csvTests
    exit
}
$ping_every_n_mins = [int]$settings.ping_every_n_mins # convert to number
Do
{ # run tests
    $Tests = Import-Csv $csvTests
    Write-Host (Split-Path $csvTests -Leaf) -ForegroundColor Green -NoNewline
    Write-Host " (Tests: $($Tests.Count))"
    $test_i = 0
    foreach ($Test in $Tests)
    { # each test
        $bShowLogMsg = $false
        $test_i += 1
        $msg1 = ""
        $TestStatus = ""
        $msg3 = ""
        $msg4 = ""
        # set TestName if it is blank
        if ($Test.TestName -eq ""){
            $TestName = NameCleanUp $Test.Ping
        }
        else {
            $TestName = NameCleanUp $Test.TestName
        }
        $msg1 = "$($test_i): $($TestName) <$($Test.Ping)> ... "
        Write-Host $msg1 -NoNewline
        $TestPing = $Test.Ping
        if ($TestPing -eq "") {Write-Warning "Ping column is empty (it will be disabled)"; $Test.disabled -eq 'true'}
        if ($Test.Disabled -eq 'true') {
            $TestStatus = "Disabled"
            Write-Host $TestStatus -ForegroundColor Yellow -NoNewline
        }
        else {
            # Ping!
            $bPing = Test-Connection -ComputerName $TestPing -Count 1 -quiet
            #
            if ($bPing) {
                $TestStatus = "OK"
                Write-Host $TestStatus -ForegroundColor Green -NoNewline
            }
            else {
                $TestStatus = "Fail"
                Write-Host $TestStatus -ForegroundColor Red -NoNewline
            }
        }
        ## Set status
        $status_change = $false # indicates whether test status has changed
        If ($Test.'Status-Current' -ne $TestStatus)
        { # status has changed
            $status_change = $true
            $Test.'Status-Prior' = $Test.'Status-Current' # save what it was
            $Test.'Date-Prior' = $Test.'Date-Current' # save when it was at that status
            # change current state
            $Test.'Status-Current' = $TestStatus
            # 
            $msg3 = " [Changed from $($Test.'Status-Prior')]"
            Write-Host $msg3 -ForegroundColor Yellow -NoNewline
        } # status has changed
        $Test.'Date-Current' = (Get-Date).ToString("yyyy-MM-dd HH:mm")
        # launcher
        $bLaunchIndicated = $true   # determine if launch should happen (assume true)
        #region: bLaunchIndicated (all kinds of ways to supress launch)
        if ($bLaunchIndicated) { 
            if (($TestStatus -eq 'OK') -and ($settings.launcher_on_ok -eq 'false')) {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: launcher_on_ok is FALSE]"
                $bShowLogMsg = $true
            } 
        } # settings.launcher_on_ok
        if ($bLaunchIndicated) { 
            if (($TestStatus -eq 'Fail') -and ($settings.launcher_on_fail -eq 'false')) {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: launcher_on_fail is FALSE]"
                $bShowLogMsg = $true
            } 
        } # settings.launcher_on_fail
        if ($bLaunchIndicated) {
            if ($settings.launcher_onlyonstatuschange -eq 'false') {
            } # launcher_onlyonstatuschange is false (launch every time)
            else
            { # launcher_onlyonstatuschange is true
                if (-not $status_change)
                { # status didn't change
                    $bLaunchIndicated = $false
                    $msg4 = " [Launcher supressed: launcher_onlyonstatuschange is TRUE (or blank)]"
                } # status didn't change
            } # launcher_onlyonstatuschange is true
        } # settings.launcher_onlyonstatuschange
        if ($bLaunchIndicated) {
            if ($settings.launcher_active -ne 'true') {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: launcher_active = FALSE]"
            } # active
        } # settings.launcher_active
        if ($bLaunchIndicated) {
            if ($Test.Silenced -eq 'true') {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: Silenced = TRUE for this test]"
                $bShowLogMsg = $true
            } # silenced
        } # Test Silenced
        if ($bLaunchIndicated) {
            if ($TestStatus -eq 'Disabled') {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: Disabled = TRUE for this test]"
                $bShowLogMsg = $true
            } # disabled
        } # Test Disabled
        if ($bLaunchIndicated) {
            if ($settings.launch_ps1 -eq '') {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: launch_ps1 was empty]"
                $bShowLogMsg = $true
            } 
        } # launch_ps1 empty
        if ($bLaunchIndicated) {
            if (-not (Test-Path($settings.launch_ps1))) {
                $bLaunchIndicated = $false
                $msg4 = " [Launcher supressed: file not found: $($settings.launch_ps1)]"
                $bShowLogMsg = $true
            }
        } # launch_ps1 bad path
        #endregion: bLaunchIndicated
        if ($bLaunchIndicated)
        { # launch indicated
            $msg4 = " [Launcher $(Split-Path $settings.launch_ps1 -Leaf)]"
            $TestResult = $TestStatus
            $Params = @{}
            $argsString =""
            Foreach ($i in 1..9) {
                $pnam=$settings."launch_param$($i)_name".TrimStart("-")
                if ($pnam -ne ""){
                    $pval=$settings."launch_param$($i)_value"
                    # replace vars
                    $pval = $pval.Replace("%TestPing%"  ,$TestPing)
                    $pval = $pval.Replace("%TestName%"  ,$TestName)
                    $pval = $pval.Replace("%TestResult%",$TestResult)
                    # boolean
                    if (($pval -eq "true") -or ($pval -eq "false")) {
                        $pval= [bool]::Parse($pval)
                    } # convert a boolean (used for switch params)
                    # append param
                    $Params[$pnam] = $pval
                    # for Launch1
                    $bArgOmit = $false
                    $argval = [string]$pval
                    if ($argval -eq "true") {$argval=""} # switch true: just use -myswitch format
                    elseif ($argval -eq "false") {$bArgOmit=$true} # switch false: omit it
                    elseif ($pval.Contains(" ")) { # surround with quotes
                        $argval = " `"$($pval)`""
                    }
                    else {
                        $argval = " $($pval)"
                    }
                    if (-not $bArgOmit) {
                        $argsString += " -$($pnam)$($argval)"
                    }
                } #pnam not blank
            } # 1..9
            # Launch!
            if ($settings.launcher_hidewindow -eq 'false') {
                Write-Host "↓============================== LAUNCH START =======================================================↓" -ForegroundColor DarkGray
                & $settings.launch_ps1 @Params
                Write-Host "↑============================== LAUNCH END   =======================================================↑" -ForegroundColor DarkGray
            } # launch shown
            else {
                Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($settings.launch_ps1)`" $($argsString)" -WindowStyle Hidden
            } # launch hidden
        } # launch indicated
        # log
        Write-Host ""
        LogMsg "$($TestStatus) $($msg1)$($msg3)$($msg4)" -ShowMsg:$bShowLogMsg
    } # each test
    # save tests csv
    Do {
        try {
            $Tests | Export-Csv -Path $csvTests -NoTypeInformation
            break
        }
        catch {
            if ($_.Exception.Message -like "*being used by another process*") {
                Write-Warning "$(Split-Path $csvTests -Leaf) is open in Excel and it can't be updated. Please close it and try again."
            } else {
                Write-Error "$(Split-Path $csvTests -Leaf) couldn't be updated. An unexpected error occurred: $_"
            }
        }
        PauseTimed -secs 10 -quiet
    } while ($true)
    # save date in settings
    $settings.last_test_time = (Get-Date).ToString("yyyy-MM-dd HH:mm")
    $retVal = CSVSettingsSave $settings $csvFile
    if ($retVal.StartsWith("Problem")) {Write-Warning $retval}
    # save date
    if (($ping_every_n_mins -gt 0) -and ($mode -eq 'loop'))
    { # loop tests
        $next_test_time = (Get-Date).AddMinutes($ping_every_n_mins)
        Write-Host "Next test in $(($ping_every_n_mins)) minutes (at $($next_test_time.ToString("yyyy-MM-dd HH:mm")) <Press Enter to test now>..." -NoNewline
        Do { # Wait for next test cycle
            if (((get-date)-$next_test_time).TotalSeconds -ge 0) {
                break # time up
            } # is time up
            Start-Sleep 5
            Write-Host "." -NoNewline
            if ([console]::KeyAvailable) {
                $key = [System.Console]::ReadKey($true) 
                if ($key.key -eq "Enter") {
                    Write-Host "<break>"
                    break
                } # enter pressed
            } # key pressed
        } # Wait for next test cycle
        While ($true)
        Write-Host ""
    } # loop tests
    else {
        break
    } # test once and stop
} # run tests
while ($true)
Write-Host "Done. " -NoNewline
Write-Host " -mode:$($mode)" -ForegroundColor Green
Start-Sleep 2
