#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=TrayPowerSwitch.ico
#AutoIt3Wrapper_outfile=bin\TrayPowerSwitch.exe
#AutoIt3Wrapper_Res_Icon_Add=button_on.ico
#AutoIt3Wrapper_Res_Icon_Add=button_off.ico
#AutoIt3Wrapper_Res_Icon_Add=button_reload.ico
#AutoIt3Wrapper_Res_Icon_Add=button_error.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ----------------------------------------------------------------------------
;
; Copyright Frank Glaser 2009
;
; Version:           1.02
; Last author:       Frank Glaser
; Last changed date: 01.06.2009
; 
; AutoIt Version:    3.3.0.0
; SciTE4AutoIt3:     21.05.2009
; 
; Script Function:
;   Control Your Power Outlets from Windows Tray.
;
; ----------------------------------------------------------------------------


#include <Array.au3>
#Include <Constants.au3>
#include <Timers.au3>

Dim Const $program_name = "TrayPowerSwitch"
Dim Const $version_num  = "1.02"
Dim Const $version_date = "2009-06-01"
Dim Const $copyright    = "(c) 2009 Frank Glaser"

# There are default 4 icons in EXE so your first icon must have (negative 1-based) index -5:
Dim Const $ico_on  = -5
Dim Const $ico_off = -6
Dim Const $ico_rel = -7
Dim Const $ico_err = -8


Dim Const $def_profile 		= 0  				; Default profile
Dim Const $max_prof	    	= 2  				; Max Number profiles

											  ; Profile 0 Cleware,	Profile 1 Infratec
Dim Const $def_exec[$max_prof] 			= ["USBswitchCmd.exe", 	"httpget.exe"] 		; Default executable
Dim Const $def_address[$max_prof]		= ["",					"powerline-01"] 	; Default ip or dns address
Dim Const $def_outlet[$max_prof]		= ["",					1]					; Default Outlet - Values
Dim Const $def_user[$max_prof] 			= ["",					"admin"]			; Default user
Dim Const $def_password[$max_prof] 		= ["",					"admin"]			; Default password
Dim Const $def_state[$max_prof] 		= [False,				False]				; Default state
Dim Const $def_err_str[$max_prof] 		= ["not found",			"error"]			; Default state response string for error
Dim Const $def_timeout[$max_prof] 		= [0,					1]					; Default time in sec before timeout
Dim Const $def_update_time[$max_prof] 	= [400,					100]				; Default time in msec before device updates status
Dim Const $def_toggle[$max_prof] 		= [False,				False]				; Default toggle state
Dim Const $def_toggle_time[$max_prof] 	= [1000,				1000]				; Default time in msec to toggle status
Dim Const $def_autupd[$max_prof] 		= [False,				False]				; Default auto update state
Dim Const $def_autupd_time[$max_prof] 	= [1000,				1000]				; Default time in msec to auto update status

Dim Const $def_state_str[$max_prof] 	= ["1",					": 1"]				; Default state response string for true
Dim Const $def_get_state[$max_prof] 	= [StringFormat ("%s -r", $def_exec[0]), _
											StringFormat ("%s -C%d -t%d ""http://%s/sw?s=0""", $def_exec[1], $def_timeout[1], $def_timeout[1], $def_address[1])]
Dim Const $def_set_state[$max_prof] 	= [StringFormat ("%s ", $def_exec[0]), _
											StringFormat ("%s -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=""", $def_exec[1], $def_timeout[1], $def_timeout[1], $def_address[1], $def_user[1], $def_password[1], $def_outlet[1])]
;"off" = switch off "on" = switch on


$profile	  = $def_profile
$exec	      = $def_exec[$profile]
$address 	  = $def_address[$profile]
$outlet 	  = $def_outlet[$profile]
$user 		  = $def_user[$profile]
$password 	  = $def_password[$profile]
$state 		  = $def_state[$profile]
$err_str	  = $def_err_str[$profile]
$timeout 	  = $def_timeout[$profile]
$updatetime	  = $def_update_time[$profile]
$autotoggle   = $def_toggle[$profile]
$toggletime	  = $def_toggle_time[$profile]
$autoupdate   = $def_autupd[$profile]
$autupd_time  = $def_autupd_time[$profile]
$state_str	  = $def_state_str[$profile]
$get_state 	  = $def_get_state[$profile]
$set_state 	  = $def_set_state[$profile]

