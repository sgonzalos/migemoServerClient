#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
Opt("WinTitleMatchMode", 3) ;1=start, 2=subStr, 3=exact, 4=advanced, -1 to -4=Nocase

#include <SendMessage.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>

; --- 1. 受信用に隠しウィンドウを作成 ---
; サーバーが返信先として認識するための窓口です
Local $hGUI = GUICreate("MigemoClientReceiver")
GUIRegisterMsg($WM_COPYDATA, "WM_COPYDATA_Handler") ; データが来たらこの関数を実行

; --- 2. サーバーの特定 ---
Local $hWndServer = WinGetHandle("[TITLE:MigemoServer]")
If @error Then
    MsgBox(16, "Error", "Server not found")
    Exit
EndIf

; --- 3. 検索リクエストの送信 ---
Global $sReceivedData = "" ; 結果を格納するグローバル変数

if($CmdLine[0] = 0 or $CmdLine[1] = "") Then
	_ConsoleWriteUTF8('$')
	Exit
ElseIf(StringLen($CmdLine[1]) <= 2) Then
	_ConsoleWriteUTF8($CmdLine[1])
	Exit
Else
	$query = $CmdLine[1]
EndIf

;Local $query = ($CmdLine[0] > 0) ? $CmdLine[1] : "kanji"

; 送信データの構築
Local $tBuffer = DllStructCreate("byte[" & StringLen($query) * 3 & "]")
Local $iBytes = _StringToUTF8Binary($tBuffer, $query)

Local $tCDS = DllStructCreate("ptr;dword;ptr")
DllStructSetData($tCDS, 1, 0)
DllStructSetData($tCDS, 2, $iBytes)
DllStructSetData($tCDS, 3, DllStructGetPtr($tBuffer))

; SendMessageの第3引数に「自分のウィンドウハンドル($hGUI)」を渡す
; これによりサーバー側が返信先を特定できます
_SendMessage($hWndServer, $WM_COPYDATA, $hGUI, DllStructGetPtr($tCDS))

; --- 4. 結果の表示 ---
; サーバーからの返信（WM_COPYDATA）が来るまで少し待機、または同期処理
If $sReceivedData <> "" Then
    ;MsgBox(64, "Success", "Received: " & $sReceivedData)
	_ConsoleWriteUTF8( $sReceivedData )
	;MsgBox (0,"",$test)
Else
    MsgBox(48, "Timeout", "No response from server")
EndIf

; --- 5. WM_COPYDATAを受け取る関数 ---
Func WM_COPYDATA_Handler($hWnd, $iMsg, $iwParam, $ilParam)
    Local $tCDS = DllStructCreate("ptr;dword;ptr", $ilParam)
    Local $cbData = DllStructGetData($tCDS, 2) ; バイト数
    Local $lpData = DllStructGetData($tCDS, 3) ; データの住所

    ; 受信したバイナリをUTF-8文字列に変換
    Local $tData = DllStructCreate("byte[" & $cbData & "]", $lpData)
    $sReceivedData = BinaryToString(DllStructGetData($tData, 1), 4) ; 4 = UTF-8

    Return True ; 処理完了をOSに通知
EndFunc

; 補助関数：文字列をUTF-8バイナリとして構造体に書き込む
Func _StringToUTF8Binary(ByRef $tStruct, $sString)
    Local $bData = StringToBinary($sString, 4)
    DllStructSetData($tStruct, 1, $bData)
    Return BinaryLen($bData)
EndFunc

Func _ConsoleWriteUTF8($sText)
    Local $dBinary = StringToBinary($sText, 4) ; 4 = UTF-8
    Local $hStdOut = _WinAPI_GetStdHandle(1)   ; 1 = STD_OUTPUT_HANDLE

    ; ハンドルが無効な場合のチェック
    If $hStdOut = 0 Or $hStdOut = -1 Then Return 0

    Local $tBuffer = DllStructCreate("byte[" & BinaryLen($dBinary) & "]")
    DllStructSetData($tBuffer, 1, $dBinary)

    Local $nWritten
    _WinAPI_WriteFile($hStdOut, DllStructGetPtr($tBuffer), BinaryLen($dBinary), $nWritten)

Return $nWritten
EndFunc