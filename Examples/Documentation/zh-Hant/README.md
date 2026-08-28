# KLShareLink 示範 App

> <span lang="zh-TW">[English](../en/README.md) · [简体中文](../zh-Hans/README.md) · [繁體中文](../zh-Hant/README.md) · [日本語](../ja/README.md) · [한국어](../ko/README.md)</span>

KLShareLink 是不含第三方執行階段相依項目、同步且可預期的 Swift 套件。它回傳通過 scheme 與 host 過濾的 HTTP(S) URL 與可選的提供者名稱。

## Link Inspector

通過過濾的明確 URL 優先 · 依文字出現順序偵測 HTTP(S) 候選 · 優先選擇符合設定提供者的候選

## Policy Playground

優先選擇符合設定提供者的候選 · 拒絕 `localhost`、`.local`、`::1` 與文件列出的直接 IPv4 範圍 · 無 URL 時可回報舊版提供者，但不會虛構目標

兩個示範 App 都有獨立的 `Package.swift` 與 App 進入點，只依賴儲存庫根目錄中的套件，不會匯入 wondays 的程式碼或資源。

只負責選擇輸入，不發出請求、不展開重新導向、不清除追蹤參數、不保存歷史，也不取代網路層的 SSRF 防護。除 `::1` 外，其他本機或私有 IPv6 直接位址不會被過濾器拒絕。網路層必須驗證解析後的位址與每次重新導向目標。
