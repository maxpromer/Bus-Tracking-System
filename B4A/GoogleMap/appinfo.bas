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

End Sub

Sub Globals
	'These global variables will be redeclared each time the activity is created.
	'These variables can only be accessed from this module.

	Private Button1 As Button
End Sub

Sub Activity_Create(FirstTime As Boolean)
	'Do not forget to load the layout file created with the visual designer. For example:
	Activity.LoadLayout("appinfo")
	
	SetStatusBarColor(Colors.RGB(25, 118, 210))

End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub

Sub Button1_Click
	Activity.Finish
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