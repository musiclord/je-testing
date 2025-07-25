VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Svc_Validation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Svc_Validation"
'===============================================================================
' Module:   Svc_Validation
' Purpose:  驗證業務服務，提供資料完整性檢查和業務規則驗證
' Layer:    Service
' Domain:   Data Validation
'===============================================================================

'--類別成員
Private m_ContextManager As Mgr_Context
'Private m_tb As Ent_TB


'--Svc_Validation
Public Sub Initialize()
    Const METHOD_NAME As String = "Initialize"
End Sub

Public Function TestCompleteness(ByVal startDate As Date, ByVal endDate As Date) As Boolean
    '完整性測試
    Const METHOD_NAME As String = "TestCompleteness"
    On Error GoTo ErrorHandler
    
    TestCompleteness = False
    '準備日期格式
    Dim sStart As String, sEnd As String
    sStart = Format(startDate, "\#yyyy\-MM\-dd\#")
    sEnd = Format(endDate, "\#yyyy\-MM\-dd\#")
    '修改欄位類型
    Dim sql As String, affected As Long
    Dim fieldsArray As Variant, fieldName As Variant
    'fieldsArray = Array(m_tb.change, m_tb.credit, m_tb.debit) <-- Dict
    For Each fieldName In fieldsArray
        
    Next fieldName
    TestCompleteness = True
    Exit Function
    
ErrorHandler:
    TestCompleteness = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function TestBalance() As Boolean
    '借貸不平測試
    Const METHOD_NAME As String = "TestBalance"
    On Error GoTo ErrorHandler
    
    TestBalance = False
    '...
    TestBalance = True
    Exit Function
    
ErrorHandler:
    TestBalance = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function TestRDE() As Boolean
    '資料攸關元素抽樣
    Const METHOD_NAME As String = "TestRDE"
    On Error GoTo ErrorHandler
    
    TestRDE = False
    '...
    TestRDE = True
    Exit Function
    
ErrorHandler:
    TestRDE = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function


'--Custom
