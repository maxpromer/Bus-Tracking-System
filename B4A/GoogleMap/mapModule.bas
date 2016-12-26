﻿Type=Activity
Version=6
ModulesStructureVersion=1
B4A=true
@EndOfDesignText@
#Region  Activity Attributes 
	#FullScreen: False
	#IncludeTitle: False
#End Region

Sub Process_Globals
	Dim timeUpdata As Timer
	Dim ShowInfo As String
End Sub

Sub Globals
	Dim mFragment As MapFragment
	Dim gmap As GoogleMap
	Dim http As HttpJob
	Dim socket As ASocket
	'socket.ClassActivity = Me
	
	Private Panel1 As Panel
	Private Panel2 As Panel
	Private EditText1 As EditText
	Private Panel3 As Panel
	Private ListView1 As ListView
	Private Panel4 As Panel
	Private Label1 As Label
	Private Button1 As Button
	Private Button2 As Button
	Private Button3 As Button
	Private Panel5 As Panel
	Private Panel6 As Panel
	Private ListView2 As ListView
	
	Dim TrackAllBus As List = Main.TrackAllBus
	Dim TrackBusName As Map
	
	Dim viewAnima1,viewAnima2 As Panel
	Dim viewAnimaX, viewAnimaY As Object
	
	Dim shortDistance As Int = 999999999
	Dim shortDistanceImei As String
	Dim FollowBus As Boolean = False
	Dim FollowImei As String
	
	Dim historyTrack As Map
	
	'Dim TouchstartX, TouchstartY As Int
	Dim TouchstartX As Int
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.LoadLayout("mainLayout")
	
	ListView1.SingleLineLayout.Label.TextColor = Colors.ARGB(255, 61, 61, 61)
	
	' Animation
	fadeIn(Panel3, 2000)
	
	Dim inList As List
	inList.Initialize
	
	If TrackAllBus.IsInitialized Then
		For i = 0 To TrackAllBus.Size - 1
			Dim m As Map = TrackAllBus.Get(0)
			If inList.IndexOf(m.Get("name")) == -1 Then 
				ListView1.AddSingleLine(m.Get("name"))
				inList.Add(m.Get("name"))
			End If
	    Next
	Else
		ToastMessageShow("Error TrackAllBus not Initialized : " & TrackAllBus, True)
	End If
	
	If mFragment.IsGooglePlayServicesAvailable = False Then
		ToastMessageShow("Google Play services not available.", True)
	Else
		mFragment.Initialize("Map", Panel1)
	End If
	
	ListView2.TwoLinesAndBitmap.Label.TextColor = Colors.ARGB(255, 61, 61, 61)
	ListView2.TwoLinesAndBitmap.Label.TextSize = 14
	ListView2.TwoLinesAndBitmap.Label.Left = ListView2.TwoLinesAndBitmap.ImageView.Left + ListView2.TwoLinesAndBitmap.ImageView.Width + (ListView2.TwoLinesAndBitmap.ImageView.Left * 2)
	ListView2.TwoLinesAndBitmap.Label.Top = 10dip
	'ListView2.TwoLinesAndBitmap.Label.Height = ListView1.TwoLinesAndBitmap.ItemHeight * 0.75
	ListView2.TwoLinesAndBitmap.SecondLabel.Visible = False
	'ListView2.TwoLinesAndBitmap.ImageView.Height = ListView2.TwoLinesAndBitmap.Label.Height
	'ListView2.TwoLinesAndBitmap.ImageView.Top = ListView2.TwoLinesAndBitmap.Label.Top
	SetDivider(ListView2, 0, 0)
	' ListView2.AddSingleLine("เกี่ยวกับโครงการ")
	ListView2.AddTwoLinesAndBitmap("ตารางเวลา", "Text#2", LoadBitmap(File.DirAssets, "time-icon.png"))
	ListView2.AddTwoLinesAndBitmap("เกี่ยวกับโครงการ", "Text#2", LoadBitmap(File.DirAssets, "info-icon.png"))
	'Button2_Click
End Sub

Sub Map_Ready
	gmap = mFragment.GetMap
	If gmap.IsInitialized = False Then
		ToastMessageShow("Error initializing map.", True)
	Else
		gmap.MyLocationEnabled = True
		Dim cp As CameraPosition
		cp.Initialize(13.4128433, 101.0620457, 10)
		gmap.AnimateCamera(cp)
   End If
End Sub

