:: ---------------------------
:: Launches a powershell script in the same folder
@echo off
if /I "%1" == "" (set hc_test=test_name) else (set hc_test=%1)
if /I "%2" == "" (set hc_action=ok)      else (set hc_action=%2)
if /I "%3" == "" (set hc_msg=[none]) else (set hc_msg=%3 %4 %5 %6)
set hc_msg=%hc_msg:  = %
echo -------------------------------------------------
echo - %~nx0            Computer:%computername% User:%username%%
echo - 
echo - Runs a powershell script in this folder.
echo - 
echo - Parameter 1: hc_test (test slug)    [%hc_test%]
echo - Parameter 2: hc_action (test action)[%hc_action%]
echo - Parameter 3: hc_msg (test msg)      [%hc_msg%]
::GOTO :EOF
::: set ps1 params here
set params=-mode ping -create -hc_test %hc_test% -hc_action %hc_action% -hc_msg '%hc_msg%'
:: Example1 set params=-mode auto -samplestrparam HelloWorld
:: Example1 set params=-samplestrparam 'This IsMyString'
:: Example2 if /I "%quiet%" == "true" set params=-quiet
::
set ps1file=%~dp0HealthChecksUpdate.ps1
set ps1file_orig=%ps1file%
:: double the quotes
set ps1file_double=%ps1file:'=''%
:: split the path into folder and name
For %%P in ("%ps1file%") do (
    Set pfolder=%%~dpP
    Set pname=%%~nxP
)
echo - 
echo -  ps1file: '%pname%'
echo -   params: %params%
echo - 
echo -------------------------------------------------
if not exist "%ps1file%"  echo ERR: Couldn't find '%ps1file%' & pause & goto :eof
:: powershell version
set exename="powershell.exe"
if exist "%ProgramFiles%\PowerShell\7\pwsh.exe" set psh_menu=true
if [%psh_menu%]==[] goto :PSH_MENU_DONE
CHOICE /T 5 /C 57 /D 7 /N /M "Multiple PS versions detected. Select PowerShell Version [5] or [7 Default] 5 secs:"
if %ERRORLEVEL%==1 echo Powershell 5 & goto :PSH_MENU_DONE
if %ERRORLEVEL%==2 echo Powershell 7 & set exename="%ProgramFiles%\PowerShell\7\pwsh.exe" & goto :PSH_MENU_DONE
:PSH_MENU_DONE
timeout /t 2 > nul
::cls
%exename% -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD] -Foregroundcolor green;& '%ps1file_double%' %params%"
::%exename% -NoProfile -ExecutionPolicy Bypass -Command "write-host [Starting PS1 called from CMD] -Foregroundcolor green; Set-Variable -Name PSCommandPath -value '%ps1file_double%';& '%ps1file_double%' %params%"
@echo off
echo -- Done with %~nx0
timeout /t 2 > nul