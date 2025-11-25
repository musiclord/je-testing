VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaReportDataOverview"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Name As String
Public JeName As String
Public JeNetAmount As String
Public TbName As String
Public TbNet As String

Public Sub Initialize()
    Name = "DATA_OVERVIEW"
    JeName = "分錄檔案名稱"
    JeNetAmount = "分錄借貸淨額"
    TbName = "試算表檔案名稱"
    TbNet = "試算表淨額"
End Sub
