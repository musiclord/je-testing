# Title
all the description shall move to #README.md
### Sub-Title
A markdown note describe how mvp project goes.

### 
- 在現代開發中，一個更標準的做法是：負責建立和設定物件的元件 (Builder/Factory)，應該直接回傳一個「完整且可用」的結果，而不是修改傳入的參數。修正後的流程：
    1. `c_App` (啟動器) 建立 c_Project (專案建構器)。
    2. `c_App` 呼叫 `c_Project.Build()`。
    3. `c_Project` 在內部建立並完整設定好 config 和 context 物件。
    4. `c_Project` 將設定完成的 config 和 context 作為結果回傳給 `c_App`。
    5. `c_App` 接收到這些完整的物件。
    6. `c_App` 將這些物件注入到 `c_Main` 中並執行。
- `c_App` 的流程變成了「建立建構器 -> 取得產品 -> 使用產品」，這是一個非常標準和易於理解的模式。在我們改進的設計中:
    - `c_Project` 的角色變成了 **「建構器 (Builder)」或「工廠 (Factory)」**。當您經營一家工廠時，您會：
        1. 按下「開始生產」按鈕 ( `projectBuilder.Build()` )。
        2. 生產完成後，在取貨區領取產品 ( `projectBuilder.Config` , `projectBuilder.Context` )。

      屬性注入 ( `.Config` , `.Context` ) 在這裡就是那個「取貨區」。
    - `c_Main` 的角色則是 **「消費者 (Consumer)」或「引擎 (Engine)」**。
        - 它的 **職責**：是使用 `config` 和 `context` 來執行應用程式的核心業務邏輯。
        - 它的 **必需品**：就是 `config` 和 `context`。沒有這兩樣東西，`c_Main` 就像一台沒有燃料和機油的引擎，完全無法運作。

      模擬建構子注入 ( `mainApp.Run(config, context)` ) 在這裡就是確保引擎在啟動前，必須加滿燃料和機油。

### Temporary note for DI design
```vb
'c_App:
	Private m_main As c_Main
	Private m_project As c_Project
	Private m_config As m_ManagerConfig
	Private m_context As m_ManagerContext
	
	Public Sub Launch()
		Set m_project = New c_Project
		'1. 呼叫建構器並初始化專案
		If m_project.Build() Then
			'2. 從建構器取得初始化好的 config 和 context
			Set m_config = m_project.Config
			Set m_context = m_project.Context
			'3. 將依賴注入至主程式
			Call m_main.Run(m_config, m_context)
		End If
	End Sub

'c_Project:
	Private m_config As m_ManagerConfig
	Private m_context As m_ManagerContext
	Private m_project As m_ManagerProject
	' 屬性 .Config
	Public Property Get Config() As m_ManagerConfig
		Set Config = m_config
	End Property
	' 屬性 .Context
	Public Property Get Context() As m_ManagerContext
		Set Context = m_context
	End Property
	
	Public Function Build() As Boolean
		Build = False
		' 在內部建立實例
		Set m_config = New m_ManagerConfig
		Set m_context = New m_ManagerContext
		Set m_project = New m_ManagerProject
		' 對實例初始化並建置專案
		If Not m_project.Setup(m_config, m_context) Then Exit Function
		Build = True
	End Function
```