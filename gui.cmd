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
	:: Padding values to add to the top and bottom of messages displayed.
	set /A "PADDING_LR = 0"
	set /A "PADDING_TB = 0"

	:: Newline character for multiline variable
	set NL=^


	:: ANSI Color Codes
	set "CYAN=[1;36m"
	set "GREEN=[1;32m"
	set "YELLOW=[1;33m"
	set "RED=[1;31m"
	set "MAGENTA=[1;35m"
	set "_COLOR=[0m"

:: Insert code here ::
goto END

:: Arguments - <line1> <line2> <line3> ... <lineN>
:updateuserinterface
	set /A "_windowwidth = 0"
	set /A "_windowheight = 2"
	set /A "_col = !PADDING_LR! + 2"

	:: Holds the entirety of the message
	set _msg=

	:: Loops through each argument given to calculate correct window dimensions for the display
	:nextline
		set "_line=%~1"

		if "!_line!" neq "" (
			call :colorstrlen "!_line!"

			:: Update the window width to fit the longest line of text
			if !_windowwidth! lss !_RETURN! set /A "_windowwidth = !_RETURN!"
			set _RETURN=

			:: Update the window height to fit an additional line of text
			set /A "_windowheight += 1"

			:: Used for properly aligning each line according to padding
			set /A "_row = !_windowheight! + !PADDING_TB! - 1"

			:: Use the string "\n" as an indicator that an empty line is desired.
			if /I "!_line!" == "\n" (set "_msg=!_msg!!NL![!_row!;!_col!H") else (set "_msg=!_msg!!NL![!_row!;!_col!H!_line!")

			shift
			goto nextline
		)

	:: Account for padding specified by the LR TB variables
	set /A "_windowwidth = !_windowwidth! + 2 * !PADDING_LR! + 2"
	set /A "_windowheight = !_windowheight! + 2 * !PADDING_TB!"

	:: Update the window to fit the correct dimensions
	mode !_windowwidth!,!_windowheight!

	:: Shows the message without the newline character that echo outputs - too slow, using vanilla echo
	rem <nul set /p x=x!_msg!

	:: Output the message to the newly resized console screen
	echo [H[2J!_msg!
	goto :EOF

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
