VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewMain 
   Caption         =   "Main"
   ClientHeight    =   3015
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   4560
   OleObjectBlob   =   "ViewMain.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    View
' Name:     Main
' Purpose:  主控制台使用者介面。
'           顯示系統主選單與功能入口，接收使用者操作事件，
'           將事件委派給 PresenterMain 處理。
'===============================================================================
