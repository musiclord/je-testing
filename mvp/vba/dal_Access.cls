VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Dal_Access"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Dal_Access"
'===============================================================================
' Module:   Dal_Access
' Purpose:  Access 資料庫的資料存取實作，提供 CRUD 操作和批次處理功能
' Layer:    Data Access Layer
' Domain:   Database Access
'===============================================================================

Implements I_Dal
'--類別成員
Private Const CHUNK_SIZE As Long = 50000
Private m_path As String
Private m_db As DAO.Database
Private m_conn As DAO.Connection
Private m_isConnected As Boolean



'--連線管理
Public Property Get I_Dal_path() As String
    I_Dal_path = m_path
End Property
Public Property Let I_Dal_path(ByVal value As String)
    m_path = value
End Property

Public Property Get I_Dal_IsConnected() As Boolean
    I_Dal_IsConnected = m_isConnected
End Property

Public Sub I_Dal_Connect()
    Const METHOD_NAME As String = "I_Dal_Connect"
    On Error GoTo ErrorHandler
    
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub I_Dal_Disconnect()
    Const METHOD_NAME As String = "I_Dal_Disconnect"
    On Error GoTo ErrorHandler
    
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub



'--資料定義 DDL (Data Definition Language)
Public Function I_Dal_CreateTable(ByVal tableName As String, ByVal rs As ADODB.Recordset, Optional ByVal dropIfExists As Boolean = True) As Boolean
    Const METHOD_NAME As String = "I_Dal_CreateTable"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_DropTable(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "I_Dal_DropTable"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_TableExists(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "I_Dal_TableExists"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--資料操作 DML (Data Manipulation Language)
Public Function I_Dal_ExecuteQuery(ByVal sql As String) As ADODB.Recordset
    Const METHOD_NAME As String = "I_Dal_ExecuteQuery"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_ExecuteNonQuery(ByVal sql As String) As Long
    Const METHOD_NAME As String = "I_Dal_ExecuteNonQuery"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_GetScalar(ByVal sql As String) As Variant
    Const METHOD_NAME As String = "I_Dal_GetScalar"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--批次操作 (Bulk Operations)
Public Function I_Dal_BulkInsert(ByVal dataSource As Variant, ByVal tableName As String) As Variant
    '基於 JET 系統的架構來全局考量與設計 Bulk Operations
    Const METHOD_NAME As String = "I_Dal_BulkInsert"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--查詢輔助 (Query Helpers)
Public Function I_Dal_GetTableSchema(ByVal tableName As String) As ADODB.Recordset
    Const METHOD_NAME As String = "I_Dal_GetTableSchema"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_GetTableList() As ADODB.Recordset
    Const METHOD_NAME As String = "I_Dal_GetTableList"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--事務管理
Public Sub I_Dal_BeginTransaction()
    Const METHOD_NAME As String = "I_Dal_BeginTransaction"
    On Error GoTo ErrorHandler
    
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub I_Dal_CommitTransaction()
    Const METHOD_NAME As String = "I_Dal_CommitTransaction"
    On Error GoTo ErrorHandler
    
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub I_Dal_RollbackTransaction()
    Const METHOD_NAME As String = "I_Dal_RollbackTransaction"
    On Error GoTo ErrorHandler
    
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub
