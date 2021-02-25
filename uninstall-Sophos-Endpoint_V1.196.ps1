<#
.SYNOPSIS
    Uninstall Sophos Connect VPN and Sophos Endpoint
    Install Symantec Endpoint Protection 14.2.5569.2100 and Forticlient 6.0.9.0277.
.DESCRIPTION
    <ENTER>
.PARAMETER
    None
.INPUTS
    None
.OUTPUTS
    None
.NOTES
  Script Version: 1.196
  App Version:    0.0
  Author:         Peter Milne
  Creation Date:  16-02-2021
  Last updated:   23-02-2021
    Purpose/Change: 16-02-2021 | Creation of document.
    Purpose/Change: 19-02-2021 | 1.192 - fixed issue with uninstalling Sophos Connect (miss type).
    Purpose/Change: 22-02-2021 | 1.193 - Added exe checking for Forticlient install & symantec
    Purpose/Change: 22-02-2021 | 1.194 - Added reboot and resume from powershell restart (not working).
    Purpose/Change: 23-02-2021 | 1.195 - Added in creating schedule task with schtasks.exe
    Purpose/Change: 23-02-2021 | 1.196 - Added msg.exe * /TIME:600 '[Restart 1/2]'
.EXAMPLE
    In SCCM | powershell –ExecutionPolicy Bypass -file "uninstall-Sophos-Endpoint_v1.196.ps1"
#>

#----------------------------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------[ Declarations ]---------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
# My Working Directory (Useful for when SCCM calls the script).
$swc_mwd                                = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#______________________
# Directories
$swc_dir_temp                           = "C:\Temp"
#______________________
# Other
$swc_hostname                           = $env:computername
#______________________
# Repository Path
$swc_repository_dir                     = "C:\SWC-IT\Installers"
#______________________
# After Reboot Script
$swc_sophos_zap_reboot_PS               = "uninstall-Sophos-Endpoint_afterReboot_v1.3.ps1"
$swc_sophos_zap_reboot_PS_src           = "$swc_mwd\$swc_sophos_zap_reboot_PS"
$swc_sophos_zap_reboot_PS_path_script   = "$swc_repository_dir\$swc_sophos_zap_reboot_PS"

#______________________
# Sophos ZAP uninstaller (Sophos Removal)
$swc_sophos_zap_uninstaller             = "SophosZap.exe"
$swc_sophos_zap_uninstaller_src         = "$swc_mwd\$swc_sophos_zap_uninstaller"
$swc_sophos_zap_uninstaller_arg         = '--confirm'
$swc_sophos_zap_uninstaller_log         = "C:\users\admin\AppData\Local\Temp\Sophos Windows Endpoint Zap log.txt"

$swc_sophos_zap_uninstaller_reg_path    = "HKLM:\SOFTWARE\Seymour Whyte Constructions IT"
$swc_sophos_zap_uninstaller_reg_name    = "Sophos ZAP Removal"
$swc_sophos_zap_uninstaller_reg_key     = "$swc_sophos_zap_uninstaller_reg_path\$swc_sophos_zap_uninstaller_reg_name"

#______________________
# Sophos Connect v1.3.65.0614 (Newer VPN)
$swc_sophos_connect_installer           = 'SophosConnect.msi'
$swc_sophos_connect_product_code_v13    = '{618EA574-0833-4E87-8A47-101E78E1E7D7}'
$swc_sophos_connect_product_code_v14    = '{D5997C14-C31C-48AF-8243-5981B7EFC7C1}'
$swc_sophos_connect_src                 = "$swc_mwd\$swc_sophos_connect_installer"
$swc_sophos_connect_arg                 = '/q'
$swc_sophos_connect_install_path        = 'C:\Program Files (x86)\Sophos\Connect'
$swc_sophos_connect_install_path_exe    = '‪C:\Program Files (x86)\Sophos\Connect\GUI\scgui.exe'


#______________________
# Sophos SSL VPN Client v2.1 (traffic light VPN)
$swc_sophos_ssl_vpn_installer           = ''
$swc_sophos_ssl_vpn_product_code        = ''

$swc_sophos_ssl_vpn_reg_path            = "HKEY:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$swc_sophos_ssl_vpn_reg_name            = ""
$swc_sophos_ssl_vpn_reg_key             = ""

$swc_sophos_ssl_vpn_src                 = "$swc_mwd\$swc_sophos_ssl_vpn_installer"
$swc_sophos_ssl_vpn_arg                 = ''
$swc_sophos_ssl_vpn_install_path        = 'C:\Program Files (x86)\Sophos\Sophos SSL VPN Client\bin'
$swc_sophos_ssl_vpn_install_path_exe    = '‪C:\Program Files (x86)\Sophos\Sophos SSL VPN Client\bin\openvpn-gui.exe'

$swc_sophos_ssl_vpn_uninstall_path_exe  = "$swc_sophos_ssl_vpn_install_path\Uninstall.exe"
$swc_sophos_ssl_vpn_uninstall_arg       = '/S'



#______________________
# Sophos Endpoint v10.8.1.2 (old anti-virus)
$swc_sophos_endpoint_installer          = 'SophosSetup.exe'
$swc_sophos_endpoint_product_code       = '{0EA5323F-DE1B-480C-911E-7827E5EA20E9}'
$swc_sophos_endpoint_version            = "10.8.1.2"

