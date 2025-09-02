VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:ServiceImport
'負責匯入資料，使用 Access 精靈匯入
Private db As DbAccess
Private gl As EntityGl
Private tb As EntityTb
Private m_Ace As New Access.Application
Private m_DataType As String
Private m_Method As String

Public Property Let dType(ByVal Value As String)
    m_DataType = Value
End Property

Public Sub Initialize(context As ContextManager)
    Set db = context.DbInput
    Set gl = context.gl
    Set tb = context.tb
End Sub

Public Sub OpenWizard(ByVal target As String)
    Dim oldTables As New Collection
    Dim oldTimes As New Collection
    Dim newTables As New Collection
    Dim tdf As Object, i As Long, found As Boolean, timeChanged As Boolean
    
    m_Ace.OpenCurrentDatabase db.path
    
    '記錄匯入前的表名稱和更新時間
    For Each tdf In m_Ace.CurrentDb.TableDefs
        If IsUserTable(tdf.Name) Then
            oldTables.Add tdf.Name
            oldTimes.Add tdf.LastUpdated
        End If
    Next tdf
    
    '依資料類型開啟匯入精靈
    Select Case LCase$(m_DataType)
        Case "excel"
            m_Ace.DoCmd.RunCommand acCmdImportAttachExcel
        Case "csv"
            m_Ace.DoCmd.RunCommand acCmdImportAttachText
        Case Else
            MsgBox "不支援的資料類型！", vbExclamation, "匯入程序"
    End Select
    
    '找出新建立或被覆寫的表
    For Each tdf In m_Ace.CurrentDb.TableDefs
        If IsUserTable(tdf.Name) Then
            found = False
            timeChanged = False
            
            '檢查是否為新表或現有表被更新
            For i = 1 To oldTables.Count
                If oldTables.Item(i) = tdf.Name Then
                    found = True
                    If oldTimes.Item(i) <> tdf.LastUpdated Then
                        timeChanged = True
                    End If
                    Exit For
                End If
            Next i
            
            '新表或時間變更的表都加入清單
            If Not found Or timeChanged Then
                newTables.Add tdf.Name
            End If
        End If
    Next tdf
    
    '處理匯入結果
    If newTables.Count = 1 Then
        Select Case LCase$(target)
            Case "gl"
                gl.Name = newTables.Item(1)
                Debug.Print "匯入/更新 GL 表：" & gl.Name
            Case "tb"
                tb.Name = newTables.Item(1)
                Debug.Print "匯入/更新 TB 表：" & tb.Name
        End Select
    ElseIf newTables.Count = 0 Then
        Debug.Print "沒有偵測到新表或更新，可能是使用者取消操作"
    Else
        Debug.Print "偵測到多個新表或更新：" & newTables.Count
    End If
    
    m_Ace.CloseCurrentDatabase
    m_Ace.Quit
    Set m_Ace = Nothing
End Sub

Public Function ApplyGl(ByVal dict As Dictionary) As Boolean
    ApplyGl = False
    '將GL欄位設給資料實體
    Dim key As Variant
    For Each key In dict.Keys
        gl.SetField key, dict(key)
    Next key
    gl.PrintFields
    '...
    '@TODO: 檢查欄位型別
    '...
    'If Not ProcessGlAmount(m_Method) Then
        'error
    'Else
        'pass
    'End If
    ApplyGl = True
End Function

Public Function ApplyTb(ByVal dict As Dictionary) As Boolean
    ApplyTb = False
    '將TB欄位設給資料實體
    Dim key As Variant
    For Each key In dict.Keys
        tb.SetField key, dict(key)
    Next key
    tb.PrintFields
    '...
    '@TODO: 檢查欄位型別
    '...
    'If Not ProcessTbAmount(m_Method) Then
        'error
    'Else
        'pass
    'End If
    ApplyTb = True
End Function

Private Function ProcessGlAmount(ByVal method As Long) As Boolean
    ProcessGlAmount = False
    Dim affected As Long
    Dim t As String
    Dim fEntry As String, fDebit As String, fCredit As String

    t = "[" & gl.Name & "]"
    fEntry = "[" & gl.EntryAmount & "]"
    fDebit = "[" & gl.DebitAmount & "]"
    fCredit = "[" & gl.CreditAmount & "]"

    Select Case method
        Case 1 ' 直接使用原始金額欄位
            ' 不改動資料

        Case 2 ' 傳票金額 = 借方金額 - 貸方金額
            On Error Resume Next
            affected = db.ExecuteNonQuery("ALTER TABLE " & t & " ADD COLUMN " & fEntry & " CURRENCY;")
            On Error GoTo 0
            affected = db.ExecuteNonQuery( _
                "UPDATE " & t & " " & _
                "SET " & fEntry & " = " & "Nz(" & fDebit & ") - Nz(" & fCredit & ");" _
            )

        Case 3 ' 依借貸別決定正負號（D/DEBIT/借/借方 視為借方）
            affected = db.ExecuteNonQuery( _
                "UPDATE " & t & " " & _
                "SET " & fEntry & " = " & _
                "IIf( UCase(Trim(Nz([" & gl.DrCr & "],''))) IN ('D','DEBIT','借','借方'), " & _
                "     Abs(Nz([" & gl.EntryAmount & "])), " & _
                "    -Abs(Nz([" & gl.EntryAmount & "])) );" _
            )

        Case Else
            Debug.Print "不支援的金額處理方式"
            Exit Function
    End Select

    ProcessGlAmount = True
End Function

Private Function ProcessTbAmount(ByVal method As Long) As Boolean
    ProcessTbAmount = False
    Dim sql As String
    Dim affected As Long
    Select Case method
        Case 1
            '直接使用變動金額
        Case 2
            '期末 - 期初 = 變動金額
            affected = db.ExecuteNonQuery( _
                "" & _
                "" _
            )
        Case 3
            '借方 - 貸方 = 變動金額
            affected = db.ExecuteNonQuery( _
                "" & _
                "" _
            )
        Case 4
            '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
            affected = db.ExecuteNonQuery( _
                "" & _
                "" _
            )
        Case Else
            Debug.Print "不支援的金額處理方式"
            Exit Function
    End Select
    ProcessTbAmount = True
End Function

'--自訂
Private Function IsUserTable(ByVal tableName As String) As Boolean
    '排除系統表和例外
    Dim Name As String
    Name = LCase$(tableName)
    IsUserTable = Not (StartsWith(Name, "msys") Or StartsWith(tableName, "~") Or InStr(1, tableName, "匯入錯誤") > 0)
End Function

Private Function StartsWith(text As String, prefix As String) As Boolean
    '判斷是否以 prefix 開頭
    StartsWith = (Left$(text, Len(prefix)) = prefix)
End Function

