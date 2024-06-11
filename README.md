# Intune Winget Update Scripts

This repository contains two PowerShell scripts used for Microsoft Intune remediation: `detection.ps1` and `remediation.ps1`. These scripts are designed to detect and update applications using Winget.

## Files

- **detection.ps1**: Detects applications that can be updated using Winget.
- **remediation.ps1**: Updates the detected applications using Winget.

## Usage

### Detection Script (`detection.ps1`)

This script is used to detect updatable applications on a system using Winget.

#### Key Features

- Logs the detection process.
- Verifies the installation and availability of Winget.
- Identifies upgradable applications and checks against a blacklist.
- Outputs the results and determines if remediation is required.

#### How to Run

1. Save the script to a desired location.
2. Execute the script in PowerShell:
   
   ```powershell
   .\detection.ps1
   ```

#### Script Details

- Initializes log files.
- Detects Winget installation path.
- Updates Winget sources.
- Identifies applications that can be updated.
- Filters and processes the output to determine if any applications require updating.
- Checks each application against a predefined blacklist to skip or conditionally check certain applications.

### Remediation Script (`remediation.ps1`)

This script is used to update applications detected by the `detection.ps1` script.

#### Key Features

- Logs the remediation process.
- Verifies the installation and availability of Winget.
- Updates applications using Winget, respecting a predefined blacklist.
- Handles special cases and errors during the update process.

#### How to Run

1. Save the script to a desired location.
2. Execute the script in PowerShell:
   
   ```powershell
   .\remediation.ps1
   ```

#### Script Details

- Initializes log files.
- Detects Winget installation path.
- Updates Winget sources.
- Identifies applications that can be updated.
- Processes each application and performs the update, respecting conditions from a predefined blacklist.
- Handles common Winget errors and attempts to resolve them by reinstalling applications if necessary.

## Blacklist Configuration

Both scripts use a predefined blacklist to skip or conditionally check certain applications during detection and remediation. The blacklist is defined within the scripts as a set of PowerShell objects.

Example:

```powershell
$AppCheck = @()
$AppCheck += New-Object PSObject -Property @{
    PackageName = "Microsoft.Teams"
    Action = "Check"
    ProcessName = "ms-teams"
    Reason = "Don't want to randomly update users Teams when they are in calls and such"
}
```

### Actions

- **Skip**: Skips the update for the specified application.
- **Check**: Checks if a specified process is running before updating the application.

## Logging

Both scripts generate log files in the `C:\Temp\Logs` directory with detailed information about the detection and remediation processes. These logs are useful for troubleshooting and auditing purposes.

## Conclusion

These scripts provide a robust solution for detecting and updating applications using Winget in a Microsoft Intune environment. They ensure that updates are performed in a controlled manner, respecting predefined conditions and minimizing disruptions to users.
