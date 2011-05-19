#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_outfile=bin\TrayPowerSwitch.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ----------------------------------------------------------------------------
;
; Copyright Frank Glaser 2009
;
; Version:           1.00
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

$timeout 			= 1
$default_address 	= "powerline-01" 	; Default ip or dns address
$default_outlet 	= 1					; Default Infratec Outlet - Values [1,2]
$default_user 		= "admin"			; Default user
$default_password 	= "admin"			; Default password

$address 	= $default_address
$outlet 	= $default_outlet
$user 		= $default_user
$password 	= $default_password

$infratec_state_1 = False	; State of Infratec Outlet 1
$infratec_state_2 = False	; State of Infratec Outlet 2

# Commandline Parameter
# address
If $CmdLine[0] > 0 Then $address = $CmdLine[1]
# outlet
If $CmdLine[0] > 1 Then $outlet = $CmdLine[2]
# user
If $CmdLine[0] > 2 Then $user = $CmdLine[3]
# password
If $CmdLine[0] > 3 Then $password = $CmdLine[4]

# Add Tray Items
Opt("TrayMenuMode",1)   ; Default tray menu items (Script Paused/Exit) will not be shown.

$chkitem1        = TrayCreateItem("Infratec 1")
$chkitem2        = TrayCreateItem("Infratec 2")
TrayCreateItem("")
$exititem        = TrayCreateItem("Exit")

If $outlet = 1 Then
	TrayItemSetState($chkitem1,$TRAY_CHECKED)
	TrayItemSetState($chkitem2,$TRAY_UNCHECKED)
Else
	TrayItemSetState($chkitem1,$TRAY_UNCHECKED)
	TrayItemSetState($chkitem2,$TRAY_CHECKED)
EndIf

TraySetState()		; Sets the state of the tray icon.

TraySetClick(8) 	; Sets the clickmode of the tray icon - what mouseclicks will display the tray menu.
					; Pressing secondary mouse button.

# Get Infratec Status
setIcon()

While 1
    $trayevent = TrayGetMsg()

    Select
        Case $trayevent = 0
            ContinueLoop

        Case $trayevent = $chkitem1
			$outlet = 1
			TrayItemSetState($chkitem1,$TRAY_CHECKED)
			TrayItemSetState($chkitem2,$TRAY_UNCHECKED)
			setIcon()

        Case $trayevent = $chkitem2
			$outlet = 2
			TrayItemSetState($chkitem1,$TRAY_UNCHECKED)
			TrayItemSetState($chkitem2,$TRAY_CHECKED)
			setIcon()

		Case $trayevent = $TRAY_EVENT_PRIMARYDOWN
			switchInfratec()

        Case $trayevent = $exititem
            ExitLoop
	EndSelect
WEnd

Exit


Func switchInfratec()
	If $outlet = 1 Then
		if $infratec_state_1 = True Then
			$pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=off""", $timeout, $timeout, $address, $user, $password, $outlet), "", @SW_HIDE, $STDERR_MERGED)
		Else
			$pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=on""", $timeout, $timeout, $address, $user, $password, $outlet), "", @SW_HIDE, $STDERR_MERGED)
		EndIf
	Else
		if $infratec_state_2 = True Then
			$pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=off""", $timeout, $timeout, $address, $user, $password, $outlet), "", @SW_HIDE, $STDERR_MERGED)
		Else
			$pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=on""", $timeout, $timeout, $address, $user, $password, $outlet), "", @SW_HIDE, $STDERR_MERGED)
		EndIf
	EndIf

	While 1
		$line = StdoutRead($pid)

		# Check Errors
		If @error Then ExitLoop

		validateLine($line)
	Wend
EndFunc

Func validateLine($line)
	# Check TimeOut
	If StringInStr ( $line, "error" ) <> 0 Then
		MsgBox(0, "Infratec TimeOut", $line)
		Exit
	EndIf

	# Check StdOut
	If $line <> "" Then

		If $outlet = 1 Then
			$infratec_state_1 = not $infratec_state_1
		Else
			$infratec_state_2 = not $infratec_state_2
		EndIf
		setIcon()
	EndIf
EndFunc

Func setIcon()

	# Get Infratec Status
	$pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?s=0""", $timeout, $timeout, $address), "", @SW_HIDE, $STDERR_MERGED)

	While 1
		$line = StdoutRead($pid)

		# Check Errors
		If @error Then ExitLoop

		# Check TimeOut
		If StringInStr ( $line, "error" ) <> 0 Then
			MsgBox(0, "Infratec TimeOut", $line)
			Exit
		EndIf

		# Check StdOut
		If $line <> "" Then
			If StringInStr ( $line, "Out 1: 0" ) <> 0 Then
				$infratec_state_1 = False
			Else
				$infratec_state_1 = True
			EndIf
			If StringInStr ( $line, "Out 2: 0" ) <> 0 Then
				$infratec_state_2 = False
			Else
				$infratec_state_2 = True
			EndIf

			If $outlet = 1 Then
				If $infratec_state_1 = True Then
					TraySetToolTip("Infratec 1 On")
					TraySetIcon("button_on.ico",1)
				Else
					TraySetToolTip("Infratec 1 Off")
					TraySetIcon("button_off.ico",1)
				EndIf
			Else
				If $infratec_state_2 = True Then
					TraySetToolTip("Infratec 2 On")
					TraySetIcon("button_on.ico",1)
				Else
					TraySetToolTip("Infratec 2 Off")
					TraySetIcon("button_off.ico",1)
				EndIf
			EndIf
		EndIf
	Wend
EndFunc
