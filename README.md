# Create-CBWinLocalMirror.ps1
PowerShell script to automate the Carbon Black Local Mirror Server configuration for Windows.

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
