VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ImportService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const CLS As String = "ImportService"


Public Sub Initialize()
    
End Sub

Public Function ImportCsv(ByVal filepath As String, ByRef db As DbAccess) As Boolean
    Const PROC As String = "ImportCsv"
    ImportCsv = False
    ' sourceRs -> ADODB.Recordset
    Dim sourceRs As ADODB.Recordset
    Set sourceRs = db.PrepareRecordset(filepath)
    
    ' CreateTable name, types
    
    ' BulkInsert sourceRs, targetRs
    
    ImportCsv = True
End Function
