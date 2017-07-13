@echo off
REM    ************************************************************************
	:: LatenPing.cmd
	::
	::     This batch file uses the native Windows ping command to give you a
	::     constantly updated indicator of your current lagginess.
	::
	::     It uses only native Windows programs to do this, so no need to worry
	::     about installing external programs.
	::
	:: USAGE:
	::     Simply double click the command file and keep it displayed somewhere
	::     that is easy to glance at.
	::
	:: OPTIONAL ARGUMENTS:
	::     -ip <IPAddressToPing>        Sets the default pinged IP address from
	::                                  8.8.8.8 to <IPAddressToPing>. Uses the
	::                                  default if <IPAddressToPing> does not
	::                                  successfully connect to the PC.
	::
	::     -delay <secondsToDelayPing>  Specifies the number of seconds to wait
	::                                  between pinging sessions. Default is 0.
	::
	::     -ex <excellentMsThresh>      Sets the threshold value for the number
	::                                  of milliseconds of ping time considered
	::                                  "excellent"
	::
	::     -good <goodMsThresh>         Sets the threshold value for the number
	::                                  of milliseconds of ping time considered
	::                                  "good"
	::
	::     -ok <okayMsThresh>           Sets the threshold value for the number
	::                                  of milliseconds of ping time considered
	::                                  "okay"
	::
	::     -bad <badMsThresh>           Sets the threshold value for the number
	::                                  of milliseconds of ping time considered
	::                                  "bad"
REM    ************************************************************************

setlocal EnableDelayedExpansion

:: Credit for non-blocking batch keyboard input
:: http://www.dostips.com/forum/viewtopic.php?t=7679

