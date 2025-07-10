VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ServiceImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ServiceImport
' Purpose:  資料匯入服務，將 PBC 檔案匯入至資料庫
'===============================================================================
Private Const MODULE_NAME = "m_ServiceImport"
' ----- 成員 -----
Private m_gl As String
Private m_tb As String
' ----- 屬性 -----
Public Property Get gl() As String
    gl = m_gl
End Property
Public Property Get tb() As String
    tb = m_tb
End Property


Public Function DefinePQ() As Boolean
    Const METHOD_NAME = "DefinePQ"
    DefinePQ = False
    '定義 Power Query 連接
    
    '轉成 ADO 記錄集
    
    DefinePQ = True
    Exit Function

ErrorHandler:
    Debug.Print ""
End Function
