Type=Class
Version=6
ModulesStructureVersion=1
B4A=true
@EndOfDesignText@

Sub Class_Globals
	Private Socket As Socket
	Private AStreams As AsyncStreams
	Private A_event As String
	Public ClassActivity As Object = mapModule
	Private aHost As String
	Private aPort As Int
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Host As String, Port As Int, Event As String)
	If Socket.Connected Then Socket.Close
	If Socket.IsInitialized = False Then Socket.Initialize("TCPSocket")
	Socket.Connect(Host, Port, 2000)
	A_event = Event
	aHost = Host
	aPort = Port
End Sub

Public Sub Reconnect
	If AStreams.IsInitialized Then AStreams.Close
	If Socket.Connected Then Socket.Close
	' Log(aHost)
	' Log(aPort)
	If Socket.IsInitialized = False Then Socket.Initialize("TCPSocket")
	Socket.Connect(aHost, aPort, 2000)
End Sub

Sub TCPSocket_Connected (Successful As Boolean)
	If Successful Then
		AStreams.Initialize(Socket.InputStream, Socket.OutputStream, "AStreams")
	Else
		ToastMessageShow("Error connect : " & LastException.Message, True)
	End If
	If SubExists(ClassActivity, A_event & "_Connected") Then
		CallSub2(ClassActivity, A_event & "_Connected", Successful)
	End If
End Sub

Sub AStreams_NewData (Buffer() As Byte)
	Dim strJson As String = BytesToString(Buffer, 0, Buffer.Length, "UTF8")
	Dim JSON As JSONParser
	JSON.Initialize(strJson)
	Dim ros As Map = JSON.NextObject
	If SubExists(ClassActivity, A_event & "_NewData") Then
		CallSub3(ClassActivity, A_event & "_NewData", ros.Get("event"), ros.Get("data"))
	End If
End Sub

Sub AStreams_Error
    ToastMessageShow(LastException.Message, True)
	
	If SubExists(ClassActivity, A_event & "_Disconnect") Then
		CallSub(ClassActivity, A_event & "_Disconnect")
	End If
End Sub

Public Sub Send(Event As String, data As Object)
	Dim dataTmp As Map
	dataTmp.Initialize
	dataTmp.Put("event", Event)
	dataTmp.Put("data", data)
	Dim JSONGenerator As JSONGenerator
    JSONGenerator.Initialize(dataTmp)
	Dim Text As String = JSONGenerator.ToString
    AStreams.Write(Text.GetBytes("UTF8"))
End Sub

Public Sub Close
	If AStreams.IsInitialized Then AStreams.Close
	If Socket.Connected Then Socket.Close
End Sub