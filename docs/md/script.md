# 簡要文字筆記

- 使用者為一般審計員及中央小組，審計案件的資料量應不超過一百萬筆，
- Power Query 無法直接連接並匯出至 Access
- Power Query 的查詢結果可以透過 `WorkbookConnection.OLEDBConnection` 取得 ADO Recordset
- 記憶體效率最高：完全跳過 Excel 工作表儲存，轉換次數最少：Power Query → ADO RS → DAO RS，符合原始需求：保留 Power Query 的資料清理優勢
- 

# 擷取紀錄筆記




```vb
' 庫存監控系統 - 需要看到其他使用者的即時異動
Set rs = dal.ExecuteQuery("SELECT ProductName, Stock FROM Products WHERE Stock < 10", offline:=False)

Do While Not rs.EOF
    ' 在處理過程中，如果其他使用者更新了庫存
    ' 線上記錄集能反映最新的資料變化
    Debug.Print rs("ProductName") & ": " & rs("Stock")
    rs.MoveNext
Loop
```

```vb
' 需要透過 Recordset 直接修改資料
Set rs = dal.ExecuteQuery("SELECT * FROM Employees WHERE Dept='Sales'", offline:=False)

Do While Not rs.EOF
    rs.Edit
    rs("Salary") = rs("Salary") * 1.1  ' 調薪 10%
    rs.Update  ' 這需要連線才能執行
    rs.MoveNext
Loop
```

```vb
' 處理百萬筆資料，不想一次全部載入記憶體
Set rs = dal.ExecuteQuery("SELECT * FROM HugeTable ORDER BY ID", offline:=False)

' 可以逐筆處理，不會耗盡記憶體
Do While Not rs.EOF
    ProcessRecord rs  ' 處理單筆記錄
    rs.MoveNext       ' 從資料庫動態載入下一筆
Loop
```

# 技術規格
### VBA
- VBA 的類別模型是比較簡化的 `COM` 架構，與 C#、Java 等語言不同，不支援多個建構子（Overloaded Constructors），不允許 Class_Initialize() 帶參數，無法在 New 關鍵字後傳入參數
    - 要能夠依賴注入，得自定義方法:
    ```vb
    ' 類別模組: clsCustomer
    Private m_name As String
    Private Sub Class_Initialize()
        ' 預設初始化
    End Sub
    Public Sub Initialize(ByVal p_name As String)
        m_name = p_name
    End Sub
    ' 類別模組: 主程式
    Dim customer As clsCustomer
    Set customer = New clsCustomer
    customer.Initialize("Alice")
    ```

### Access
...

### Excel
...


### MVC
- Model 
- View
- Controller
- Three-tier Layer
- DAL
    - 資料存取層 (Data Access Layer)
    - 一種系統架構模式，拆分資料存取邏輯與業務邏輯
    - 集中管理，統一所有資料庫操作
    - 可替換與維護，更換底層資料存取技術 (例如ACE換至SQL) 而不影響其他模組的應用
- ORM
    - 程式設計技術，用於OOP和RDB之間建立映射關係
    - 物件映射，資料表 ↔ 類別 (Class)
    - 欄位映射，欄位 ↔ 物件屬性 (Property)
    - 關係映射，外鍵關係 ↔ 物件關聯
- DAO:
    - `Microsoft Office 16.0 Access database engine Object Library`
    - 直接對本地 Access 資料庫操作，通常具有更佳的性能、較低的記憶體消耗及穩定性
    - 直接使用 ACE/JET 引擎與資料庫溝通
- ADO:
    - `Microsoft ActiveX Data Objects 6.1 Library`
    - 處理 `DML`，也就是 `SELECT`、`INSERT`、`UPDATE`、`DELETE`
    - 通用性強，可連接多種資料庫 (MS-SQL, Oracle, MySQL) ，也可直接將 **Excel** 工作表作為資料來源做SQL查詢 `SELECT * FROM [Sheet1$]`
    - 基於 `OLE DB` 而多一層抽象，因此性能略遜於 DAO，且記憶體消耗較高，尤其大量 COM 物件操作
- ADOX:
    - `Microsoft ADO Ext. 6.0 for DDL and Security`
    - 處理 `DDL`，也就是 `CREATE`、`ALTER`、`DROP`、`TRUNCATE`
    - 屬於 `ADO` 的擴充套件
- Script:
    - `Microsoft Scripting Runtime`

### 程式設計
- Implement
    - 定義一個介面標準，實作類別來提供介面中聲明的所有公共方法和屬性，實現鬆耦合，例如輕易替換 `DAL` 層的具體實作為 `SQL` 或 `ACE` 等連接方法。
- Dependency Injection
    - 不直接在類別內部創建依賴的物件，而是透過 `建構函式` 或 `初始化方法` 將依賴物件傳入，藉此在不同