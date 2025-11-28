VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "PresenterImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Presenter
' Name:     Import
' Purpose:  資料匯入展示器。
'           處理檔案選擇、欄位對應設定等 UI 事件，
'           呼叫 ServiceImport 執行匯入並更新進度顯示。
'===============================================================================
