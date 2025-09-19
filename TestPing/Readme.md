# TestPing

Use TestPing.ps1 to ping a list of machines (TestPing.csv).  
TestPing.ps1 will report the status and call an external .ps1 file with the results of the ping.  
TestPing is designed to work with a HealthChecks server (Working with HealthChecks) but it can be used to launch anything.  

## Server pre-requisites

You will need a working HealthChecks server (see <https://healthchecks.io> for more info)  
You will need a suitable agent PC to run the Task Scheduler  
The agent PC should already have C:\HealthChecksUpdate\HealthChecksUpdate.ps1 installed and operational (see Readme in that folder)  

## Agent setup steps

- Copy this folder somewhere local to the machine  
C:\TestPing

- Delete the Log and Settings and CSV files (if found) to prompt for new values  

| File                     | Description           |
| ------------------------ | --------------------- |
| TestPing Log.txt       | Log of activity       |
| TestPing Settings.csv  | Settings              |
| TestPing.csv           | List of hosts to ping |

- Run the program interactively (once) to setup the CSVs   
Double-click TestPing.cmd  
You will be prompted to set up the .CSV settings file  

- Create a list of hosts to ping  
Only edit Ping and TestName and second columns, the rest can be cleared.  
TestPing.csv  

| Column                   | Description                                 |
| ------------------------ | ------------------------------------------- |
| Ping                     |  8.8.8.8    (IP or hostname)                |
| TestName                 |  google-dns (optional, no spaces)           |
| Status-Current           |  (read-only) OK                             |
| Date-Current             |  (read-only) Last tested                    |
| Status-Prior             |  (read-only) Fail                           |
| Date-Prior               |  (read-only) Last failed                    |
| Disabled                 |  FALSE, disables this test                  |
| Silenced                 |  FALSE, Supress launcher for this test      |

- Inspect and change the settings  
TestPing Settings.csv  

| Setting                     | Description (first mentioned is default)                      |
| --------------------------- | ------------------------------------------------------------- |
| ping_every_n_mins           | how often to ping (if loop is specified)                      |
| launcher_active             | TRUE to use launcher_ps1, FALSE to disable                    |
| launcher_hidewindow         | FALSE to show launched process, TRUE to show commands         |
| launcher_onlyonstatuschange | FALSE to run ps1 every time, TRUE only if ping status changes |
| launcher_on_ok              | TRUE to run ps1 on ping success                               |
| launcher_on_fail            | FALSE to supress ps1 (do nothing) on ping fail                |
| launch_ps1                  | Full path to ps1 file (should be local)                       |
| launch_param1_name          | name of arguemnt (1-9) (without the '-')                      |
| launch_param1_value         | value of argument (1-9) %TestName% %TestResult% can be used   |

- Run the tests using one of these commands

| Method                    | Description                                             |
| ------------------------- | ------------------------------------------------------- |
| TestPing.cmd              | Launch with mode -loop                                  |
| TestPing Scheduled.cmd    | Launch with mode -once                                  |
| TestPing.ps1 -mode once   | From a powershell script (loops every n minutes)        |
| TestPing.ps1 -mode loop   | List of hosts to ping                                   |

Note: It's better to use Task Scheduler (than mode -loop) for testing every n minutes.  
Task Scheduler runs as a background service, survives reboots, and will be more reliable.  

## Working with HealthChecks

TestPing.ps1 was created to run with HealthChecksUpdate.ps1, and the default settings call it at C:\HealthChecksUpdate\HealthChecksUpdate.ps1  
See the read.me of that project for more information  

- Make sure the HealthChecks site reflects the test results as they are pinged  
Click on the test and adjust the Period and Grace Period  

- Windows Task Scheduler
It should be run as task scheduler service periodically to report each result to HealthChecks using HealthChecksUpdate.ps1.  
Open Task Scheduler and import the .xml file  
Rename the task to [HealthChecks TestPing]  

- How it works / notes.
With HealthChecksUpdate.ps1 as the launcher, every ping calls the launcher, not just when the status changes, so that the website recognizes the keep-alive state.  
Conversely, failures are supressed and do not call the launcher.  This allows the website's natural grace period to work instead of immediately signaling failure.  
This is appropriate where momentary outages (reboots, ISP blips) are permissable, to prevent status flapping.  
New sites added to the TestPing.csv are automatically added to the HealthChecks website (via the -create switch)  
