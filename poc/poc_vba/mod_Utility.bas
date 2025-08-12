Attribute VB_Name = "mod_Utility"

Option Explicit
'Module: Utility
'Description:通用功能工具，作為開放函數讓當前Excel專案存取使用。

Private cApp As cApplication

Public Sub Start()
    Set cApp = New cApplication
End Sub

Public Function DetectCSVEncoding(ByVal filePath As String) As Long
    ' 使用二進制讀取樣本進行分析
    Dim stream As Object
    Dim bomBytes As Variant      ' 接收 .Read 的結果
    Dim sampleBytes() As Byte    ' 用於讀取樣本
    Dim defaultEncoding As Long
    Dim detectedEncoding As Long
    Dim i As Long, byteValue As Integer, byteCount As Integer
    Dim isLikelyUTF8 As Boolean
    Dim bytesRead As Long
    
    defaultEncoding = 950 ' 預設為 Big5
    detectedEncoding = defaultEncoding
    
    On Error GoTo DetectionError
    
    Set stream = CreateObject("ADODB.Stream")
    With stream
        .Type = 1 ' adTypeBinary - 始終使用二進制模式
        .Open
        .LoadFromFile filePath
        
        ' --- 步驟 1: 檢查 UTF-8 BOM ---
        If .Size >= 3 Then
            .Position = 0
            bomBytes = .Read(3) ' 現在可以正確賦值給 Variant
            
            ' 檢查 Variant 中陣列的元素
            If bomBytes(0) = &HEF And bomBytes(1) = &HBB And bomBytes(2) = &HBF Then
                detectedEncoding = 65001 ' UTF-8 with BOM
                Debug.Print "檢測到 UTF-8 編碼 (BOM)"
                GoTo Cleanup ' 已確定，跳到清理步驟
            End If
        End If
        
        ' --- 後續代碼保持不變 ---
        ' --- 步驟 2: 如果沒有 BOM，讀取二進制樣本進行啟發式分析 ---
        .Position = 0 ' 重置位置
        If .Size > 0 Then
            ' 讀取前 4KB 或全部內容作為樣本
            Dim sampleSize As Long
            sampleSize = WorksheetFunction.Min(4096, .Size)
            sampleBytes = .Read(sampleSize) ' 讀取二進制數據到數組
            bytesRead = UBound(sampleBytes) + 1 ' 實際讀取的位元組數 (+1 因為是 0-based)
        Else
            bytesRead = 0 ' 空檔案
        End If
        
        .Close ' 讀完樣本即可關閉
    End With
    Set stream = Nothing ' 釋放 stream 物件

    ' --- 步驟 3: 分析二進制樣本內容 (啟發式) ---
    ' [保持不變]
    If bytesRead > 0 Then
        isLikelyUTF8 = False
        byteCount = 0 ' 用於追蹤 UTF-8 多位元組序列
        
        For i = 0 To bytesRead - 1 ' 遍歷讀取的位元組數組 (0-based)
            byteValue = sampleBytes(i) ' 直接取得位元組值 (0-255)
            
            If byteCount = 0 Then ' 檢查是否為多位元組序列的起始位元組
                If byteValue >= &H80 Then ' 非 ASCII 字元
                    If byteValue >= &HC2 And byteValue <= &HDF Then ' UTF-8 雙位元組序列起始 (C2-DF)
                        byteCount = 1
                    ElseIf byteValue >= &HE0 And byteValue <= &HEF Then ' UTF-8 三位元組序列起始 (E0-EF)
                        byteCount = 2
                    ElseIf byteValue >= &HF0 And byteValue <= &HF4 Then ' UTF-8 四位元組序列起始 (F0-F4)
                        byteCount = 3
                    Else
                        ' 發現無效的起始位元組 (可能不是 UTF-8)
                        isLikelyUTF8 = False
                        Debug.Print "發現無效的 UTF-8 起始位元組: " & Hex(byteValue) & " at position " & i & "，傾向非 UTF-8"
                        Exit For ' 不再繼續檢查
                    End If
                End If
            Else ' 檢查是否為有效的後續位元組 (80-BF)
                If byteValue >= &H80 And byteValue <= &HBF Then
                    byteCount = byteCount - 1 ' 消耗一個後續位元組
                    If byteCount = 0 Then
                        isLikelyUTF8 = True ' 至少找到一個完整的多位元組序列
                    End If
                Else
                    ' 發現無效的後續位元組 (肯定不是 UTF-8)
                    isLikelyUTF8 = False
                    Debug.Print "發現無效的 UTF-8 後續位元組: " & Hex(byteValue) & " at position " & i & "，確定非 UTF-8"
                    Exit For ' 不再繼續檢查
                End If
            End If
        Next i
        
        ' 額外檢查：如果 byteCount 在結束時不為 0，表示序列不完整，可能不是 UTF-8
        If byteCount <> 0 Then
             isLikelyUTF8 = False
             Debug.Print "UTF-8 序列在樣本結尾處不完整，傾向非 UTF-8"
        End If
        
        ' 根據分析結果判斷
        If isLikelyUTF8 Then
             ' 如果在樣本中發現了有效的 UTF-8 多位元組模式且序列完整
             detectedEncoding = 65001 ' UTF-8 without BOM
             Debug.Print "啟發式檢測：傾向 UTF-8 編碼 (無 BOM)"
        Else
             ' 如果樣本中沒有發現明顯的 UTF-8 模式，或者發現了無效/不完整模式
             detectedEncoding = defaultEncoding ' 保持預設 Big5
             Debug.Print "啟發式檢測：未發現明確 UTF-8 模式，使用預設編碼: " & defaultEncoding
        End If
        
    Else
        ' 空檔案或只包含 ASCII，使用預設編碼
        Debug.Print "檔案為空或只含 ASCII，使用預設編碼: " & defaultEncoding
    End If

Cleanup:
    DetectCSVEncoding = detectedEncoding ' 返回最終檢測結果
    Set stream = Nothing ' 確保釋放
    On Error GoTo 0 ' 恢復正常錯誤處理
    Exit Function

DetectionError:
    Debug.Print "讀取檔案偵測編碼時發生錯誤: " & Err.Description & "，使用預設編碼: " & defaultEncoding
    DetectCSVEncoding = defaultEncoding ' 出錯時返回預設值
    Set stream = Nothing
    On Error GoTo 0
End Function