Sub Map_MarkerClick(SelectedMarker As Marker) As Boolean
	' ToastMessageShow(SelectedMarker.Title, False)
	ShowInfo = SelectedMarker.Title
	StartActivity(BusInfo)
	Return True
End Sub

Sub Activity_Resume

End Sub

Sub Activity_Pause (UserClosed As Boolean)
	Main.GExit = True
End Sub


Sub EditText1_TextChanged (Old As String, New As String)
	
End Sub

Sub ListView1_ItemClick (Position As Int, Value As Object)
	fadeOut(Panel3, 500)
	EditText1.Text = Value
	
	ProgressDialogShow("รอซักครู่...")
	http.Initialize("ListByName", Me)
	http.Download2("http://<Can not be revealed>:85/track", Array As String("name", EditText1.Text))
End Sub

Sub JobDone (Job As HttpJob)
	If Job.Success = True Then
		Select Job.JobName
			Case "ListByName"
				Dim strJson As String = Job.GetString
				Dim JSON As JSONParser
			    JSON.Initialize(strJson)
			    Dim ros As Map = JSON.NextObject
				Dim e As Boolean = ros.Get("e")
				If e = False Then
					Dim data As List = ros.Get("data")
					If TrackBusName.IsInitialized = False Then 
						TrackBusName.Initialize
					End If
					If historyTrack.IsInitialized = False Then 
						historyTrack.Initialize
					End If
					For i = 0 To data.Size - 1
						Dim row As Map = data.Get(i)
						Dim online As Boolean = row.Get("online")
						Dim imei As String = row.Get("imei")
						'Dim name As String = row.Get("name")
						'Dim car_number As Int = row.Get("car_number")
						Dim lat As Double = row.Get("latitude")
						Dim lng As Double = row.Get("longitude")
						Dim trackLog As List = row.Get("before")
							
						If historyTrack.ContainsKey(imei) = False Then
							historyTrack.Put(imei, trackLog)
						Else
							Dim before As List = historyTrack.Get(imei)
							before.AddAll(trackLog)
							historyTrack.Put(imei, before)
						End If
							
						' Dim m As Marker = gmap.AddMarker3(lat, lng, "รถเมล์สาย" & name & " เบอร์ " & car_number, SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-60x60.png")))
						Dim icon As Object = SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-90x90.png"))
						If online = False Then icon = SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-90x90-black.png"))
						Dim m As Marker = gmap.AddMarker3(lat, lng, imei, icon)
						TrackBusName.Put(imei, m)
					Next
				Else
					Dim msg As String = ros.Get("msg")
					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
				End If
		End Select
	Else
		ToastMessageShow("Error: " & Job.ErrorMessage, True)
	End If
	socket.Initialize("<Can not be revealed>", 86, "ASocket")
	If timeUpdata.IsInitialized = False Then
		timeUpdata.Initialize("timeUpdata", 3000)
	End If
	timeUpdata.Enabled = True
	EditText1.Enabled = False
	Button2.Visible = True
End Sub

Sub ASocket_Connected(Successful As Boolean)
	If Successful = False Then
		'ToastMessageShow("ไม่สามารถเปิด Socket เพื่ออัพเดทข้อมูลได้ : " & LastException.Message, True)
		Select Msgbox2("ไม่สามารถเชื่อมต่อไปยังเซิฟเวอร์ได้", "ปัญหาการเชื่อมต่อ", "ลองอีกครั้ง", "ไม่สนใจ", "", Null)
			Case DialogResponse.POSITIVE
				ASocket_Disconnect
		End Select
	End If
	TranslateTo(Panel4, Panel4.Left, (100%y - (Panel4.Height - 10dip - 1dip)), 500)
	UpdataBar
	ProgressDialogHide
End Sub

Sub ASocket_Disconnect
	socket.Reconnect
	ProgressDialogShow("กำลังเชื่อมต่อใหม่")
End Sub

Sub ASocket_NewData(event As String, data As Object)
	'Log(data)
	If event = "BUS:" & EditText1.Text Then
		Dim m As Map = data
		Dim imei As String = m.Get("imei")
		Dim location As Map = m.Get("location")
		Dim lat As Double = location.Get("lat")
		Dim lng As Double = location.Get("long")
		'Dim speed As Double = location.Get("speedkm")
		Dim marker As Marker = TrackBusName.Get(imei)
		Dim latlng As LatLng
		latlng.Initialize(lat, lng)
		marker.Position = latlng
		UpdataBar
		SetFollowBus
	End If
	'ToastMessageShow("Event: " & event & " , Data: " & data, True)