$timerbegin = 0
$timerdiff  = 0

# Parse Commandline Parameter
If $CmdLine[0] > 0 Then
	$CmdParam = $CmdLine
	_ArrayDelete($CmdParam, 0)
	FOR $element IN $CmdParam
		$el = StringLeft ($element,2)
		Select
			Case $el = "-l"
				$profile = StringTrimLeft($element,3)
				If $profile < 0 Then $profile = 0
				If $profile >= $max_prof Then $profile = $max_prof-1
				$profile	= $def_profile
				$profile	  = $def_profile
				$exec	      = $def_exec[$profile]
				$address 	  = $def_address[$profile]
				$outlet 	  = $def_outlet[$profile]
				$user 		  = $def_user[$profile]
				$password 	  = $def_password[$profile]
				$state 		  = $def_state[$profile]
				$err_str	  = $def_err_str[$profile]
				$timeout 	  = $def_timeout[$profile]
				$updatetime	  = $def_update_time[$profile]
				$autotoggle   = $def_toggle[$profile]
				$toggletime	  = $def_toggle_time[$profile]
				$autoupdate   = $def_autupd[$profile]
				$autupd_time  = $def_autupd_time[$profile]
				$state_str	  = $def_state_str[$profile]
				$get_state 	  = $def_get_state[$profile]
				$set_state 	  = $def_set_state[$profile]
				ExitLoop
			Case $el = "-e"
				$exec = StringTrimLeft($element,3)
			Case $el = "-a"
				$address = StringTrimLeft($element,3)
			Case $el = "-o"
				$outlet = StringTrimLeft($element,3)
			Case $el = "-u"
				$user = StringTrimLeft($element,3)
			Case $el = "-p"
				$password = StringTrimLeft($element,3)
			Case $el = "-s"
				$state = StringTrimLeft($element,3)
			Case $el = "-?"
				MsgBox(0, 'Help', "Parameter: " & @LF _
								& "-l=" & @TAB & "load profile 0=Infratec 1=Cleware (no further parameters are accepted)" & @LF _
								& "-e=" & @TAB & "executable" & @LF _
								& "-a=" & @TAB & "address" & @LF _
								& "-o=" & @TAB & "outlet" & @LF _
								& "-u=" & @TAB & "user" & @LF _
								& "-p=" & @TAB & "password" & @LF _
								& "-s=" & @TAB & "state")
								#q= quiet
								#x= close after setting state
				Exit
			Case Else
				MsgBox(0, '', StringFormat ("Unknown Parameter: %s", $element) & @LF _
								& "-? for help")
				Exit
		EndSelect
	NEXT
Else
	# No Commandline Parameter
	#Exit
EndIf


# Add Tray Items
TraySetIcon(@ScriptFullPath, $ico_rel)

Opt("TrayMenuMode",1)   ; Default tray menu items (Script Paused/Exit) will not be shown.

$autotoggleItem    = TrayCreateItem("Toggle")
TrayCreateItem("")
$fixStatusItem     = TrayCreateItem("Update")
$autoStatusItem    = TrayCreateItem("Auto-Update")
$showStatusItem    = TrayCreateItem("Show Response")
TrayCreateItem("")
$aboutItem         = TrayCreateItem("About")
TrayCreateItem("")
$exititem          = TrayCreateItem("Exit")

TraySetState()		; Sets the state of the tray icon.

TraySetClick(8) 	; Sets the clickmode of the tray icon - what mouseclicks will display the tray menu.
					; Pressing secondary mouse button.

# Get Outlet Status
setIcon()

