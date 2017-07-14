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

REM Hold the options that are read by the updateuserinterface function 
	:: Initial window width and height values
	set WIDTH=25
	set HEIGHT=5

	:: Padding values to add to the top and bottom of messages displayed.
	set PADDING_TB=0
	set PADDING_LR=0
:: Arguments - <line1> <line2> <line3> ... <lineN>
:updateuserinterface
