Function Step1_Validation
		'sTemp = "@BetweenDate( Posting_Date_JE ,"& Chr(34) & iRemove( sPeriod_Start_Date , "/") & Chr(34) & "," & Chr(34) & iRemove( sPeriod_End_Date , "/") & Chr(34) & ")" 
		Call Sort_FieldName
		Set db = Client.OpenDatabase("#GL#.IDM")
		Set task = db.Extraction
		For i = 1 To UBound(NewArray)
			If NewArray(i) <> "" Then task.AddFieldToInc NewArray(i)
		Next i
		dbName = "#GL#In_Period.IDM"
		task.AddExtraction dbName, "", ""
		task.CreateVirtualDatabase = False
		task.PerformTask 1, db.Count
		Client.OpenDatabase (dbName)
		
		Call Z_Rename_DB("#GL#In_Period.IDM","#GL#.IDM")
		
		'2019.05.20 Add For WP 
		Set db = Client.OpenDatabase("#GL#.IDM")
		Set task = db.TopRecordsExtraction
		task.IncludeAllFields
		task.AddKey "會計科目編號_JE", "D"
		dbName = "#GL#DESC.IDM"
		task.OutputFileName = dbName
		task.NumberOfRecordsToExtract = 1
		task.CreateVirtualDatabase = False
		task.PerformTask
		Set task = Nothing
		Set db = Nothing
		Client.OpenDatabase (dbName)		
				
		' Completeness/rollforward test
		' Summarization GL file
	 	Set db = Client.OpenDatabase("#GL#.IDM")
		Set task = db.Summarization
		task.AddFieldToSummarize  "會計科目編號_JE"  	'  彙總的欄位 
		task.AddFieldToTotal "傳票金額_JE"  	' 彙總的數字欄位
		 dbName = "#GL_Account_Sum.IDM"
		task.OutputDBName = dbName
		task.CreatePercentField = FALSE
		task.StatisticsToInclude = SM_SUM
		task.PerformTask
		Set task = Nothing
		Set db = Nothing
		Client.OpenDatabase ( dbName )
	 						
		' JoinDatabase Sum_GL & TB 
		'  需增加入主key和次要key值的型態判斷
		Set db = Client.OpenDatabase( "#GL_Account_Sum.IDM" )
		Set task = db.JoinDatabase
		task.FileToJoin "#TB#.IDM"
		task.IncludeAllPFields     ' 主要檔案的欄位加入 (若有選擇會科名稱，則可以加入)
		task.AddSFieldToInc "會計科目編號_TB"	'  次要檔案的欄位加入，為使畫面較乾淨，只需加入必要欄位
		task.AddSFieldToInc "會計科目名稱_TB"
		'task.AddSFieldToInc "Opening_Balance_TB"
		'task.AddSFieldToInc "Ending_Balance_TB"
		task.AddSFieldToInc "試算表變動金額_TB"
		task.IncludeAllSFields	
		task.AddMatchKey "會計科目編號_JE", "會計科目編號_TB", "A"
		task.CreateVirtualDatabase = False
		dbName = "#Completeness_calculate.IDM"
		task.PerformTask dbName, "", WI_JOIN_ALL_REC
		Set task = Nothing
		Set db = Nothing
		Client.OpenDatabase (dbName)						
		
		' 增加計算欄位、會科編號判斷
		Call Z_Field_Info("#Completeness_calculate.IDM", "傳票金額_JE_SUM")
		Set db = Client.OpenDatabase("#Completeness_calculate.IDM")
		Set task = db.TableManagement
		Set field = db.TableDef.NewField
		field.Name = "DIFF"
		field.Description = ""
		field.Type = WI_NUM_FIELD 'WI_VIRT_NUM
		'field.Equation = " ENDING_BALANCE_TB - OPENING_BALANCE_TB - 傳票金額_JE_SUM "
		field.Equation = " 試算表變動金額_TB - 傳票金額_JE_SUM "
		field.Decimals = sDecimals
		task.AppendField field
		task.PerformTask
		Set task = Nothing
		Set db = Nothing
		Set field = Nothing

		Call Z_Field_Info("#Completeness_calculate.IDM", "會計科目編號_TB")
		Set db = Client.OpenDatabase("#Completeness_calculate.IDM")
		Set task = db.TableManagement
		Set field = db.TableDef.NewField
		field.Name = "ACCOUNT_NUM_ALL"
		field.Description = ""

		If sType = "WI_VIRT_NUM" Then 
			field.Type = WI_VIRT_NUM
			field.Equation = "@If( 會計科目編號_JE <> 0,  會計科目編號_JE , 會計科目編號_TB )"
			field.Decimals = sDecimals    
		ElseIf sType = "WI_VIRT_CHAR" Then
			field.Type = WI_VIRT_CHAR
			field.Equation = "@If( 會計科目編號_JE <> " & Chr(34) & Chr(34) & ",  會計科目編號_JE , 會計科目編號_TB )"
			field.Length = sLen
		End If
		task.AppendField field
		task.PerformTask
		Set task = Nothing
		Set db = Nothing
		Set field = Nothing 


		'  將完整性檔案的必要欄位匯出
		Set db = Client.OpenDatabase("#Completeness_calculate.IDM")
		Set task = db.Extraction
		task.AddFieldToInc "ACCOUNT_NUM_ALL"
		task.AddFieldToInc "會計科目名稱_TB"
		'task.AddFieldToInc "Opening_Balance_TB"
		'task.AddFieldToInc "Ending_Balance_TB"
		task.AddFieldToInc "試算表變動金額_TB"
		task.AddFieldToInc "傳票金額_JE_SUM"
		task.AddFieldToInc "DIFF"
		dbName = "#Completeness_Check.IDM"
		task.AddExtraction dbName, "", ""
		task.CreateVirtualDatabase = False
		task.PerformTask 1, db.Count
		Set task = Nothing
		Set db = Nothing
		
		'傳票號借貸不平
		
		Set db = Client.OpenDatabase("#GL#.IDM")
		Set task = db.Summarization
		task.AddFieldToSummarize "傳票號碼_JE"
		task.AddFieldToTotal "傳票金額_JE"
		dbName = "#GL#In_Period_Doc_Sum.IDM"
		task.OutputDBName = dbName
		task.CreatePercentField = FALSE
		task.StatisticsToInclude = SM_SUM
		task.PerformTask
		Set task = Nothing
		Set db = Nothing
		Client.OpenDatabase (dbName)
		
		Set db = Client.OpenDatabase("#GL#In_Period_Doc_Sum.IDM")
		Set task = db.Extraction
		task.IncludeAllFields
		dbName = "#GL#In_Period_Doc_Sum_Diff.IDM"
		task.AddExtraction dbName, "", " 傳票金額_JE_SUM <> 0"
		task.CreateVirtualDatabase = False
		task.PerformTask 1, db.Count
		Set task = Nothing
		Set db = Nothing
		Client.OpenDatabase (dbName)	
			
		Set db = Client.OpenDatabase("#GL#.IDM")
		Set task = db.JoinDatabase
		task.FileToJoin "#GL#In_Period_Doc_Sum_Diff.IDM"
		task.IncludeAllPFields
		task.IncludeAllSFields
		task.AddMatchKey "傳票號碼_JE", "傳票號碼_JE", "A"
		task.CreateVirtualDatabase = False
		dbName = "#GL_#Doc_not_Balance.IDM"
		task.PerformTask dbName, "", WI_JOIN_MATCH_ONLY
		Set task = Nothing
		Set db = Nothing
		Client.OpenDatabase (dbName)			
			
		If GetTotal("#GL_#Doc_not_Balance.IDM" ,"" ,"DBCount" ) <> 0 Then 
			
			If FindField("#GL_#Doc_not_Balance.IDM","DEBIT_傳票金額_JE_T") = 0 Then 
				Call Z_Field_Info("#GL_#Doc_not_Balance.IDM", "傳票金額_JE")
				Set db = Client.OpenDatabase("#GL_#Doc_not_Balance.IDM")
				Set task = db.TableManagement
				Set field = db.TableDef.NewField
				field.Name = "DEBIT_傳票金額_JE_T"
				field.Description = ""
				field.Type = WI_NUM_FIELD 'WI_VIRT_NUM
				field.Equation = "@If( 傳票金額_JE >= 0,  傳票金額_JE , 0 )"
				field.Decimals = sDecimals    
				task.AppendField field
				task.PerformTask
				Set task = Nothing
				Set db = Nothing
				Set field = Nothing         
			
				Set db = Client.OpenDatabase("#GL_#Doc_not_Balance.IDM")
				Set task = db.TableManagement
				Set field = db.TableDef.NewField
				field.Name = "CREDIT_傳票金額_JE_T"
				field.Description = ""
				field.Type = WI_NUM_FIELD 'WI_VIRT_NUM
				field.Equation = "@If( 傳票金額_JE < 0,  傳票金額_JE , 0 )"
				field.Decimals = sDecimals    
				task.AppendField field
				task.PerformTask
				Set task = Nothing
				Set db = Nothing
				Set field = Nothing
			
				Set db = Client.OpenDatabase("#GL_#Doc_not_Balance.IDM")
				Set task = db.Summarization
				task.AddFieldToSummarize "傳票號碼_JE"
				task.AddFieldToSummarize "總帳日期_JE"
				task.AddFieldToTotal "DEBIT_傳票金額_JE_T"
				task.AddFieldToTotal "CREDIT_傳票金額_JE_T"
				dbName = "#GL_#Doc_not_Balance_Sum.IDM"
				task.OutputDBName = dbName
				task.CreatePercentField = FALSE
				task.StatisticsToInclude = SM_SUM
				task.PerformTask
				Set task = Nothing
				Set db = Nothing
				Client.OpenDatabase (dbName)		
					
			End If 
				
			Call Z_Delete_File("#GL#In_Period_Doc_Sum.IDM")
			Call Z_Delete_File("#GL#In_Period_Doc_Sum_Diff.IDM")
			
		End If 
				
End Function