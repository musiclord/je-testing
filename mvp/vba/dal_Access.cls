VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "dal_Access"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     dal_Access
' Purpose:  實作 Access 資料庫的具體操作
'===============================================================================

' === 實作介面 ===
Implements i_dal

' === 常數 ===
Private Const MODULE_NAME As String = "dal_Access"

' === 私有成員 ===
Private m_database As DAO.Database
Private m_workspace As DAO.Workspace
Private m_dbPath As String
Private m_enableDebugPrinting As Boolean
