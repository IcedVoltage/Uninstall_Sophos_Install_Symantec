<#
.SYNOPSIS
    Run SophosZap.exe (for a 2nd time) to cleanup the old anti-virus software.
.DESCRIPTION
    <ENTER>
.PARAMETER
    None
.INPUTS
    None
.OUTPUTS
    None
.NOTES
  Script Version: 1.3
  App Version:    0.0
  Author:         Peter Milne
  Creation Date:  22-02-2021
  Last updated:   23-02-2021
    Purpose/Change: 22-02-2021 | 1.0 - Creation of document.
    Purpose/Change: 23-02-2021 | 1.2 - Added the registry keys - "SophosRemoved" = "yes"
    Purpose/Change: 23-02-2021 | 1.3 - Fixed error with source location of SophosZap.exe
.EXAMPLE
    In SCCM | powershell –ExecutionPolicy Bypass -file "uninstall-Sophos-Endpoint_afterReboot_v1.3.ps1"
#>

#----------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------[ Declarations ]---------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
# My Working Directory (Useful for when SCCM calls the script).
#$swc_mwd                                = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$swc_mwd = "C:\SWC-IT\Installers"
#______________________
# Directories
$swc_dir_temp                           = "C:\Temp"
#______________________
# Repository Path
$swc_repository_dir                     = "C:\SWC-IT\Installers"
#______________________
# After Reboot Script
$swc_sophos_zap_reboot_PS               = "uninstall-Sophos-Endpoint_afterReboot_v1.3.ps1"
$swc_sophos_zap_reboot_PS_path_script   = "$swc_repository_dir\$swc_sophos_zap_reboot_PS"
#______________________
# Source Files
$swc_installer                          = "uninstall-Sophos-Endpoint_afterReboot_v1.3.ps1"
$swc_installer_src                      = "$swc_mwd\$swc_installer"
$swc_installer_arg                      = ""
#______________________
# Sophos ZAP uninstaller (Sophos Removal)
$swc_sophos_zap_uninstaller             = "SophosZap.exe"
$swc_sophos_zap_uninstaller_src         = "$swc_repository_dir\$swc_sophos_zap_uninstaller"
$swc_sophos_zap_uninstaller_arg         = '--confirm'
$swc_sophos_zap_uninstaller_log         = "C:\users\admin\AppData\Local\Temp\Sophos Windows Endpoint Zap log.txt"

$swc_sophos_zap_uninstaller_reg_path    = "HKLM:\SOFTWARE\Seymour Whyte Constructions IT"
$swc_sophos_zap_uninstaller_reg_name    = "Sophos ZAP Removal"
$swc_sophos_zap_uninstaller_reg_key     = "$swc_sophos_zap_uninstaller_reg_path\$swc_sophos_zap_uninstaller_reg_name"
#______________________
# Registry Information
$swc_reg_path                           = 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT'
$swc_reg_name                           = 'Remove Sophos Part 2'
$swc_reg_key                            = "$swc_reg_path"+"\"+"$swc_reg_name"
#______________________
# General Information
$swc_Contact                            = "Seymour Whyte Constructions IT"
$swc_DisplayName                        = "Remove-Sophos-Part-2"
$swc_DisplayVersion                     = "0"
$swc_ClientVersion                      = "0"
$swc_Publisher                          = "IT@SW"
$swc_Author                             = "Peter Milne"
$swc_AuthorContact                      = "0733863222"
$swc_ScriptVersion                      = "1.3"
$swc_Version                            = "0"
#______________________
# Get today's Date & Time
$swc_currentDate                        = Get-Date -Format "dd-MM-yyyy"
$swc_currentDateTime                    = Get-Date -Format "dd-MM-yyyy HH:mm"
#______________________
# Logging
[string]$swc_dir_logfile                = "C:\SWC-IT\logs"
[string]$swc_logfile                    = "$swc_dir_logfile\Log-SCCM" + "_$swc_DisplayName" + "_$swc_ClientVersion" + "_v$swc_ScriptVersion" + "_$swc_currentDate.log"
[int]$numberOfErrors                    = "0"
#______________________
# Event Viewer
$swc_EV_LogName                         = "Seymour Whyte IT"
$swc_EV_Source                          = "SCCM - $swc_DisplayName"
$swc_EV_Message_Info                    = "SCCM app ($swc_DisplayName) has been successfully installed"
$swc_EV_Message_Warning                 = "SCCM app ($swc_DisplayName) has been installed but with warnings. Please check the installation and verify that the application was installed correctly."
$swc_EV_message_Error                   = "SCCM app ($swc_DisplayName) was not installed. Check installation logs."
#______________________
#______________________
# Log FIle Initialization
$swc_txt_initalization                  = "
///////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
||||||||||||||||||||||||||||||||||[ Start ]|||||||||||||||||||||||||||||||||||
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////