# Event Handling Loop
While 1
    $trayevent = TrayGetMsg()

	# auto update state handling
	# has to be done before event handling else it will not update icon if app is out of focus
	If $autoupdate = True Then
		$timerdiff = TimerDiff($timerbegin)
		if ($timerdiff > $autupd_time) Then
			setIcon()
			$timerbegin = TimerInit()
		EndIf
	EndIf

    Select
        Case $trayevent = 0
            ContinueLoop

		Case $trayevent = $autotoggleItem
			$autotoggle = Not $autotoggle
			If $autotoggle = True Then
				TrayItemSetState($autotoggleItem, $TRAY_CHECKED)
				setIcon()
				$timerbegin = TimerInit()
			Else
				TrayItemSetState($autotoggleItem, $TRAY_UNCHECKED)
				setIcon()
			EndIf

		Case $trayevent = $fixStatusItem
            setIcon()
        Case $trayevent = $autoStatusItem
			$autoupdate = Not $autoupdate
			If $autoupdate = True Then
				TrayItemSetState($autoStatusItem, $TRAY_CHECKED)
				setIcon()
			Else
				TrayItemSetState($autoStatusItem, $TRAY_UNCHECKED)
				setIcon()
			EndIf
		Case $trayevent = $showStatusItem
            showStatusString()

        Case $trayevent = $aboutItem
            showVersion()

        Case $trayevent = $exititem
            ExitLoop

		Case $trayevent = $TRAY_EVENT_PRIMARYDOWN
			If $autotoggle = True Then
				switchOutlet(False)
				Sleep($toggletime)
				switchOutlet(True)
			Else
				switchOutlet(Not $state)
			EndIf
	EndSelect

WEnd

Exit



Func switchOutlet($nextstate)

	TraySetIcon(@ScriptFullPath, $ico_rel)

	$state = $nextstate

	$pid = Run(@ComSpec & " /c " & $set_state & StringFormat("%d",$state), "", @SW_HIDE, $STDERR_MERGED)
	ProcessWaitClose ($pid)

	While 1
		$line = StdoutRead($pid)

		# Check Errors
		If @error Then ExitLoop

		# Check StdOut
		If StringInStr ( $line, StringFormat ("Der Befehl ""%s"" ist entweder falsch geschrieben oder\r\nkonnte nicht gefunden werden", $exec) ) <> 0 Then $err = True
		If StringInStr ( $line, $err_str ) <> 0 Then
			TraySetIcon(@ScriptFullPath, $ico_err)
			TraySetToolTip("No Response")
			Return
		EndIf
	Wend

	# Sleep to get the correct state
	Sleep($updatetime)

	# Update Tray Icon
	setIcon()
EndFunc

Func setIcon()
    Local   $err = False
	$state = False

	# Get Outlet Status
	$pid = Run(@ComSpec & " /c " & $get_state, "", @SW_HIDE, $STDERR_MERGED)
	ProcessWaitClose ($pid)

	While 1
		# read from StdOut
		$line = StdoutRead($pid)

		# Check Errors
		If @error Then ExitLoop

		# Check StdOut
		If StringInStr ( $line, StringFormat ("Der Befehl ""%s"" ist entweder falsch geschrieben oder\r\nkonnte nicht gefunden werden", $exec) ) <> 0 Then $err = True
		If StringInStr ( $line, $err_str ) <> 0 Then $err = True

		# Check Status
		If StringInStr ( $line, $state_str ) <> 0 Then
			$state = True
		EndIf
	Wend

	# Status Handling
	If $state = True Then
		TraySetToolTip(StringFormat ("Outlet %d ON", $outlet))
		TraySetIcon(@ScriptFullPath, $ico_on)
	Else
		TraySetToolTip(StringFormat ("Outlet %d OFF", $outlet))
		TraySetIcon(@ScriptFullPath, $ico_off)
	EndIf

	# $error Handling
	If $err = True Then
		TraySetIcon(@ScriptFullPath, $ico_err)
		TraySetToolTip("No Response")
		Return
	Endif
EndFunc

Func showStatusString ()
    Local $pid, $line, $response = ""

    # Get Infratec Status
	$pid = Run(@ComSpec & " /c " & $get_state, "", @SW_HIDE, $STDERR_MERGED)
	ProcessWaitClose ($pid)

    if $pid = 0 Then
        MsgBox(4096, "Error report", StringFormat("%d", @error), 10)
        Return
    EndIf

    While 1
        $line = StdoutRead($pid)

        If @error Then ExitLoop
        $response = $response & $line
    WEnd

	setIcon()
	MsgBox(4096, "Status report", $response)

EndFunc

Func showVersion ()
    Local   $text
    $text = StringFormat($program_name & "V" & $version_num & "\nBuilt " & $version_date & "\n" & $copyright)
    MsgBox(4096, $program_name & " V" & $version_num, $text)
EndFunc