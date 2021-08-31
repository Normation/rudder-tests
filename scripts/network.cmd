@echo on
set HOSTFILE=c:/Windows/System32/drivers/etc/hosts

rem Initialise hosts file
set NET=%1
set FIRST_IP=%2
echo 127.0.0.1       localhost > %HOSTFILE%
echo ::1             localhost >> %HOSTFILE%

echo %NET%.%FIRST_IP%    server.rudder.local server rudder >> %HOSTFILE%

rem allow variable modification for iteration
setlocal enabledelayedexpansion
SET /A "i=%FIRST_IP%"

rem iterate over parameters to generate hosts file lines
:loop
if NOT [%3]==[] (
  echo %NET%.!i!    %3 >> %HOSTFILE%
  SET /A "i=!i!+1"
  shift
)
if NOT [%3]==[] goto loop

