#########################
# Synopsis & Parameters #
#########################

<#
  .SYNOPSIS
  Configures the Carbon Black Local Mirror server for Windows.

  .DESCRIPTION
  Configures the Carbon Black Local Mirror server for Windows.

  THIS SCRIPT IS PROVIDED "AS IS", USE IS AT YOUR OWN RISK, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS/CREATORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THIS SCRIPT OR THE USE OR OTHER DEALINGS IN THIS
  SCRIPT.

  .PARAMETER CBUpdatesURL
  Specifies the Carbon Black external URL from which the Carbon Black Local Mirror server receives the updates.

  .PARAMETER CBUpdatesFolderName
  Specifies the name for the folder in which the Carbon Black Local Mirror server files are placed.

  .PARAMETER CBUpdatesScheduledTaskName
  Specifies the name for the scheduled task that is used for receiving the updates.

  .PARAMETER CBUpdatesIntervalMinutes
  Specifies the updates interval in minutes.

  .PARAMETER CBUseSSL
  Specifies if updates must be received using SSL.

  .PARAMETER CBUpdatesWebSiteName
  Specifies the name for the website in IIS.

  .PARAMETER CBZipFile
  Specifies the name for the ZIP file that contains the Carbon Black Local Mirror server files.

  .PARAMETER HostNameFQDN
  Specifies the fully qualified domain name (FQDN) used for the IIS website.

  .PARAMETER InstallIIS
  Specifies if IIS must be installed.

  .INPUTS
  None. You cannot pipe objects to Create-CBWinLocalMirror.ps1.

  .OUTPUTS
  None. Create-CBWinLocalMirror.ps1 generates progress output.

  .EXAMPLE
  PS> .\Create-CBWinLocalMirror.ps1

  .EXAMPLE
  PS> .\Create-CBWinLocalMirror.ps1 -CBUpdatesURL updates2.cdc.carbonblack.io -CBUpdatesFolderName CB_SignatureUpdates -CBUpdatesScheduledTaskName CB_SignatureUpdates -CBUpdatesIntervalMinutes 60 -CBUseSSL $False -CBUpdatesWebSiteName CB_SignatureUpdates -CBZipFile cbdefense_mirror_win_x64_v3.0.zip -HostNameFQDN domain.lab.local -InstallIIS $True
#>

param (
    [Parameter(Mandatory=$true)]
    [bool]$AcceptEULA,
    [string]$CBUpdatesURL,
    [string]$CBUpdatesFolderName,
    [string]$CBUpdatesScheduledTaskName,
    [int]$CBUpdatesIntervalMinutes,
    [bool]$CBUseSSL,
    [string]$CBUpdatesWebSiteName,
    [string]$CBZipFile,
    [string]$HostNameFQDN,
    [bool]$InstallIIS
)


#############
# Variables #
#############

$varAcceptEULA = $AcceptEULA
$varCBUpdatesURL = $CBUpdatesURL
$varCBUpdatesFolderName = $CBUpdatesFolderName
$varCBUpdatesScheduledTaskName = $CBUpdatesScheduledTaskName
$varCBUpdatesIntervalMinutes = $CBUpdatesIntervalMinutes
$varCBUseSSL = $CBUseSSL
$varCBUpdatesWebSiteName = $CBUpdatesWebSiteName
$varCBZipFile = $CBZipFile
$varHostNameFQDN = $HostNameFQDN
$varInstallIIS = $InstallIIS
$varScriptRootFolder = $PSScriptRoot


########
# EULA #
########

Clear

If ($varAcceptEULA -ne $True) {
    Write-Host "`nThe EULA has not been accepted.`n" -ForegroundColor Red
    Break
}


###################
# Check elevation #
###################

Write-Host "Checking for elevated permissions... " -NoNewline
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "[NOT OK]`n" -ForegroundColor Red
    Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again.`n`n"
    Break
} else {
    Write-Host "[OK]" -ForegroundColor Green
}


