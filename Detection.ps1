<#	
	.NOTES
	===========================================================================
	 Created with: 	PowerShell
	 Created on:   	22/05/2024 3:30 PM
	 Modified on:	03/06/2024
	 Created by:    DeakinCarr
	 Organization: 	UtilitiseIT PTY LTD
	 Filename:     	Detection
     Tenant:        
	 Version:		1.1.0
	===========================================================================
	.DESCRIPTION
		A description of the file.
    .NOTES
        Versions:
        - 1.0.5 - Added 'Microsoft.VCRedist.2005.x64' to the skip list.
        - 1.0.6 - Added 'Microsoft.VCRedist.*', 'Microsoft.VC++*' to the skip list. 
                - Changed blacklist checker from -eq to -like as to allow for wild cards in package names.
        - 1.0.7 - Changed blacklist to skip everything titled 'Microsoft.VC*'
        - 1.0.8 - Changed the way the end position is determined
        - 1.0.9 - Added a way to change install context and swapped the name of the blacklist variable
        - 1.1.0 - Fixed a bug that users cant run winget if they have multiple wingets installed
#>
 

# Initialize log file names and paths
$WorkingDirectory = "$env:HOMEDRIVE\Temp"
$ScriptName = "Detection_Update_Apps_With_Winget_1.1.0"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$TempLogs = "$WorkingDirectory\Logs\$Stamp`_$env:COMPUTERNAME`_$env:USERNAME`_$ScriptName.txt"
Start-Transcript -Path $TempLogs

$SYSTEM_MODE = $True

function Remove-ContinuousNonAsciiSequences {
    param (
        [string]$inputString
    )

    # Regular expression to match continuous non-ASCII characters
    $nonAsciiPattern = '[^\x00-\x7F]+'

    # Remove continuous non-ASCII sequences
    $cleanString = $inputString -replace $nonAsciiPattern, ' '

    return $cleanString
}


