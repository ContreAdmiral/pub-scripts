@ECHO OFF
COLOR 0A
ECHO ---------------------------------------
echo ---------------------------------------
setLocal EnableDelayedExpansion
REM "DRIVES" can be one drive identifier with colon, multiple separated by spaces,
REM or asterisk for all.
REM "DEST" can be a drive letter or a UNC.
REM *************************************************************************************
REM \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
REM *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
SET BKDRIVEIP=ServerName
SET LOCATIONOFD2VHDFILE="C:\Windows\Backups\disk2vhd.exe"
SET LOCATIONOF7ZIP="C:\Program Files\7-Zip\7z.exe"
SET LOCATIONOFBLATFILE="C:\Windows\Backups\mail\blat.exe"
REM \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
SET PINGDESTSERVER=%BKDRIVEIP%
SET DRIVES="C:"
SET COMPANYNAME=HG
SET DEST=\\%BKDRIVEIP%\Backups$\%COMPUTERNAME%
SET LOGDEST=C:\Windows\Backups\Logs
SET SERVERNAME=%COMPUTERNAME%-DAILY
SET NumberofVHDFilestoKeep=1
SET NumberofLOGFilestoKeep=60
SET LogName=%COMPANYNAME%-%SERVERNAME%--%date:~-10,2%%date:~-7,2%%date:~-4,4%-TS.txt
SET FILENAME=%COMPANYNAME%-%SERVERNAME%--%date:~-10,2%%date:~-7,2%%date:~-4,4%-TS
REM \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
REM *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
NET USE \\%BKDRIVEIP% /delete /y
NET USE \\%BKDRIVEIP% /user:%BKDRIVEIP%\localbackups ba8bMBPTN8IZT9 /p:yes
IF EXIST %DEST% (ECHO FOLDER LOCATION EXIST) ELSE (MKDIR %DEST%)
REM *-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
REM \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
REM SET For E-Mail results
REM SET TO=EmailAddress
REM SET SERVERANDPORT=ServerAddress:25
REM SET SENDER=SenderAddress
REM SET AUTHUSER=AuthUser
REM SET NAMEP=Password
REM SET SUBJECT=%COMPANYNAME%-%SERVERNAME%--%date:~-10,2%%date:~-7,2%%date:~-4,4%-TS
REM SET BODY=%LOGDEST%\%LogName%
REM \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
echo --------------------------------------------------------------- >> %LOGDEST%\%LogName%
echo ---------                     --------------------------------- >> %LOGDEST%\%LogName%
echo ---------%COMPANYNAME% %SERVERNAME% Server Backup Report------- >> %LOGDEST%\%LogName%
echo ---------%date%---------------------------------------- >> %LOGDEST%\%LogName%
echo --------------------------------------------------------------- >> %LOGDEST%\%LogName%
REM *************************************************************************************
REM echo >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Backup Procedure Started >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Started Deleting VHD Files >> %LOGDEST%\%LogName%
REM Keep most # recent Files in DEST, delete the rest
for /f "skip=%NumberofVHDFilestoKeep% tokens=* delims= " %%a in ('dir/b/o-d %DEST%\*.VHD') do echo (del "%DEST%\%%a") >> %LOGDEST%\%LogName%
for /f "skip=%NumberofVHDFilestoKeep% tokens=* delims= " %%a in ('dir/b/o-d %DEST%\*.VHD') do (del "%DEST%\%%a")
echo [%date%] [%time%] Finished Deleting VHD Files >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Started Deleting Log Files >> %LOGDEST%\%LogName%
REM Keep most # recent Log Files in BODY DEST, delete the rest
for /f "skip=%NumberofLOGFilestoKeep% tokens=* delims= " %%b in ('dir/b/o-d %LOGDEST%\*.txt') do echo (del "%LOGDEST%\%%b") >> %LOGDEST%\%LogName%
for /f "skip=%NumberofLOGFilestoKeep% tokens=* delims= " %%b in ('dir/b/o-d %LOGDEST%\*.txt') do (del "%LOGDEST%\%%b")
echo [%date%] [%time%] Finished Deleting Log Files >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Pinging backup device Started >> %LOGDEST%\%LogName%
ping %PINGDESTSERVER%  >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Pinging backup device Done >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Backup Started >> %LOGDEST%\%LogName%
%LOCATIONOFD2VHDFILE% -accepteula %DRIVES% %DEST%\%FILENAME%.VHD
echo %date% %time% Backup Finished >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo The content of Destination Include: >> %LOGDEST%\%LogName%
DIR /O-d %DEST% >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo [%date%] [%time%] File Verification Of Drive 0 Started >> %LOGDEST%\%LogName%
REM %LOCATIONOF7ZIP% x "%DEST%\%FILENAME%.VHD" "Confirmation.txt" -oC:\Backup\Recover%date:~-10,2%%date:~-7,2%%date:~-4,4% >> %LOGDEST%\%LogName%
%LOCATIONOF7ZIP% x "%DEST%\%FILENAME%-1.VHD" "Confirmation.txt" -oC:\Backup\Recover%date:~-10,2%%date:~-7,2%%date:~-4,4% >> %LOGDEST%\%LogName%
%LOCATIONOF7ZIP% t "%DEST%\%FILENAME%-0.VHD" >> %LOGDEST%\%LogName%
echo [%date%] [%time%] File Verification Of Drive Finished >> %LOGDEST%\%LogName%
echo ############################################################### >> %LOGDEST%\%LogName%
echo [%date%] [%time%] Backup Procedure Finished >> %LOGDEST%\%LogName%
echo --------------------------------------------------------------- >> %LOGDEST%\%LogName%
echo ---------------END OF REPORT----------------------------------- >> %LOGDEST%\%LogName%
echo --------------------------------------------------------------- >> %LOGDEST%\%LogName%
REM %LOCATIONOF7ZIP% a %LOGDEST%\Archive\%FILENAME%.zip %LOGDEST%\Archive\%LogName%
REM %LOCATIONOFBLATFILE% %BODY% -to %TO% -server %SERVERANDPORT% -f %SENDER% -subject %SUBJECT% 
REM -attach %LOGDEST%\Archive\%FILENAME%.zip
exit