REM Initialization code for reading keyboard input
	:: Storage of special characters into variables
		:: Credit - https://stackoverflow.com/questions/21367518/is-it-possible-to-echo-some-non-printable-characters-in-batch-cmd
		for /F %%A in ('copy /Z "%~dpf0" nul') do set "ENTER=%%A"

		:: Credit - http://www.dostips.com/forum/viewtopic.php?t=7679
		for /F "delims= " %%T in ('robocopy /L . . /njh /njs') do set "TAB=%%T"

		:: Credit - http://www.dostips.com/forum/viewtopic.php?t=2124
		for /F %%a in ('"prompt $H&for %%b in (1) do rem"') do set "BACKSPACE=%%a"

		:: Credit - http://www.dostips.com/forum/viewtopic.php?t=2124
		for /F %%a in ('"prompt $_&for %%b in (1) do rem"') do set "LINEFEED=%%a"

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

	:: Clean the screen for blank initialization
	echo [2J[s

:: Initialization code for the ping testing program
REM Values used for calculating ping
	:: IP address to ping
	set IPADDR=8.8.8.8

	:: Number of seconds to wait to ping the server again
	set DELAY=0

	:: Threshold values for ping categories
	set EX=20
	set GOOD=25
	set OK=45
	set BAD=90

	:: Specifies the number of pings to make per sample
	set SAMPLESIZE=2

REM Values used for basic functionality
	:: Name of the temporary file that holds ping info
	set TEMPDIR=temp.ping

	:: Alias for booleans
	set TRUE=1
	set FALSE=0

	:: Specifies the starting window width and height
	set WIDTH=25
	set HEIGHT=5
	set DEFAULTHEIGHT=1

	:: Holds the current display state
	:: <init>
	::     <menu>
	::         <exec>
	::         <opts>
	::         <help>
	::         <exit>
	set DISPLAYSTATE=init

	:: Holds the string to be prompted to the screen
	set DISPLAYMSG=

	:: Holds the coordinates of the display message
	set /A "DISPLAYMSG_ROW = 1"
	set /A "DISPLAYMSG_COL = 1"

	:: Whether or not to display the message as an error
	set ERRORFLAG=%FALSE%

	:: Whether or not to clear the previous screen on user interface updateuserinterfacehelper
	set CLEARPREVSCREEN=!TRUE!

	:: Aliases for the commands to execute after calling the updateuserinterface subroutine
	set THENPAUSEPROMPT=0
	set THENPAUSENOPROMPT=1
	set THENWAITPROMPT=2
	set THENWAITNOPROMPT=3

	:: Holds the program state (for pausing or unpausing the program)
	:: RUN - update as usual
	:: PAUSEPROMPT - paused with "press any key to continue..." display message
	:: PAUSENOPROMPT - paused without a display message
	set PROGRAMSTATE=RUN

	:: Used for allowing basic text animations
	set /A "FR = 0"

	:: Holds the number of seconds to wait after displaying a message to continue
	set WAITPROMPTTIME=5

	:: Max integer
	set MAXINT=2147483647

	:: Holds the initial value of N
	set /A "N1 = 1"

	:: Holds the previous value of N1
	set /A "N0 = !N1!"

	:: Holds the output of subroutines
	set _RETURN=

REM Lag status labels
	set EXCELLENT=[1;36mEXCELLENT[0m
	set GOOD=[1;32mGOOD[0m
	set OKAY=[1;33mOKAY[0m
	set BAD=[1;31mBAD[0m
	set TERRIBLE=[1;35mTERRIBLE[0m

REM Hold the messages related to ping values obtained
	set LAGSTATEMSG=initializing...
	set LAGSTATE=init

goto eventloop

:: Event loop subroutine that reads keyboard input, updates console states, etc.
:eventloop
	REM Keyboard controller code
		set TOKENFOUND=
		set K1=

		:: Find the token containing the key pressed
		for /F "tokens=9* delims=," %%I in ('tasklist /v /fi "pid eq %MY_PID%" /fo csv /nH') do (
			:: Search for the relevant string from the input thread
			echo %%I | findstr /c:"IN=" > nul

			if errorlevel 1 (
				echo %%J | findstr /c:"IN=" > nul

				if errorlevel 1 (
					echo %%K | findstr /c:"IN=" > nul

					if errorlevel 1 (
						echo This is not the token you are looking for > nul
					) else (
						set "TOKENFOUND=%%K"
						set TOKENFOUND=!TOKENFOUND:"=!
					)
				) else (
					set "TOKENFOUND=%%J"
					set TOKENFOUND=!TOKENFOUND:"=!
				)
			) else (
				set "TOKENFOUND=%%I"
				set TOKENFOUND=!TOKENFOUND:"=!
			)
		)

		:: Split the main token into the more usable N1 and K1 variables
		for /F "tokens=1,2 delims=-" %%I in ("!TOKENFOUND!") do (
			:: Set the new N value
			set /A "N1 = %%I"

			:: Set the new key value
			set "K1=%%J"
		)

	REM Start of LatenPing.cmd logic

	:: Check that a key has been pressed. If so, the program is no longer "paused"
	if "!N0!" neq "!N1" set "PROGRAMSTATE=RUN"

	:: Root of program state
	if "!PROGRAMSTATE!" == "RUN" (
		:: Code is still initializing (getting command line arguments, first ping, etc.)
		if "!DISPLAYSTATE!" == "init" (
			:: Animate the initializing message to let the user know that the program is still working
			set /A "FR0 = FR % 7"
			if "!FR0!" == "0" set "DISPLAYMSG=initializing"
			if "!FR0!" == "1" set "DISPLAYMSG=initializing."
			if "!FR0!" == "2" set "DISPLAYMSG=initializing.."
			if "!FR0!" == "3" set "DISPLAYMSG=initializing..."
			if "!FR0!" == "4" set "DISPLAYMSG=initializing...."
			if "!FR0!" == "5" set "DISPLAYMSG=initializing....."
			if "!FR0!" == "6" set "DISPLAYMSG=initializing......"

			set CLEARPREVSCREEN=!TRUE!
			set ERRORFLAG=!FALSE!
			set /A "DISPLAYMSG_ROW = 3"
			set /A "DISPLAYMSG_COL = 2"
			
			:: Determines whether or not the first real ping can be made
			set STARTPING=!TRUE!

			:: Continue mapping arguments
			set "_arg0=%~1"
			set "_arg1=%~2"

			if defined _arg0 (
				if defined _arg1 (
					:: Change the global variable values based on given arguments
					call :mapargument "!_arg0!" "!_arg1!"

					:: Shift to the next pair of arguments
					shift
					shift

					:: A pair or arguments was found, so there could be more, so avoid first ping
					set STARTPING=!FALSE!
				)
			)

			:: Start the first ping once arguments are finished mapping
			if "!STARTPING!" == "!TRUE!" (
				call :pingaddress "!IPADDR!"
				set "DISPLAYSTATE=menu"
			)
		) else (
			if "!DISPLAYSTATE!" == "menu" (

			) else (
				if "!DISPLAYSTATE" == "exec" (

				) else (
					if "!DISPLAYSTATE" == "opts" (

					) else (
						if "!DISPLAYSTATE" == "help" (

						) else (
							REM The program should now exit
						)
					)
				)
			)
		)

		:: Update the display
		call :updateuserinterface "!DISPLAYMSG!" !DISPLAYMSG_ROW! !DISPLAYMSG_COL! !TRUE!
	) else (
		if "!PROGRAMSTATE!" == "PAUSEPROMPT" (
			if "!ERRORFLAG!" == "!TRUE!" (
				call :updateuserinterfaceerror "!DISPLAYMSG!" !DISPLAYMSG_ROW! !DISPLAYMSG_COL! !TRUE!
				set _RETURN=

				echo Press any key to continue...
			) else (
				call :updateuserinterface "!DISPLAYMSG!" !DISPLAYMSG_ROW! !DISPLAYMSG_COL! !TRUE!
				set _RETURN=

				echo Press any key to continue...
			)
		) else (
			if "!PROGRAMSTATE!" == "PAUSENOPROMPT" (
				if "!ERRORFLAG!" == "!TRUE!" (
					call :updateuserinterfaceerror "!DISPLAYMSG!" !DISPLAYMSG_ROW! !DISPLAYMSG_COL! !TRUE!
					set _RETURN=
				) else (
					call :updateuserinterface "!DISPLAYMSG!" !DISPLAYMSG_ROW! !DISPLAYMSG_COL! !TRUE!
					set _RETURN=
				)
			) else (
				call :updateuserinterfaceerror "Unexpected PROGRAMSTATE: '!PROGRAMSTATE!' encountered. Exiting program." 2 1 !TRUE! !THENWAITPROMPT!
				set _RETURN=

				goto END
			)
		)
	)

	:: Save the N value for the next loop
	set /A "N0 = !N1!"
	
	:: Update the frame counter for the next iteration
	set /A "FR += 1"

	goto eventloop

:: Subroutine that handles LatenPing logic if the program is currently running
:runtestping
	goto :EOF

:: Subroutine that handles LatenPing logic if the program is currently paused with a prompt message
:pauseprompttestping
	goto :EOF

:: Subroutine that handles LatenPing logic if the program is currently paused without a prompt message
:pausenoprompttestping
	goto :EOF

:: Subroutine that outputs the main menu to the screen
:displaymainmenu
	goto :EOF

:: Subroutine that displays the help menu to the screen
:displayhelpmenu
	goto :EOF

:: Subroutine that displays the current lag status based on the information available
:: Arguments: isFirstRun
:displaycurrentlagstatus
	goto :EOF

:: Subroutine that maps command line arguments and their values to their corresponding variables
:: Arguments: flagKey flagValue
:mapargument
	if "%~1"=="-ip" (
		call :testipaddress "%~2" "!IPADDR!"
		set IPADDR=!_RETURN:"=!
	) else (
		if "%~1"=="-delay" (
			call :sanitizenumber "%~2" "!DELAY!"
			set DELAY=!_RETURN:"=!
		) else (
			if "%~1"=="-ex" (
				call :sanitizenumber "%~2" "!EX!"
				set EX=!_RETURN:"=!
			) else (
				if "%~1"=="-good" (
					call :sanitizenumber "%~2" "!GOOD!"
					set GOOD=!_RETURN:"=!
				) else (
					if "%~1"=="-ok" (
						call :sanitizenumber "%~2" "!OK!"
						set OK=!_RETURN:"=!
					) else (
						if "%~1"=="-bad" (
							call :sanitizenumber "%~2" "!BAD!"
							set BAD=!_RETURN:"=!
						) else (
							if "%~1"=="-samplesize" (
								call :sanitizenumber "%~2" "!SAMPLESIZE!"
								set SAMPLESIZE=!_RETURN:"=!
							)
						)
					)
				)
			)
		)
	)

	:: Clear the return variable
	set _RETURN=
	goto :EOF

:: Subroutine that tests if the incoming IP address is valid. Stores a valid address to _RETURN
:: Arguments: givenIPAddress defaultIPAddress
:testipaddress
	call :pingaddress "%~1"

	:: Set the new address and switch it in the loop below if applicable
	set _RETURN=

	for /F "tokens=2,4,5 delims= " %%A in (!TEMPDIR!) do (
		:: Search for a timeout
		echo %%A | findstr /c:"timed" > nul

		if errorlevel 1 (
			:: Search for a failed IP address
			echo %%B | findstr /c:"not" > nul

			if errorlevel 1 (
				:: Search for a valid IP return
				echo %%C | findstr /c:"time=" > nul

				if errorlevel 1 (
					echo This might be a superflous token, so do nothing yet. > nul
				) else (
					:: Detected that this is a valid IP address
					_RETURN="%~1"
				)
			) else (
				set "DISPLAYMSG=IP: '%~1' is not valid. Using IP: '%~2'"
				set CLEARPREVSCREEN=!TRUE!
				set ERRORFLAG=!TRUE!
				set /A "DISPLAYMSG_ROW = 1"
				set /A "DISPLAYMSG_COL = 1"
				set PROGRAMSTATE=PAUSEPROMPT

				set _RETURN="%~2"
			)
		) else (
			set "DISPLAYMSG=IP: '%~1' timed out. Using IP: '%~2'"
			set CLEARPREVSCREEN=!TRUE!
			set ERRORFLAG=!TRUE!
			set /A "DISPLAYMSG_ROW = 1"
			set /A "DISPLAYMSG_COL = 1"
			set PROGRAMSTATE=PAUSEPROMPT

			set _RETURN="%~2"
		)
	)

	:: Handle the case where an unknown response is given
	if not defined _RETURN (
		set "DISPLAYMSG=Unknown response from IP: '%~1'. Using '%~2'"
		set CLEARPREVSCREEN=!TRUE!
		set ERRORFLAG=!TRUE!
		set /A "DISPLAYMSG_ROW = 1"
		set /A "DISPLAYMSG_COL = 1"
		set PROGRAMSTATE=PAUSEPROMPT

		set _RETURN="%~2"
	)

	goto :EOF

:: Subroutine that tests that the incoming argument is a number.
:: Arguments: testNumber defaultValue
:: https://stackoverflow.com/questions/17584282/how-to-check-if-a-parameter-or-variable-is-numeric-in-windows-batch-file
:sanitizenumber
	set _sanitycontainer=

	:: Only adds char to _sanitycontainer if char is not in delims
	for /F "delims=0123456789" %%i in ("%~1") do set _sanitycontainer=%%i

	if defined _sanitycontainer (
		set "DISPLAYMSG=Argument '%~1' is not a valid number. Using '%~2' as the default value."
		set CLEARPREVSCREEN=!TRUE!
		set ERRORFLAG=!TRUE!
		set /A "DISPLAYMSG_ROW = 1"
		set /A "DISPLAYMSG_COL = 1"
		set PROGRAMSTATE=PAUSEPROMPT

		set _RETURN="%~2"
	) else (
		set _RETURN="%~1"
	)

	goto :EOF

:: Subroutine that pings a given address
:: Arguments: ipAddress
:pingaddress
	ping -n !SAMPLESIZE! %~1 > !TEMPDIR! 2>&1

	set _RETURN=
	goto :EOF

:: Displays a message to the screen
:: Arguments: message rowNumber columnNumber clearScreen?
:displaymessage
	set /A "_row = %~2 + 1"
	set /A "_column = %~3 + 1"

	:: Clear the screen if the flag is set
	if "%~4" == "!TRUE!" cls

	:: Move the cursor if row and column are defined
	if defined _row (
		if defined _column (
			echo [%_row%;%_column%H%~1
		) else (
			echo %~1
		)
	) else (
		echo %~1
	)

	set _RETURN=
	goto :EOF

:: Displays a red error message using the displaymessage subroutine
:: Arguments: message rowNumber columnNumber clearScreen?
:displayerror
	call :displaymessage "[1;31m%~1[0m" "%~2" "%~3" "%~4"

	set _RETURN=
	goto :EOF

:: Subroutine that changes the contents and size of the screen based on arguments given
:: Arguments: message rowNumber columnNumber clearScreen? actionAfterDisplay
:updateuserinterface
	:: Calculate the new window size to use with the message
	call :strlen "%~1"
	set _messagelength=!_RETURN:"=!
	set _RETURN=

	:: Sets the new window dimensions
	call :setwindowsizes "%~2" "%~3" !_messagelength!

	:: Displays the given message on the newly resized window
	call :displaymessage "%~1" "%~2" "%~3" "%~4"

	:: Determines the command to run after displaying the message
	call :updateuserinterfacehelper "%~5"

	set _RETURN=
	goto :EOF

:: Same as updateuserinterface, but for errors
:: Arguments: message rowNumber columnNumber clearScreen? actionAfterDisplay
:updateuserinterfaceerror
	:: Calculate the new window size to use with the message
	call :strlen "ERROR - %~1"
	set _messagelength=!_RETURN:"=!
	set _RETURN=

	:: Sets the new window dimensions
	call :setwindowsizes "%~2" "%~3" !_messagelength!

	:: Displays the given message on the newly resized window
	call :displayerror "ERROR - %~1" "%~2" "%~3" "%~4"

	:: Determines the command to run after displaying the message
	call :updateuserinterfacehelper "%~5"

	set _RETURN=
	goto :EOF

:: Action executed after updateuserinterfacexxx is called. Allows for text to be read by a human.
:: Arguments: actionAfterDisplay
:updateuserinterfacehelper
	set _actionafterdisplay="%~1"

	if defined _actionafterdisplay (
		if !_actionafterdisplay! == "%THENPAUSEPROMPT%" (
			pause
		) else (
			if !_actionafterdisplay! == "%THENPAUSENOPROMPT%" (
				pause > nul
			) else (
				if !_actionafterdisplay! == "%THENWAITPROMPT%" (
					timeout /t %WAITPROMPTTIME% /nobreak
				) else (
					if !_actionafterdisplay! == "%THENWAITNOPROMPT!" (
						timeout /t %WAITPROMPTTIME% /nobreak > nul
					)

					:: Treat any other command as "do nothing," which does not interrupt the program
				)
			)
		)
	)

	:: Default to doing nothing if no action is specified

	set _RETURN=
	goto :EOF

:: Calculates the new window dimensions given the padding values
:: Arguments: rowNumber columnNumber messageLength
:setwindowsizes
	set /A "_row = %~1"
	set /A "_column = %~2"
	set /A "_messagelength = %~3"

	if defined _row (
		if defined _column (
			set /A "WIDTH = !_messagelength! + 2 * !_row!"
			set /A "HEIGHT = !DEFAULTHEIGHT! + 2 * !_column!"
		) else (
			set /A "WIDTH = !_messagelength! + 2 * !_row!"
			set HEIGHT=!DEFAULTHEIGHT!
		)
	) else (
		if defined _column (
			set /A "WIDTH = !_messagelength! + 2"
			set /A "HEIGHT = !DEFAULTHEIGHT! + 2 * !_column!"
		) else (
			set /A "WIDTH = !_messagelength! + 2"
			set HEIGHT=!DEFAULTHEIGHT!
		)
	)

	mode !WIDTH!,!HEIGHT!

	set _RETURN=
	goto :EOF

:: Handles keyboard input in a separate thread
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

:: Calculates the length of the string given as an argument
:: Arguments: string
:: Credit https://helloacm.com/get-string-length-using-windows-batch/
:strlen
	set /A "_RETURN = 0"
	set "_tempstr=%~1"
	set "_substr=!_tempstr!"

	:: Removes the first char of the string temp until empty
	:strlenloop
		if defined _substr (
			set _substr=!_substr:~1!
			set /A "_RETURN += 1"
			goto strlenloop
		)

	goto :EOF

:: End of the batch file
endlocal
:END
exit