$swc_sophos_endpoint_reg_path           = "HKEY:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$swc_sophos_endpoint_reg_name           = "{0EA5323F-DE1B-480C-911E-7827E5EA20E9}"
$swc_sophos_endpoint_reg_key            = "$swc_sophos_endpoint_reg_path\$swc_sophos_endpoint_reg_name"

$swc_sophos_endpoint_src                = "$swc_mwd\$swc_sophos_endpoint_installer"
$swc_sophos_endpoint_arg                = ''
$swc_sophos_endpoint_install_path       = 'C:\Program Files\Sophos'
$swc_sophos_endpoint_install_path_exe   = 'C:\Program Files\Sophos\Sophos UISophos UI.exe'


#______________________
# Symantec Endpoint Protection v14.2.5569.2100.105
$swc_symantec_endpoint_installer        = 'setup.exe'
$swc_symantec_endpoint_product_code     = '{CE2F0EC1-BF6B-42A6-993C-1D9655D0C9DF}'
[string]$swc_symantec_endpoint_version  = "14.2.5569.2100.105"

$swc_symantec_endpoint_reg_path         = "HKEY:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$swc_symantec_endpoint_reg_name         = '{CE2F0EC1-BF6B-42A6-993C-1D9655D0C9DF}'
$swc_symantec_endpoint_reg_key          = "$swc_symantec_endpoint_reg_path\$swc_symantec_endpoint_reg_name"

$swc_symantec_endpoint_src              = "$swc_mwd\$swc_symantec_endpoint_installer"
$swc_symantec_endpoint_arg              = '/s /v"/quiet /norestart"'
$swc_symantec_endpoint_install_path     = 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\14.2.5569.2100.105\Bin'
$swc_symantec_endpoint_install_path_exe = 'C:\Program Files (x86)\Symantec\Symantec Endpoint Protection\14.2.5569.2100.105\Bin\SymCorpUI.exe'


#______________________
# Fortinet FortiClient v6.0.9.0277 (newest VPN)
$swc_forticlient_installer              = 'FortiClientSetup_6.0.9.0277_x64.exe'
$swc_forticlient_product_code           = '{6C0A3C5E-7725-49D8-A016-B3ADCACF61C2}'

$swc_forticlient_reg_path               = 'HKEY:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$swc_forticlient_reg_name               = '{6C0A3C5E-7725-49D8-A016-B3ADCACF61C2}'
$swc_forticlient_reg_key                = "$swc_forticlient_reg_path\$swc_forticlient_reg_name"

$swc_forticlient_src                    = "$swc_mwd\$swc_forticlient_installer"
$swc_forticlient_arg                    = '/quiet /norestart'
$swc_forticlient_install_path           = 'C:\Program Files\Fortinet\FortiClient'
$swc_forticlient_install_path_exe       = 'C:\Program Files\Fortinet\FortiClient\FortiClient.exe'


#______________________
# Registry Information
$swc_reg_path                           = 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT'
$swc_reg_name                           = 'Remove Sophos Part 1'
$swc_reg_key                            = "$swc_reg_path"+"\"+"$swc_reg_name"
#______________________
# General Information
$swc_Contact                            = "Seymour Whyte Constructions IT"
$swc_DisplayName                        = "Remove-Sophos-Part-1"
$swc_DisplayVersion                     = "0"
$swc_ClientVersion                      = "0"
$swc_Publisher                          = "IT@SW"
$swc_Author                             = "Peter Milne"
$swc_AuthorContact                      = "0733863222"
$swc_ScriptVersion                      = "1.196"
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
# Log FIle Initialization
$swc_txt_initalization                  = "
///////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
||||||||||||||||||||||||||||||||||[ Start ]|||||||||||||||||||||||||||||||||||
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////

-------------------------------------------------------------------------------
IT@SW              : Uninstall of Sophos AV + VPNs & install Symantec  [Start]
-------------------------------------------------------------------------------
Started            : $swc_currentDateTime
Source             : $swc_mwd
Source Files       : $swc_sophos_connect_installer, $swc_sophos_zap_uninstaller & $swc_symantec_endpoint_installer (Symantec)
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
    Swc-Write-Log -level 0 -text "[2.3] - The directory ($swc_repository_dir) was created for the repository exe/MSI location."
}
ElseIf(Test-Path $swc_repository_dir){
    Swc-Write-Log -level 1 -text "[2.4] - The directory ($swc_repository_dir) already exists for the repository exe/MSI location."
}
Else{
    Swc-Write-Log -level 2 -text "[2.5] - The directory ($swc_repository_dir) was not created and or does not exist for the repository exe/MSI location."
}

#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------[ Execution ]-----------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------



#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#________________________ [ 0.0 - Check if part 1/2 of the script has alreay been completed. ] _______________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________


