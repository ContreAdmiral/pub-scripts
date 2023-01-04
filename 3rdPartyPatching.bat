REM @ECHO OFF
setLocal EnableDelayedExpansion
REM exit
REM Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v DisableSR /t REG_DWORD /d 0 /f
REM sc config srservice start= Auto
REM net start srservice


REM ::::: Disable .NET FrameWork update ::::::::::::
Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Patch My PC\Options"  /v DisableAutoCheck_Chk_NETFramework /t REG_SZ /d 1 /f
Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Patch My PC\Options"  /v Manual_Install_Chk_NETFramework /t REG_SZ /d 1 /f
Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Patch My PC\Options"  /v Skip_Chk_NETFramework /t REG_SZ /d 1 /f


REM ::::::: Kill Running Processes ::::::::::::::
taskkill.exe /F /IM PatchMyPC.exe


REM ::::::: Varibles SET ::::::::::
SET NumberoftemptxtFilestoKeep=10
SET TEMPLOGDEST=c:\temp
SET UpdatesPath=AddServerHere
SET UpdatesUser=UserName
SET UpdatesPassword=ZGJtwwNw2Nw2BwNwNw2w2uwNw2
SET PCINFOPATCH=AddServerHere\info

REM ::::::::: Creating Directories ::::::::
set LocaltempDir=c:\temp
set LocalUpdateDir=C:\Updates
set PatchMyPCITProCache=C:\Updates\PatchMyPCITProCache
set localscriptsdirectory=C:\Updates\scripts
set localtoolsdirectory=C:\Updates\tools


REM ::: Create Local Temp Directory :::
IF not exist %LocalUpdateDir% (mkdir %LocalUpdateDir%)
REM ::: Create Local Temp Directory :::

REM ::: Create Local updates Directory :::
IF not exist %LocalUpdateDir% (mkdir %LocalUpdateDir%)
REM ::: Create Local updates Directory :::

REM ::: Create Local PatchMyPCITProCache Directory :::
IF not exist %PatchMyPCITProCache% (mkdir %PatchMyPCITProCache%)
REM ::: Create Local updates Directory :::

REM ::: Create Local Scripts Directory :::
IF not exist %localscriptsdirectory% (mkdir %localscriptsdirectory%)
REM ::: Create Local Scripts Directory :::

REM ::: Create Local Tools Directory and Copy Files:::
IF not exist %localtoolsdirectory% (mkdir %localtoolsdirectory%)
xcopy "%UpdatesPath%\tools" "%localtoolsdirectory%" /i /y
REM ::: Create Local Tools Directory and Copy Files:::

REM :::::: Map Network Drive :::::::::
net use z: /delete /y
net use %UpdatesPath% /user:%UpdatesUser% %UpdatesPassword% /persistent:yes

dir %UpdatesPath% > c:\temp\%computername%-drivemapp-%date:~-10,2%%date:~-7,2%%date:~-4,4%.txt

for /f "skip=%NumberoftemptxtFilestoKeep% tokens=* delims= " %%a in ('dir/b/o-d %TEMPLOGDEST%\%computername%-drivemapp-*.txt') do (del "%TEMPLOGDEST%\%%a")

REM ::::::::::::::::::::::::::::: Enabling System Features :::::::::::::::::::::::::::::
REM *************************
REM Copy PS1 Script to local computer and Enable SystemRestore
echo f | xcopy "%UpdatesPath%\Scripts\EnableComputerRestore.ps1" "%localscriptsdirectory%\EnableComputerRestore.ps1" /d /y
powershell -ExecutionPolicy ByPass -File "%localscriptsdirectory%\EnableComputerRestore.ps1"
REM ::::::::::::::::::::::::::::: Enabling System Features :::::::::::::::::::::::::::::

REM ::::::::::::::::::::::::::::: Uninstall Not Needed softwares :::::::::::::::::::::::::::::
REM net stop TeamViewer
REM "C:\Program Files (x86)\TeamViewer\uninstall.exe" /S
REM ::::::::::::::::::::::::::::: Uninstall Not Needed softwares :::::::::::::::::::::::::::::

REM ::::::::::::::::::::::::::::: Run CCcleaner as system to clean up system temp files :::::::::::::::::::::::::::::
SchTasks /ru "SYSTEM" /Create /SC MONTHLY /D 1 /TN "SystemCCleaner-File" /TR "'C:\Program Files\CCleaner\CCleaner64.exe' /auto" /ST 16:00 /f
vol | date | find /i "Fri" > nul 
if not errorlevel 1 goto FRI
goto END
:FRI
SCHTASKS /Run /TN "SystemCCleaner-File"
goto END
:END
REM ::::::::::::::::::::::::::::: Run CCcleaner as system to clean up system temp files :::::::::::::::::::::::::::::

REM Get Product Keys from a computer
REM echo f | xcopy "%UpdatesPath%\Scripts\ProduKey.exe" "%localscriptsdirectory%\ProduKey.exe" /d /y
REM "%localscriptsdirectory%\ProduKey.exe" /stext "%localscriptsdirectory%\productkey-%computername%.txt"
REM echo f | xcopy "%localscriptsdirectory%\productkey-%computername%.txt" "%UpdatesPath%\Scripts\ProductKeys\productkey-%computername%.txt" /d /y

REM Get List of CSCUsers
REM dir c:\windows\CSC\v2.0.6\namespace\hge-pdc\RedirectedFolders > "%localscriptsdirectory%\listofCSCUsers-%computername%.txt"
REM echo f | xcopy "%localscriptsdirectory%\listofCSCUsers-%computername%.txt" "%UpdatesPath%\Scripts\listofCSCUsers\listofCSCUsers-%computername%.txt" /d /y

REM *************************

REM *************************
Echo Runnning the 3RD Party Patch Software
echo --------------------------------------------------------------------  > %PCINFOPATCH%\%computername%.txt
echo f | xcopy "%UpdatesPath%\PatchMyPC.exe" "%LocalUpdateDir%\PatchMyPC.exe" /d /y
echo f | xcopy "%UpdatesPath%\PatchMyPC.ini" "%LocalUpdateDir%\PatchMyPC.ini" /d /y
SchTasks /ru "SYSTEM" /Create /SC MONTHLY /D 1 /TN "PatchMyPC-Task" /TR "C:\Updates\PatchMyPC.exe /silent" /ST 21:00 /f
SCHTASKS /Run /TN "PatchMyPC-Task"
echo -------Runnning the 3RD Party Patch Software--%date:~-10,2%%date:~-7,2%%date:~-4,4%-------  >> %PCINFOPATCH%\%computername%.txt
echo --------------------------------------------------------------------  >> %PCINFOPATCH%\%computername%.txt
REM %UpdatesPath%\PatchMyPC.exe /silent
Echo Finished running the patch
REM *************************
echo running pc cleaning files script >> c:\temp\%computername%-drivemapp-%date:~-10,2%%date:~-7,2%%date:~-4,4%.txt
\\contoso.server.local\scripts\UserCleaning.bat
exit