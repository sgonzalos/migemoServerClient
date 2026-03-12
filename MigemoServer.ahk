#Requires AutoHotkey v2.0
#SingleInstance Force

#Include migemo.ahk

Tray := A_TrayMenu ; For convenience.
Tray.Delete() ; Delete the standard items.
Tray.Add("Info", TrayInfo)
Tray.Add("Exit", TrayExit)

mig := Migemo()

; WM_COPYDATA (0x4A) メッセージを受け取ったら ReceiveQuery 関数を実行
OnMessage(0x4A, ReceiveQuery)

; サーバーが起動したことを通知（タイトルを固定するとクライアントが見つけやすい）
MyGui := Gui()
MyGui.Title := "MigemoServer"

TrayInfo()

#ESC::
{
    TrayInfo()
}

; --- 2. メッセージ受信関数 ---
ReceiveQuery(wParam, lParam, msg, hwnd) {

    ; lParam は COPYDATASTRUCT 構造体へのポインタ
    cbData := NumGet(lParam, A_PtrSize, "UInt")      ; 送られてきたデータのサイズ
    lpData := NumGet(lParam, A_PtrSize * 2, "UPtr")  ; データが置いてある住所
    
    ; クライアントから送られてきた文字列を取得
    queryStr := StrGet(lpData, cbData, "UTF-8")
    
    ; Migemoで検索実行
    resultRegex := mig.Query(queryStr)
    
    clientHwnd := wParam
    SendBack(clientHwnd, resultRegex)

    return 1
}

SendBack(targetHwnd, str) {
    buf := Buffer(StrPut(str, "UTF-8"))
    StrPut(str, buf, "UTF-8")
    cds := Buffer(A_PtrSize * 3)
    NumPut("UPtr", 0, cds, 0)
    NumPut("UInt", buf.Size, cds, A_PtrSize)
    NumPut("UPtr", buf.Ptr, cds, A_PtrSize * 2)
    SendMessage(0x4A, A_ScriptHwnd, cds.Ptr, targetHwnd)
}

TrayExit(*){
    ExitApp()
}

TrayInfo(*){
    TrayTip("MigemoServer is running" , , 1 + 16)
}