-------------------------------------------------------------------------------
IT@SW              : Uninstall Sophos AV (2nd pass of SophosZap.exe)  [Start]
-------------------------------------------------------------------------------
Started            : $swc_currentDateTime
Source             : $swc_mwd
Source Files       : $swc_sophos_zap_uninstaller
Install Location   : $swc_sophos_endpoint_install_path
Install Location   : $swc_sophos_connect_install_path
Install Location   : $swc_sophos_ssl_vpn_install_path
Install Location   : $swc_symantec_endpoint_install_path
Author             : $swc_Author
Contact Info       : IT.ServiceDesk@seymourwhyte.com.au 
------------------------------------------------------------------------------

///////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
|||||||||||||||||||||||||||||||||[ Logging ]||||||||||||||||||||||||||||||||||
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////
"

#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------[ Functions ]-----------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
function Swc-Write-Log{
<#
.SYNOPSIS
    Assists with logging message to a log file
.DESCRIPTION
    Adds a file name extension to a supplied name.
    Takes any strings for the file name or extension.
.PARAMETER level
    Specifies the severity of the alert (either Success, Alert or Failure).
.PARAMETER text
    Specifies the conetent of the log message.
.EXAMPLE
PS> Swc-Write-Log -level 0 -text "{Registry} - RegKey (DisplayVersion) does not = $swc_DisplayVersion."
           .
          ":"
        ___:____     |"\/"|
      ,'        `.    \  /
      |  O        \___/  |
    ~^~^~^~^~^~^~^~^~^~^~^~^~
#>

#---------------[Inputs]---------------
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("0","1","2")]
    [Int]$level,

    [Parameter(Mandatory=$true)]
    [string]$text
)

#------------[Declarations]------------
# Get today's Date & Time
$swc_currentDate         = Get-Date -Format "dd-MM-yyyy"
$swc_currentDateTime     = Get-Date -Format "dd-MM-yyyy HH:mm"

# Logging
[string]$swc_dir_logfile = "C:\SWC-IT\logs"
[string]$swc_logfile     = "$swc_dir_logfile\Log-SCCM" + "_$swc_DisplayName" + "_$swc_ClientVersion" + "_v$swc_ScriptVersion" + "_$swc_currentDate.log"
[string]$Alertlevel      = ""

#-------------[Execution]--------------
# Check the alert level from the user input & then set the variable
If($level -eq "0"){
    $Alertlevel = ' - [Success] - '
}
ElseIf($level -eq "1"){
    $Alertlevel = ' - [Alert]   - '
}
ElseIf($level -eq "2"){
    $Alertlevel = ' - [Failure] - '
    $global:numberOfErrors++
}
Else{
    Write-Output "Unknown error with Swc-Write-Log function" >> $swc_logfile
}

#---------------[Result]---------------
$result = Write-Output $swc_currentDateTime" "$Alertlevel" "$text >> $swc_logfile

