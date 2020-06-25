@echo off
IF NOT DEFINED in_subprocess (cmd /k SET in_subprocess=y ^& %0 %*) & exit )
SETLOCAL enabledelayedexpansion

FOR /F "usebackq tokens=1,2 delims==" %%i in (`wmic os get LocalDateTime /VALUE 2^>NUL`) do if '.%%i.'=='.LocalDateTime.' set ldt=%%j
set localdatetime=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%-%ldt:~8,2%h%ldt:~10,2%m%ldt:~12,2%s

SET /p screensSuffix="What is the preferred suffix?: "

SET outputDirectory=C:\Tools\Workshop\
REM %~n1\
SET inputFilePath=%~1
SET screensDirectory=screens-%localdatetime%%screensSuffix%\

MKDIR "!outputDirectory!%screensDirectory%" 2> NUL
CD /D "!outputDirectory!"


REM Generates Screenshots

REM Finds duration of file in seconds
ffmpeg -i "%inputFilePath%" -map 0:v:0 -c copy -f null - > temp.txt 2>&1

REM Extracts the last 2 lines of the ffmpeg output (the wanted lines are from the 2nd last to the 3rd last)
FOR /F "delims=" %%a in (temp.txt) do (
    SET "lastBut1=!lastLine!"
    SET "lastLine=%%a"
)
FOR /F "tokens=2 delims==" %%b in ("!lastBut1!") do (
    FOR /F "tokens=1 delims= " %%c in ("%%b") do (
        SET "frameCount=%%c"
    )
)

REM Divides the framecount by 15 to have an interval the length of 1/15 of the video to generate a screenshot at that interval
SET /A interval= !frameCount! / 15

REM Deletes the PNGs already present in the directory
DEL %screensDirectory%*.png >NUL 2>&1

REM Extracts screen at each interval and names the file as the frame number
ffmpeg -analyzeduration 2147483647^
 -probesize 2147483647^
 -i "%inputFilePath%"^
 -loglevel error^
 -vf [in]setpts=PTS,select="not(mod(n\,%interval%))"[out]^
 -vsync 0^
 -stats^
 -f image2^
 -start_number 0^
 -frame_pts 1^
 "%outputDirectory%%screensDirectory%%%d%screensSuffix%.png" & 

ECHO Finished generating screenshots

pause