End Sub

Sub UpdataBar
	If gmap.MyLocation.IsInitialized = False Then
		Label1.Text = "ไม่พบที่อยู่ของคุณ"
		Return
	End If
	Dim MyLocal As LatLng = gmap.MyLocation
	
	shortDistance = 999999999
	For i = 0 To TrackBusName.Size - 1
		Dim listA As List = historyTrack.Get(TrackBusName.GetKeyAt(i))
		If listA.Size < 5 Then
			Continue
		End If
		Dim marker As Marker = TrackBusName.GetValueAt(i)
		Dim markerPos As LatLng = marker.Position
		Dim Distance As Int = getDistance(MyLocal.Latitude, MyLocal.Longitude, markerPos.Latitude, markerPos.Longitude)
		If Distance < shortDistance Then
			shortDistance = Distance
			shortDistanceImei = TrackBusName.GetKeyAt(i)
		End If
	Next
	
	Dim getTime As Boolean = False
	Dim trackLog As List = historyTrack.Get(shortDistanceImei)
	' Log(trackLog)
	If trackLog.Size >= 5 Then
		getTime = True
		Dim speedLog As List
		speedLog.Initialize
		Dim SumDistance As Float = 0
		For i = 1 To 4
			Dim track As Map = trackLog.Get(trackLog.Size - i)
			Dim track2 As Map = trackLog.Get(trackLog.Size - i - 1)
			Dim DistanceA As Float = getDistance(track.Get("latitude"), track.Get("longitude"), track2.Get("latitude"), track2.Get("longitude"))
			' speedLog.Add()
			SumDistance = SumDistance + DistanceA
		Next
		Dim speedkm As Double = NumberFormat(SumDistance / 4 / 30, 0, 2)
		Dim time2user As Int = shortDistance / speedkm / 60
	End If
	If getTime Then
		Label1.Text = "อีก " & time2user & " นาที รถเมล์จะมาถึง"
	Else
		If shortDistance < 1000 Then
			Label1.Text = "รถเมล์ใกล้สุดห่าง " & shortDistance & " เมตร"
		Else
			Label1.Text = "รถเมล์ใกล้สุดห่าง " & NumberFormat(shortDistance / 1000, 0, 1) & " กิโลเมตร"
		End If
	End If
	
End Sub

Sub getDistance(lat1 As Double, lng1 As Double, lat2 As Double, lng2 As Double) As Double
	Dim R As Int = 6378137 ' Earth’s mean radius in meter
	Dim dLat As Double = rad(lat2 - lat1)
	Dim dLong As Double = rad(lng2 - lng1)
	Dim a As Double = Sin(dLat / 2) * Sin(dLat / 2) + Cos(rad(lat1)) * Cos(rad(lat2)) * Sin(dLong / 2) * Sin(dLong / 2)
	Dim c As Double = 2 * ATan2(Sqrt(a), Sqrt(1 - a))
	Return R * c 'returns the distance in meter
End Sub

Sub rad(x As Double) As Double
	  Return x * 22 / 7 / 180
End Sub

Sub timeUpdata_Tick
	UpdataBar
End Sub

Sub Button1_Click
	Dim colorEnabledA = 0, colorPressedA = 0 As Int
	If FollowBus = False Then
		colorEnabledA = Colors.RGB(230, 0, 0)
		colorPressedA = Colors.RGB(179, 0, 0)
		FollowImei = shortDistanceImei
		If FollowImei = "" Then
			Msgbox("ไม่พบที่อยู่ของคุณกรุณาเปิด GPS", "ผิดพลาด")
			Return
		End If
		SetFollowBus
		FollowBus = True
		Button1.Text = "ยกเลิก"
	Else
		colorEnabledA = Colors.RGB(0, 123, 192)
		colorPressedA = Colors.RGB(0, 80, 126)
		FollowBus = False
		FollowImei = ""
		Button1.Text = "ติดตาม"
	End If
	Dim ColorEnabled As ColorDrawable
	ColorEnabled.Initialize(colorEnabledA, 0)
	Dim ColorPressed As ColorDrawable
	ColorPressed.Initialize(colorPressedA, 0)
	Dim Style As StateListDrawable
	Style.Initialize
	Style.AddState(Style.State_Enabled, ColorEnabled)
	Style.AddState(Style.State_Pressed, ColorPressed)
	Button1.Background = Style
	
	Dim Rec As Rect
	Dim Canvas1 As Canvas
	Rec.Initialize(0, 0, Panel4.Width, Panel4.Height)
	Canvas1.Initialize(Panel4)
	Canvas1.DrawRect(Rec, colorEnabledA, False, 4dip)
