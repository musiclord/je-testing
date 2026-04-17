# Repo Cleanup Summary

## 目的

這份文件只回答一件事：**目前倉庫應該先整理到什麼程度，才能安全進入正式規劃與開發。**

---

## 一句話總結

目前 repo 已有：
- 完整的 JET 領域知識
- 舊版 JE Tool 的始祖程式 `ideascript.bas`
- .NET 10 WinForms 專案骨架
- 可作為前端目標的 `jet-template.html`

但還沒有：
- WebView2 整合
- Thin Bridge
- Action Dispatcher
- Application CQRS
- SQLite / SQL Server 的正式實作分層

所以當前階段的正確工作不是直接開發功能，而是先把 **文件定位、命名、目標架構、遷移邊界** 整理乾淨。

---

## 目前 repo 的角色分布

### 1. `docs/jet-domain-model.md`
角色：**業務規格唯一事實來源**

用途：
- 定義 GL / TB / Account Mapping / Date Dimension
- 定義步驟 1~5 的工作流程
- 定義 R1-R8 / A2-A4 等規則

判斷：
- 這份文件應保留為最核心文件
- 不應混入 WinForms、WebView2、資料庫框架細節

### 2. `docs/ideascript.bas`
角色：**始祖程式與遷移來源**

用途：
- 提供舊 JE Tool 的實際流程、欄位命名、規則執行順序
- 補足領域文件未寫清楚的操作細節

判斷：
- 它是遷移參考，不是新系統的目標結構
- 後續應做「功能切塊對照」，不是直接逐段翻譯

### 3. `docs/jet-template.html`
角色：**前端 UI 目標模板**

用途：
- 定義操作流程與畫面型態
- 作為未來 WebView2 載入的 HTML 原型
- 方便 AI 直接修改 UI/UX

判斷：
- 應保留在 `docs/` 作為設計模板
- 正式整合時再移入 .NET 專案資源目錄

### 4. `src/JET/JET.slnx`
角色：**新系統宿主骨架**

現況：
- 目前只有最小 WinForms 專案
- `Form1` 還是空白殼
- 尚未導入 WebView2

判斷：
- 現在是正確的起點
- 但還不能代表應用架構已落地

---

## 已整理出的最終架構方向

### 技術棧
- `.NET 10`
- `WinForms`
- `WebView2`
- `HTML/CSS/JS`
- `SQLite`
- `SQL Server`

### 分層模式
- `Thin-Bridge Action-Dispatcher`
- `Application CQRS`

### 核心原則
1. `Form1` 只做 host，不做業務邏輯
2. 前端只送 `action + payload`
3. Bridge 只負責轉送，不內嵌規則
4. Application 層用命令/查詢拆開流程
5. SQLite 管本機狀態與設定
6. SQL Server 管大量正式資料與運算

---

## 本次整理前發現的主要問題

### 文件命名不一致
舊文件引用了：
- `docs/architecture.md`
- `docs/technical_guide.md`
- `JE_Testing_Tool_1.html`

但 repo 實際存在的是：
- `docs/jet-architecture.md`
- `docs/jet-technical-guide.md`
- `docs/jet-template.html`

### 架構描述落後
部分文件仍只描述：
- `WinForms + WebView2 + SQL Server`

但目前已定案為：
- `WinForms + WebView2 + HTML + SQLite + SQL Server`
- `Thin-Bridge Action-Dispatcher + Application CQRS`

### 專案骨架與文件尚未接軌
目前 `src/JET/JET`：
- 可建置
- 但尚未承接 `jet-template.html`
- 也尚未反映未來的分層結構

---

## 現在應先整理到什麼程度

在還沒進入正式開發前，repo 應先達成以下狀態：

### A. 文件層面
- [x] 文件名稱與引用一致
- [x] 根 README 能正確描述最新架構
- [x] `docs/` 有索引文件
- [x] 有一份專門描述 repo 整理狀態的摘要
- [ ] 後續補一份 `ideascript.bas` → 新系統模組對照表

### B. 專案層面
- [x] `JET.slnx` 可建置
- [x] SDK 版本固定
- [x] `.gitignore` 已基本完整
- [ ] 後續將 `WebView2` 納入宿主專案
- [ ] 後續建立 `wwwroot` / `Bridge` / `Application` 等結構

### C. 規劃層面
- [x] 已明確定案前端模板來源
- [x] 已明確定案 legacy 規則來源
- [x] 已明確定案未來系統分層方式
- [ ] 下一步要做功能盤點與模組切分，而不是直接寫 UI 事件

---

## 建議的下一步 planning 順序

1. **功能盤點**
   - 從 `ideascript.bas` 列出步驟 1~5 的功能清單
   - 對照 `jet-domain-model.md`，標記哪些已有規格、哪些仍缺

2. **模組切分**
   - 定義 `Commands` / `Queries`
   - 定義 Bridge action 名稱
   - 定義前端固定綁定元素與 payload schema

3. **資料策略切分**
   - 哪些資料先進 SQLite
   - 哪些資料一定要進 SQL Server
   - 哪些查詢可以先以 SQLite 驗證流程，再升級到 SQL Server

4. **前端整合規劃**
   - 將 `jet-template.html` 拆成可嵌入 WebView2 的靜態資源
   - 決定 CSS / JS / assets 的目錄結構

5. **宿主最小落地**
   - 讓 WinForms + WebView2 能載入前端頁面
   - 先打通一條最小 action：前端按鈕 → Bridge → C# → 回傳結果

---

## 現階段結論

**這個 repo 現在已經可以進入正式 planning，但還不應直接進入大規模功能開發。**

先整理文件與架構邊界是對的，因為現在最怕的不是功能太少，而是：
- 把舊 VBA 邏輯直接塞進 WinForms
- 把前端事件直接綁到資料庫操作
- 沒有 action contract 就讓 AI 任意改 UI
- 還沒切分 CQRS 就先堆功能

那樣後面一定會爛掉。
