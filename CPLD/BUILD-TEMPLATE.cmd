@ECHO OFF
REM Make sure this script name is identical to both the folder name
REM and the filename of the .pld and .tt2 files.
REM Also, edit the CPLD and package variables to suit the chip

set CPLD=1502
set package=plcc

if %CPLD% equ 1502 (
    if %package% equ plcc (
        set CHIPDES=f1502plcc44
        set DEV=P1502C44
    ) else (
        set CHIPDES=f1502tqfp44
        set DEV=P1502T44
    )
) else if %CPLD% equ 1504 (
    if %package% equ plcc (
        set CHIPDES=f1504plcc44
        set DEV=P1504C44
    ) else (
        set CHIPDES=f1504tqfp44
        set DEV=P1504T44
    )
) else if %CPLD% equ 1508 (
    if %package% equ plcc (
        set CHIPDES=f1508plcc84
        set DEV=P1508C84
    ) else (
        set CHIPDES=f1508tqfp84
        set DEV=P1508T84
    )
) else (
    exit 1
)
ECHO Compiling for %CPLD%
ECHO Running cupl.exe...
C:\Wincupl\Shared\cupl.exe -j -a -l -e -x -f -b -m4 %CHIPDES% %~n0
if %ErrorLevel% equ 0 (
    ECHO Running find...
    if %CPLD% equ 1502 (
        find1502 -i %~dp0\%~n0.tt2 -CUPL -dev %DEV% -str JTAG ON -str logic_doubling off
    ) else if %CPLD% equ 1504 (
        find1504 -i %~dp0\%~n0.tt2 -CUPL -dev %DEV% -str JTAG ON -str logic_doubling off
    ) else if %CPLD% equ 1508 (
        find1508 -i %~dp0\%~n0.tt2 -CUPL -dev %DEV% -str JTAG ON -str logic_doubling off
    )
)