If(Test-Path -Path 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Remove Sophos Part 1'){
    # ----------------------------
    # [0.1] - Logging
    Swc-Write-Log -level 0 -text "[0.0] - {Checking} - Skipping script - since part 1 has already been completed."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[0.0] - {Checking} - Skipping script - since part 1 has already been completed."
    exit
}
ElseIf(Test-Path -Path 'HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Remove Sophos Part 2'){
    # ----------------------------
    # [0.2] - Logging
    Swc-Write-Log -level 0 -text "[0.1] - {Checking} - Skipping script - since part 2 has already been completed."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[0.1] - {Checking} - Skipping script - since part 2 has already been completed."
    exit
}
Else{
    # ----------------------------
    # [0.3] - Logging
    Swc-Write-Log -level 0 -text "[0.2] - {Checking} - Part 1 or 2 do not appear to be completed. Proceeding with part 1."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[0.2] - {Checking} - Part 1 or 2 do not appear to be completed. Proceeding with part 1."
}


#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#__________________________ [ 1.0 - Uninstall Sophos Connect VPN (newer version of VPN) ] __________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

<#
  ___
    _-_-  _/\______\\__
 _-_-__  / ,-. -|-  ,-.`-.
    _-_- `( o )----( o )-'
           `-'      `-'
           As of v1.193 (20-02-2021) this works.
           However, I'd like to add in a Get-Process | kill PID prior to uninstalling
           22-02-2021 - Still works
#>

If(Test-Path $swc_sophos_connect_install_path){ <# Check if the legacy VPN (Sophos Connect) is installed. #>
    # ----------------------------
    # [1.1] - WMI query to get info on anthing instalkled called: Sophos Connect.
    $App_SophosConnect = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Sophos Connect"}
    Start-Sleep -s 10

    # ----------------------------
    # [1.2] - If the product is detected, uninstall it.

    If($App_SophosConnect.Name -eq "Sophos Connect"){
        # ----------------------------
        # [1.3] - Logging
        Swc-Write-Log -level 0 -text "[3.0] - {Uninstall Sophos Connect VPN} - Detected legacy VPN - Attempting to uninstall"
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[3.0] - {Uninstall Sophos Connect VPN} - Detected legacy VPN - Attempting to uninstall."

        # ----------------------------
        # [1.4] - Uninstall Legacy Sophos Connect VPN
        $App_SophosConnect.Uninstall()                                                                                             <# --- MAIN PART --- #>

        # ----------------------------
        # [1.5] - Wait - I don't think I can add a -wait command to $app.uninstall()
        Start-Sleep -s 60 

        # ----------------------------
        # [1.6] - Logging
        Swc-Write-Log -level 0 -text "[3.1] - {Uninstall Sophos Connect VPN} - Uninstalled Sophos Connect VPN."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[3.1] - {Uninstall Sophos Connect VPN} - Uninstalled Sophos Connect VPN."
    }
    # ----------------------------
    # [1.7] - Check if the install location is still present & if so, delete the folder.
    #         After an uninstall sometimes the install folder is still left over.

    If(Test-Path $swc_sophos_connect_install_path){

        Swc-Write-Log -level 0 -text "[3.2] - {Uninstall Sophos Connect VPN} - The install path for Sophos Connect still exists. ($swc_sophos_connect_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[3.2] - {Uninstall Sophos Connect VPN} - The install path for Sophos Connect still exists. ($swc_sophos_connect_install_path)."

        Remove-Item -Path $swc_sophos_connect_install_path -Recurse                                              <# --- MAIN PART --- #>

        Swc-Write-Log -level 0 -text "[3.3] - {Uninstall Sophos Connect VPN} -  Deleted the Sophos Connect directory ($swc_sophos_connect_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[3.3] - {Uninstall Sophos Connect VPN} -  Deleted the Sophos Connect directory ($swc_sophos_connect_install_path)."
    }
}
ElseIf(-not(Test-Path $swc_sophos_connect_install_path)){
    # [1.4] - Logging - Check if the Sophos Connect VPN install path isn't detected.   
    Swc-Write-Log -level 1 -text "[3.4] - {Uninstall Sophos Connect VPN} - Skipping uninstall - The Sophos Connect directory was not detected ($swc_sophos_connect_install_path)"
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[3.4] - {Uninstall Sophos Connect VPN} - Skipping uninstall - The Sophos Connect directory was not detected ($swc_sophos_connect_install_path)"
}
Else{
    # [1.5] - Logging - Catch all error checking
    Swc-Write-Log -level 2 -text "[3.5] - {Uninstall Sophos Connect VPN} - Unknown error occured when attempting to detect the Sophos Connect directory ($swc_sophos_connect_install_path)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[3.5] - {Uninstall Sophos Connect VPN} - Unknown error occured when attempting to detect the Sophos Connect directory ($swc_sophos_connect_install_path)."
}

#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#________________________________ [ 2.0 - Uninstall Sophos SSL VPN (Traffic Light) ] _______________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

<# Doesn't work - leaving it out #>

#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#______________________________________ [ 3.0 - Install Forticlient v6.0.9.277 ] ___________________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

