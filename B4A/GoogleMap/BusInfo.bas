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
	Dim NameTmp As String
	Private ImageView1 As ImageView
	Private Label4 As Label
	Private Label5 As Label
	Private Label6 As Label
	Private Button1 As Button
	Private Button2 As Button
End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.LoadLayout("BusInfo")
	
	SetStatusBarColor(Colors.RGB(25, 118, 210))
	
	ProgressDialogShow("รอซักครู่")
	
	NameTmp = ""
	For i=0 To 6
		NameTmp = NameTmp & Chr(Rnd(33, 127))
	Next
	
	http.Initialize("LoadInfo", Me)
	http.Download("http://<Can not be revealed>:85/track/" & InfoImei)
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)
	CallSub(ImageDownloader, "ActivityIsPaused")
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
					Dim data As Map = ros.Get("data")
					Dim imagepath As String = data.Get("picture")
					Dim links As Map
   					links.Initialize
   					links.Put(ImageView1, imagepath)
					CallSubDelayed2(ImageDownloader, "Download", links)
					Label4.Text = data.Get("driver")
					Label5.Text = data.Get("car_number")
					Label6.Text = data.Get("name")
					ProgressDialogHide
				Else
					Dim msg As String = ros.Get("msg")
					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
				End If
		End Select
	Else
		ToastMessageShow("Error: " & Job.ErrorMessage, True)
	End If
End Sub

Sub Button1_Click
	Activity.Finish
End Sub

Sub Button2_Click
	StartActivity(trackHistory)
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
