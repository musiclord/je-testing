VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vProject 
   Caption         =   "Project Metadata"
   ClientHeight    =   5415
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   5760
   OleObjectBlob   =   "vProject.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "vProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===== 表單資訊 =====
'名稱: vProject
'描述: 設定專案元數據，包含客戶資訊和會計期間。
'
'===== 表單控制項 =====
'文字方塊:
'  - txtClientName: 客戶名稱輸入欄位
'  - txtbPeriodStart: 會計期間開始日期
'  - txtbPeriodEnd: 會計期間結束日期
'  - txtbPeriodLast: 上一會計期間日期
'
'命令按鈕:
'  - ButtonConfirm: 確認按鈕，點擊時觸發 DoConfirm 事件
'  - ButtonExit: 退出按鈕，點擊時觸發 DoExit 事件


Public Event DoConfirm()
Public Event DoExit()

Private Sub UserForm_Initialize()

End Sub

Private Sub ButtonConfirm_Click()
    RaiseEvent DoConfirm
End Sub

Private Sub ButtonExit_Click()
    RaiseEvent DoExit
End Sub
