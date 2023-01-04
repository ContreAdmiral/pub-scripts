
setLocal EnableDelayedExpansion


SET DEST=D:

dir %dest%

for /f "skip=1 tokens=* delims= " %%a in ('dir/b/o-d %DEST%\WindowsImageBackup*') do (rmdir /s /q "%DEST%\%%a")

WBADMIN START BACKUP -backupTarget:d: -allcritical -quiet

move "%DEST%\WindowsImageBackup" "%DEST%\WindowsImageBackup-%date:~-10,2%%date:~-7,2%%date:~-4,4%"

exit