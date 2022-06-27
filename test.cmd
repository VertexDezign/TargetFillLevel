@ECHO off

@REM Pack mod
CALL pack.cmd

IF %ERRORLEVEL% NEQ 0 ( exit 1 )

setlocal
FOR /F "tokens=*" %%i IN ('type .env') DO SET %%i

SET modTestPath=%testTempFolder%%modName%

ECHO Prepare files to test
RMDIR %modTestPath% /s /q
MKDIR %modTestPath%
COPY %filename% %modTestPath%
CD %modTestPath%
UNZIP -o %filename%
DEL %filename%

ECHO Execute TestRunner
%testRunner% %modTestPath% -g %gamePath% --noPause

endlocal
