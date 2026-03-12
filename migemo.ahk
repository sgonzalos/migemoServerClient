#Requires AutoHotkey v2.0

/*
try {
    ; インスタンス化 (辞書が ./dict/migemo-dict にある想定)
    mig := Migemo()

    ; 検索対象のサンプルテキスト
    targetText := "AutoHotkeyは非常に強力な自動化ツールです。クラスも使えます。"

    ; ユーザー入力
    userInput := InputBox("検索したいキーワードをローマ字で入力", "Migemo検索", "w300 h130").Value
    
    if userInput != "" {
        ; Migemoで正規表現を生成
        pattern := mig.Query(userInput)
        
        MsgBox("生成された正規表現:`n" . pattern)

        ; 実際に検索してみる
        if RegExMatch(targetText, pattern, &match) {
            MsgBox("マッチしました！`n見つかった文字列: " . match[0])
        } else {
            MsgBox("マッチするものが見つかりませんでした。")
        }
    }
} catch Error as e {
    MsgBox("エラーが発生しました:`n" . e.Message)
}
*/

class Migemo {
    static DLL_NAME := "migemo.dll"
    
    __New(dllPath := "", dictPath := "dict/migemo-dict") {
        this.hModule := 0
        this.pMigemo := 0
        
        ; 1. DLLのロード
        dllFullPath := dllPath == "" ? A_ScriptDir "\" . Migemo.DLL_NAME : dllPath
        this.hModule := DllCall("LoadLibrary", "Str", dllFullPath, "Ptr")
        
        if !this.hModule
            throw Error("DLLの読み込みに失敗しました: " . dllFullPath)
        
        ; 2. Migemoオブジェクトの作成
        this.pMigemo := DllCall("migemo.dll\migemo_open", "AStr", dictPath, "Ptr")
        if !this.pMigemo
            throw Error("Migemoの初期化に失敗しました。辞書パスを確認してください。")
    }

    ; クエリから正規表現パターンを生成
	Query(input) {
        if !this.pMigemo
            return ""
        
        ; migemo_query は結果のポインタを返す
        pResult := DllCall("migemo.dll\migemo_query", "Ptr", this.pMigemo, "AStr", input, "Ptr")
        if !pResult
            return ""
            
        ; 1. 文字列をAHKの変数として取得 (CP0 はシステムのアンシコードページ、環境によりUTF-8)
        resultStr := StrGet(pResult, "UTF-8")
        
        ; 2. 【重要】取得したメモリを即座に解放
        DllCall("migemo.dll\migemo_release", "Ptr", this.pMigemo, "Ptr", pResult)

		return resultStr
	}

    ; リソースの解放
    __Delete() {
        if this.pMigemo {
            DllCall("migemo.dll\migemo_close", "Ptr", this.pMigemo)
            this.pMigemo := 0
        }
        if this.hModule {
            DllCall("FreeLibrary", "Ptr", this.hModule)
            this.hModule := 0
        }
    }
}