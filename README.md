# Update Applications with Winget

This repository contains two PowerShell scripts designed for use with Microsoft Intune to detect and remediate outdated applications using Winget. The scripts are:

1. `detection.ps1`
2. `remediation.ps1`

## Table of Contents

- [Description](#description)
- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
  - [Detection Script](#detection-script)
  - [Remediation Script](#remediation-script)
- [Expected Results in Intune](#expected-results-in-intune)
- [Logging](#logging)
- [Known Issues](#known-issues)
- [Contributing](#contributing)
- [License](#license)
- [Version History](#version-history)

## Description

### detection.ps1

The detection script identifies applications that require updates on a system. It leverages Winget to find updatable applications while skipping certain blacklisted applications or checking if specific processes are running before proceeding with the update.

Key Features:

- Logs details about applications that require updates.
- Skips applications based on a predefined blacklist.
- Checks if specific processes are running before updating certain applications.
- Outputs results in a structured format for easy review.

### remediation.ps1

The remediation script updates the applications identified by the detection script. It uses Winget to perform the updates while adhering to the blacklist and check conditions defined.

Key Features:

- Updates applications identified by the detection script.
- Handles errors gracefully and logs them.
- Can uninstall and reinstall applications if needed.
- Respects blacklist conditions and checks for running processes before updating.

## Requirements

- Windows 10 or later
- Winget installed on the system
- PowerShell 5.1 or later

## Setup

1. **Clone the Repository:**
   
   ```bash
   git clone https://github.com/your-repository/update-apps-with-winget.git
   cd update-apps-with-winget
   ```

2. **Ensure Winget is Installed:**
   Winget must be installed and available on all target systems. For installation instructions, visit the [Winget installation guide](https://docs.microsoft.com/en-us/windows/package-manager/winget/).

3. **Deploy Scripts through Intune:**
   Use Intune to deploy the detection and remediation scripts as part of your device compliance policies. Configure the scripts to run periodically to ensure applications remain up to date.

## Usage

### Detection Script

Deploy the `detection.ps1` script to identify outdated applications. The script will log its findings and only exit with an error code if updates are required.

**Example Command:**

```powershell
.\detection.ps1
```

### Remediation Script

Deploy the `remediation.ps1` script to update the applications identified by the detection script. It logs the update process and handles any errors encountered during the updates.

**Example Command:**

```powershell
.\remediation.ps1
```

## Expected Results in Intune

When deployed through Intune, you can expect the following results:

- **Detection Script:**
  
  - Logs details about applications that require updates.
  - Skips applications listed in the blacklist or those with active processes that should not be interrupted.
  - If no updates are needed, the script exits with a success code (0).
  - As soon as an update is found to be required, the script exits with an error code (1) to trigger the remediation script.

- **Remediation Script:**
  
  - Updates the applications found with `winget update`.
  - Respects the conditions set for blacklisted applications.
  - Logs the update process, including any errors encountered.
  - Handles special cases where applications might need to be uninstalled before updating.

## Logging

Both scripts create detailed logs for troubleshooting and auditing purposes.

- **Log Location:** `C:\Temp\Logs\`
- **Log File Naming Convention:** `<Timestamp>_<COMPUTERNAME>_<USERNAME>_<ScriptName>.txt`

The logs include information about:

- The start and end of the script execution.
- Applications checked and their update status.
- Any errors or issues encountered during execution.

## Known Issues

- Winget might fail to update certain applications due to installer issues. The remediation script attempts to handle this by uninstalling and reinstalling the application.
- Applications with specific process names might not be updated if the process is running. This is by design to avoid interrupting users.

## Version History

### detection.ps1

- **1.0.5**: Added 'Microsoft.VCRedist.2005.x64' to the skip list.
- **1.0.6**: Added 'Microsoft.VCRedist.*', 'Microsoft.VC++*' to the skip list. Changed blacklist checker from `-eq` to `-like` to allow for wildcards in package names.
- **1.0.7**: Changed blacklist to skip everything titled 'Microsoft.VC*'.
- **1.0.8**: Changed the way the end position is determined.

### remediation.ps1

- **1.0.5**: Added 'Microsoft.VCRedist.2005.x64' to the skip list.
- **1.0.6**: Added 'Microsoft.VCRedist.*', 'Microsoft.VC++*' to the skip list. Changed blacklist checker from `-eq` to `-like` to allow for wildcards in package names.
- **1.0.7**: Changed blacklist to skip everything titled 'Microsoft.VC*'.
- **1.0.8**: Changed the way the end position is determined.
- **1.0.9**: Added a way to change install context and swapped the name of the blacklist variable.
