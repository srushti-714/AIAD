Start-Transcript -Path C:\WindowsAzure\Logs\CustomscriptLogs.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

function Disable-InternetExplorerESC 
{
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
Disable-InternetExplorerESC

cd HKLM:\
New-Item -Path HKLM:\System\CurrentControlSet\Control\Network -Name NewNetworkWindowOff -Force 
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

#Enable File Download in IE
Function Enable-IEFileDownload
       {
           $HKLM = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
           $HKCU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3"
           Set-ItemProperty -Path $HKLM -Name "1803" -Value 0
           Set-ItemProperty -Path $HKCU -Name "1803" -Value 0
		   Set-ItemProperty -Path $HKLM -Name "1604" -Value 0
           Set-ItemProperty -Path $HKCU -Name "1604" -Value 0
           Set-ItemProperty -Path $HKLM -Name "2600" -Value 0
           Set-ItemProperty -Path $HKCU -Name "2600" -Value 0
       }  
Enable-IEFileDownload

#Disable server manager startup   
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose

#Install AZ-module
Install-PackageProvider NuGet -Force
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module Az -Repository PSGallery -Force -AllowClobber

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/srushti-714/AIAD/master/aiadmodule.psm1" -OutFile "C:\aiadmodule.psm1"


 $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("http://dl.delivery.mp.microsoft.com/filestreamingservice/files/6d88cf6b-a578-468f-9ef9-2fea92f7e733/MicrosoftEdgeEnterpriseX64.msi","C:\Packages\MicrosoftEdgeBetaEnterpriseX64.msi")
        sleep 5
        
	    Start-Process msiexec.exe -Wait '/I C:\Packages\MicrosoftEdgeBetaEnterpriseX64.msi /qn' -Verbose 
