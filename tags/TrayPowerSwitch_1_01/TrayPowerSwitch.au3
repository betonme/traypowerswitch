#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_outfile=bin\TrayPowerSwitch.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; ----------------------------------------------------------------------------
;
; Copyright Frank Glaser 2009
;
; Version:           1.01
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

Dim Const $program_name = "TrayPowerSwitch"
Dim Const $version_num  = "1.01"
Dim Const $version_date = "2009-06-27"
Dim Const $copyright    = "(c) 2009 Frank Glaser"

$infratec_type = 1
    ; 0 = 2 Outlets, Master/Slave
    ; 1 = 4 Outlets (PM 4 IP)

If $infratec_type = 0 Then

    $timeout 			= 1
    $default_address 	= "powerline-01" 	; Default ip or dns address
    $default_outlet 	= 1					; Default Infratec Outlet - Values [1,2]
    $default_user 		= "admin"			; Default user
    $default_password 	= "admin"			; Default password

ElseIf $infratec_type = 1 Then

    $timeout 			= 4
    $default_address 	= "ipswitch" 	; Default ip or dns address
    $default_outlet 	= 3					; Default Infratec Outlet - Values [1,2[3,4]]
    $default_user 		= "admin"			; Default user
    $default_password 	= "admin"			; Default password
EndIf

$address 	= $default_address
$outlet 	= $default_outlet
$user 		= $default_user
$password 	= $default_password

If $infratec_type = 0 Then
    $numOutlets = 2
Else
    $numOutlets = 4
EndIf

; Note: Index 0 of any arrays defined are not used
Dim $outlet_name[5]
if $infratec_type = 0 Then
    $outlet_name[1] = "Infratec 1"
    $outlet_name[2] = "Infratec 2"
    $outlet_name[3] = "-"
    $outlet_name[4] = "-"
Else
    $outlet_name[1] = "ETMC"
    $outlet_name[2] = "Switch"
    $outlet_name[3] = "MMC"
    $outlet_name[4] = "HIOB"
EndIf

Dim $infratec_state[5]
$infratec_state[1] = False	; State of Infratec Outlet 1
$infratec_state[2] = False	; State of Infratec Outlet 2
$infratec_state[3] = False	; State of Infratec Outlet 3
$infratec_state[4] = False	; State of Infratec Outlet 4

Dim $stateString[5]
If $infratec_type = 0 Then
    $stateString[1] = "Out 1"
    $stateString[2] = "Out 2"
    $stateString[3] = "Out 3"
    $stateString[4] = "Out 4"
Else
    $stateString[1] = $outlet_name[1]   ; PM 4 IP reports names
    $stateString[2] = $outlet_name[2]
    $stateString[3] = $outlet_name[3]
    $stateString[4] = $outlet_name[4]
EndIf

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

Dim $chkitem[5]
If $infratec_type <> 1 Then
    $chkitem[1]      = TrayCreateItem("Infratec 1")
    $chkitem[2]      = TrayCreateItem("Infratec 2")
    $chkitem[3]      = 0
    $chkitem[4]      = 0
Else
    $chkitem[1]  = TrayCreateItem($outlet_name[1])
    $chkitem[2]  = TrayCreateItem($outlet_name[2])
    $chkitem[3]  = TrayCreateItem($outlet_name[3])
    $chkitem[4]  = TrayCreateItem($outlet_name[4])
EndIf
TrayCreateItem("")
$fixStatusItem   = TrayCreateItem("Fix Status (reread)")
$showStatusItem  = TrayCreateItem("Show status response string")
$aboutItem       = TrayCreateItem("About")
TrayCreateItem("")
$exititem        = TrayCreateItem("Exit")

TrayItemSetState($chkitem[1],$TRAY_UNCHECKED)
TrayItemSetState($chkitem[2],$TRAY_UNCHECKED)
If $infratec_type = 1 Then
    TrayItemSetState($chkitem[3],$TRAY_UNCHECKED)
    TrayItemSetState($chkitem[4],$TRAY_UNCHECKED)
EndIf

TrayItemSetState($chkitem[$outlet], $TRAY_CHECKED)

TraySetState()		; Sets the state of the tray icon.

TraySetClick(8) 	; Sets the clickmode of the tray icon - what mouseclicks will display the tray menu.
                    ; Pressing secondary mouse button.

; Adjust TrayMenuMode to not automatically uncheck menu items
; when clicked
AutoItSetOption("TrayMenuMode", 1 + 2 + 8)

# Get Infratec Status
setIcon()

While 1
    $lastOutlet = $outlet
    $trayevent = TrayGetMsg()

    Select
        Case $trayevent = 0
            ContinueLoop
        Case $trayevent = $chkitem[1]
            $outlet = 1
        Case $trayevent = $chkitem[2]
            $outlet = 2
        Case $trayevent = $chkitem[3]
            $outlet = 3
        Case $trayevent = $chkitem[4]
            $outlet = 4

        Case $trayevent = $fixStatusItem
            setIcon()
        Case $trayevent = $showStatusItem
            showStatusString()
        Case $trayevent = $aboutItem
            showVersion()

        Case $trayevent = $TRAY_EVENT_PRIMARYDOWN
            switchInfratec()

        Case $trayevent = $exititem
            ExitLoop
    EndSelect

    if $outlet <> $lastOutlet Then
        changeSelection($outlet)
    EndIf
