VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaReportEngagementOverview"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Public Name As String
Public Client As String
Public PrepStartDate As String
Public PrepEndDate As String
Public PreparedBy As String
Public PreparedDate As String

Public Sub Initialize()
    Name = "ENGAGEMENT_OVERVIEW"
    Client = "客戶"
    PrepStartDate = "財報準備期間開始日"
    PrepEndDate = "財報準備期間結束日"
    PreparedBy = "報表生產人"
    PreparedDate = "報表生產時間"
End Sub
