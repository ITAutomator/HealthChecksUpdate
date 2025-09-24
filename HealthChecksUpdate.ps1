<#
HealthChecksUpdate.ps1
Use this to update a HealthChecks server from an agent script.
See Readme.md for more information.

Usage:
HealthChecksUpdate.ps1 -mode ping -hc_test test_17 -hc_action OK -hc_msg TestResultOK -create
HealthChecksUpdate.ps1 -mode ping -hc_test test_17 -hc_action fail -hc_msg TestResultFailure

#>
Param( 
      [string] $mode      = "menu"         # menu or ping
    , [string] $hc_test   = "TestName"     # test name
    , [string] $hc_action = "OK"           # action: OK,fail,start,log
    , [string] $hc_msg    = "Ping Message" # log message to attach
    , [Switch] $Create    = $false         # Create test
    )  

Function HealthChecksPing
{
    Param( 
          [string] $hc_url     = "https://healthchecks.io" # Server URL
        , [string] $hc_msg     = ""     # log message to attach
        , [string] $hc_action  = "OK"   # action: OK,fail,start,log
        , [Switch] $Create     = $false # Create test
        )
    # The possible protocols are
    # [System.Enum]::GetNames([System.Net.SecurityProtocolType]) are one of SystemDefault, Ssl3, Tls, Tls11, Tls12, Tls13
    # Add by using -bor operand
    # For Invoke-RestMethod calls, your system SecurityProtocol may have to have a match with the website
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
    # base uri
    $uri = $hc_url.TrimEnd("/")
    # action
    if ($hc_action -eq "OK") {}
    elseif ($hc_action -eq "fail")  {$uri += '/fail'  }
    elseif ($hc_action -eq "start") {$uri += '/start' }
    elseif ($hc_action -eq "log")   {$uri += '/log'   }
    else {Write-Warning "Invalid action: $($hc_action)";exit 1}
    # create
    If($Create ) {$uri += '?create=1'}

    $irmArguments = @{
        Uri        = $uri
        TimeoutSec = 10
    }
    Try
    {
        if($null -ne $hc_msg)
        {
            # See https://healthchecks.io/docs/attaching_logs/
            $result = Invoke-RestMethod -Method Post -Body $hc_msg @irmArguments
        }
        else
        {
            $result = Invoke-RestMethod @irmArguments
        }
        $err_msg = ""
    }
    catch
    {   
        $err_txt = $_.Exception.Message
        $err_txt = $err_txt.Replace("`n"," ")
        $err_txt = $err_txt.replace("`r"," ")
        $err_txt = $err_txt.replace("`t"," ")
        $err_msg = "[ERR Ping: $($err_txt)] "
        Write-Warning $err_msg 
    }
    Return "$($err_msg)HC: $($uri) [$($hc_msg)]"
}
Function SlugNameCleanUp ($hc_slug="")
{
    $hc_slug = $hc_slug.Replace(" ","-")
    $hc_slug = $hc_slug.Replace(".","-")
    $hc_slug = $hc_slug.Replace("\","_")
    $hc_slug = $hc_slug.Replace("/","_")
    $hc_slug = $hc_slug.ToLower()
    Return $hc_slug
}

Function TestHealthCheckCreate
{
    param(
        [string]$BaseUrl     = "https://healthchecks.rethinkits16.synology.me",
        [string]$ApiKey      = "TrPwgKiB63pS_5f97yNtFz9fFFJIOWio",
        [string]$CheckName   = "MyTestCheck2",
        [string]$Description = "Test check created by PowerShell",
        [int]$TimeoutSeconds = 6*60*60,   # 6 hours
        [int]$GraceSeconds   = 10*60       # 10 minutes
    )
    # For Invoke-RestMethod calls, your system SecurityProtocol may have to have a match with the website
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
   
    # append a / if needed
    if (-not $BaseUrl.endswith("/")) {$BaseUrl += "/"}
    $ApiUrl = $BaseUrl + "api/v3/checks/"
    # Build headers with API key
    $Headers = @{
        "X-Api-Key" = $ApiKey
        "Content-Type" = "application/json"
    }
    # Step 1: Check if the check already exists
    try {
        $allChecks = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method GET
    }
    catch {
        # show error
        Write-Host "Couldn't connect to HealthChecks server. Check your settings."
        Write-Host "Error: $($_.Exception.Message)"
        Write-Host $_.ToString()
        start-sleep -Seconds 5
        exit
    }
    $check = $allChecks.checks | Where-Object { $_.name -eq $CheckName }
    if ($check) {
        Return $check
    }
    else {
        $body = @{
            name        = $CheckName
            slug        = SlugNameCleanUp $CheckName
            desc        = $Description
            timeout     = $TimeoutSeconds
            grace       = $GraceSeconds
        } | ConvertTo-Json
        $newCheck = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method POST -Body $body
        if ($newCheck) {
            Write-Host "✅ Created new check '$CheckName'."
            Return $newCheck
        } else {
            Write-Error "❌ Failed to create check."
            Return $null
        }
    }
}
######################
## Main Procedure
######################
###
## To enable scrips, Run powershell 'as admin' then type
## Set-ExecutionPolicy Unrestricted
###
### Main function header - Put ITAutomator.psm1 in same folder as script
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
Write-Host " Update HealthChecks.IO server with keep-alive messages."
Write-Host " For more info see: https://healthchecks.io/"
Write-Host ""
Write-Host "To run interactively with a menu:"
Write-Host 'HealthChecksUpdate.cmd [or .ps1]'
Write-Host ""
Write-Host "To run from a command prompt:"
Write-Host "HealthChecksUpdate.ps1 -mode ping -hc_test test7 -hc_action ok -hc_msg 'hi there'"
Write-Host "-----------------------------------------------------------------------------"
# Load settings
$csvFile = "$($scriptDir)\$($scriptBase) Settings.csv"
$settings = CSVSettingsLoad $csvFile
# Default settings
$settings_updated = $false
if ($null -eq $settings.hc_svr)     {$settings.hc_svr     = "<Replace with server url: https://healthchecks.io>"; $settings_updated = $true}
if ($null -eq $settings.hc_pingkey) {$settings.hc_pingkey = "<Replace with pingkey: Project > Settings > API > Ping key (e.g. B2LSAFxxxxxxxxxxxx4RyZ)"; $settings_updated = $true}
if ($null -eq $settings.hc_apikey)  {$settings.hc_apikey  = "<Replace with apikey: Project > Settings > API > api key (e.g. NMOPKxxxxxxxxxxxx438xh)"; $settings_updated = $true}
if ($null -eq $settings.hc_test)    {$settings.hc_test    = "TestName"; $settings_updated = $true}
if ($null -eq $settings.TimeoutSeconds)  {$settings.TimeoutSeconds  = 2*60*60; $settings_updated = $true} # 2 hours
if ($null -eq $settings.GraceSeconds)    {$settings.GraceSeconds    = 10*60; $settings_updated = $true} # 10 minutes
if ($settings_updated) {$retVal = CSVSettingsSave $settings $csvFile; Write-Host "Initialized - $($retVal)"}
# Show Settings
Write-Host "      File: $(Split-Path $csvFile -Leaf) [Your settings file - edit if needed]"
Write-Host "    hc_svr: " -NoNewline; Write-Host $settings.hc_svr -NoNewline -ForegroundColor Green; Write-Host " [This is your Healthchecks Server]"
Write-Host "hc_pingkey: " -NoNewline; Write-Host $settings.hc_pingkey -NoNewline -ForegroundColor Green; Write-Host " [This corresponds to a HealthChecks Project test list]"
Write-Host "-----------------------------------------------------------------------------"
if ($settings.hc_pingkey.startswith("<")) {
    Write-Host "You need to set the HealthChecks URL and your project's ping_key value in the CSV file."
    PressEnterToContinue 'Press Enter to open the CSV file.'
    Start-Process $csvFile
    exit
}
$settings.hc_svr = $settings.hc_svr.trim("/")
if ($mode -eq "menu")
{ # mode menu
    Do {
        # Test name
        Write-Host "Enter a test (slug) name. [From your HealthChecks Project test list]"
        Write-Host "- No spaces or dots"
        Write-Host "- Alphanumerics/symbols only"
        Write-Host "- Test will be created if not found"
        Write-Host "- Test slug is case sensitive"
        Write-Host "-------------------------------------"
        $hc_slug = PromptForString "Test name (Type x to exit)" -defaultValue $settings.hc_test
        if ($hc_slug  -eq 'x') {
            break
        }
        else {
            # Save Settings
            $hc_slug = SlugNameCleanUp $hc_slug 
            $settings.hc_test = $hc_slug
            $retVal = CSVSettingsSave $settings $csvFile
        }
        $hc_url="$($settings.hc_svr)/ping/$($settings.hc_pingkey)/$($hc_slug)"
        # Test action
        $choices = "E&xit","O&K","&Fail","&Start","&Log"
        $hc_action = AskForChoice "Test value:" -Choices ($choices) -DefaultChoice 1 -ReturnString
        if ($hc_action -eq "Exit") {
            break
        }
        # Test message
        $hc_msg = "Tested via $($env:COMPUTERNAME)"
        $hc_msg = PromptForString "Message to include (Type x to exit)" -defaultValue $hc_msg
        if ($hc_msg  -eq 'x') {
            break
        }
        #
        $test = TestHealthCheckCreate -BaseUrl $settings.hc_svr -ApiKey $settings.hc_apikey -CheckName $hc_slug -Description "Created by HealthChecksUpdate.ps1 [$($env:USERNAME) on $($env:COMPUTERNAME) at $(Get-Date -Format "yyyy-MM-dd")]" -TimeoutSeconds $settings.TimeoutSeconds -GraceSeconds $settings.GraceSeconds
        if ($null -eq $test) {
            Write-Warning "Couldn't create or find test. Check your settings."
            Start-Sleep 2
            break
        }
        $result = HealthChecksPing -hc_url $hc_url -hc_action $hc_action -hc_msg $hc_msg -Create
        LogMsg $result -ShowMsg
        Start-Sleep 2
        Write-Host "-------------------------------------"
    } while ($true)
} # mode menu
else
{ # mode ping
    # test
    if ($hc_slug -eq "") {Write-Warning "Test name is blank";Start-Sleep 2;exit 1}
    $hc_slug = SlugNameCleanUp($hc_test)
    # url
    $hc_url="$($settings.hc_svr)/ping/$($settings.hc_pingkey)/$($hc_slug)"
    # msg
    $hc_msg=$hc_msg.Trim().Replace("[none]","")
    if ($hc_msg -eq "") {$hc_msg=$hc_action}
    # info
    Write-Host "      Test: " -NoNewline; Write-Host $hc_slug -ForegroundColor Green
    Write-Host "    Action: " -NoNewline; Write-Host $hc_action -ForegroundColor Green
    Write-Host "       Msg: " -NoNewline; Write-Host $hc_msg -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------------------"
    $msg = HealthChecksPing -hc_url $hc_url -hc_action $hc_action -hc_msg "$($hc_msg) (on $($env:COMPUTERNAME))" -Create:$Create
    LogMsg $msg -ShowMsg
} # mode ping
Write-Host "Done."
Start-Sleep 2