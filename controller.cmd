@echo off
REM    ************************************************************************
	:: controller.cmd
	::
	::     This batch file uses native Windows CMD.EXE pure-batch commands to
	::     asynchronously read input from the keyboard.
	::
	:: USAGE:
	::     Take relevant framework code and insert custom code where applicable
REM    ************************************************************************

setlocal EnableDelayedExpansion

REM Initialization code for keyboard input
:keyboardinputinit
	REM Storage of character literals to environment variables

	:: Credit - https://stackoverflow.com/questions/21367518/is-it-possible-to-echo-some-non-printable-characters-in-batch-cmd
	for /F %%A in ('copy /Z "%~dpf0" nul') do set "ENTER=%%A"

	:: Credit - http://www.dostips.com/forum/viewtopic.php?t=7679
	for /F "delims= " %%T in ('robocopy /L . . /njh /njs') do set "TAB=%%T"

	:: Credit - http://www.dostips.com/forum/viewtopic.php?t=2124
	for /F %%a in ('"prompt $H&for %%b in (1) do rem"') do set "BACKSPACE=%%a"

	:: Credit - http://www.dostips.com/forum/viewtopic.php?t=2124
	for /F %%a in ('"prompt $_&for %%b in (1) do rem"') do set "LINEFEED=%%a"

	REM Bookkeeping variables

	:: Used for easy identification of this batch file's PID
	set "SELF_TITLE=Session:%RANDOM%1337"
	title %SELF_TITLE%

	:: Save the PID of this batch file
	set MY_PID=
	for /F "tokens=2 delims=," %%i in ('tasklist /fi "windowtitle eq %SELF_TITLE%" /fo csv /nH') do set "MY_PID=%%~i"

	:: Key counter for input thread
	set /A "N = 1"

	:: Skip all of this code if the very first argument given is the input keyword
	if /I "%~1" == "input" goto keyboardinputthread

	:: Title initialization and communication pathway between i/o
	title IN=0-

	:: Releases keyboard input to a separate thread
	start /b "" cmd /c "%~0" input

	goto :EOF

REM Handles keyboard input in a separate thread
:keyboardinputthread
	:: Container for the key pressed
	set K=

	:: Xcopy method of acquiring keyboard input. Pauses the current thread until input is received
	for /F "eol=0 delims=" %%i in ('xcopy /w "%~f0." ?') do set "K=%%i"

	:: Change the title of the program if a key was detected
	if not "!K:~-1!" == "" (
		set K=!K:~-1!
	)

	:: Send special keys with their string name encapsulated in square brackets
	if "!K!" == "!TAB!" (
		title IN=!N!-[TAB]
	) else (
		if "!K!" == "!BACKSPACE!" (
			title IN=!N!-[BACKSPACE]
		) else (
			if "!K!" == "-" (
				title IN=!N!-[HYPHEN]
			) else (
				if "!K!" == "!LINEFEED!" (
					title IN=!N!-[LINEFEED]
				) else (
					if "!K!" == "!ENTER!" (
						title IN=!N!-[ENTER]
					) else (
						if "!K!" == " " (
							title IN=!N!-[SPACE]
						) else (
							title IN=!N!-!K!
						)
					)
				)
			)
		)
	)

	:: Increment the number that keeps track of num keys detected so far
	:: Used for differentiating between keypress and keyidle
	set /A  "N += 1"

	goto keyboardinputthread
