@ECHO off

@REM Pack mod
CALL pack.cmd

IF %ERRORLEVEL% NEQ 0 ( exit 1 )

SET testRunnerPath="D:\Code\FSTools\TestRunner\\"
SET gamePath="G:\SteamLibrary\steamapps\common\Farming Simulator 22\\"
SET modTestPath=%testRunnerPath%%modName%\

ECHO Prepare files to test
MKDIR %modTestPath%
COPY %filename% %modTestPath%
CD %modTestPath%
UNZIP -o %filename%
DEL %filename%
DIR

ECHO Execute TestRunner
%testRunnerPath%TestRunner_public.exe %modTestPath% -g %gamePath% --noPause