###################################################
# Check connection to updates2.cdc.carbonblack.io #
###################################################

Write-Host "Checking the connection to Carbon Black Updates service ($CBUpdatesURL)... " -NoNewline

Try {
    $out = (Test-NetConnection -Port 80 -ComputerName $CBUpdatesURL -WarningAction SilentlyContinue).TcpTestSucceeded
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

If ($out -eq $False) {
	Write-Host "[WARNING]" -ForegroundColor Yellow
    Write-Host "`nThe connection to Carbon Black Updates service failed. Make sure this system has proxy/firewall access to $varCBUpdatesURL." -ForegroundColor Yellow
} Else {
    Write-Host "[OK]" -ForegroundColor Green
}


#########################################
# Check if IIS is installed and running #
#########################################

Write-Host "Checking the install state for Web Server (IIS)... " -NoNewline

Try {
    $out = (Get-WindowsFeature -Name Web-Common-Http).InstallState
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

Try {
    $out2 = (Get-WindowsFeature -Name Web-Static-Content).InstallState
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

If ($out -ne "Installed" -or $out2 -ne "Installed") {
    Write-Host "[NOT OK]" -ForegroundColor Red
    Write-Host "`nWeb Server (IIS) must be installed.`n" -ForegroundColor Red
    If ($varInstallIIS -eq $True) {
        Write-Host "InstallIIS = True`n`n--> Installing Web Server (IIS)... " -NoNewline
        Try {
            $out = Add-WindowsFeature -Name Web-Dir-Browsing -IncludeAllSubFeature -IncludeManagementTools
        } Catch {
            Write-Error "An error occurred: $Error"
			Break
        }

        Try {
            $out = Add-WindowsFeature -Name Web-Static-Content -IncludeAllSubFeature -IncludeManagementTools
        } Catch {
            Write-Error "An error occurred: $Error"
			Break
        }

        Write-Host "[OK]" -ForegroundColor Green
    } Else {
        Break
    }
} Else {
    Write-Host "[OK]" -ForegroundColor Green
}


#######################################
# Create AV Signatures Updates folder #
#######################################

Write-Host "Checking existence Carbon Black Signatures Updates folder... " -NoNewline

$varIISFolder = (Get-WebFilePath -PSPath "IIS:\Sites\Default Web Site").FullName
If (!(Test-Path -Path "$varIISFolder\$varCBUpdatesFolderName")) {
    Write-Host "[CREATING --> " -ForegroundColor Green -NoNewline
    
    Try {
        $out = New-Item -Path "$varIISFolder" -Name "$varCBUpdatesFolderName" -ItemType "Directory" -Force
    } Catch {
        Write-Error "An error occurred: $Error"
		Break
    }
    
    Write-Host "OK]" -ForegroundColor Green
} Else {
    Write-Host "[OK]" -ForegroundColor Green
}


##################
# Unzip ZIP file #
##################

Write-Host "Extracting Mirror Server files... " -NoNewline

Try {
    $out = Expand-Archive -Path "$varScriptRootFolder\$varCBZipFile" -DestinationPath "$varIISFolder\$varCBUpdatesFolderName" -Force
    $varTempFolder = (Get-Item -Path "$varIISFolder\$varCBUpdatesFolderName\cb*").FullName
    Copy-Item "$varTempFolder\*" -Destination "$varIISFolder\$varCBUpdatesFolderName" -Force
    Remove-Item -Path "$varTempFolder" -Recurse -Force
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

Write-Host "[OK]" -ForegroundColor Green


#######################################################################
# Configure outdir variable in do_update.bat and/or do_update_ssl.bat #
#######################################################################

Write-Host "Updating do_update.bat & do_update_ssl.bat... " -NoNewline

Try {
    $out = (Get-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update.bat") -replace "%1","$varIISFolder\$varCBUpdatesFolderName" | Set-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update.bat" -Force
    $out = (Get-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update.bat") -replace "upd.exe","$varIISFolder\$varCBUpdatesFolderName\upd.exe" | Set-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update.bat" -Force
    $out = (Get-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update_ssl.bat") -replace "%1","$varIISFolder\$varCBUpdatesFolderName" | Set-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update_ssl.bat" -Force
    $out = (Get-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update_ssl.bat") -replace "upd.exe","$varIISFolder\$varCBUpdatesFolderName\upd.exe" | Set-Content -Path "$varIISFolder\$varCBUpdatesFolderName\do_update_ssl.bat" -Force
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

Write-Host "[OK]" -ForegroundColor Green


##############################################
# Execute do_update.bat or do_update_ssl.bat #
##############################################

Set-Location -Path "$varIISFolder\$varCBUpdatesFolderName"
If ($varCBUseSSL -eq $False) {
    Write-Host "Downloading Carbon Black Signature Updates, please wait... " -NoNewline
    $out = & "$varIISFolder\$varCBUpdatesFolderName\do_update.bat"
    Write-Host "[OK]" -ForegroundColor Green
} Else {
    Write-Host "Downloading Carbon Black Signature Updates, please wait... " -NoNewline
    $out = & "$varIISFolder\$varCBUpdatesFolderName\do_update_ssl.bat"
    Write-Host "[OK]" -ForegroundColor Green
}


#########################
# Create scheduled task #
#########################

Write-Host "Creating the Carbon Black Signature Updates scheduled task... " -NoNewline
If ($varCBUseSSL -eq $False) {
    Try {
        $varTaskAction = New-ScheduledTaskAction -Execute "$varIISFolder\$varCBUpdatesFolderName\do_update.bat" -WorkingDirectory "$varIISFolder\$varCBUpdatesFolderName"
    } Catch {
        Write-Error "An error occurred: $Error"
		Break
    }
} Else {
    Try {
        $varTaskAction = New-ScheduledTaskAction -Execute "$varIISFolder\$varCBUpdatesFolderName\do_update_ssl.bat" -WorkingDirectory "$varIISFolder\$varCBUpdatesFolderName"
    } Catch {
        Write-Error "An error occurred: $Error"
		Break
    }
}

Try {
    $varTaskTrigger = New-ScheduledTaskTrigger -Once -At 12pm  -RepetitionInterval (New-TimeSpan -Minutes $varCBUpdatesIntervalMinutes) #-RepetitionDuration ([timespan]::MaxValue)
    $varTaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable
    $varTask = New-ScheduledTask -Action $varTaskAction -Trigger $varTaskTrigger -Settings $varTaskSettings
    $out = Register-ScheduledTask -TaskName "$varCBUpdatesScheduledTaskName" -InputObject $varTask -User "NT AUTHORITY\SYSTEM"
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

Write-Host "[OK]" -ForegroundColor Green


######################
# Create IIS Website #
######################

Write-Host "Creating the Carbon Black Signature Updates website... " -NoNewline
Try {
    $out = New-WebSite -Name "$varCBUpdatesWebSiteName" -Port 80 -HostHeader $varHostNameFQDN -PhysicalPath "$varIISFolder\$varCBUpdatesFolderName"
    $out = Set-WebConfigurationProperty -Filter /system.webServer/directoryBrowse -Name enabled -PSPath "IIS:\Sites\$varCBUpdatesWebSiteName" -Value $True
    $varFileExtension = ".idx"
    $varMimeType = "text/plain"
    $out = Add-WebConfigurationProperty //staticContent -Name collection -PSPath "IIS:\Sites\$varCBUpdatesWebSiteName" -value @{fileExtension=$varFileExtension; mimeType=$varMimeType}
    $out = & iisreset
} Catch {
    Write-Error "An error occurred: $Error"
	Break
}

Write-Host "[OK - FINISHED]" -ForegroundColor Green