#----------------[END]-----------------
return $result
}                       #[WORKING] end function Swc-Write-Log
function Swc-Check-If-Directory-Exists{
<#
.SYNOPSIS
    Checks if a directory exists and then creates it if it didn't (plus logs each step).
.DESCRIPTION
    Using test-path, this function simply checks if the path exists. If it does not, it will create it & log it out.
    Relies on function "Swc-Write-Log"
.PARAMETER pm_path_to_test
    Pass in the full path like: "C:\SWC-IT\Logs"
.EXAMPLE
PS> Swc-Check-If-Directory-Exists -path "C:\Temp"
           .
          ":"
        ___:____     |"\/"|
      ,'        `.    \  /
      |  O        \___/  |
    ~^~^~^~^~^~^~^~^~^~^~^~^~
#>
#---------------[Inputs]---------------
Param(
    [Parameter(Mandatory=$true)]
    [string]$path
)

#------------[Declarations]------------

#-------------[Execution]--------------

If( -not(Test-Path $path) ){
    New-Item -ItemType Directory -Path $path -Force
    Swc-Write-Log -level 0 -text "The directory ($path) was created."
    $result = "[Success] - The directory ($path) was created."
}
ElseIf(Test-Path $path){
    Swc-Write-Log -level 1 -text "The directory ($path) already exists."
    $result = "[Alert] - The directory ($path) already exists."
}
Else{
    Swc-Write-Log -level 2 -text "The directory ($path) was not created or does not exist."
    $result = "[Failure] - Unknown error when attempting to create/check for ($path)."
}

#----------------[END]-----------------
return $result
}       #[WORKING] end function Swc-Check-If-Directory-Exists
function Swc-Create-RegKeys{
<#
.SYNOPSIS
    Creates custom registry keys
.DESCRIPTION

.PARAMETER pm_install_path_exe
    Pass in the test path (like an exe)
.PARAMETER pm_reg_path
    Enter the registry path (ie HKLM:\SOFTWARE....)

.EXAMPLE
PS> Swc-Create-RegKeys `
    -pm_install_path_exe "C:\Temp\doc.txt" `
    -pm_reg_path         "HKLM:\SOFTWARE\Seymour Whyte Constructions IT" `
    -pm_reg_name         "Removal of Sophos" `
    -pm_reg_key          "HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Removal of Sophos" `
    -pm_Author           "Peter Milne" `
    -pm_AuthorContact    "0733863222" `
    -pm_Contact          "Seymour Whyte Constructions IT" `
    -pm_DisplayName      "Removal of Sophos Endpoint" `
    -pm_DisplayVersion   "0" `
    -pm_currentDate      "17-02-2021" `
    -pm_Publisher        "IT@SW" `
    -pm_ScriptVersion    "1.0" `
    -pm_Version          "0"

           .
          ":"
        ___:____     |"\/"|
      ,'        `.    \  /
      |  O        \___/  |
    ~^~^~^~^~^~^~^~^~^~^~^~^~
#>

#---------------[Inputs]---------------
Param(

    [Parameter(Mandatory=$true)]
    [string]$pm_install_path_exe,

    [Parameter(Mandatory=$true)]
    [string]$pm_reg_path,

    [Parameter(Mandatory=$true)]
    [string]$pm_reg_key,

    [Parameter(Mandatory=$true)]
    [string]$pm_reg_name,
 
    [Parameter(Mandatory=$true)]
    [string]$pm_Author,    

    [Parameter(Mandatory=$true)]
    [string]$pm_AuthorContact, 

    [Parameter(Mandatory=$true)]
    [string]$pm_Contact, 

    [Parameter(Mandatory=$true)]
    [string]$pm_DisplayName, 

    [Parameter(Mandatory=$true)]
    [string]$pm_DisplayVersion,
     
    [Parameter(Mandatory=$true)]
    [string]$pm_currentDate,
     
    [Parameter(Mandatory=$true)]
    [string]$pm_Publisher,
     
    [Parameter(Mandatory=$true)]
    [string]$pm_ScriptVersion,

    [Parameter(Mandatory=$true)]
    [string]$pm_Version   
)

#------------[Declarations]------------
# Get today's Date & Time
$pm_currentDate         = Get-Date -Format "dd-MM-yyyy"
$pm_currentDateTime     = Get-Date -Format "dd-MM-yyyy HH:mm"
#______________________
# Logging
[string]$pm_dir_logfile = "C:\SWC-IT\logs"
[string]$pm_logfile     = "$swc_dir_logfile\Log-SCCM" + "_$pm_DisplayName" + "_$pm_ClientVersion" + "_v$pm_ScriptVersion" + "_$pm_currentDate.log"
#______________________
# Event Viewer
<#
*** not working at this stage ***
$pm_EV_LogName           = "Seymour Whyte IT"
$pm_EV_Source            = "SCCM - $pm_DisplayName"
$pm_EV_Message_Info      = "SCCM app ($pm_DisplayName) has been successfully installed"
$pm_EV_Message_Warning   = "SCCM app ($pm_DisplayName) has been installed but with warnings. Please check the installation and verify that the application was installed correctly."
$pm_EV_message_Error     = "SCCM app ($pm_DisplayName) was not installed. Check installation logs."
#>
#----------[Initialisations]-----------
<#
New-EventLog -LogName $pm_EV_LogName -Source $pm_EV_Source
#>
#-------------[Execution]--------------

If(Test-Path "$pm_install_path_exe"){
    New-Item         -Path "$pm_reg_path"  -Name "$pm_reg_name"   –Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "Author"         -Value "$pm_Author"         -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "AuthorContact"  -Value "$pm_AuthorContact"  -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "Contact"        -Value "$pm_Contact"        -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "DisplayName"    -Value "$pm_DisplayName"    -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "DisplayVersion" -Value "$pm_DisplayVersion" -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "InstallDate"    -Value "$pm_currentDate"    -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "Publisher"      -Value "$pm_Publisher"      -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "ScriptVersion"  -Value "$pm_ScriptVersion"  -PropertyType "String" -Force
    New-ItemProperty -Path "$pm_reg_key"   -Name "Version"        -Value "$pm_Version"        -PropertyType "DWord"  -Force

    #Swc-Write-Log -level 0 -text "{Registry} - RegKeys created because the application (.exe) was detected."
    #Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" -Message "{Registry} - RegKeys created because the application (.exe) was detected."
    #---------------[Result]---------------
    $result = "Information - {Registry} - RegKeys created because the application (.exe) was detected ($pm_install_path_exe)."

}
ElseIf(-not(Test-Path $pm_install_path_exe)){

    #Swc-Write-Log -level 1 -text "{Registry} - RegKeys not created because the application (.exe) was not detected."
    #Write-EventLog -log $swc_EV_LogName -source $pm_EV_Source -EntryType Warning -eventID "20" -Message "{Registry} - RegKeys not created because the application (.exe) was not detected."
    #---------------[Result]---------------
    $result = "Warning - {Registry} - RegKeys not created because the application (.exe) was not detected ($pm_install_path_exe)."

}
Else{

    #Swc-Write-Log -level 2 -text "{Registry} - Unknown error attempting to detect/create the RegKeys"
    #Write-EventLog -log $pm_EV_LogName -source $pm_EV_Source -EntryType Error -eventID "30" -Message "{Registry} - Unknown error attempting to detect/create the RegKeys"
    #---------------[Result]---------------
    $result = "Error - {Registry} - Unknown error attempting to detect/create the RegKeys ($pm_reg_key)."

}

#---------------[Result]---------------
#----------------[END]-----------------
return $result
}
#----------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------[ Initialisations ]-------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