try {
    # Find where Winget should be installed in a system environment
    switch ($SYSTEM_MODE) {
        $True {
            $Winget = Get-ChildItem -Path "C:\Program Files\WindowsApps" | Where-Object {$_.Name -like "Microsoft.DesktopAppInstaller_*x64__8wekyb3d8bbwe"} | Get-ChildItem | Where-Object {$_.Name -eq "winget.exe"}
            # Sometimes a user has more than one winget version installed for some reason, so we just want the latest version
            $Winget = $Winget[$Winget.Count - 1]
        }
        $false {
            $Winget = "winget"
        }
    }
    

    # Ensure winget is installed and available
    if (-not ($Winget)) {
        Write-Host "winget is not installed or not found in the system PATH." -ForegroundColor Red
        Stop-Transcript
        exit 1
    }

    # Get the filepath to winget
    switch ($SYSTEM_MODE) {
        $True {
            $WingetPath = $Winget.VersionInfo.FileName
        }
        $false {
            $WingetPath = "winget"
        }
    }

    # Update winget sources, then use winget to find all updatable applications
    
    (. "$($WingetPath)" source update --disable-interactivity --verbose)
    $upgradableApps = (. "$($WingetPath)" update --accept-source-agreements | Out-String)
    $upgradableApps = (Remove-ContinuousNonAsciiSequences $upgradableApps) -split "`n"

    if ($upgradableApps -match "No installed package found matching input criteria.") {
        if ($upgradableApps -match "explicit targeting") {
            ($upgradableApps) -split "`n" | Where-Object { -not $_.startsWith("  ")}   
            Write-Error "An application requires targeting!!!!!!!!"
            Stop-Transcript
            exit 1;
        }
        ($upgradableApps) -split "`n" | where-Object { -not $_.startsWith("  ")}   
        Stop-Transcript
        exit 0;
    }
    
    # Winget has an Ascii spinnder which causes blank lines of varying length. The following finds the actual start of the output by finding the header values
    $startPos = $upgradableApps.IndexOf(($upgradableApps -match "-----------")[0]) + 1
    $header = $upgradableApps[$startPos - 2]
    $endPos = $upgradableApps.IndexOf(($upgradableApps -match " upgrades available.")[0]) - 1

    # Determines the start points of each column within the Winget Output
    $NameColumnStart = 0
    $IdColumnStart = $header.IndexOf("Id")
    $VersionColumnStart = $header.IndexOf("Version")
    $AvailableColumnStart = $header.IndexOf("Available")
    $SourceColumnStart = $header.IndexOf("Source")

    
    function Parse-Winget-Line {
        param (
            [string]$line
        )

        # If the line is empty, leave
        if (-not $line){return}

        # Extract the values within each line between the expected column start and endpoints then trim the whitespace
        
        $appName = $line.Substring($NameColumnStart, $IdColumnStart-$NameColumnStart).trim()
        $packageName = $line.Substring($IdColumnStart, $VersionColumnStart-$IdColumnStart).trim()
        $version = $line.Substring($VersionColumnStart, $AvailableColumnStart-$VersionColumnStart).trim()
        $available = $line.Substring($AvailableColumnStart, $SourceColumnStart-$AvailableColumnStart).trim()
        $source = $line.Substring($SourceColumnStart, $line.Length-$SourceColumnStart).trim()

        $props = @{
            AppName = $appName
            PackageName = $packageName
            Version = $version
            Available = $available
            Source = $source
        }
        
        # Create a PSObject using Add-Member
        $obj = New-Object PSObject
        foreach ($prop in $props.GetEnumerator()) {
            $obj | Add-Member -NotePropertyName $prop.Key -NotePropertyValue $prop.Value
        }
        
        return $obj
    }
        
    function Check-Updates {
        param (
            [PSObject]$App,
            [PSObject]$AppCheck
        )
        Write-Host "`nChecking if app requires update $($App.appName)"
        Write-Host "Package Name: $($App.packageName)"
        Write-Host "Version: $($App.version)"
        Write-Host "Available Version: $($App.available)"
        
        try {
            # Find the item cooresponding the black list entry
            $AppCheckedItem = $AppCheck | Where-Object { "$($App.PackageName)" -like $_.PackageName }

            if ($AppCheckedItem){
                switch ($AppCheckedItem.Action) {
                    # If the package is blacklisted with the skip flag, bypass the update with only a warning.
                    "Skip" {
                        Write-Host "`t|_`tThe App '$($AppCheckedItem.PackageName)' is to be skipped so it won't be updated."
                        if ($AppCheckedItem.Reason){
                            Write-Host "`t|_`tIt is listed to be skipped for the following reason: $($AppCheckedItem.Reason)"
                        }
                        return "`n---------------------------------------------------------------------------"
                    }
                    # If the package is blacklisted with the 'Check' flag, determine if the process is running 
                    # and only update it if its not being used.
                    "Check" {
                        Write-Host "'$($AppCheckedItem.PackageName)' has a Check condition. Checking if '$($AppCheckedItem.ProcessName)' is running."
                        $Process = Get-Process -Name $AppCheckedItem.ProcessName -ErrorAction SilentlyContinue
                        if ($Process) {
                            Write-Host "`t|_The process '$($AppCheckedItem.ProcessName)' is still running so it won't be updated."
                            return "`n---------------------------------------------------------------------------"
                        } else {
                            Write-Host "`t|_The process '$($AppCheckedItem.ProcessName)' is not runnning."
                        }
                    }
                    default {
                        Write-Host "An unknown blacklist flag has been assigned to this item: '$($AppCheckedItem.Action)'"
                        Write-Host "Remember the action flags are case sensitive."
                    }
                }
            }

            Write-Host "Remediation required!"
            exit 1

        } catch {

            Write-Host "Error updating app $($App.appName): $_"

        }

        return "`n---------------------------------------------------------------------------"
    }

    
        
    $AppCheck = @()
    $AppCheck += New-Object PSObject -Property @{
        PackageName = "Microsoft.Teams"
        Action = "Check"
        ProcessName = "ms-teams"
        Reason = "Don't want to randomly update users Teams when they are in calls and such"
    }
    $AppCheck += New-Object PSObject -Property @{
        PackageName = "Microsoft.Teams.Classic"
        Action = "Check"
        ProcessName = "Teams"
        Reason = "Don't want to randomly update users Teams when they are in calls and such"
    }
    $AppCheck += New-Object PSObject -Property @{
        PackageName = "Microsoft.VC*"
        Action = "Skip"
        Reason = "Known to kick people from software when updating Visual C++ on devices"
    }
    $AppCheck += New-Object PSObject -Property @{
        PackageName = 'Oracle.JavaRuntimeEnvironment'
        Action = "Skip"
        Reason = "Unknown"
    }
    $AppCheck += New-Object PSObject -Property @{
        PackageName = 'Microsoft.RemoteDesktopClient'
        Action = "Skip"
        Reason = "Application kicks people off when updated"
    }
    $AppCheck += New-Object PSObject -Property @{
        PackageName = 'Microsoft.Office'
        Action = "Skip"
        Reason = "We would expect office to auto update, so we don't worry about it here."
    }
    

    # For every apps, extract the relevant information
    $Apps = $upgradableApps[$startPos..$endPos] | foreach-Object { Parse-Winget-Line $_ }
    $Apps | foreach-Object { Check-Updates $_ $AppCheck -Verbose }

    Write-Host "No updates required!"
    Stop-Transcript
    exit 0
}
catch {
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    Stop-Transcript
    exit 1
}