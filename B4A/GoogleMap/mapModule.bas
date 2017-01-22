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
	Dim AllPlaces As List = Main.AllPlaces
	Dim TrackBusMarker As Marker
	Dim TrackBus As Map
	Dim MakePoint As List
	
	Dim viewAnima1,viewAnima2 As Panel
	Dim viewAnimaX, viewAnimaY As Object

	Dim FollowBus As Boolean = False
	
	Dim historyTrack As List
	
	'Dim TouchstartX, TouchstartY As Int
	Dim TouchstartX As Int
	
	Dim SelectPlace As Int
	Private Panel8 As Panel
	Private ListView3 As ListView
	
'	Dim Panel8_TouchstartY As Float
End Sub

Sub Activity_Create(FirstTime As Boolean)
	Activity.LoadLayout("mainLayout")
	
	If TrackBus.IsInitialized = False Then
		TrackBus.Initialize
	End If
	
	ListView1.SingleLineLayout.Label.TextColor = Colors.ARGB(255, 61, 61, 61)
	
	' Animation
	fadeIn(Panel3, 2000)
	
	Dim inList As List
	inList.Initialize
	
	If AllPlaces.IsInitialized Then
'		For i = 0 To TrackAllBus.size - 1
'			Dim m As Map = TrackAllBus.get(0)
'			If inList.indexof(m.get("name")) == -1 Then 
'				ListView1.addsingleline(m.get("name"))
'				inList.add(m.get("name"))
'			End If
'	    Next
		
		For i = 0 To AllPlaces.size - 1
			Dim m As Map = AllPlaces.get(i)
			ListView1.addsingleline(m.get("name"))
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
	If SelectedMarker.Title = "จุดเริ่มต้น" Or SelectedMarker.Title = "จุดสิ้นสุด" Then
		Return False
	End If
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
	' fadeOut(Panel3, 500)
	EditText1.Text = Value

	ProgressDialogShow("รอซักครู่...")
'	http.Initialize("ListByName", Me)
	http.Initialize("TrackPlace", Me)
	If gmap.MyLocation.IsInitialized Then
		Dim MyLocal As LatLng = gmap.MyLocation
		http.Download2("http://<Can not be revealed>:85/track", Array As String("place", EditText1.Text, "location", $"${MyLocal.Latitude},${MyLocal.Longitude}"$))
	Else
		http.Download2("http://<Can not be revealed>:85/track", Array As String("place", EditText1.Text))
	End If
	SelectPlace = Position
End Sub

Sub JobDone (Job As HttpJob)
	If Job.Success = True Then
		Select Job.JobName

			Case "TrackPlace"
				Dim strJson As String = Job.GetString
'				Log(strJson)
				Dim JSON As JSONParser
			    JSON.Initialize(strJson)
			    Dim ros As Map = JSON.NextObject
				Dim e As Boolean = ros.Get("e")
				If e = False Then
					Dim dataMap As Map = ros.Get("data")
					Dim point As List = dataMap.Get("point")
					gmap.Clear
					
					Dim pl As Polyline = gmap.AddPolyline
					Dim points As List
					points.Initialize
					For i = 0 To point.Size - 1
						Dim local As Map = point.Get(i)
						Dim l As LatLng
						l.Initialize(local.Get("lat"), local.Get("long"))
						points.Add(l)
					Next
					pl.Color = Colors.ARGB(255, 236, 233, 0)
					pl.points = points
					
					Dim place As Map = AllPlaces.get(SelectPlace)
					
					Dim local1 As Map = point.Get(0)
					Dim local2 As Map = point.Get(point.Size - 1)
					
					gmap.AddMarker(local1.Get("lat"), local1.Get("long"), "จุดเริ่มต้น")
					gmap.AddMarker(local2.Get("lat"), local2.Get("long"), "จุดสิ้นสุด")
					
					Dim cp As CameraPosition
					cp.Initialize((local1.Get("lat") + local2.Get("lat")) / 2, (local1.Get("long") + local2.Get("long")) / 2, 12)
					gmap.AnimateCamera(cp)
					
					EditText1.Enabled = False
					Button2.Visible = True
					fadeOut(Panel3, 500)
					
					Dim listbus As List = dataMap.Get("busline")

					ListView3.Clear
					ListView3.TwoLinesAndBitmap.Label.TextColor = Colors.ARGB(255, 61, 61, 61)
					ListView3.TwoLinesAndBitmap.ImageView.Left = 20dip
					ListView3.TwoLinesAndBitmap.Label.Left = ListView3.TwoLinesAndBitmap.ImageView.Width + 30dip
					ListView3.TwoLinesAndBitmap.SecondLabel.Left = ListView3.TwoLinesAndBitmap.Label.Left
					ListView3.AddTwoLinesAndBitmap2("ดูเส้นทาง", "แสดงเส้นทางบนแผนที่", LoadBitmap(File.DirAssets, "a-b-make-icon-90x90.png"), 0)
					For i = 0 To listbus.Size - 1
						Dim row As Map = listbus.Get(i)