<#
******************************************************
    Check/Create the Event Viewer Location

    New-EventLog
    Write-EventLog -LogName
    Remove-EventLog [Remove-EventLog -LogName "MyLog"]
    Sits in [Event Viewer] > [Applications and Services Logs] > [Seymour Whyte IT]
******************************************************
#>
New-EventLog -LogName $swc_EV_LogName -Source $swc_EV_Source

<#
******************************************************
    Check/Create the Logging File Directory
******************************************************
#>
Swc-Check-If-Directory-Exists -path "$swc_dir_logfile"

If(-not(Test-Path $swc_dir_logfile)){
    New-Item -ItemType Directory -Path $swc_dir_logfile -Force
    Write-Output $swc_txt_initalization >> $swc_logfile
    Swc-Write-Log -level 0 -text "[1.0] - {Initialisation} - The directory ($swc_dir_logfile) was created for the log file location."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[1.0] - {Initialisation} - The directory ($swc_dir_logfile) was created for the log file location."
}
ElseIf(Test-Path $swc_dir_logfile){
    Write-Output $swc_txt_initalization >> $swc_logfile
    Swc-Write-Log -level 1 -text "[1.1] - {Initialisation} - The directory ($swc_dir_logfile) already exists for the log file location."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[1.1] - {Initialisation} - The directory ($swc_dir_logfile) already exists for the log file location."
}
Else{
    Write-Output $swc_txt_initalization >> $swc_logfile
    Swc-Write-Log -level 2 -text "[1.2] - {Initialisation} - The directory ($swc_dir_logfile) was not created and or does not exist for the log file location."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[1.2] - {Initialisation} - The directory ($swc_dir_logfile) was not created and or does not exist for the log file location."
}

