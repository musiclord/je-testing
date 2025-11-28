VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "PresenterFilter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Presenter
' Name:     Filter
' Purpose:  篩選條件展示器。
'           處理篩選條件的 UI 設定與驗證，
'           呼叫 ServiceFilter 執行篩選並回傳結果至 View。
'===============================================================================
