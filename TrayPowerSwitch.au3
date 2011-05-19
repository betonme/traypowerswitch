#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_outfile=bin\TrayPowerSwitch.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ----------------------------------------------------------------------------
;
; Copyright Frank Glaser 2009
;
; Version:           0.99
; Last author:       Frank Glaser
; Last changed date: 27.05.2009
;
; AutoIt Version:    3.3.0.0
; SciTE4AutoIt3:     21.05.2009
;
; Script Function:
;   Control Your Power Outlets from Windows Tray.
;
; ----------------------------------------------------------------------------

#Include <Constants.au3>

$timeout 			= 1						; not used yet
$default_exec 	= "USBswitchCmd.exe" 	; Default executable

$exec 	= $default_exec

$outlet_state_1 = False	; State of Cleware Outlet 1

# Commandline Parameter
# excecutable
If $CmdLine[0] > 0 Then $exec = $CmdLine[1]

# Add Tray Items
Opt("TrayMenuMode",1)   ; Default tray menu items (Script Paused/Exit) will not be shown.

$exititem        = TrayCreateItem("Exit")

TraySetState()		; Sets the state of the tray icon.

TraySetClick(8) 	; Sets the clickmode of the tray icon - what mouseclicks will display the tray menu.
					; Pressing secondary mouse button.

# Get Cleware Status
setIcon()

While 1
    $trayevent = TrayGetMsg()

    Select
        Case $trayevent = 0
            ContinueLoop

		Case $trayevent = $TRAY_EVENT_PRIMARYDOWN
			switchOutlet()

        Case $trayevent = $exititem
            ExitLoop
	EndSelect
WEnd

Exit


Func switchOutlet()

if $outlet_state_1 = True Then
		$pid = Run(@ComSpec & " /c " & StringFormat ("%s 0", $exec), "", @SW_HIDE, $STDERR_MERGED)
	Else
		$pid = Run(@ComSpec & " /c " & StringFormat ("%s 1", $exec), "", @SW_HIDE, $STDERR_MERGED)
	EndIf

	While 1
		$line = StdoutRead($pid)

		# Check Errors
		If @error Then ExitLoop

		Sleep(1000) ; sleep one second to get the correct state

		validateLine($line)
	Wend
EndFunc

Func validateLine($line)
	# Check TimeOut
	If StringInStr ( $line, "error" ) <> 0 Then
		MsgBox(0, "Cleware TimeOut", $line)
		Exit
	EndIf

	# Check StdOut - no return value
	$outlet_state_1 = not $outlet_state_1

	setIcon()

EndFunc

Func setIcon()

	# Get Cleware Status
	$pid = Run(@ComSpec & " /c " & StringFormat ("%s -r", $exec), "", @SW_HIDE, $STDERR_MERGED)

	While 1
		$line = StdoutRead($pid)

		# Check Errors
		If @error Then ExitLoop

		# Check TimeOut
		If StringInStr ( $line, "USBswitch not found" ) <> 0 Then
			MsgBox(0, "Cleware not found", $line)
			Exit
		EndIf

		# Check StdOut
		If $line <> "" Then
			If StringInStr ( $line, "0" ) <> 0 Then
				$outlet_state_1 = False
			Else
				$outlet_state_1 = True
			EndIf

			If $outlet_state_1 = True Then
				TraySetToolTip("Cleware 1 On")
				TraySetIcon("button_on.ico",1)
			Else
				TraySetToolTip("Cleware 1 Off")
				TraySetIcon("button_off.ico",1)
			EndIf
		EndIf
	Wend
EndFunc
