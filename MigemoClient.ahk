#Requires AutoHotkey v2.0
;@Ahk2Exe-ConsoleApp
DetectHiddenWindows true

;query := A_Args.Length > 0 ? A_Args[1] : "kanji"
OnMessage(0x4A, ReceiveResult)

; 1. サーバーのウィンドウ（待ち受け役）を見つける
if !(serverHwnd := WinExist("MigemoServer")) {
    MsgBox "サーバーが起動していません"
    ExitApp
}

if(A_Args.Length = 0 OR A_Args[1] =""){
    OutputStdout("$")
    ExitApp
}else if(StrLen(A_Args[1]) <= 2){
    OutputStdout(A_Args[1])
    ExitApp
}else{
    query := A_Args[1]
}

; 2. 送りたい文字列をバイナリ（UTF-8）に変換して準備
buf := Buffer(StrPut(query, "UTF-8"))
StrPut(query, buf, "UTF-8")

; 3. COPYDATASTRUCT（データの送り状）を作成
; PtrSize * 3 の領域を確保（dwData, cbData, lpData の3要素）
cds := Buffer(A_PtrSize * 3)
NumPut("UPtr", 0,        cds, 0)            ; dwData: 識別番号（自由に使ってOK）
NumPut("UInt", buf.Size, cds, A_PtrSize)    ; cbData: 送るデータのバイト数
NumPut("UPtr", buf.Ptr,  cds, A_PtrSize * 2) ; lpData: データが入っている場所の住所

; 4. WM_COPYDATA (0x4A) メッセージを送信
; SendMessageは「返事（返り値）」が来るまで待ってくれる
resultPtr := SendMessage(0x4A, A_ScriptHwnd, cds.Ptr, serverHwnd)

ExitApp

; --- 2. メッセージ受信関数 ---
ReceiveResult(wParam, lParam, msg, hwnd) {

   ; lParam は COPYDATASTRUCT 構造体へのポインタ
    cbData := NumGet(lParam, A_PtrSize, "UInt")      ; 送られてきたデータのサイズ
    lpData := NumGet(lParam, A_PtrSize * 2, "UPtr")  ; データが置いてある住所
    
    ; クライアントから送られてきた文字列を取得
    migemoStr := StrGet(lpData, cbData, "UTF-8")
    OutputStdout(migemoStr)

    return 1
}

OutputStdout(OutputString){

    try stdout := FileOpen("*", "w" ,"UTF-8")
    catch {
        MsgBox "stdout がありません（パイプで実行されていません）"
        ExitApp
    }
    stdout.WriteLine(OutputString)
    stdout.Close()
}