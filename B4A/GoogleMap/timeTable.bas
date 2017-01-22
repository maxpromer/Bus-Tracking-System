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

	Private ScrollView1 As ScrollView
	Private Button1 As Button
	
	Dim topPos As Int
End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.LoadLayout("sc_timeTable")
	
	SetStatusBarColor(Colors.RGB(25, 118, 210))
	
	'ScrollView1.Panel.LoadLayout("timeTable")
	ScrollView1.Panel.RemoveAllViews
	
	'ProgressDialogShow("รอซักครู่...")
	http.Initialize("LoadInfo", Me)
	http.Download("http://<Can not be revealed>:85/timetable")
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub

Sub JobDone (Job As HttpJob)
	If Job.Success = True Then
		Select Job.JobName
			Case "LoadInfo"
				Dim strJson As String = Job.GetString
				Dim JSON As JSONParser
			    JSON.Initialize(strJson)
			    Dim ros As Map = JSON.NextObject
				Dim e As Boolean = ros.Get("e")
				If e = False Then
					Dim listRoute As List = ros.Get("data")
					
					For i = 0 To listRoute.Size - 1
						Dim data As Map = listRoute.Get(i)
						Dim l_name As String = data.Get("name")
						Dim l_from As String = data.Get("from")
						Dim l_to As String = data.Get("to")
						Dim l_time As List = data.Get("time")
						
						Dim LabelRoute As Label
						LabelRoute.Initialize("LabelRoute")
						LabelRoute.TextSize = 14
						LabelRoute.TextColor = Colors.RGB(130, 130, 130)
						LabelRoute.Text = l_from & " -> " & l_to
						ScrollView1.Panel.AddView(LabelRoute, 20dip, topPos + 20dip, 100%x, 20dip)
						topPos = topPos + 20dip + 20dip + 10dip
						
'						Log(LabelRoute.Text)
'						Log(l_time)
						
						Dim FistH As Boolean = False
						For i2 = 0 To l_time.Size - 1
							Dim time As String = l_time.Get(i2)
							Dim time_arr(2) As String = Regex.split(":", time)
							Dim lHour As Int = time_arr(0)
							Dim lMin As Int = time_arr(1)
							Dim nHour As Int = DateTime.GetHour(DateTime.Now) 
							Dim nMin As Int = DateTime.GetMinute(DateTime.Now) 
							If FistH = False And lHour >= nHour And lMin >= nMin Then
								Dim panelTmp As Panel
								panelTmp.Initialize("panelTmp")
								panelTmp.Color = Colors.RGB(236, 236, 236)
								ScrollView1.Panel.AddView(panelTmp, 0, topPos, 100%x, 40dip)
								FistH = True
							End If
							Dim LabelTmp As Label
							LabelTmp.Initialize("LabelTmp")
							LabelTmp.TextSize = 20
							LabelTmp.TextColor = Colors.RGB(100, 100, 100)
							LabelTmp.Text = l_name
							LabelTmp.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
							
							Dim LabelTmp2 As Label
							LabelTmp2.Initialize("LabelTmp2")
							LabelTmp2.TextSize = 22
							LabelTmp2.TextColor = Colors.RGB(62, 62, 62)
							LabelTmp2.Text = time
							LabelTmp2.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.RIGHT)
							ScrollView1.Panel.AddView(LabelTmp, 20dip, topPos, 100%x - 40dip, 40dip)
							ScrollView1.Panel.AddView(LabelTmp2, 20dip, topPos, 100%x - 40dip, 40dip)
							topPos = topPos + 40dip
						Next
					Next
					ScrollView1.Panel.Height = topPos + 20dip
					'ProgressDialogHide
				Else
					Dim msg As String = ros.Get("msg")
					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
				End If
		End Select
	Else
		ToastMessageShow("Error: " & Job.ErrorMessage, True)
	End If
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