$ZabbixLocalPath = "C:\Windows\zabbix\"
If(!(test-path $ZabbixLocalPath))
{
      New-Item -ItemType Directory -Force -Path $ZabbixLocalPath
}

$ZabbixLocalPath = "C:\temp\"
If(!(test-path $ZabbixLocalPath))
{
      New-Item -ItemType Directory -Force -Path $ZabbixLocalPath
}

SC STOP "Zabbix Agent" | cmd
SC Delete "Zabbix Agent" | cmd

#Get-Service "Zabbix Agent" | Where-Object {$_.Status -eq "Running"}
#if "%ERRORLEVEL%"=="0" (
#    echo Program is running
#   GOTO ZABBIXRUNNING
#) else (
#    echo Program is not running
#    GOTO ZABBIXNOTRUNNING
#)

#:ZABBIXNOTRUNNING
ECHO ZABBIX NOT INSTALLED
# ::::::: Install the service :::::::
$url = "https://cdn.zabbix.com/zabbix/binaries/stable/4.0/4.0.37/zabbix_agent-4.0.37-windows-amd64.zip"
$output = "C:\temp\zabbix_agent.zip"
Invoke-WebRequest -Uri $url -OutFile $output

$ZippedFilePath = "C:\temp\zabbix_agent.zip"
$DestinationFolder = "C:\Windows\zabbix"
[void] (New-Item -Path $DestinationFolder -ItemType Directory -Force)
$Shell = new-object -com Shell.Application
$Shell.Namespace($DestinationFolder).copyhere($Shell.NameSpace($ZippedFilePath).Items(), 0x14) 

Set-Content -Path 'C:\Windows\zabbix\conf\zabbix_agentd.win.conf' -Value 'LogFile=C:\Windows\zabbix\zabbix_agentd.log'
Add-Content -Path 'C:\Windows\zabbix\conf\zabbix_agentd.win.conf' -Value 'Server=192.168.100.50'
Add-Content -Path 'C:\Windows\zabbix\conf\zabbix_agentd.win.conf' -Value 'ServerActive=192.168.100.50'
Add-Content -Path 'C:\Windows\zabbix\conf\zabbix_agentd.win.conf' -Value 'HostnameItem=system.hostname'

"C:\Windows\zabbix\bin\zabbix_agentd.exe --config C:\Windows\zabbix\conf\zabbix_agentd.win.conf --install" | cmd
"C:\Windows\zabbix\bin\zabbix_agentd.exe --start" | cmd
sc.exe failure "Zabbix Agent" reset= 30 Actions= restart/5000
Del -Path 'C:\temp\zabbix_agent.zip' -Force

Remove-NetFirewallRule -DisplayName "ZabbixAgent"
New-NetFirewallRule -DisplayName 'ZabbixAgent' -Profile Any -Direction Inbound -Action Allow -Protocol TCP -LocalPort 10050