'						Dim online As Boolean = row.Get("online")
'						Dim imei As String = row.Get("imei")
						Dim name As String = row.Get("name")
						Dim car_number As Int = row.Get("car_number")
'						Dim lat As Double = row.Get("latitude")
'						Dim lng As Double = row.Get("longitude")
'						Dim trackLog As List = row.Get("before")
						
						ListView3.AddTwoLinesAndBitmap2(name & " เบอร์ " & car_number, "ประเภท: รถโดยสารประจำทาง", LoadBitmap(File.DirAssets, "bus-icon-90x90.png"), row)
					Next
					
					Panel8.Visible = True
					TranslateTo(Panel8, 0, Panel2.Top + Panel2.Height + 20dip, 500)
					ProgressDialogHide
				Else
					Dim msg As String = ros.Get("msg")
					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
					ProgressDialogHide
				End If
				
			Case "BuslineInfo"
'				Log("BuslineInfo")
				Dim strJson As String = Job.GetString
'				Log(strJson)
				Dim JSON As JSONParser
			    JSON.Initialize(strJson)
			    Dim ros As Map = JSON.NextObject
				Dim e As Boolean = ros.Get("e")
				If e = False Then
					Dim dataMap As Map = ros.Get("data")
					MakePoint = dataMap.Get("make-point")
					
					socket.Initialize("<Can not be revealed>", 86, "ASocket")
					If timeUpdata.IsInitialized = False Then
						timeUpdata.Initialize("timeUpdata", 3000)
					End If
					timeUpdata.Enabled = True
				Else
					Dim msg As String = ros.Get("msg")
					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
				End If
				ProgressDialogHide
				
