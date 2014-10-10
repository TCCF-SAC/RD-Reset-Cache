RD-Reset-Cache
==============

Resets remote desktop user cache and personal files when they become inactive.

## Parameters:

Name                    | Description   | Default Value | Required
----------------------- | ------------- | ------------- | :--------:
**maxIdleTime**         | Maximum time in minutes that a user can be idle before the script runs | *45* |
**sleepTimeMinutes**    | The time in minutes that the script sleeps before checking the users idle state again. | *5* |

## Usage

This script is meant to run at startup, or logon, for each user. You can enable it through the Windows Startup folder or a Group Policy.
The script will always run the cleaning routines when it is initially run or opened against the user account that opened it.

## Running the script

PowerShell command-line with default parameters

* Navigate to the folder that contains the script
* Run `.\resetcache.ps1`

PowerShell command-line with custom parameters

* Navigate to the folder that contains the script
* Run `.\resetcache.ps1 -maxIdleTime 15 -sleepTimeMinutes 2`

This will run the script and check the user idle state every 2 minutes, resetting their cache when they are idle for 15 minutes or more.

The parameters are not case sensitive so the following code will exhibit the same behavior:

    .\resetcache.ps1 -maxidletime 15 -sleeptimeminutes 2

## What is cleaned?

The following folder contents will be cleaned with this script:

* Temporary folder, such as \AppData\Local\Temp
* Document folder
* Favorites folder
* Recent files folder
* Internet cache folder
* Cookies folder
* History folder
* Downloads folder
* Desktop folder