End Sub

Sub Button2_Click
	Button2.Visible = False
	EditText1.Text = ""
	EditText1.Enabled = True
	timeUpdata.Enabled = False
	TrackBusName.Clear
	TranslateTo(Panel4, Panel4.Left, 100%y, 500)
	fadeIn(Panel3, 500)
	gmap.Clear
End Sub

Sub Button3_Click
	TranslateTo(Panel5, 0, 0, 300)
	fadeIn(Panel6, 300)
End Sub

Sub Panel6_Click
	TranslateTo(Panel5, -70%x, 0, 300)
	fadeOut(Panel6, 300)
End Sub

Sub SetFollowBus
	If FollowBus = False Then Return
	If FollowImei = "" Then Return
	
	Dim marker As Marker = TrackBusName.Get(FollowImei)
	Dim latlng As LatLng
	latlng = marker.Position
	Dim cp As CameraPosition
	cp.Initialize(latlng.Latitude, latlng.Longitude, 18)
	gmap.AnimateCamera(cp)
End Sub

Sub TranslateTo(View As Panel, toX As Int, toY As Int, Duration As Int)
	View.Visible = True
	Dim startX As Int = View.Left
	Dim startY As Int = View.Top
	Dim anima As Animation
	anima.InitializeTranslate("AnimationTranslate", 0, 0, -(startX - toX), -(startY - toY))
	anima.Duration = Duration
	anima.RepeatCount = 0
	anima.RepeatMode = anima.REPEAT_RESTART
	anima.Start(View)
	viewAnima2 = View
	viewAnimaX = toX
	viewAnimaY = toY
End Sub

Sub AnimationTranslate_AnimationEnd
	viewAnima2.Left = viewAnimaX
	viewAnima2.Top = viewAnimaY
End Sub

Sub fadeIn(View As Panel, Duration As Int)
	View.Visible = True
	Dim anima As Animation
	anima.InitializeAlpha("", 0, 1)
	anima.Duration = Duration
	anima.RepeatCount = 0
	anima.RepeatMode = anima.REPEAT_RESTART
	anima.Start(View)
	viewAnima1 = View
End Sub

Sub fadeOut(View As Panel, Duration As Int)
	View.Visible = True
	Dim anima As Animation
	anima.InitializeAlpha("Animation", 1, 0)
	anima.Duration = Duration
	anima.RepeatCount = 0
	anima.RepeatMode = anima.REPEAT_RESTART
	anima.Start(View)
	viewAnima1 = View
End Sub

Sub Animation_AnimationEnd
    viewAnima1.Visible = False
End Sub

Sub SetBitmapDensity(b As Bitmap) As Bitmap
   Dim jo As JavaObject = b
   Dim den As Int = Density * 160
   jo.RunMethod("setDensity", Array(den))
   Return b
End Sub

Sub SetDivider(lv As ListView, Color As Int, Height As Int)
   Dim r As Reflector
   r.Target = lv
   Dim CD As ColorDrawable
   CD.Initialize(Color, 0)
   r.RunMethod4("setDivider", Array As Object(CD), Array As String("android.graphics.drawable.Drawable"))
   r.RunMethod2("setDividerHeight", Height, "java.lang.int")
End Sub


Sub Panel6_Touch (Action As Int, X As Float, Y As Float)
	' ToastMessageShow("panel touched",False)
	Select Action
		Case Activity.ACTION_DOWN
			TouchstartX = X
			'TouchstartY = Y
		Case Activity.ACTION_MOVE
			If TouchstartX - X >= 0dip Then
				Panel5.Left = -(TouchstartX - X)
			End If
		Case Activity.ACTION_UP
			If Abs(TouchstartX - X) > 30%x Then 
				Panel6_Click
			Else 
				TranslateTo(Panel5, 0, 0, 300)
			End If
   End Select
End Sub

Sub ListView2_ItemClick (Position As Int, Value As Object)
	Select Position
		Case 0
			StartActivity(timeTable)
		Case 1
			StartActivity(appinfo)
	End Select
End Sub