<#
******************************************************
    Check/Create the Temp Directory
******************************************************
#>

If(-not(Test-Path $swc_dir_temp)){
    New-Item -ItemType Directory -Path $swc_dir_temp -Force
    Swc-Write-Log -level 0 -text "[2.0] - {Initialisation} - The directory ($swc_dir_temp) was created for the temp location."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[2.0] - {Initialisation} - The directory ($swc_dir_temp) was created for the temp location."
}
ElseIf(Test-Path $swc_dir_temp){
    Swc-Write-Log -level 1 -text "[2.1] - {Initialisation} - The directory ($swc_dir_temp) already exists for the temp location."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[2.1] - {Initialisation} - The directory ($swc_dir_temp) already exists for the temp location."
}
Else{
    Swc-Write-Log -level 2 -text "[2.2] - {Initialisation} - The directory ($swc_dir_temp) was not created and or does not exist for temp location."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[2.2] - {Initialisation} - The directory ($swc_dir_temp) was not created and or does not exist for temp location."
}

<#
******************************************************
    Check/Create the Installer Repository Directory
******************************************************
#>

If(-not(Test-Path $swc_repository_dir)){
    New-Item -ItemType Directory -Path $swc_repository_dir -Force
    Swc-Write-Log -level 0 -text "[2.3] - {Initialisation} - The directory ($swc_repository_dir) was created for the repository exe/MSI location."
}
ElseIf(Test-Path $swc_repository_dir){
    Swc-Write-Log -level 1 -text "[2.4] - {Initialisation} - The directory ($swc_repository_dir) already exists for the repository exe/MSI location."
}
Else{
    Swc-Write-Log -level 2 -text "[2.5] - {Initialisation} -  The directory ($swc_repository_dir) was not created and or does not exist for the repository exe/MSI location."
}

#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------[ Execution ]-----------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#________________________ [ 1.0 - Check if part 1/2 of the script has alreay been completed. ] _______________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________