'			Case "ListByName"
'				Dim strJson As String = Job.GetString
'				Dim JSON As JSONParser
'			    JSON.Initialize(strJson)
'			    Dim ros As Map = JSON.NextObject
'				Dim e As Boolean = ros.Get("e")
'				If e = False Then
'					Dim dataList As List = ros.Get("data")
'					Log(dataList)
'					
'					ListView3.Clear
'					ListView3.TwoLinesAndBitmap.Label.TextColor = Colors.ARGB(255, 61, 61, 61)
'					ListView3.TwoLinesAndBitmap.ImageView.Left = 20dip
'					ListView3.TwoLinesAndBitmap.Label.Left = ListView3.TwoLinesAndBitmap.ImageView.Width + 30dip
'					ListView3.TwoLinesAndBitmap.SecondLabel.Left = ListView3.TwoLinesAndBitmap.Label.Left
'					ListView3.AddTwoLinesAndBitmap2("ดูเส้นทาง", "แสดงเส้นทางบนแผนที่", LoadBitmap(File.DirAssets, "a-b-make-icon-90x90.png"), 0)
'					For i = 0 To dataList.Size - 1
'						Dim row As Map = dataList.Get(i)
''						Dim online As Boolean = row.Get("online")
''						Dim imei As String = row.Get("imei")
'						Dim name As String = row.Get("name")
'						Dim car_number As Int = row.Get("car_number")
''						Dim lat As Double = row.Get("latitude")
''						Dim lng As Double = row.Get("longitude")
''						Dim trackLog As List = row.Get("before")
'						
'						ListView3.AddTwoLinesAndBitmap2(name & " เบอร์ " & car_number, "รออีก ... นาที", LoadBitmap(File.DirAssets, "bus-icon-90x90.png"), row)
'					Next
'					
'					
'					Panel8.Visible = True
'					TranslateTo(Panel8, 0, Panel2.Top + Panel2.Height + 20dip, 500)
'					ProgressDialogHide
'					If TrackBusName.IsInitialized = False Then 
'						TrackBusName.Initialize
'					End If
'					If historyTrack.IsInitialized = False Then 
'						historyTrack.Initialize
'					End If
'					For i = 0 To data.Size - 1
'						Dim row As Map = data.Get(i)
'						Dim online As Boolean = row.Get("online")
'						Dim imei As String = row.Get("imei")
'						'Dim name As String = row.Get("name")
'						'Dim car_number As Int = row.Get("car_number")
'						Dim lat As Double = row.Get("latitude")
'						Dim lng As Double = row.Get("longitude")
'						Dim trackLog As List = row.Get("before")
'							
'						If historyTrack.ContainsKey(imei) = False Then
'							historyTrack.Put(imei, trackLog)
'						Else
'							Dim before As List = historyTrack.Get(imei)
'							before.AddAll(trackLog)
'							historyTrack.Put(imei, before)
'						End If
'							
'						' Dim m As Marker = gmap.AddMarker3(lat, lng, "รถเมล์สาย" & name & " เบอร์ " & car_number, SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-60x60.png")))
'						Dim icon As Object = SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-90x90.png"))
'						If online = False Then icon = SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-90x90-black.png"))
'						Dim m As Marker = gmap.AddMarker3(lat, lng, imei, icon)
'						TrackBusName.Put(imei, m)
'					Next
'				Else
'					Dim msg As String = ros.Get("msg")
'					Msgbox("เกิดปัญหากับการเชื่อมต่อเซิฟเวอร์ : " & msg, "ผิดพลาด")
'				End If
'				ProgressDialogHide
		End Select
	Else
		ToastMessageShow("Error: " & Job.ErrorMessage, True)
	End If
	
'	socket.Initialize("<Can not be revealed>", 86, "ASocket")
'	If timeUpdata.IsInitialized = False Then
'		timeUpdata.Initialize("timeUpdata", 3000)
'	End If
'	timeUpdata.Enabled = True
'	EditText1.Enabled = False
'	Button2.Visible = True
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
	Dim m As Map = data
	Dim imei As String = m.Get("imei")
	If imei = TrackBus.Get("imei") Then
		If event = "UPDATE" Then
			Dim location As Map = m.Get("location")
			Dim lat As Double = location.Get("lat")
			Dim lng As Double = location.Get("long")
			'Dim speed As Double = location.Get("speedkm")
			Dim latlng As LatLng
			latlng.Initialize(lat, lng)
			TrackBusMarker.Position = latlng
			UpdataBar
			SetFollowBus
		Else If event = "REMOVE" Then
			' รอเพิ่ม
			Msgbox("ขณะนี้รถโดยสารที่ท่านเลือก ได้ออกจากระบบการให้บริการ", "ผิดพลาด")
			Button2_Click
			socket.Close
		End If
	End If
	'ToastMessageShow("Event: " & event & " , Data: " & data, True)
End Sub

Sub UpdataBar
	Dim Distance As Int = 0
	If gmap.MyLocation.IsInitialized = False Then
		Label1.Text = "ไม่พบที่อยู่ของคุณ"
		Return
	End If
	Dim MyLocal As LatLng = gmap.MyLocation
	Dim BusLocal As LatLng = TrackBusMarker.Position
'	Log(MyLocal)
'	Log(BusLocal)
'	
'	Log(MakePoint)
	Distance = DistanceByMakepoint(MakePoint, MyLocal.Latitude, MyLocal.Longitude, BusLocal.Latitude, BusLocal.Longitude)
'	Log(Distance)
	If historyTrack.Size >= 5 Then
		Dim speedLog As List
		speedLog.Initialize
		Dim SumDistance As Float = 0
		For i = 1 To 4
			Dim track As Map = historyTrack.Get(historyTrack.Size - i)
			Dim track2 As Map = historyTrack.Get(historyTrack.Size - i - 1)
			Dim DistanceA As Float = getDistance(track.Get("latitude"), track.Get("longitude"), track2.Get("latitude"), track2.Get("longitude"))
			' speedLog.Add()
			SumDistance = SumDistance + DistanceA
		Next
'		Log(SumDistance)
		Dim speedkm As Double = SumDistance / 4 / 30
'		Log(speedkm)
		Dim time2user As Int = Distance / speedkm / 60
'		Log(time2user)
		
		Label1.Text = "อีก " & time2user & " นาที รถเมล์จะมาถึง"
	Else
		Label1.Text = "รถเมล์ใกล้สุดห่าง " & NumberFormat(Distance, 0, 2) & " กิโลเมตร"
	End If
	
End Sub

Sub getDistance(lat1 As Double, lng1 As Double, lat2 As Double, lng2 As Double) As Double
	Dim R As Int = 6371
	Dim dLat As Double = rad(lat2 - lat1)
	Dim dLong As Double = rad(lng2 - lng1)
	Dim a As Double = Sin(dLat / 2) * Sin(dLat / 2) + Cos(rad(lat1)) * Cos(rad(lat2)) * Sin(dLong / 2) * Sin(dLong / 2)
	Dim c As Double = 2 * ATan2(Sqrt(a), Sqrt(1 - a))
	Return R * c ' returns the distance in km
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
		If gmap.MyLocationEnabled = False Then
			Msgbox("ไม่พบที่อยู่ของคุณกรุณาเปิด GPS", "ผิดพลาด")
			Return
		End If
		FollowBus = True
		SetFollowBus
		Button1.Text = "ยกเลิก"
	Else
		colorEnabledA = Colors.RGB(0, 123, 192)
		colorPressedA = Colors.RGB(0, 80, 126)
		FollowBus = False
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
'	TrackBusName.Clear
	TranslateTo(Panel4, Panel4.Left, 100%y, 500)
	fadeIn(Panel3, 500)
	TranslateTo(Panel8, 0, 100%y, 500)
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

	Dim latlng As LatLng
	latlng = TrackBusMarker.Position
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

Sub ListView3_ItemClick (Position As Int, Value As Object)
	If Position <> 0 Then
		TrackBus = Value
		
'		Dim online As Boolean = row.Get("online")
'		Dim imei As String = row.Get("imei")
		Dim name As String = TrackBus.Get("name")
		Dim car_number As Int = TrackBus.Get("car_number")
		Dim lat As Double = TrackBus.Get("latitude")
		Dim lng As Double = TrackBus.Get("longitude")
		historyTrack = TrackBus.Get("before")
		
		Dim icon As Object = SetBitmapDensity(LoadBitmap(File.DirAssets, "bus-icon-90x90.png"))
		TrackBusMarker = gmap.AddMarker3(lat, lng, name & " เบอร์ " & car_number, icon)
		
'		Log("Load bus info")
		http.Initialize("BuslineInfo", Me)
		http.Download2("http://<Can not be revealed>:85/busline", Array As String("name", name))
		ProgressDialogShow("รอซักครู่...")
	End If
	TranslateTo(Panel8, 0, 100%y, 500)
End Sub

Sub DistanceByMakepoint(point As List, startLat As Double, startLong As Double, endLat As Double, endLong As Double) As Double
	Dim makepointStartLat As Double = 0
	Dim makepointStartLong As Double = 0
	Dim minDistanceStart As Double = Power(10, 12)
	Dim makepointEndLat As Double = 0
	Dim makepointEndLong As Double = 0
	Dim minDistanceEnd As Int = Power(10, 12)
	Dim indexStart As Int = -1
	Dim indexEnd As Int = -1
	
'	Log(minDistanceStart)
'	Log(point)
	For index = 0 To point.Size - 1
		Dim pointRow As List = point.Get(index)
		Dim tmpDistance As Double = getDistance(startLat, startLong, pointRow.Get(0), pointRow.Get(1))
'		Log("tmpDistance = " & tmpDistance)
		If tmpDistance < minDistanceStart Then
			makepointStartLat = pointRow.Get(0)
			makepointStartLong = pointRow.Get(1)
			minDistanceStart = tmpDistance
			indexStart = index
'			Log("Set indexStart = " & indexStart)
		End If
		
		Dim tmpDistance2 As Double = getDistance(endLat, endLong, pointRow.Get(0), pointRow.Get(1))
'		Log("tmpDistance2 = " & tmpDistance2)
		If tmpDistance2 < minDistanceEnd Then
			makepointEndLat = pointRow.Get(0)
			makepointEndLong = pointRow.Get(1)
			minDistanceEnd = tmpDistance2
			indexEnd = index
'			Log("Set indexEnd = " & indexEnd)
		End If
	Next
	
	
'	Log(minDistanceStart)
'	Log(makepointStartLat & "," & makepointStartLong)
'	Log(minDistanceEnd)
'	Log(makepointEndLat & "," & makepointEndLong)
'	Log(indexStart)
'	Log(indexEnd)

	Dim Distance As Double = minDistanceStart
	Dim indexSele As Int
	Dim notindexSele As Int
	
	If indexStart < indexEnd Then
		indexSele = indexEnd
		notindexSele = indexStart
	Else
		indexSele = indexStart
		notindexSele = indexEnd
	End If
	
'	Log("inNewLoop")
'	Log("Start is " & indexSele)
'	Log("End is " & notindexSele)
	For index = indexSele To notindexSele Step -1
		Dim pointRow As List = point.Get(index)
'		Log(pointRow)
		Dim indexNext As Int
		If index < indexSele Then
			indexNext = index + 1
		Else
			indexNext = index
		End If
		Dim pointRowNext As List = point.Get(indexNext)
		Distance = Distance + getDistance(pointRow.Get(0), pointRow.Get(1), pointRowNext.Get(0), pointRowNext.Get(1))
	Next
'	Log("Outloop")
	Distance = Distance + minDistanceEnd
	Distance = Round2(Distance, 2)
	
'	Log("New Distance is " & Distance & " km.")
'	Log("Old Distance is " & NumberFormat(getDistance(startLat, startLong, endLat, endLong), 0, 2) & " km.")

	Return Distance
End Sub
