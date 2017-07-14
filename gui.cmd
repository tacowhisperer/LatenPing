@echo off
REM    ************************************************************************
	:: gui.cmd
	::
	::     This batch file uses native Windows CMD.EXE pure-batch commands to
	::     set a framework with which messages may be displayed to the console.
	::
	:: USAGE:
	::     Take relevant framework code and insert custom code where applicable
REM    ************************************************************************

setlocal EnableDelayedExpansion

REM Function return variable
	set _RETURN=

REM Hold the options that are read by the updateuserinterface function 
	:: Initial window width and height values
	set /A "WIDTH = 25"
	set /A "HEIGHT = 5"

	:: Padding values to add to the top and bottom of messages displayed.
	set /A "PADDING_TB = 0"
	set /A "PADDING_LR = 0"

	:: ANSI Color Codes
	set "CYAN=[1;36m"
	set "GREEN=[1;32m"
	set "YELLOW=[1;33m"
	set "RED=[1;31m"
	set "MAGENTA=[1;35m"
	set "_COLOR=[0m"

:: Arguments - <line1> <line2> <line3> ... <lineN>
:updateuserinterface
	set "A=%CYAN%Andres%_COLOR%"
	set "B=%GREEN%Salgado%_COLOR%"
	set "C=%YELLOW%wrote%_COLOR%"
	set "D=%RED%this%_COLOR%"
	set "E=%MAGENTA%batch%_COLOR%"
	set "F=script."

	call :colorstrlen "!A!"
	set /A "la = !_RETURN!"
	set /A "lac = !la! + 2"

	call :colorstrlen "!B!"
	set /A "lb = !_RETURN!"
	set /A "lbc = !lac! + !lb! + 1"

	call :colorstrlen "!C!"
	set /A "lc = !_RETURN!"
	set /A "lcc = !lbc! + !lc! + 1"

	call :colorstrlen "!D!"
	set /A "ld = !_RETURN!"
	set /A "ldc = !lcc! + !ld! + 1"

	call :colorstrlen "!E!"
	set /A "le = !_RETURN!"
	set /A "lec = !ldc! + !le! + 1"

	call :colorstrlen "!F!"
	set /A "lf = !_RETURN!"
	set /A "lfc = !lec! + !lf!"

	echo %A% %B% %C% %D% %E% %F%
	echo %CYAN%!la!%_COLOR% [2;!lac!H%GREEN%!lb!%_COLOR%[2;!lbc!H%YELLOW%!lc!%_COLOR%[2;!lcc!H%RED%!ld!%_COLOR%[2;!ldc!H%MAGENTA%!le!%_COLOR%[2;!lec!H!lf!
	pause

	goto END

REM Calculates the length of the string given as an argument
:: Arguments: string
:colorstrlen
	set /A "_pos = 0"
	set /A "_RETURN = 0"
	set "_tempstr=%~1"
	set "_substr=!_tempstr!"

	:: Credit - https://stackoverflow.com/questions/15004825/looping-for-every-character-in-variable-string-batch
	set "_isANSI=f"
	:nextchar
		set "_chartemp=!_substr:~%_pos%,1!"
		
		:: Sets the ANSI escape sequence flag if <ESC> is detected
		if "!_chartemp!" == "" set "_isANSI=t"

		:: Does not count ANSI escape sequences as part of the string length
		if "!_isANSI!" == "t" (
			if "!_chartemp!" == "m" (
				set "_isANSI=f"
			)
		) else (
			if "!_chartemp!" neq "" set /A "_RETURN += 1"
		)

		if "!_chartemp!" neq "" (
			set /A "_pos += 1"
			goto nextchar
		)

	goto :EOF

:END

endlocal
exit
