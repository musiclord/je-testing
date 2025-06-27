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
' Purpose:  匯入資料的服務，應使用 PowerQuery 與 M 語言
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "m_ServiceImport"


Public Function CreatePowerQueryFrom(csvPath As String) As queryTable

End Function

Public Function GetRecordsetFrom(queryTable As queryTable) As ADODB.Recordset

End Function

Public Function Ado2Dao(sourceRS As ADODB.Recordset, dbPath As String, tableName As String) As Boolean
    'This function should consider move to DAL.
    
End Function
