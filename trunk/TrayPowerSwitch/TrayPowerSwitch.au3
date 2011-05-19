#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=TrayPowerSwitch.ico
#AutoIt3Wrapper_outfile=bin\TrayPowerSwitch.exe
#AutoIt3Wrapper_Compression=0
#AutoIt3Wrapper_Res_Icon_Add=button_on.ico
#AutoIt3Wrapper_Res_Icon_Add=button_off.ico
#AutoIt3Wrapper_Res_Icon_Add=button_reload.ico
#AutoIt3Wrapper_Res_Icon_Add=button_error.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ----------------------------------------------------------------------------
;
; Copyright Frank Glaser 2009
;
; Version:           1.07
; Last author:       Frank Glaser
; Last changed date: 20.11.2009
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

; Program Version Information
Dim Const $program_name = "TrayPowerSwitch"
Dim Const $version_num  = "1.07"
Dim Const $version_date = "2009-11-20"
Dim Const $copyright    = "(c) 2009 Frank Glaser"

; There are default 4 icons in EXE so your first icon must have (negative 1-based) index -5:
Dim Const $ico_on  = -5
Dim Const $ico_off = -6
Dim Const $ico_rel = -7
Dim Const $ico_err = -8

; Outlet state
Dim $state = 0

; Config variables
Dim Const $ini_file = @Workingdir & "\TrayPowerSwitch.ini"
Dim Const $max_par = 14
Dim $name, $exec, $outlet, $err_str, $updatetime, $autotoggle, $toggletime, $autoupdate, $autupd_time, $state_str_on, $state_str_off, $get_state, $set_state_on, $set_state_off



###################################
#### Parse Commandline Parameter
Dim $profile

parseCmdPar()


###################################
#### Ini File
Dim $config_profiles

readConfig()


###################################
#### GUI: Tray Items
Dim $configItem[UBound($config_profiles)]
Dim $autotoggleItem
Dim $fixStatusItem
Dim $autoStatusItem
Dim $showStatusItem
Dim $aboutItem
Dim $exititem

setLoadIcon()
createTrayApp()


###################################
#### Configuration
loadProfile($profile)	; Load profile parameter
setIcon()				; Set Icon according to outlet status


###################################
#### Message Loop
main()

Exit


###################################
#### Functions
Func main ()
	Local $timerbegin = 0
	Local $timerdiff  = 0

	While 1
		$trayevent = TrayGetMsg()

		; auto update state handling
		; has to be done before event handling else it will not update icon if app is out of focus
		If $autoupdate = True Then
			$timerdiff = TimerDiff($timerbegin)
			if ($timerdiff > $autupd_time) Then
				setIcon()
				$timerbegin = TimerInit()
			EndIf
		EndIf

		; load profile handling
		$i = _ArraySearch($configItem, $trayevent)
		If 0 <= $i Then
			$profile = $config_profiles[$i]
			setLoadIcon()
			loadProfile ($profile)
			setIcon()
			saveConfig()
			ContinueLoop
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
				setLoadIcon()
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
				setLoadIcon()
				showStatusString()
				setIcon()

			Case $trayevent = $aboutItem
				showVersion()

			Case $trayevent = $exititem
				ExitLoop

			Case $trayevent = $TRAY_EVENT_PRIMARYDOWN
				If $autotoggle = True Then
					setLoadIcon()
					switchOutlet(False)
					setIcon()
					Sleep($toggletime)
					setLoadIcon()
					switchOutlet(True)
					setIcon()
				Else
					setLoadIcon()
					switchOutlet(Not $state)
					setIcon()
				EndIf
		EndSelect

	WEnd
EndFunc


Func switchOutlet ($nextstate)
	$state = $nextstate
	If $state = True Then
		$pid = Run(@ComSpec & " /c " & $set_state_on, "", @SW_HIDE, $STDERR_MERGED)
	Else
		$pid = Run(@ComSpec & " /c " & $set_state_off, "", @SW_HIDE, $STDERR_MERGED)
	EndIf
	ProcessWaitClose ($pid)

	While 1
		; read from StdOut
		$line = StdoutRead($pid)

		; Check Errors
		If @error Then ExitLoop

		; Check StdOut
		If StringInStr ( $line, StringFormat ("Der Befehl ""%s"" ist entweder falsch geschrieben oder\r\nkonnte nicht gefunden werden", $exec) ) <> 0 Then $err = True
		If StringInStr ( $line, $err_str ) <> 0 Then
			TraySetIcon(@ScriptFullPath, $ico_err)
			TraySetToolTip("No Response")
			Return
		EndIf
	Wend

	; Sleep to get the correct state
	Sleep($updatetime)
EndFunc


Func setLoadIcon ()
	TraySetIcon(@ScriptFullPath, $ico_rel)
EndFunc


Func setIcon ()
	Local $pid, $line, $response
	Local   $err = False

	$state = False

	; Get Outlet Status
	$pid = Run(@ComSpec & " /c " & $get_state, "", @SW_HIDE, $STDERR_MERGED)
	ProcessWaitClose ($pid)

	While 1
		; read from StdOut
		$line = StdoutRead($pid)

		; Check Errors
		If @error Then ExitLoop

		; Check StdOut
		If StringInStr ( $line, StringFormat ("Der Befehl ""%s"" ist entweder falsch geschrieben oder\r\nkonnte nicht gefunden werden", $exec) ) <> 0 Then $err = True
		If StringInStr ( $line, $err_str ) <> 0 Then $err = True

        $response = $response & $line
	Wend

	; Check Status
	If StringInStr ( $response, $state_str_on ) <> 0 Then
		$state = True
	ElseIf StringInStr ( $response, $state_str_off ) <> 0 Then
		$state = False
	EndIf

	; Status Handling
	If $state = True Then
		TraySetToolTip(StringFormat ("%s %d ON", $name, $outlet))
		TraySetIcon(@ScriptFullPath, $ico_on)
	Else
		TraySetToolTip(StringFormat ("%s %d OFF", $name, $outlet))
		TraySetIcon(@ScriptFullPath, $ico_off)
	EndIf

	; Error Handling
	If $err = True Then
		TraySetIcon(@ScriptFullPath, $ico_err)
		TraySetToolTip("No Response")
		Return
	Endif
EndFunc


Func showStatusString ()
    Local $pid, $line, $response = ""

	; Get Outlet Status
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

	MsgBox(4096, "Status report", $response)
EndFunc


Func showVersion ()
    Local   $text
    $text = StringFormat($program_name & "V" & $version_num & "\nBuilt " & $version_date & "\n" & $copyright)
    MsgBox(4096, $program_name & " V" & $version_num, $text)
EndFunc


Func parseCmdPar ()
	If $CmdLine[0] > 0 Then
		Local $CmdParam = $CmdLine
		_ArrayDelete($CmdParam, 0)
		FOR $element IN $CmdParam
			Local $el = StringLeft ($element,2)
			Select
				Case $el = "-p"
					; Commandline Parameter load_profil overwrites ini file load_profile parameter
					$profile = StringTrimLeft($element,3)
				Case $el = "-?"
					MsgBox(4096, 'Help', "Parameter: " & @LF _
									& "-p=" & @TAB & "load profile" )
					Exit
				Case Else
					MsgBox(4096, '', StringFormat ("Unknown Parameter: %s", $element) & @LF _
									& "-? for help")
					Exit
			EndSelect
		NEXT
	Else
		;No Commandline Parameter do nothing
	EndIf
EndFunc


Func readConfig ()
	If FileExists($ini_file) Then
		;File Exist do nothing
	Else
		;File does not exist
		MsgBox(4096, "TrayPowerSwitch", "Unable to open ini file")
		Exit
	EndIf

	$config_profiles = IniReadSectionNames ($ini_file)
	If @error Then
		MsgBox(4096, "TrayPowerSwitch", "Error occurred, probably no INI file")
		Exit
	Else
		_ArrayDelete($config_profiles, 0)
		_ArrayDelete($config_profiles, 0)
	EndIf

	If $profile = '' Then
		$profile = IniRead($ini_file, "General", "load_profile", "Default")
	EndIf

	Local $read_profile = IniReadSection($ini_file, $profile)
	If UBound($read_profile) < ($max_par+1) Then
		MsgBox(4096, "TrayPowerSwitch", "Profile incomplete or missing" )
		Exit
	EndIf
EndFunc


Func saveConfig ()
	IniWrite($ini_file, "General", "load_profile", $profile)
EndFunc


Func loadProfile ($profile)
	$name 			= String (IniRead($ini_file, $profile, "name", ""))
	$exec 			= String (IniRead($ini_file, $profile, "exec", ""))
	$outlet 		= Int    (IniRead($ini_file, $profile, "outlet", ""))
	$err_str 		= String (IniRead($ini_file, $profile, "err_str", ""))
	$updatetime 	= Int    (IniRead($ini_file, $profile, "updatetime", ""))
	$autotoggle 	=        (IniRead($ini_file, $profile, "autotoggle", ""))
	$toggletime 	= Int    (IniRead($ini_file, $profile, "toggletime", ""))
	$autoupdate 	=        (IniRead($ini_file, $profile, "autoupdate", ""))
	$autupd_time 	= Int    (IniRead($ini_file, $profile, "autupd_time", ""))
	$state_str_on 	= String (IniRead($ini_file, $profile, "state_str_on", ""))
	$state_str_off	= String (IniRead($ini_file, $profile, "state_str_off", ""))
	$get_state 		= String (IniRead($ini_file, $profile, "get_state", ""))
	$set_state_on 	= String (IniRead($ini_file, $profile, "set_state_on", ""))
	$set_state_off 	= String (IniRead($ini_file, $profile, "set_state_off", ""))

	$i = _ArraySearch($config_profiles, $profile)
	If 0 <= $i Then
		FOR $element IN $configItem
			If $element = $configItem[$i] Then
				TrayItemSetState($element, $TRAY_CHECKED)
			Else
				TrayItemSetState($element, $TRAY_UNCHECKED)
			EndIf
		NEXT
	EndIf
EndFunc


Func createTrayApp ()
	Opt("TrayMenuMode",1)   ; Default tray menu items (Script Paused/Exit) will not be shown.

	FOR $element IN $config_profiles
		_ArrayPush($configItem, TrayCreateItem($element))
	NEXT
	TrayCreateItem("")
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
EndFunc
