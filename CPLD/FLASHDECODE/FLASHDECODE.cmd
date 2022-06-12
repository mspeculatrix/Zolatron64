@ECHO OFF
REM Make sure this script name is identical to both the folder name
REM and the filename of the .pld and .tt2 files.
REM Also, edit the CPLD variable to suit the chip

set CPLD=1502

if %CPLD% equ 1502 (
    set CHIPDES=f1502tqfp44
    set DEV=P1502T44
) else if %CPLD% equ 1504 (
    set CHIPDES=f1504tqfp44
    set DEV=P1504T44
) else (
    exit 1
)
ECHO Compiling for %CPLD%
ECHO Running cupl.exe...
C:\Wincupl\Shared\cupl.exe -j -a -l -e -x -f -b -m4 %CHIPDES% %~n0
ECHO Running find...
if %ErrorLevel% equ 0 (
    if %CPLD% equ 1502 (
        find1502 -i %~dp0\%~n0.tt2 -CUPL -dev %DEV% -str JTAG ON -str logic_doubling off
    ) else if %CPLD% equ 1504 (
        find1504 -i %~dp0\%~n0.tt2 -CUPL -dev %DEV% -str JTAG ON -str logic_doubling off
    )
)
