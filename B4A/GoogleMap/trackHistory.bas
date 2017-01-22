Type=Activity
Version=6
ModulesStructureVersion=1
B4A=true
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	'These global variables will be declared once when the application starts.
	'These variables can be accessed from all modules.

	Dim http As HttpJob
End Sub

Sub Globals
	'These global variables will be redeclared each time the activity is created.
	'These variables can only be accessed from this module.

	Dim InfoImei As String = mapModule.ShowInfo
	
	Private ScrollView1 As ScrollView
	Private Button1 As Button
	
	Dim topPos As Int
	
End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.LoadLayout("layoutHistory")

	SetStatusBarColor(Colors.RGB(25, 118, 210))
	
	'ScrollView1.Panel.LoadLayout("timeTable")
	ScrollView1.Panel.RemoveAllViews
	
	http.Initialize("LoadInfo", Me)
	http.Download("http://<Can not be revealed>:85/track/" & InfoImei & "/history")
End Sub

Sub JobDone (Job As HttpJob)
	If Job.Success = True Then
		ProgressDialogHide
		Select Job.JobName
			Case "LoadInfo"
				Dim strJson As String = Job.GetString
				Dim JSON As JSONParser
			    JSON.Initialize(strJson)
			    Dim ros As Map = JSON.NextObject
				Dim e As Boolean = ros.Get("e")
				If e = False Then
					Dim data As List = ros.Get("data")
					Dim tableHistory As Map
					If tableHistory.IsInitialized = False Then 
						tableHistory.Initialize
					End If
					For i = 0 To data.Size - 1
						Dim m_h As Map = data.Get(i)
						Dim start_h As Long = m_h.Get("start") * 1000
						Dim end_h As Long = m_h.Get("end") * 1000
						Dim time As Int = Abs(end_h  / 1000 - start_h / 1000) / 60
						DateTime.SetTimeZone(7)
   						DateTime.TimeFormat = "HH:mm"
						Dim mapList As Map
						mapList.Initialize
						mapList.Put("TimeHM", DateTime.Time(start_h) & " - " & DateTime.Time(end_h))
						mapList.Put("Timet", time & " นาที")
						
						DateTime.DateFormat = "dd/MM/yyyy"
						Dim date As String = DateTime.Date(start_h)
						If tableHistory.ContainsKey(date) Then
							Dim before As List = tableHistory.Get(date)
							before.Add(mapList)
							tableHistory.Put(date, before)
						Else
							Dim listA As List
							If listA.IsInitialized = False Then listA.Initialize
							listA.Add(mapList)
							tableHistory.Put(date, listA)
						End If
					Next
					For i = 0 To tableHistory.Size - 1
						Dim LabelRoute As Label
						LabelRoute.Initialize("LabelRoute")
						LabelRoute.TextSize = 14
						LabelRoute.TextColor = Colors.RGB(130, 130, 130)
						LabelRoute.Text = tableHistory.GetKeyAt(tableHistory.Size - 1 - i)
						ScrollView1.Panel.AddView(LabelRoute, 20dip, topPos + 20dip, 100%x, 20dip)
						topPos = topPos + 20dip + 20dip
						
						Dim l_time As List = tableHistory.GetValueAt(tableHistory.Size - 1 - i)
						
						For i2 = 0 To l_time.Size - 1
							Dim mTime As Map = l_time.Get(i2)

							Dim LabelTmp As Label
							LabelTmp.Initialize("LabelTmp")
							LabelTmp.TextSize = 20
							LabelTmp.TextColor = Colors.RGB(100, 100, 100)
							LabelTmp.Text = mTime.Get("TimeHM")
							LabelTmp.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
							
							Dim LabelTmp2 As Label
							LabelTmp2.Initialize("LabelTmp2")
							LabelTmp2.TextSize = 22
							LabelTmp2.TextColor = Colors.RGB(62, 62, 62)
							LabelTmp2.Text = mTime.Get("Timet")
							LabelTmp2.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.RIGHT)
							ScrollView1.Panel.AddView(LabelTmp, 20dip, topPos, 100%x - 40dip, 40dip)
							ScrollView1.Panel.AddView(LabelTmp2, 20dip, topPos, 100%x - 40dip, 40dip)
							topPos = topPos + 40dip
						Next
					Next
					ScrollView1.Panel.Height = topPos + 20dip
				Else
					Dim msg As String = ros.Get("msg")
					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
				End If
		End Select
	Else
		ToastMessageShow("Error: " & Job.ErrorMessage, True)
	End If
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub

Sub SetStatusBarColor(clr As Int)
   Dim p As Phone
   If p.SdkVersion >= 21 Then
     Dim jo As JavaObject
     jo.InitializeContext
     Dim window As JavaObject = jo.RunMethodJO("getWindow", Null)
     window.RunMethod("addFlags", Array (0x80000000))
     window.RunMethod("clearFlags", Array (0x04000000))
     window.RunMethod("setStatusBarColor", Array(clr))
   End If
End Sub

Sub Button1_Click
	Activity.Finish
End Sub