<#
            ______
            _\ _~-\___
    =  = ==(____AA____D
                \_____\___________________,-~~~~~~~`-.._
                /     o O o o o o O O o o o o o o O o  |\_
                `~-.__        ___..----..                  )
                      `---~~\___________/------------`````
                      =  ===(_________D
    22-02-2021 - Still works
#>

If( `
    ($swc_hostname -like "IT-10*") <# Checking that the hostname isn't a server #> `
    -or `
    ($swc_hostname -like "WS87*") `
    -or `
    ($swc_hostname -like "HO-DEV-WIN10-02") `
    -and `
    (-not(Test-Path $swc_forticlient_install_path_exe))              <# Checking that Forticlient VPN is not already installed.#>
  ){
    # ----------------------------
    # [3.1] - Logging
    Swc-Write-Log -level 0 -text "[5.0] - {Install Forticlient} - Installing Forticlient v6.0.9.0277."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[5.0] - {Install Forticlient} - Installing Forticlient v6.0.9.0277."    
    
    # ----------------------------
    # [3.2] - Install Forticlient
    Start-Process -FilePath $swc_forticlient_src -ArgumentList $swc_forticlient_arg -wait                <# --- MAIN PART --- #>
    Start-Sleep -s 60

    # ----------------------------
    # [3.3] - Logging
    Swc-Write-Log -level 0 -text "[5.1] - {Install Forticlient} - Installing registry keys."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[5.1] - {Install Forticlient} - Installing registry keys."

    # ----------------------------
    # [3.4] - Registry
    Swc-Create-RegKeys `
        -pm_install_path_exe "$swc_forticlient_install_path_exe" `
        -pm_reg_path         "HKLM:\SOFTWARE\Seymour Whyte Constructions IT" `
        -pm_reg_name         "FortiClient VPN" `
        -pm_reg_key          "HKLM:\SOFTWARE\Seymour Whyte Constructions IT\FortiClient VPN" `
        -pm_Author           "Peter Milne" `
        -pm_AuthorContact    "0733863222" `
        -pm_Contact          "Seymour Whyte Constructions IT" `
        -pm_DisplayName      "FortiClient VPN" `
        -pm_currentDate      "$swc_currentDate" `
        -pm_Publisher        "IT@SW" `
        -pm_ScriptVersion    "1.196" `
        -pm_DisplayVersion   "$swc_symantec_endpoint_version" `
        -pm_Version          "$swc_symantec_endpoint_version"
    
    # ----------------------------
    # [3.5] - Checking + logging   
    <#
    ******************************************************
        Check if the the application was installed to the system.
           |\---/|
           | ,_, |
            \_`_/-..----.
         ___/ `   ' ,""+ \  
        (__...'   __\    |`.___.';
          (_,...'(_,.`__)/'.....+
    ******************************************************
    #>

    If(Test-Path "$swc_forticlient_install_path_exe"){
        Swc-Write-Log -level 0 -text "[5.2] - {Install Forticlient} - The application appears to be installed correctly - (.exe) detected in ($swc_forticlient_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[5.2] - {Install Forticlient} - The application appears to be installed correctly - (.exe) detected in ($swc_forticlient_install_path)."
    }
    ElseIf(-not(Test-Path "$swc_forticlient_install_path_exe")){
        Swc-Write-Log -level 1 -text "[5.3] - {Install Forticlient} - The application potentially did not install correctly, (.exe) not detected in ($swc_forticlient_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                            -Message "[5.3] - {Install Forticlient} - The application potentially did not install correctly, (.exe) not detected in ($swc_forticlient_install_path)."
    }
    Else{
        Swc-Write-Log -level 2 -text "[5.4] - {Install Forticlient} - Unknown error occured when attempting to install/detect the (.exe) in ($swc_forticlient_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                            -Message "[5.4] - {Install Forticlient} - Unknown error occured when attempting to install/detect the (.exe) in ($swc_forticlient_install_path)."
    }

}
ElseIf(Test-Path $swc_forticlient_install_path_exe){
    # ----------------------------
    # [3.6] - If the Forticlient is already installed, just skip it.
    Swc-Write-Log -level 1 -text "[5.5] - {Install Forticlient} - Skipping install - The Forticlient was detected in ($swc_forticlient_install_path)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[5.5] - {Install Forticlient} - Skipping install - The Forticlient was detected in ($swc_forticlient_install_path)."
}
Else{
    # ----------------------------
    # [3.7] - Logging - Catch all error checking
    Swc-Write-Log -level 0 -text "[5.6] - {Install Forticlient} - Unknown error attempting to detect/install Forticlient v6.0.9.0277."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[5.6] - {Install Forticlient} - Unknown error attempting to detect/install Forticlient v6.0.9.0277."
}

#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#__________________________________ [ 4.0 - Install Symantec Endpoint Protection ] _________________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

<#
      )  (
     (   ) )
      ) ( (
    _______)_
 .-'---------|  
( C|/\/\/\/\/|
 '-./\/\/\/\/|
   '_________'
    '-------'
    22-02-2021 - Still works
#>

If(-not(Test-Path $swc_symantec_endpoint_install_path_exe)){ <# If Symantec isn't installed, then install it. #>
    # ----------------------------
    # [4.1] - Logging 
    Swc-Write-Log -level 0 -text '[6.0] - {Install Symantec} - Symantec (.exe) not detected. Starting the Symantec installer (exe) with /s /v"/quiet /norestart"'
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message '[6.0] - {Install Symantec} - Symantec (.exe) not detected. Starting the Symantec installer (exe) with /s /v"/quiet /norestart"'

    # ----------------------------
    # [4.2] - Install Symantec Endpoint Anti-virus
    Start-Process -FilePath $swc_symantec_endpoint_src -ArgumentList $swc_symantec_endpoint_arg  -Wait                              <# --- MAIN PART --- #>
    Start-Sleep -s 60

    # ----------------------------
    # [4.3] - Logging
    Swc-Write-Log -level 0 -text '[6.1] - {Install Symantec} - Attempting to create the registry keys.'
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message '[6.1] - {Install Symantec} - Attempting to create the registry keys.'

    # ----------------------------
    # [4.4] - Create Registry keys (using function above)
    Swc-Create-RegKeys `
        -pm_install_path_exe "$swc_symantec_endpoint_install_path_exe" `
        -pm_reg_path         "HKLM:\SOFTWARE\Seymour Whyte Constructions IT" `
        -pm_reg_name         "Symantec Endpoint" `
        -pm_reg_key          "HKLM:\SOFTWARE\Seymour Whyte Constructions IT\Symantec Endpoint" `
        -pm_Author           "Peter Milne" `
        -pm_AuthorContact    "0733863222" `
        -pm_Contact          "Seymour Whyte Constructions IT" `
        -pm_DisplayName      "Symantec Endpoint" `
        -pm_currentDate      "$swc_currentDate" `
        -pm_Publisher        "IT@SW" `
        -pm_ScriptVersion    "1.196" `
        -pm_DisplayVersion   "$swc_symantec_endpoint_version" `
        -pm_Version          "$swc_symantec_endpoint_version"
    
    # ----------------------------
    # [4.5] - Checking + logging
    <#
    ******************************************************
        Check if the the application was installed to the system.
           |\---/|
           | ,_, |
            \_`_/-..----.
         ___/ `   ' ,""+ \  
        (__...'   __\    |`.___.';
          (_,...'(_,.`__)/'.....+
    ******************************************************
    #>

    If(Test-Path "$swc_symantec_endpoint_install_path_exe"){
        Swc-Write-Log -level 0 -text "[6.2] - {Install Symantec} - The application appears to be installed correctly - (.exe) detected in ($swc_symantec_endpoint_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[6.2] - {Install Symantec} - The application appears to be installed correctly - (.exe) detected in ($swc_symantec_endpoint_install_path)."
    }
    ElseIf(-not(Test-Path "$swc_symantec_endpoint_install_path_exe")){
        Swc-Write-Log -level 1 -text "[6.3] - {Install Symantec} - The application potentially did not install correctly, (.exe) not detected in ($swc_symantec_endpoint_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                            -Message "[6.3] - {Install Symantec} - The application potentially did not install correctly, (.exe) not detected in ($swc_symantec_endpoint_install_path)."
    }
    Else{
        Swc-Write-Log -level 2 -text "[6.4] - {Install Symantec} - Unknown error occured when attempting to install/detect the (.exe) in ($swc_symantec_endpoint_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                            -Message "[6.4] - {Install Symantec} - Unknown error occured when attempting to install/detect the (.exe) in ($swc_symantec_endpoint_install_path)."
    }
}
ElseIf(Test-Path $swc_symantec_endpoint_install_path_exe){
    # ----------------------------
    # [4.6] - Logging - If Symantec is already installed, just skip it.
    Swc-Write-Log -level 1 -text "[6.5] - {Install Symantec} - Skipping Install - The application (Symantec) appears to already be installed to ($swc_symantec_endpoint_install_path)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[6.5] - {Install Symantec} - Skipping Install - The application (Symantec) appears to already be installed to ($swc_symantec_endpoint_install_path)."
}
Else{
    # ----------------------------
    # [4.7] - Catch all error checking
    Swc-Write-Log -level 2 -text "[6.5] - {Install Symantec} - Unknown error occured when attempting to detect/install Symantec in ($swc_symantec_endpoint_install_path)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[6.5] - {Install Symantec} - Unknown error occured when attempting to detect/install Symantec in ($swc_symantec_endpoint_install_path)."
}

#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#__________________________________ [ 5.0 - Uninstall Sophos Endpoint Protection ] _________________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

<#
---------------+---------------
          ___ /^^[___              _
         /|^+----+   |#___________//
       ( -+ |____|    ______-----+/
        ==_________--'            \
          ~_|___|__

Source: 
- https://support.sophos.com/support/s/article/KB-000038989?language=en_US#Pre
- https://missionimpossiblecode.io/post/continue-your-automation-to-run-once-after-restarting-a-headless-windows-system/
- https://www.codeproject.com/Articles/223002/Reboot-and-Resume-PowerShell-Script#:~:text=Restarting%20a%20computer%20from%20PowerShell,Windows%5CCurrentVersion%5CRun%22.
- https://devblogs.microsoft.com/scripting/use-powershell-to-create-scheduled-tasks-folders/

[1] - Open a Command Prompt with admin privilege.
[2] - Change the path to the current location of SophosZap.exe.
[3] - Run the command SophosZap --confirm
[4] - Once SophosZap has completed its first steps, you’ll see a prompt to Reboot and re-execute.
[5] - Restart the computer.
[6] - Open a Command Prompt with admin privilege.
[7] - Run the command SophosZap --confirm one more time.
[8] - Restart the computer.
[9] - Done
#>


<#
******************************************************
    Copy the uninstall Sophos (post reboot) script to to C:\SWC-IT\Installers.
******************************************************
#>

Copy-Item -Path $swc_sophos_zap_reboot_PS_src   -Destination $swc_repository_dir -Force
Copy-Item -Path $swc_sophos_zap_uninstaller_src -Destination $swc_repository_dir -Force

Swc-Write-Log -level 0 -text "[7.0] - {Copy PS Script} - Copying the source files to the repository ($swc_repository_dir) directory"
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[7.0] - {Copy PS Script} - Copying the source files to the repository ($swc_repository_dir) directory"

<#
******************************************************
    Checking if the exe was actually copied to the temp location
       |\---/|
       | ,_, |
        \_`_/-..----.
     ___/ `   ' ,""+ \  
    (__...'   __\    |`.___.';
      (_,...'(_,.`__)/'.....+
******************************************************
#>

If(Test-Path "$swc_sophos_zap_reboot_PS_path_script"){
    Swc-Write-Log -level 0 -text "[7.1] - {Copy PS Script} - The uninstall script appears to be copied correctly - (.ps1) detected in ($swc_repository_dir)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[7.1] - {Copy PS Script} - The uninstall script appears to be copied correctly - (.ps1) detected in ($swc_repository_dir)."
}
ElseIf(-not(Test-Path "$swc_install_path_exe")){
    Swc-Write-Log -level 1 -text "[7.2] - {Copy PS Script} - The uninstall script potentially did not copy correctly, no (.ps1) detected in ($swc_repository_dir)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[7.2] - {Copy PS Script} - The uninstall script potentially did not copy correctly, no (.ps1) detected in ($swc_repository_dir)."
}
Else{
    Swc-Write-Log -level 2 -text "[5.3] - {Copy PS Script} - Unknown error occured when attempting to copy the (.ps1) in ($swc_repository_dir)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[7.3] - {Copy PS Script} - Unknown error occured when attempting to copy the (.ps1) in ($swc_repository_dir)."
}


<#
******************************************************
    Code to write out scheduled task script that self-deletes
******************************************************
#>

<#
******************************************************

    This code schedules the above script
    - https://docs.microsoft.com/en-us/windows/win32/taskschd/schtasks
    - https://devblogs.microsoft.com/scripting/use-powershell-to-create-scheduled-tasks-folders/

    /F
        A value that forcefully deletes the task and suppresses warnings if the specified task is running.

    /TN taskname
        A value that specifies a name which uniquely identifies the scheduled task.

    /RU username
        A value that specifies the user context under which the task runs. For the system account, 
        valid values are "", "NT AUTHORITY\SYSTEM", or "SYSTEM". For Task Scheduler 2.0 tasks,
        "NT AUTHORITY\LOCALSERVICE", and "NT AUTHORITY\NETWORKSERVICE" are also valid values.

    /SC schedule
        A value that specifies the schedule frequency. Valid values are: MINUTE, HOURLY, DAILY, 
        WEEKLY, MONTHLY, ONCE, ONLOGON, ONIDLE, and ONEVENT.

    /TR taskrun
        A value that specifies the path and file name of the task to be run at the scheduled time.
        For example: C:\Windows\System32\calc.exe.

Deleteing a task
schtasks /Delete 
[/S system [/U username [/P [password]]]]
[/TN taskname] [/F]

schtasks.exe /create /f /tn HeadlessRestartTask /ru SYSTEM /sc ONSTART /tr "powershell.exe -file $swc_sophos_zap_reboot_PS_path_script"
Write-Host "`"$swc_sophos_zap_reboot_PS_path_script`" is scheduled to run once after reboot."
powershell –ExecutionPolicy Bypass -file "uninstall-Sophos-Endpoint_afterReboot_v1.0.ps1"


******************************************************
#>
# [5.01] - look up any scheduled tasks with the name SWC
Get-ScheduledTask -TaskName SWC* | FL > 'C:\SWC-IT\logs\Log-SCCM_GetScheduleTask_zap_pre_creation_of_schedule.log'

# ----------------------------
# [5.02] - Creates a scheduled task to run once (the powershell script that runs SophosZap.exe --confirm from C:\swc-it\installers).
schtasks.exe /create /F /TN SWC_Sophos_Removal_Reboot /RU SYSTEM /SC ONSTART /TR "powershell.exe -file $swc_sophos_zap_reboot_PS_path_script"

# ----------------------------
# [5.03] - PowerShell to schedule the above script at $swc_sophos_zap_reboot_PS_path_script
$swc_TaskTrigger = (New-ScheduledTaskTrigger -atstartup)
$swc_TaskAction  = New-ScheduledTaskAction -Execute Powershell.exe -argument "-ExecutionPolicy Bypass -File $swc_sophos_zap_reboot_PS_path_script"
$swc_TaskUserID  = New-ScheduledTaskPrincipal -UserId System -RunLevel Highest -LogonType ServiceAccount

Register-ScheduledTask `
    -Force `
    -TaskName SWC_Sophos_Removal_Reboot `
    -Action    $swc_TaskAction `
    -Principal $swc_TaskUserID `
    -Trigger   $swc_TaskTrigger

# ----------------------------
# [5.04] - look up any scheduled tasks with the name SWC
Get-ScheduledTask -TaskName SWC* | FL > 'C:\SWC-IT\logs\Log-SCCM_GetScheduleTask_zap_post_creation_of_schedule.log'


<#
******************************************************
    Start the Sophos Zap uninstaller [1st run]
******************************************************
#>

# ----------------------------
# [5.1] - Not applying this installer for Windows Server - only for Windows 10 machines.
Swc-Write-Log -level 0 -text '[7.4] - {Uninstall Sophos} - Checking hostname and if Symantec is already installed.'
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message '[7.4] - {Uninstall Sophos} - Checking hostname and if Symantec is already installed.'

If( `
    ($swc_hostname -like "IT-10*") -or ($swc_hostname -like "WS87*") -or ($swc_hostname -like "HO-DEV-WIN10-02") <# Checking that the hostname isn't a server #> `
    -and `
    (Test-Path $swc_symantec_endpoint_install_path_exe) <# Checking that Symantec is installed. #>
  ){
    # ----------------------------
    # [5.2] - Logging
    Swc-Write-Log -level 0 -text '[7.5] - {Uninstall Sophos} - Hostname matches IT-10* or WS87* - proceeding with Sophos uninstall.'
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message '[7.5] - {Uninstall Sophos} - Hostname matches IT-10* or WS87* - proceeding with Sophos uninstall.'
        
    # ----------------------------
    # [5.3] - Check if the sohpos AV is installed.
    If(Test-Path 'C:\Program Files\Sophos\Sophos UI\Sophos UI.exe'){
        # ----------------------------
        # [5.4] - Stop the background Sophos services.
        Swc-Write-Log -level 0 -text "[7.6] - {Uninstall Sophos} - Stopping Sophos core services (SAVService & Sophos AutoUpdate Service)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[7.6] - {Uninstall Sophos} - Stopping Sophos core services (SAVService & Sophos AutoUpdate Service)."
        
        # ----------------------------
        # [5.5] - Stopping Sophos services
        net stop "SAVService"                   <# Sophos Anti-Virus service #>
        Start-Sleep -s 30

        net stop "Sophos AutoUpdate Service"    <# Sophos AutoUpdate service #>                                                              <# --- MAIN PART --- #>
        Start-Sleep -s 30

        # ----------------------------
        # [5.6] - Logging
        Swc-Write-Log -level 0 -text "[7.7] - {Uninstall Sophos} - Stopped the background Sophos services."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[7.7] - {Uninstall Sophos} - Stopped the background Sophos services."

        # ----------------------------
        # [5.6] - Uninstall Sophos AV (only if it's detected)
        Swc-Write-Log -level 0 -text "[7.8] - {Uninstall Sophos} - Starting Sophos ZAP uninstaller."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[7.8] - {Uninstall Sophos} - Starting Sophos ZAP uninstaller"
        
        # ----------------------------
        # [5.7] - Uninstalling Sophos Endpoint (using Sophos Zap).
        Start-Process -FilePath $swc_sophos_zap_uninstaller_src -ArgumentList $swc_sophos_zap_uninstaller_arg -wait                         <# --- MAIN PART --- #>
        Start-Sleep -s 60

        # ----------------------------
        # [5.8] - Logging
        Swc-Write-Log -level 0 -text "[7.9] - {Uninstall Sophos} - [1/2] Run of SophosZap.exe - Uninstalled Sophos Endpoint Protection using Sophos ZAP."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[7.9] - {Uninstall Sophos} - [1/2] Run of SophosZap.exe - Uninstalled Sophos Endpoint Protection using Sophos ZAP."
    }

    <#
    ******************************************************
        Check if the the application was uninstalled from the system.
           |\---/|
           | ,_, |
            \_`_/-..----.
         ___/ `   ' ,""+ \  
        (__...'   __\    |`.___.';
          (_,...'(_,.`__)/'.....+
    ******************************************************
    #>

    If(-not(Test-Path "$swc_sophos_endpoint_install_path_exe")){
        Swc-Write-Log -level 0 -text "[7.12] - {Uninstall Sophos} - The application appears to be uninstalled correctly - (.exe) not detected in ($swc_sophos_endpoint_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                            -Message "[7.12] - {Uninstall Sophos} - The application appears to be uninstalled correctly - (.exe) not detected in ($swc_sophos_endpoint_install_path)."
    }
    ElseIf(Test-Path "$swc_sophos_endpoint_install_path_exe"){
        Swc-Write-Log -level 1 -text "[7.13] - {Uninstall Sophos} - The application potentially did not uninstall correctly, (.exe) detected in ($swc_sophos_endpoint_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                            -Message "[7.13] - {Uninstall Sophos} - The application potentially did not uninstall correctly, (.exe) detected in ($swc_sophos_endpoint_install_path)."
    }
    Else{
        Swc-Write-Log -level 2 -text "[7.14] - Unknown error occured when attempting to install/detect the (.exe) in ($swc_sophos_endpoint_install_path)."
        Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                            -Message "[7.14] - Unknown error occured when attempting to install/detect the (.exe) in ($swc_sophos_endpoint_install_path)."
    }
}
Else{
    Swc-Write-Log -level 0 -text "[7.15] - {Uninstall Sophos} - Aborting install - Hostname didn't match IT-10* or WS87* - it might be a server."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[7.15] - {Uninstall Sophos} - Aborting install - Hostname didn't match IT-10* or WS87* - it might be a server."
}

#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________
#___________________________________________________________________________________________________________________

#----------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------[ Registry ]----------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

<#
******************************************************
    Check/Create the registry key
    Just checking that the application (.exe) is present & then creating the reg keys.
                       O  o
              _\_   o
    >('>   \\/  o\ .
           //\___=
              ''
******************************************************
#>

If(Test-Path "$swc_symantec_endpoint_install_path_exe"){
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
    New-ItemProperty -Path "$swc_reg_key"   -Name "Zap Run Once"   -Value "yes"                 -PropertyType "String" -Force

    Swc-Write-Log -level 0 -text "[8.0] - {Registry} - RegKeys created because the application (.exe) was detected."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[8.0] - {Registry} - RegKeys created because the application (.exe) was detected."
}
ElseIf(-not(Test-Path $swc_symantec_endpoint_install_path_exe)){
    Swc-Write-Log -level 1 -text "[8.1] - {Registry} - RegKeys not created because the application (.exe) was not detected."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[8.1] - {Registry} - RegKeys not created because the application (.exe) was not detected."
}
Else{
    Swc-Write-Log -level 2 -text "[8.2] - {Registry} - Unknown error attempting to detect/create the RegKeys"
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[8.2] - {Registry} - Unknown error attempting to detect/create the RegKeys"
}

<#
******************************************************
	Checking if the reg files did get created.
******************************************************
#>

If(Test-Path -Path "$swc_reg_key"){
    Swc-Write-Log -level 0 -text "[9.0] - {Registry} - Registry keys appear to have been created correctly ($swc_reg_key)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                        -Message "[9.0] - {Registry} - Registry keys appear to have been created correctly ($swc_reg_key)."
}
ElseIf(-not(Test-Path -Path "$swc_reg_key")){
    Swc-Write-Log -level 2 -text "[9.1] - {Registry} - Registry keys do not appear to be present ($swc_reg_key)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Warning -eventID "20" `
                        -Message "[9.1] - {Registry} - Registry keys do not appear to be present ($swc_reg_key)."
}
Else{
    Swc-Write-Log -level 2 -text "[9.2] - {Registry} - Registry keys do not appear to have been created and or do not exist in ($swc_reg_key)."
    Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Error -eventID "30" `
                        -Message "[9.2] - {Registry} - Registry keys do not appear to have been created and or do not exist in ($swc_reg_key)."
}

#----------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------[ Restart ]------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

msg.exe * /TIME:600 'Hello,
We are changing Anti-Virus software and need you to restart your computer some time today.
Please ensure you save any open files prior to restarting.
Thank you
----------------
Seymour Whyte IT
07 3386 3222
IT.ServiceDesk@seymourwhyte.com.au'

# not using the restart - it's too aggressive for staff.

<#
Swc-Write-Log -level 1 -text "[10.0] - {Restart} - This computer will restart in 5 minutes."
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[10.0] - {Restart} - This computer will restart in 5 minutes."
#>

# shutdown -r -t 28800 /c "Restart [1/2] - This computer will restart in 8 hours, please save your work."


#----------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------[ End ]--------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------

Swc-Write-Log -level 1 -text "[11.0] - {End} - End of install script."
Write-EventLog -log $swc_EV_LogName -source $swc_EV_Source -EntryType Information -eventID "10" `
                    -Message "[11.0] - {End} - End of install script."

Write-Output `
"
///////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
|||||||||||||||||||||||||||||||||||[ End ]||||||||||||||||||||||||||||||||||||
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////

-------------------------------------------------------------------------------
IT@SW                 : Uninstall of Sophos AV + VPNs & install Symantec [END]
-------------------------------------------------------------------------------
Number of Errors      : $numberOfErrors
Install Location      : $swc_sophos_endpoint_install_path
Install Location      : $swc_sophos_connect_install_path
Install Location      : $swc_sophos_ssl_vpn_install_path
Install Location      : $swc_symantec_endpoint_install_path
Registry Key          : $swc_reg_key
------------------------------------------------------------------------------

///////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
||||||||||||||||||||||||||||||||||[ Extra ]|||||||||||||||||||||||||||||||||||
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////

$swc_currentDateTime - [THE END] ... Good job, your script kind of worked .... I guess?
Therefore do not worry about tomorrow. For tomorrow will worry about itself.
Each day has enough trouble of its own.
------------------------------------------------------------------------------
   _          _          _          _          _
 >(')____,  >(')____,  >(')____,  >(')____,  >(') ___,
   (` =~~/    (` =~~/    (` =~~/    (` =~~/    (` =~~/
~^~^`---'~^~^~^`---'~^~^~^`---'~^~^~^`---'~^~^~^`---'~^~^~
               
[JOKE OF THE DAY]
- Knock, knock
- Who’s there?
- Yah
- Yah who?
- No, I prefer google.         
   _____                                                _       __ __            __      
  / ___/ ___   __  __ ____ ___   ____   __  __ _____   | |     / // /_   __  __ / /_ ___ 
  \__ \ / _ \ / / / // __ `__ \ / __ \ / / / // ___/   | | /| / // __ \ / / / // __// _ \
 ___/ //  __// /_/ // / / / / // /_/ // /_/ // /       | |/ |/ // / / // /_/ // /_ /  __/
/____/ \___/ \__, //_/ /_/ /_/ \____/ \__,_//_/        |__/|__//_/ /_/ \__, / \__/ \___/ 
            /____/                                                    /____/             

///////////////////////////////////////\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\///////////////////////////////////////          
" >> $swc_logfile

#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------