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
; Version:           1.04
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
Dim Const $version_num  = "1.04"
Dim Const $version_date = "2009-06-01"
Dim Const $copyright    = "(c) 2009 Frank Glaser"

# There are default 4 icons in EXE so your first icon must have (negative 1-based) index -5:
Dim Const $ico_on  = -5
Dim Const $ico_off = -6
Dim Const $ico_rel = -7
Dim Const $ico_err = -8


###################################
#### Ini File
Dim Const $ini_file = @Workingdir & "\TrayPowerSwitch.ini"
Dim Const $max_par = 19

If FileExists($ini_file) Then
    ;File Exist do nothing
Else
    ;File does not exist
	MsgBox(4096, "TrayPowerSwitch", "Unable to open ini file")
    Exit
EndIf

$load_profile = IniRead($ini_file, "General", "load_profile", "Default")

$read_profile = IniReadSection($ini_file, $load_profile)
If UBound($read_profile) < ($max_par+1) Then
	MsgBox(4096, "TrayPowerSwitch", UBound($read_profile) )
    Exit
EndIf

$name 			= String (IniRead($ini_file, $load_profile, "name", ""))
$exec 			= String (IniRead($ini_file, $load_profile, "exec", ""))
$address 		= String (IniRead($ini_file, $load_profile, "address", ""))
$outlet 		= Int    (IniRead($ini_file, $load_profile, "outlet", ""))
$user 			= String (IniRead($ini_file, $load_profile, "user", ""))
$password 		= String (IniRead($ini_file, $load_profile, "password", ""))
$state 			=        (IniRead($ini_file, $load_profile, "state", ""))
$err_str 		= String (IniRead($ini_file, $load_profile, "err_str", ""))
$timeout 		= Int    (IniRead($ini_file, $load_profile, "timeout", ""))
$updatetime 	= Int    (IniRead($ini_file, $load_profile, "updatetime", ""))
$autotoggle 	=        (IniRead($ini_file, $load_profile, "autotoggle", ""))
$toggletime 	= Int    (IniRead($ini_file, $load_profile, "toggletime", ""))
$autoupdate 	=        (IniRead($ini_file, $load_profile, "autoupdate", ""))
$autupd_time 	= Int    (IniRead($ini_file, $load_profile, "autupd_time", ""))
$state_str_on 	= String (IniRead($ini_file, $load_profile, "state_str_on", ""))
$state_str_off	= String (IniRead($ini_file, $load_profile, "state_str_off", ""))
$get_state 		= String (IniRead($ini_file, $load_profile, "get_state", ""))
$set_state_on 	= String (IniRead($ini_file, $load_profile, "set_state_on", ""))
$set_state_off 	= String (IniRead($ini_file, $load_profile, "set_state_off", ""))


###################################
#### GUI
# Add Tray Items
TraySetIcon(@ScriptFullPath, $ico_rel)

Opt("TrayMenuMode",1)   ; Default tray menu items (Script Paused/Exit) will not be shown.

$autotoggleItem    = TrayCreateItem("Toggle")
If $autotoggle = True Then TrayItemSetState($autotoggleItem, $TRAY_CHECKED)
TrayCreateItem("")
$fixStatusItem     = TrayCreateItem("Update")
$autoStatusItem    = TrayCreateItem("Auto-Update")
If $autotoggle = True Then TrayItemSetState($autoStatusItem, $TRAY_CHECKED)
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


###################################
#### Message Loop
Dim $timerbegin = 0
Dim $timerdiff  = 0

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


###################################
#### Functions
Func switchOutlet($nextstate)

	TraySetIcon(@ScriptFullPath, $ico_rel)

	$state = $nextstate
	;$pid = Run(@ComSpec & " /c " & $set_state & StringFormat("%d",$state), "", @SW_HIDE, $STDERR_MERGED)
	If $state = True Then
		$pid = Run(@ComSpec & " /c " & $set_state_on, "", @SW_HIDE, $STDERR_MERGED)
	Else
		$pid = Run(@ComSpec & " /c " & $set_state_off, "", @SW_HIDE, $STDERR_MERGED)
	EndIf
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
		If StringInStr ( $line, $state_str_on ) <> 0 Then
			$state = True
		ElseIf StringInStr ( $line, $state_str_off ) <> 0 Then
			$state = False
		EndIf
	Wend

	# Status Handling
	If $state = True Then
		TraySetToolTip(StringFormat ("%s %d ON", $name, $outlet))
		TraySetIcon(@ScriptFullPath, $ico_on)
	Else
		TraySetToolTip(StringFormat ("%s %d OFF", $name, $outlet))
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
