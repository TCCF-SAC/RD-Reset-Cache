Param (
    [string]$maxIdleTime = 45, # Maximum idle time in minutes
    [int]$sleepTimeMinutes = 5 # Script sleep time in minutes
)

Add-Type @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace PInvoke.Win32 {

    public static class UserInput {

        [DllImport("user32.dll", SetLastError=false)]
        private static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        [StructLayout(LayoutKind.Sequential)]
        private struct LASTINPUTINFO {
            public uint cbSize;
            public int dwTime;
        }

        public static DateTime LastInput {
            get {
                DateTime bootTime = DateTime.UtcNow.AddMilliseconds(-Environment.TickCount);
                DateTime lastInput = bootTime.AddMilliseconds(LastInputTicks);
                return lastInput;
            }
        }

        public static TimeSpan IdleTime {
            get {
                return DateTime.UtcNow.Subtract(LastInput);
            }
        }

        public static int LastInputTicks {
            get {
                LASTINPUTINFO lii = new LASTINPUTINFO();
                lii.cbSize = (uint)Marshal.SizeOf(typeof(LASTINPUTINFO));
                GetLastInputInfo(ref lii);
                return lii.dwTime;
            }
        }
    }
}
'@

function Debug($strUser, $TempDir, $myprofile, $mydocuments, $mydownloads, $myfavorites, $myrecent,
    $mycache, $mycookies, $myhistory, $firstRun)
{
    $now = (Get-Date).ToString("MM/dd/yyyy hh:mm:ss");
    $idleTime = [PInvoke.Win32.UserInput]::IdleTime;

    $message =
    "---------------------------------------------------" + $crlf +
    "Date/Time Now: $now" + $crlf +
    "UserName: $strUser" + $crlf +
    "Temp Dir: $TempDir" + $crlf +
    "Profile Path: $myprofile" + $crlf +
    "Documents Path: $mydocuments" + $crlf +
    "Downloads Path: $mydownloads" + $crlf +
    "Favorites Path: $myfavorites" + $crlf +
    "Recent Path: $myrecent" + $crlf +
    "Cache Path: $mycache" + $crlf +
    "Cookies Path: $mycookies" + $crlf +
    "History Path: $myhistory" + $crlf +
    "Idle Time: $idleTime" + $crlf +
    "First Run: $firstRun" + $crlf +
    "Max Idle Time: $maxIdleTime" + $crlf +
    "Sleep Time: $sleepTimeMinutes";

    $dumpFile = "$mydocuments\$strUser.txt";
    $message | Add-Content $dumpFile;
}

function CleanDirectory($path, [string[]]$exclusions)
{
    $test_path = Test-Path $path

    if ($test_path -eq $true)
    {
        Remove-Item -Path $path\* -Recurse -Force -Exclude $exclusions
    }
}

function EmptyRecycleBin()
{
    $Shell = New-Object -ComObject Shell.Application;
    $Recycler = $Shell.NameSpace(0xa);

    foreach ($item in $Recycler.Items())
    {
        # Delete all items
        Remote-Item -Path $item.Path -Confirm:$false -Force -Recurse
    }
}

$sleepTime = (60 * $sleepTimeMinutes); # Sleep time in seconds.
$crlf = "`r`n";

$firstRun = $true;
$isClean = $false;

$strUser = $env:UserName;

# DEBUG
# Temp directory is cleaned using GPO's
#$TempDir = $env:temp; # \AppData\Local\Temp

$mydocuments = [environment]::getfolderpath("MyDocuments");
# Get profile path using the documents path.
# We could use $env:USERPROFILE on a normal install, but
# on a domain with folder redirections, the path will not be correct.
$myprofile = (Get-Item -Path $mydocuments).Parent.FullName;
$myfavorites = [environment]::GetFolderPath("Favorites");
$myrecent = [environment]::GetFolderPath("Recent");
$mycache = [environment]::GetFolderPath("InternetCache");
$mycookies = [environment]::GetFolderPath("Cookies");
$myhistory = [environment]::GetFolderPath("History");
$mydownloads = "$myprofile\Downloads";
$mydesktop = "$myprofile\Desktop";

while($true)
{
    $idleTimeMinutes = [PInvoke.Win32.UserInput]::IdleTime.Minutes;

    #Write-Host "Idle Minutes: $idleTimeMinutes";
    #Write-Host "Is Clean: $isClean";

    if (
        ($firstRun) -or
        ( ($isClean -ne $true) -and ($idleTimeMinutes -ge $maxIdleTime) )
       )
    {
        $docExclusions = "My Music", "My Pictures", "My Videos"

        # Clean Documents folder
        CleanDirectory $mydocuments $docExclusions

        # Clean Downloads
        CleanDirectory $mydownloads

        # Clean Favorites
        CleanDirectory $myfavorites

        # Clean Recent files
        CleanDirectory $myrecent

        # Clean Cache
        CleanDirectory $mycache

        # Clean Cookies
        CleanDirectory $mycookies

        # Clean History
        CleanDirectory $myhistory

        # Clean Desktop
        CleanDirectory $mydesktop

        # Empty the Recycle bin
        EmptyRecycleBin

        #Debug $strUser $TempDir $myprofile $mydocuments $mydownloads $myfavorites $myrecent $mycache $mycookies $myhistory $firstRun

        $isClean = $true; # Don't clean the profile again until the user's idle time is reset
        $firstRun = $false; # This is no longer considered a first run of the application.
    }
    elseif ( $isClean = $true -and $idleTimeMinutes -le $maxIdleTime )
    {
        # The users idle time has fallen below the max idle time limit.
        # Allow their profile to be cleaned again.
        $isClean = $false;
    }

    # DEBUG
    #$message = "IdleTimeMinutes = $idleTimeMinutes" + $crlf + "Is Clean: $isClean";
    #$dumpFile = "$mydocuments\$strUser.txt";
    #$message | Add-Content $dumpFile;

    Start-Sleep -s $sleepTime # Sleep for X minutes.
}
