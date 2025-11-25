VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaSystemReports"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'系統報表集合
Private m_EngagementOverview As SchemaReportEngagementOverview
Private m_DataOverview As SchemaReportDataOverview
Private m_CompletenessDetail As SchemaReportCompletenessDetail
Private m_DocumentBalanceDetail As SchemaReportDocumentBalanceDetail
Private m_AccountMappingInfo As SchemaReportAccountMappingInfo
Private m_FieldMappingInfo As SchemaReportFieldMappingInfo

Public Sub Initialize()
    Set m_EngagementOverview = New SchemaReportEngagementOverview
    Set m_DataOverview = New SchemaReportDataOverview
    Set m_CompletenessDetail = New SchemaReportCompletenessDetail
    Set m_DocumentBalanceDetail = New SchemaReportDocumentBalanceDetail  
    Set m_AccountMappingInfo = New SchemaReportAccountMappingInfo
    Set m_FieldMappingInfo = New SchemaReportFieldMappingInfo
    
    m_EngagementOverview.Initialize
    m_DataOverview.Initialize
    m_CompletenessDetail.Initialize
    m_DocumentBalanceDetail.Initialize
    m_AccountMappingInfo.Initialize
    m_FieldMappingInfo.Initialize
End Sub

Public Property Get EngagementOverview() As SchemaReportEngagementOverview
    Set EngagementOverview = m_EngagementOverview
End Property

Public Property Get DataOverview() As SchemaReportDataOverview
    Set DataOverview = m_DataOverview
End Property

Public Property Get CompletenessDetail() As SchemaReportCompletenessDetail
    Set CompletenessDetail = m_CompletenessDetail
End Property

Public Property Get DocumentBalanceDetail() As SchemaReportDocumentBalanceDetail
    Set DocumentBalanceDetail = m_DocumentBalanceDetail
End Property

Public Property Get AccountMappingInfo() As SchemaReportAccountMappingInfo
    Set AccountMappingInfo = m_AccountMappingInfo
End Property

Public Property Get FieldMappingInfo() As SchemaReportFieldMappingInfo
    Set FieldMappingInfo = m_FieldMappingInfo
End Property

Private Sub Class_Terminate()
    Set m_EngagementOverview = Nothing
    Set m_DataOverview = Nothing
    Set m_CompletenessDetail = Nothing
    Set m_DocumentBalanceDetail = Nothing
    Set m_AccountMappingInfo = Nothing
    Set m_FieldMappingInfo = Nothing
End Sub
