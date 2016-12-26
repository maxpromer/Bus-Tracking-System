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

End Sub

Sub Globals
	Dim mFragment As MapFragment
	Dim gmap As GoogleMap
	Private Panel1 As Panel
	Private Panel2 As Panel
	Private EditText1 As EditText
	Private Panel3 As Panel
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.LoadLayout("mainLayout")
	Panel1.Width = 100%x
	Panel1.Height = 100%y
	Panel2.Width = 100%x - 40dip
	Panel2.Left = 20dip
	Panel2.Top = 20dip
	EditText1.Width = 100%x - 40dip - 10dip

	If mFragment.IsGooglePlayServicesAvailable = False Then
		ToastMessageShow("Google Play services not available.", True)
	Else
		mFragment.Initialize("Map", Panel1)
	End If
End Sub

Sub Map_Ready
   Log("map ready")
   gmap = mFragment.GetMap
   If gmap.IsInitialized = False Then
      ToastMessageShow("Error initializing map.", True)
   Else
      gmap.AddMarker(36, 15, "Hello!!!")
      Dim cp As CameraPosition
      cp.Initialize(36, 15, gmap.CameraPosition.Zoom)
      gmap.AnimateCamera(cp)
   End If
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)

End Sub
