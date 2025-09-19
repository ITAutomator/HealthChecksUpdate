# HealthChecksUpdate
<img src="https://raw.githubusercontent.com/ITAutomator/Assets/main/HealthChecksUpdate/WebBadge.png" alt="HealthChecksUpdate" width="200"/>  

Use HealthChecksUpdate.ps1 in your scripts to update your HealthChecks.io database from an agent computer.  
You can set up agents to check in periodically with the server to indicate they are still operational.  
HeathChecks uses a dead mans switch concept to ensure your list of vital computers and services are checking in and alive.  

## Server pre-requisites

You will need a working HealthChecks server (see <https://healthchecks.io> for more info)  
You will need a project (test list) for this program to use, and the associcated ping key (see below)  

## Agent setup steps

- Copy this folder somewhere local to the machine.  The assumed location is  
C:\HealthChecksUpdate

- Delete the Log and Settings files (if found) to reset and prompt for new values  
HealthChecksUpdate Log.txt  
HealthChecksUpdate Settings.csv  

- Run the program interactively to set up the CSV  
Double-click HealthChecksUpdate.cmd, a simple launcher for HealthChecksUpdate.ps1.  
You will be prompted to set up the .CSV settings file.  
For the hc_svr value, include your HealthChecks base URL: (e.g.) <https://healthchecks.io>  
For the hc_pingkey, include your projects API ping key. In HealthChecks, a project corresponds to a named HealthChecks test list.  
To get/set the ping key: From your web site: [your project] > Settings > API Access > Ping key (e.g. B2LxxxFRDm3D_DcZ9q4RyZ)  
Be careful with the ping key as it allows modifications to your tests, but it can always be Revoked and Reset.  

- Run the program interactively again to send a test ping  
Double-click HealthChecksUpdate.cmd  
Enter a test name (it will be created if missing)  

- Make sure the HealthChecks site reflects the test result  
Click on the test and adjust the Period and Grace Time.  

- Windows Task Scheduler (if setting up an agent PC for uptime testing)  
Open Task Scheduler and import the .xml file  
Rename the task to 'HealthChecks Agent'  

- About Period and Grace Time  
HealthChecks assumes failure if an OK ping is not received within the period of the test.  
Failure notifications will occur after the grace time expires, or when a failure ping is sent.  
Hint: For tests that you want to assume are OK, *unless* a failure signal is sent, set the Period to max (365 days).  

- About Notifications (Integrations)  
Adjust how notifications occur using the Integrations tab. (Email, Teams, etc)  

## Usage

The most common method is to set up HealthChecksUpdate from the Task Scheduler as described above.  
HealthChecks.ps1 can also be called from your script.  

- Powershell
HealthChecksUpdate.ps1 -mode ping -hc_test test_17 -hc_action OK -hc_msg TestMessage -create  
HealthChecksUpdate.ps1 -mode ping -hc_test test_17 -hc_action fail -hc_msg TestMessage  

- Batch / Cmd
C:\HealthChecksUpdate\PingFromBatchFile.cmd test17 OK Test Passed!  
C:\HealthChecksUpdate\PingFromBatchFile.cmd test17 fail Test 17 Failed!  
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\HealthChecksUpdate\HealthChecksUpdate.ps1' -mode ping -hc_test test_17 -create -hc_action OK -hc_msg 'hello there'"  

## Test Add-ons

These are add-on test methods that will use C:\HealthChecksUpdate to perform other kinds of tests.  
See the Readme.md in their curresponding subfolder for more info.  

- TestPing  
TestPing.ps1 pings other computers on the local network and test their updatime by sending the results to HealthChecks. (An agent of agents)  

- TestFileAge  
TestFileAge.ps1 tests files to make sure their modified date is recent. This can be used to make sure a process (backups, transfer, etc) is running.  

