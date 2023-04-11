@ECHO off

@REM Pack mod
CALL pack.cmd

IF %ERRORLEVEL% NEQ 0 ( exit 1 )

setlocal
FOR /F "tokens=*" %%i in ('type .env') do SET %%i

ECHO Copy file to mod folder
COPY %filename% %gameProfile%mods\
ECHO Copy file to remote PC
COPY %filename% %remoteGameProfile%mods\

ECHO Happy Testing: %modName%

@REM Available FS22 start params
@REM -cheats (enables cheats in the console)
@REM -autoStartSavegameId 3 (loads the savegame automatically | *Replace "3" with the savegame ID of your choice)
@REM -restart (prevents intro videos from playing | will also keep logging the game to the logfile)
@REM -disableFramerateLimiter (removes the FPS cap | not recommended )

endlocal
