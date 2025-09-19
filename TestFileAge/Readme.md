# TestFileAge

Use TestFileAge.ps1 to test a list of Folder / File Specs to look for a recently modified file (TestFileAge.csv).
This would be commonly used to see if a log file was getting updated or a recent backup file exists.
Note that this tests the modified date of a file, not the contents of the file.
TestFileAge.ps1 will report the status and call an external .ps1 file with the results of the ping.
TestFileAge is designed to work with a HealthChecks server (Working with HealthChecks) but it can be used to launch anything.

## Server pre-requisites

You will need a working HealthChecks server (see <https://healthchecks.io> for more info)
You will need a suitable agent PC to run the Task Scheduler
The agent PC should already have C:\HealthChecksUpdate\HealthChecksUpdate.ps1 installed and operational (see Readme in that folder)

## Agent setup steps

- Copy this folder somewhere local to the machine  

C:\HealthChecks\TestFileAge  

| File                     | Description           |
| ------------------------ | --------------------- |
| TestFileAge Log.txt       | Log of activity       |
| TestFileAge Settings.csv  | Settings              |
| TestFileAge.csv           | List of folders /files to look for |

- Delete the Log and Settings and CSV files (if found) to prompt for new values
- Run the program interactively (once) to setup the CSVs
Double-click TestFileAge.cmd  
You will be prompted to set up the .CSV settings file

- Create a list of hosts to ping (TestFileAge.csv). Columns after Status-Current can be cleared / ignored, they are set by the program.

C:\HealthChecks\TestFileAge\TestFileAge.csv

| Column                   | Description                                |
| ------------------------ | ------------------------------------------ |
| TestName                 |  Log File Test (no spaces)                 |
| Folder                   |  c:\test                                   |
| FolderSubdirsToo         | True / False (search subfolers for file)   |
| Filespec                 |  *.txt    (file to look for)               |
| MaxAgeMins               |  1440   (must be newer than 1 day)         |
| Status-Current           |  (read-only) OK                            |
| Date-Current             |  (read-only) Last tested                   |
| Status-Prior             |  (read-only) Fail                          |
| Date-Prior               |  (read-only) Last failed                   |
| Disabled                 |  FALSE, disables this test                 |
| Silenced                 |  FALSE, Supress launcher for this test     |

- Inspect and change the settings  

C:\HealthChecks\TestFileAge\TestFileAge Settings.csv

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

| Method                      | Description                                             |
| --------------------------- | ------------------------------------------------------- |
| TestFileAge.cmd              | Launch with mode -loop                                  |
| TestFileAge Scheduled.cmd    | Launch with mode -once                                  |
| TestFileAge.ps1 -mode once   | From a powershell script (loops every n minutes)        |
| TestFileAge.ps1 -mode loop   | List of hosts to ping                                   |

Note: It's better to use Task Scheduler (than mode -loop) for testing every n minutes.
Task Scheduler runs as a background service, survives reboots, and will be more reliable.

## Working with HealthChecks

TestFileAge.ps1 was created to run with HealthChecksUpdate.ps1, and the default settings call it at C:\HealthChecksUpdate\HealthChecksUpdate.ps1
See the read.me of that project for more information

- Make sure the HealthChecks site reflects the test results as they are pinged
Click on the test and adjust the Period and Grace Period

- Windows Task Scheduler
It should be run as task scheduler service periodically to report each result to HealthChecks using HealthChecksUpdate.ps1.
Open Task Scheduler and import the .xml file
Rename the task to [HealthChecks TestFileAge]

- How it works / notes.
With HealthChecksUpdate.ps1 as the launcher, every ping calls the launcher, not just when the status changes, so that the website recognizes the keep-alive state.
Conversely, failures are supressed and do not call the launcher.  This allows the website's natural grace period to work instead of immediately signaling failure.
This is appropriate where momentary outages (reboots, ISP blips) are permissable, to prevent status flapping.
New sites added to the TestFileAge.csv are automatically added to the HealthChecks website (via the -create switch)
