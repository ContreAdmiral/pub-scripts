REM @ECHO OFF
setLocal EnableDelayedExpansion

rem this script is used to map a network drive for a system user to run the patch my pc on the workstation. look at the gpo.

SET NumberoftemptxtFilestoKeep=10
SET TEMPLOGDEST=c:\temp
SET CCLEANERFILESPATCH=\\contoso.server.local\updates$\ccleaner
SET SERVERNAME=SERVERNAME
SET UpdatesPath=\\contoso.server.local\updates$
SET PCINFOPATCH=\\contoso.server.local\updates$\info

set LocaltempDir=c:\temp
set LocalUpdateDir=C:\Updates

REM *************************
ECHO copying ccleaning ini files to local directory
echo f | xcopy "%UpdatesPath%\ccleaner\ccleaner.ini" "C:\Program Files\CCleaner\ccleaner.ini" /d /y
echo f | xcopy "%UpdatesPath%\ccleaner\winsys.ini" "C:\Program Files\CCleaner\winsys.ini" /d /y
REM echo f | xcopy "%UpdatesPath%\ccleaner\winreg.ini" "C:\Program Files\CCleaner\winreg.ini" /d /y
echo f | xcopy "%UpdatesPath%\ccleaner\winapp.ini" "C:\Program Files\CCleaner\winapp.ini" /d /y
dir "C:\Program Files\CCleaner\ >> c:\temp\%computername%-drivemapp-%date:~-10,2%%date:~-7,2%%date:~-4,4%.txt
ECHO finished copying files
echo cleaning local user files
REM "c:\Program Files\CCleaner\CCleaner64.exe" /auto

echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
net localgroup administrators >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
systeminfo >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt

REM dir c:\Windows\CSC\v2.0.6\namespace\%SERVERNAME%\RedirectedFolders >> \\contoso.server.local\updates$\info\%computername%.txt

echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo --------------------------------------------------------------------  >> \\contoso.server.local\updates$\info\%computername%.txt

REM ::: Copy Patch My PC Files to Updates$ folder :::

rem Set task name
set TASKNAME=PatchMyPC-Task

rem Get task status
:CheckTaskStatus
for /f "tokens=2 delims=:" %%i  in ('schtasks /Query /TN "%TASKNAME%" /FO LIST ^| findstr "Status:"') do (set STATUS=%%i)
rem Strip spaces from task status
set STATUS=%STATUS: =%
rem Compare task status...
if /i %STATUS%==Running (
echo Task "%TASKNAME%" is Running
timeout /t 30
GOTO CheckTaskStatus
)
if /i %STATUS%==Ready (
echo f | xcopy "%LocalUpdateDir%\PatchMyPC-%computername%.log" "%UpdatesPath%\PatchMyPC-%computername%.log" /d /y
)
Echo end of script

echo ------End of Script Files------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo ------End of Script Files------------------  >> \\contoso.server.local\updates$\info\%computername%.txt

REM Copying BGInfo
SET BGInfoDIR=C:\BGInfo
REM ::: Create Local BGInfo Directory :::
IF not exist %BGInfoDIR% (mkdir %BGInfoDIR%)
REM ::: Create Local BGInfo Directory :::

echo f | xcopy "%UpdatesPath%\BGInfo\Bginfo.exe" "%BGInfoDIR%\Bginfo.exe" /d /y
echo f | xcopy "%UpdatesPath%\BGInfo\HughesGroup.bgi" "%BGInfoDIR%\HughesGroup.bgi" /d /y

echo %BGInfoDIR%\Bginfo.exe %BGInfoDIR%\HughesGroup.bgi /nolicprompt /timer:0 > "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\pcinfo.bat"
echo exit >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\pcinfo.bat"
REM echo pause >> "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\pcinfo.bat"

Echo end of script

echo ------End of Script Files------------------  >> \\contoso.server.local\updates$\info\%computername%.txt
echo ------End of Script Files------------------  >> \\contoso.server.local\updates$\info\%computername%.txt

exit