If(
    (Test-Path -Path 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Remove Sophos Part 1') <# Proceed if only part 1 of the uninstall has been done. #>`
    -and `
    (-not(Test-Path -Path 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Remove Sophos Part 2'))
  ){
    # ----------------------------
    # [1.1] - Logging
    Swc-Write-Log -level 0 -text "[3.0] - {Checking} - Proceeding with the script - since only part 1 has already been completed."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[3.0] - {Checking} - Proceeding with the script - since only part 1 has already been completed."
}
ElseIf( `
    (Test-Path -Path 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Remove Sophos Part 1') <# Skip the script if part 1 & 2 are already done. #>`
    -and `
    (Test-Path -Path 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Remove Sophos Part 2')
   ){
    # ----------------------------
    # [1.2] - Logging
    Swc-Write-Log -level 0 -text "[3.1] - {Checking} - Exiting Script - Skipping script - since part 1 & 2 are already complete."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[3.1] - {Checking} - Exiting Script - Skipping script - since part 1 & 2 are already complete"
    exit
}
Else{
    # ----------------------------
    # [1.3] - Logging
    Swc-Write-Log -level 0 -text "[3.2] - {Checking} - Exiting Script - Unknown error when checking if part 1 or 2 have been completed."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[3.2] - {Checking} - Exiting Script - Unknown error when checking if part 1 or 2 have been completed."
    exit
}


#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#______________________________ [ 2.0 - Uninstall Sophos Endpoint Protection (2nd pass) ] __________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

<#
---------------+---------------
          ___ /^^[___              _
         /|^+----+   |#___________//
       ( -+ |____|    ______-----+/
        ==_________--'            \
          ~_|___|__
#>


#------------------------------
# [1.0] - Logging
Swc-Write-Log -level 1 -text "[4.1] - {Scheduled Task} - SWC_Sophos_Removal_Reboot caused uninstall-Sophos-Endpoint-afterReboot_v1.3.ps1 to be started after a reboot."
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[4.1] - {Scheduled Task} - SWC_Sophos_Removal_Reboot caused uninstall-Sophos-Endpoint-afterReboot_v1.3.ps1 to be started after a reboot."

Swc-Write-Log -level 1 -text "[4.2] - {Scheduled Task} - Attempting to remove the one time schedule task (SWC_Sophos_Removal_Reboot)."
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[4.2] - {Scheduled Task} - Attempting to remove the one time schedule task (SWC_Sophos_Removal_Reboot)."
#------------------------------
# [1.1] - Removing the scheduled task (that calls this script).
start-sleep -s 2
schtasks.exe /delete /F /TN SWC_Sophos_Removal_Reboot 
Start-Sleep -s 30

# ----------------------------
# [1.2] - look up any scheduled tasks with the name SWC
Get-ScheduledTask -TaskName SWC* | FL > Get-ScheduledTask -TaskName SWC* | FL > 'C:\SWC-IT\logs\Log-SCCM_GetScheduleTask_zap_post_removal_of_schedule.log'

#------------------------------
# [1.3] - Logging (starting sophos ZAP)
Swc-Write-Log -level 1 -text "[4.2] - {Uninstall Sophos} - Starting Sophos Zap uninstaller for a 2nd time."
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[4.2] - {Uninstall Sophos} - Starting Sophos Zap uninstaller for a 2nd time."
#------------------------------
# [1.4] - Uninstalling Sophos Endpoint (using Sophos Zap).
Start-Process -FilePath $swc_sophos_zap_uninstaller_src -ArgumentList $swc_sophos_zap_uninstaller_arg -wait 
Start-Sleep -s 60

#------------------------------
# [1.5] - Logging
Swc-Write-Log -level 1 -text "[4.3] - {Uninstall Sophos} - [2/2] Run of SophosZap.exe - Uninstalled Sophos Endpoint Protection using Sophos ZAP."
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[4.3] - {Uninstall Sophos} - [2/2] Run of SophosZap.exe - Uninstalled Sophos Endpoint Protection using Sophos ZAP."

#------------------------------
# [1.6] - Alert user

msg.exe * /TIME:600 'Hello,
We are changing Anti-Virus software and need you to restart your computer some time today.
Please ensure you save any open files prior to restarting.
Thank you
----------------
Seymour Whyte IT
07 3386 3222
IT.ServiceDesk@seymourwhyte.com.au'

#----------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------[ Registry ]----------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

If(
    (-not(Test-Path "C:\Program Files (x86)\Sophos\Connect\GUI\scgui.exe")) <# Checking that the old Sophos Connect has been uninstalled. #> `
    -and `
    (-not(Test-Path "C:\Program Files\Sophos\Sophos UISophos UI.exe")) <# Checking that the old Sophos Endpoint has been uninstaleld. #> `
    -and `
    (Test-Path "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\14.2.5569.2100.105\Bin\SymCorpUI.exe") <# Checking that the new Symantec AV has been installed. #> `
    -and `
    (Test-Path "C:\Program Files\Fortinet\FortiClient\FortiClient.exe") <# Checking that the new VPN (Forticlient) has been installed. #>
){
    New-Item         -Path "$swc_reg_path"  -Name "$swc_reg_name"  –Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "Author"         -Value "$swc_Author"         -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "AuthorContact"  -Value "$swc_AuthorContact"  -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "Contact"        -Value "$swc_Contact"        -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "DisplayName"    -Value "$swc_DisplayName"    -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "DisplayVersion" -Value "$swc_DisplayVersion" -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "InstallDate"    -Value "$swc_currentDate"    -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "Publisher"      -Value "$swc_Publisher"      -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "ScriptVersion"  -Value "$swc_ScriptVersion"  -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "Version"        -Value "$swc_Version"        -PropertyType "DWord"  -Force
     
    New-ItemProperty -Path "$swc_reg_key"   -Name "Zap Run Twice"  -Value "yes"                 -PropertyType "String" -Force
    New-ItemProperty -Path "$swc_reg_key"   -Name "SophosRemoved"  -Value "yes"                 -PropertyType "String" -Force

    Swc-Write-Log -level 0 -text "[5.0] - {Registry} - RegKeys created because forticlient & symantec were detected & sopohs av, sophos connect were not."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[5.0] - {Registry} - RegKeys created because forticlient & symantec were detected & sopohs av, sophos connect were not."
}
Else{
    Swc-Write-Log -level 2 -text "[5.1] - {Registry} - Unknown error attempting to detect/create the RegKeys"
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[5.1] - {Registry} - Unknown error attempting to detect/create the RegKeys"
}

#----------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------[ End ]--------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
