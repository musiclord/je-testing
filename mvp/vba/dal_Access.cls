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

' === 常數 ===
Private Const MODULE_NAME As String = "dal_Access"

' === 私有成員 ===
Private m_connection As ADODB.Connection
Private m_connectionString As String
Private m_isConnected As Boolean
Private m_inTransaction As Boolean

' === 實作介面 ===

