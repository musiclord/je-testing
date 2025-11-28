VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DbSchemaSource"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Schema
' Name:     Source
' Purpose:  ...
'
'===============================================================================

'--
Private m_GL As MapperFieldGl
Private m_TB As MapperFieldTb

'-------------------------------------------------------------------------------
'-- Source Layer
'-------------------------------------------------------------------------------
'-- GL
Public Property Get GL() As MapperFieldGl
    Set GL = m_GL
End Property

'-- TB
Public Property Get TB() As MapperFieldTb
    Set TB = m_TB
End Property

'-- Account Mapping

'-- Date Dimension



