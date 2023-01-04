ECHO OFF
setLocal EnableDelayedExpansion
REM exit
color 3f
REM mode con:cols=85 lines=50

set RemoteZabbixConfigDirectory=\\hge-pdc.hg.local\updates$\zabbix\
set LocalZabbixDirectory=C:\Windows\zabbix\

Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Stopping Zabbix Service
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
C:\Windows\zabbix\bin\zabbix_agentd.exe --stop
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Uninstalling Zabbix service
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
C:\Windows\zabbix\bin\zabbix_agentd.exe --config C:\Windows\zabbix\conf\zabbix_agentd.win.conf --uninstall
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Creating Local Zabbix Installation Directory
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM ::: Create Local Scripts Directory :::
IF not exist %LocalZabbixDirectory% (mkdir %LocalZabbixDirectory%)
REM ::: Create Local Scripts Directory :::
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Copying Zabbix Installation files to Zabbix Local directory
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM ::: Copy Zabbix Configuration Files and Directory :::
xcopy /E "%RemoteZabbixConfigDirectory%*" "%LocalZabbixDirectory%*" /d /y /EXCLUDE:%RemoteZabbixConfigDirectory%ExcludedFiles.txt
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Installing Zabbix service
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
C:\Windows\zabbix\bin\zabbix_agentd.exe --config C:\Windows\zabbix\conf\zabbix_agentd.win.conf --install
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Starting Zabbix Service
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
C:\Windows\zabbix\bin\zabbix_agentd.exe --start
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo Adding Firewall Exception Rule
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
netsh advfirewall firewall delete rule name="Zabbix Port 10050"
netsh advfirewall firewall add rule name="Zabbix Port 10050" dir=in action=allow protocol=TCP localport=10050
Echo.
Echo.
Echo ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Echo ::::::::::::::Zabbix Agent Is Installed ::::::::::::::::::::::::::::::::::::::
Echo ::::::::::::::Go To Zabbix Web Portal and add agent to the hosts list:::::::::
Echo.
Echo.
Echo ::::::::::::::Computer Information::::::::::::::::::::::::::::::::::::::::::::
FOR /F "tokens=2 delims=:" %%a IN ('ipconfig ^| findstr /IC:"IPv4 Address"') DO Echo ::::::::::IP Address:%%a
Echo ::::::::::PC Name   : %computername%
explorer C:\Windows\zabbix\
C:\Windows\zabbix\zabbix_agentd.log
Pause


