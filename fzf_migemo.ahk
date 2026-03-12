#Requires AutoHotkey v2.0


FzfSelect(listObject) {
    ; リストを一時ファイルに書き出す
    tempInput := A_ScriptDir "\fzf_input.txt"
    tempOutput := A_ScriptDir "\fzf_output.txt"

    if(FileExist(tempInput)){
        FileDelete(tempInput)
    }
    if(FileExist(tempOutput)){
        FileDelete(tempOutput)
    }

    if (listObject is Array) {
        content := ""
        for item in listObject
            content .= item "`n"
        FileAppend(Trim(content, "`n"), tempInput, "UTF-8")
    } else {
        FileCopy(listObject,tempInput,1)
        ;tempInput := listObject
    }

    ; 実行コマンドの構築
    ; --cycle, --reverse などはお好みで
    reloadcmd := "reload:for /f \`"delims=\`" %R in ('MigemoClient {q}') do @rg --color=always %R " . tempInput . " || echo NotMatch"
    ;MsgBox reloadcmd
    shellcmd := "chcp 65001" . " & "
    ;shellCmd := shellcmd . 'fzf --reverse --disabled --ansi --query "" '
    shellCmd := shellcmd . 'fzf --disabled --ansi --query "" '
                . '--bind "start:' . reloadcmd . '" '
                . '--bind "change:' . reloadcmd . '" '
                . '> "' tempOutput '"'
    ; cmd.exe を起動して fzf を実行（終了まで待機）
    ;MsgBox shellCmd
    try {
        RunWait(A_ComSpec ' /c ' shellCmd, , "")
        
        ; 結果の読み込み
        if FileExist(tempOutput) {
            result := FileRead(tempOutput, "UTF-8")
            result := Trim(result, "`r`n")
        } else {
            result := ""
        }
    } catch {
        result := ""
    }

    ; 一時ファイルの削除
    if FileExist(tempInput){
        FileDelete(tempInput)
    } 
    if FileExist(tempOutput){
         FileDelete(tempOutput)
    }

    return result
}

; --- 使用例 ---
F1:: {

    RowCount := 100
    DataList := []
    Loop RowCount {
        DataList.Push("Row " A_Index . "Data A-" A_Index)
    }
    ;selected := FzfSelect(myList)
    DataList := ["リンゴ", "バナナ", "ミカン", "スイカ", "メロン"]

    selected := FzfSelect(DataList)

    if (selected != "") {
        MsgBox("選択された項目: " selected)
    } else {
        MsgBox("キャンセルされました")
    }
}