WEnd

Exit

Func changeSelection($thisOutlet)
    For $ii = 1 To 4
        if $thisOutlet = $ii Then
            TrayItemSetState($chkitem[$ii],$TRAY_CHECKED)
        Else
            TrayItemSetState($chkitem[$ii],$TRAY_UNCHECKED)
        EndIf
        setIcon()
    Next
EndFunc

Func switchOutlet($thisOutlet, $thisState)

    if $thisState = True Then
        $pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=off""", _
            $timeout, $timeout, $address, $user, $password, $thisOutlet), "", @SW_HIDE, $STDERR_MERGED)
    Else
        $pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?u=%s&p=%s&o=%d&f=on""",  _
            $timeout, $timeout, $address, $user, $password, $thisOutlet), "", @SW_HIDE, $STDERR_MERGED)
    EndIf
    if $pid = 0 Then
        MsgBox(4096, "switchOutlet: httpget Error", StringFormat("httpget returned error %d !", @error), 10)
        Return
    EndIf

    While 1
        $line = StdoutRead($pid)

        # Check Errors
        If @error Then
#            MsgBox(4096, "switchOutlet Error", StringFormat("switchOutlet StdoutRead Error %d !", @error))
            ExitLoop
        EndIf

        validateLine($line, $thisOutlet)
    Wend

EndFunc

Func switchInfratec()
    switchOutlet($outlet, $infratec_state[$outlet])
EndFunc

Func validateLine($line, $thisOutlet)
    # Check TimeOut
    If StringInStr ( $line, "error" ) <> 0 Then
        TraySetIcon("warning",1)
        MsgBox(0, "Infratec Error", "Error reported: " & $line)
        Exit
    EndIf

    # Check StdOut
    If $line <> "" Then
        $infratec_state[$thisOutlet] = not $infratec_state[$thisOutlet]
        setIcon()
    EndIf
EndFunc

Func showStatusString ()
    Local $pid, $line, $response = ""

    # Get Infratec Status
    $pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?s=0""", $timeout, $timeout, $address), "", @SW_HIDE, $STDERR_MERGED)
    if $pid = 0 Then
        MsgBox(4096, "showStatus: httpget Error", StringFormat("httpget returned error %d !", @error), 10)
        Return
    EndIf
    While 1
        $line = StdoutRead($pid)
        If @error Then
            # MsgBox(4096, "setIcon: Error", StringFormat("StdoutRead Error %d !", @error))
            # TraySetIcon("warning",1)
            ExitLoop
        EndIf
        $response = $response & $line
    WEnd
    MsgBox(4096, "showStatus: Status string", "Infratec reports: " & $response)

EndFunc

Func showVersion ()
    Local   $text

    $text = StringFormat($program_name & "V" & $version_num & "\nBuilt " & $version_date & "\n" & $copyright)
    MsgBox(4096, $program_name & " V" & $version_num, $text)
EndFunc

Func setIcon()
    Local   $toolTip
    Local   $ii

    # Get Infratec Status
    $pid = Run(@ComSpec & " /c " & StringFormat ("httpget -C%d -t%d ""http://%s/sw?s=0""", $timeout, $timeout, $address), "", @SW_HIDE, $STDERR_MERGED)
    if $pid = 0 Then
        MsgBox(4096, "setIcon: httpget Error", StringFormat("httpget returned error %d !", @error), 10)
        Return
    EndIf

    While 1
        $line = StdoutRead($pid)
#        MsgBox(4096, "httget output", $line)

        # Check Errors
        If @error Then
            # MsgBox(4096, "setIcon: Error", StringFormat("StdoutRead Error %d !", @error))
            # TraySetIcon("warning",1)
            ExitLoop
        EndIf

        # Check TimeOut
        If StringInStr ( $line, "error" ) <> 0 Then
            TraySetIcon("warning",1)
            MsgBox(0, "setIcon: Error", "Infratec error indicated: " & $line, 30)
            Exit
        EndIf

        # Check StdOut
        If $line <> "" Then
            For $ii = 1 to $numOutlets
                If StringInStr ( $line, $stateString[$ii] & ": 1" ) <> 0 Then
                    $infratec_state[$ii] = True
                Else
                    $infratec_state[$ii] = False
                EndIf
            Next

            If $infratec_state[$outlet] = True Then
                $toolTip = $outlet_name[$outlet] & " ON"
                TraySetIcon("button_on.ico",1)
            Else
                $toolTip = $outlet_name[$outlet] & " OFF"
                TraySetIcon("button_off.ico",1)
            EndIf
            TraySetToolTip($toolTip)

        EndIf
    Wend
EndFunc
