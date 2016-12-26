#include <AltSoftSerial.h>

AltSoftSerial mySerial;

#define LEDGPS  A1
#define LEDSEND A0

#define MODULEONOFF_PIN 4

String ModuleIMEI = "";
bool onConnect = false;
long StartGPSDisconnect = -1;

typedef struct GPS {
  float latitude;
  float longitude;
  float speed;
};

void setup() {
  pinMode(LEDGPS, OUTPUT);
  pinMode(LEDSEND, OUTPUT);
  pinMode(MODULEONOFF_PIN, OUTPUT);
  digitalWrite(MODULEONOFF_PIN, HIGH);
  
  Serial.begin(9600);
  mySerial.begin(9600);

  Serial.println("Turn ON 3G Module.");
  loopRestartModule();
}

void loop() {
  isInternet(&onConnect);
  Serial.print("Internet is ");
  Serial.println(onConnect ? "ON" : "OFF");
  if (!onConnect) { 
    Serial.println("Trun on internet.");
    onConnect = OnInternet("true"); // On Internet
    if (onConnect && !getIMEI(&ModuleIMEI)) {
      onConnect = false;
    }
    delay(500);
    return;
  }

  GPS gps;
  if (!GetPosition(&gps)) {
    Serial.println("Fail get location.");
    digitalWrite(LEDGPS, !digitalRead(LEDGPS));
    if (StartGPSDisconnect == -1) {
      StartGPSDisconnect = millis();
    } else if (((millis() - StartGPSDisconnect) / 1000) > (2 * 60)) {
      Serial.println("GPS get timeout for 2min, restart module.");
      loopRestartModule();
      StartGPSDisconnect = -1;
    }
    // Serial.println((millis() - StartGPSDisconnect) / 1000);
    delay(500);
    return;
  }
  StartGPSDisconnect = -1;
  
  if (gps.latitude == 0.0 && gps.longitude == 0.0 && gps.speed == 0.0) {
    Serial.println("Get location error.");
    return;
  }
  digitalWrite(LEDGPS, HIGH);
  
  Serial.print("Location is ");
  Serial.print(gps.latitude, 6);
  Serial.print(F(", "));
  Serial.print(gps.longitude, 6);
  Serial.print(F(", "));
  Serial.print(gps.speed);
  Serial.println();
  
  Serial.println("Connect to server.");
  digitalWrite(LEDSEND, HIGH);
  
  long hStart = millis();
  
  String content, url = "<Can not be revealed>";
  url += "?imei=" + ModuleIMEI;
  url += "&latitude=" + String(gps.latitude, 6);
  url += "&longitude=" + String(gps.longitude, 6);
  url += "&speedkm=" + String(gps.speed);
  url += "&verify=" + <Can not be revealed>;
  Serial.println(url);
  bool getSuccess = httpget(url, &content);
  Serial.println("load time is " + String(millis() - hStart));
  if (getSuccess) {
    Serial.println(content);
    digitalWrite(LEDSEND, LOW);
    delay(30000 - (millis() - hStart));
  } else {
    Serial.println("Fail for get.");
    delay(100);
    for (int i=0;i<4;i++) {
      digitalWrite(LEDSEND, HIGH);
      delay(50);
      digitalWrite(LEDSEND, LOW);
      delay(50);
    }
  }
}

bool testOnline() {
  return SendCommand("AT");
}

bool OnInternet(String Operator) {
  bool onConnect;
  isInternet(&onConnect);
  if (onConnect) {
    Serial.println("Internet Now ON");
    return true;
  }
  
  String arg[3];
  Operator.toLowerCase();

  // Set default
  arg[0] = "internet"; // APN
  arg[1] = ""; // Username
  arg[2] = ""; // Password
  if (Operator == "ais" || Operator == "tot" || Operator == "mybycat") {
    // Use default
  } else if (Operator == "dtac") {
    arg[0] = "www.dtac.co.th"; // APN
  } else if (Operator == "true") {
    arg[1] = "True"; // Username
    arg[2] = "true"; // Password
  } else {
    Serial.println("Not support operator '" + String(Operator) + "'");
    return false;
  }
  
  bool err;
  String content;

  // Setup internet
  SendCommand("AT+QICSGP=1,1,\"" + arg[0] + "\",\"" + arg[1] + "\",\"" + arg[2] + "\",1", &err, &content);
  if (err) {
    Serial.println("Error send command 'AT+QICSGP=1,1,\"" + arg[0] + "\",\"" + arg[1] + "\",\"" + arg[2] + "\",1' : " + String(content));
    return false;
  }
  
  SendCommand("AT+QIACT=1", 30000, &err, &content);
  if (err) {
    Serial.println("Error send command 'AT+QIACT=1' : " + String(content));
    return false;
  }

  Serial.println("Internet ON");
  return true;
}

bool OffInternet() {
  bool err;
  String content;
  SendCommand("AT+QIDEACT=1", 3000, &err, &content);
  if (err) {
    Serial.println("Error send command 'AT+QIDEACT=1' : " + String(content));
    return false;
  }

  Serial.println("Internet OFF");
  return true;
}

bool isInternet(bool *Connected) {
  Connected = false;
  
  bool err;
  String content;
  SendCommand("AT+QIACT?", &err, &content);
  /*if (err) {
    Serial.println("Error send command 'AT+QIACT?' : " + String(content));
    return false;
  }*/

  *Connected = (content.indexOf("+QIACT:") >= 0);
  
  // Serial.println("Is Success");
  return true;
}

bool httpget(String url, String *content) {
  bool onConnect;
  isInternet(&onConnect);
  if (!onConnect) {
    Serial.println("Internet Now Off");
    return false;
  }

  ClearBuf();

  mySerial.println("AT+QHTTPURL=" + String(url.length()) + ",30"); // Set timeout to 30 Sec

  if (!WaitReply(100)) {
    Serial.println("Time out");
    *content = "!Time out";
    return false;
  }

  delay(10);

  bool _err;
  String _content;
  ReadReply(&_err, &_content);
  if (_content != "CONNECT") {
    Serial.println("ERROR Step1: " + _content);
    return false;
  }

  mySerial.println(url);

  if (!WaitReply(100)) {
    Serial.println("Time out");
    *content = "!Time out";
    return false;
  }

  delay(10);

  ReadReply(&_err, &_content);
  if (_err) {
    Serial.println("ERROR Step2: " + _content);
    return false;
  }

  mySerial.println("AT+QHTTPGET=30");

  if (!WaitReply(500)) {
    Serial.println("Time out");
    *content = "!Time out";
    return false;
  }

  delay(10);

  ReadReply(&_err, &_content);
  if (_err) {
    Serial.println("ERROR Step3: " + _content);
    return false;
  }

  if (!WaitReply(30000)) {
    Serial.println("Time out Step3");
    *content = "!Time out";
    return false;
  }

  delay(10);

  ReadReply(&_err, &_content);
  if (_content.indexOf("+QHTTPGET:") <= -1) {
    Serial.println("ERROR Step4: " + _content);
    return false;
  }

  // Serial.println("Step4: " + _content);

  mySerial.println("AT+QHTTPREAD=30");

  if (!WaitReply(30000)) {
    Serial.println("Time out");
    *content = "!Time out";
    return false;
  }

  //delay(500);

  String tmp = "";
  long timeRun = millis();
  while (millis() - timeRun < 500) {
    if (mySerial.available()) {
      tmp += (char)mySerial.read();
      timeRun = millis();
    }
    if (tmp.indexOf("\r\nCONNECT\r\n") >= 0) {
      tmp.replace("\r\nCONNECT\r\n", "");
    }
    if (tmp.lastIndexOf("\r\nOK\r\n") >= 0) {
      tmp = tmp.substring(0, tmp.lastIndexOf("\r\nOK\r\n"));
      for (int i=0;i<tmp.length();i++)
        *content += tmp.charAt(i);
    }
  }

  // Serial.println(*content);
  
  return true;
}

bool getIMEI(String *IMEI) {
  bool err;
  SendCommand("AT+GSN", 500, &err, IMEI);
  if (!isValidNumber(*IMEI)) {
    Serial.println("Get IMET Fail ! : " + *IMEI);
    *IMEI = "";
    return false;
  }
  return true;
}

// GNSS Module

bool gpsStart() {
  bool err;
  String content;
  SendCommand("AT+QGPS=1", &err, &content);
  if (!err || content == "+CME ERROR: 504")
    return true;

  Serial.println("ERROR TEXT '" + content + "'");
  return false;
}

bool GetPosition(GPS *data) {
  data->latitude = 0;
  data->longitude = 0;

  data->speed = 0;
    
  bool err;
  String content;
  SendCommand("AT+QGPSLOC?", &err, &content);

  if (content.indexOf("+QGPSLOC:") == -1) {
    if (err && content == "+CME ERROR: 505") {
      Serial.println("Restart gpsStart()");
      if (!gpsStart()) {
        return false;
      } else {
        GetPosition(data);
      }
    } else if (err && content == "+CME ERROR: 516") {
      Serial.println("Not fixed now");
      return false;
    } else {
      Serial.println("ERROR TEXT '" + content + "'");
      return false;
    }
  }
  
  String tempGPSData[11];
  content = content.substring(content.indexOf(":")+2);
  int index = 0, i=0;
  do {
    int End = content.indexOf(",", index);
    tempGPSData[i] = content.substring(index, End);
    i++;
    index = End+1;
  } while(index != 0);

  tempGPSData[1].replace(".", "");
  tempGPSData[2].replace(".", "");

  data->latitude = (tempGPSData[1].substring(0, 2)).toFloat() + (tempGPSData[1].substring(2, 8)).toFloat() / 600000;
  data->longitude = (tempGPSData[2].substring(0, 3)).toFloat() + (tempGPSData[2].substring(3, 9)).toFloat() / 600000;

  data->speed = tempGPSData[7].toFloat();
 
  return true;
}

void SendCommand(String cmd, int timeOut, bool *err, String *content) {
  *err = true;
  *content = "";
  
  ClearBuf();

  mySerial.println(cmd); // Send command

  if (!WaitReply(timeOut)) {
    Serial.println("Time out");
    *content = "!Time out";
    return;
  }

  delay(50);
  
  ReadReply(err, content);
}

void SendCommand(String cmd, bool *err, String *content) {
  SendCommand(cmd, 500, err, content);
}

bool SendCommand(String cmd) {
  bool err;
  String content;
  SendCommand(cmd, 1000, &err, &content);
  return !err;
}



void ClearBuf() {
  while(mySerial.available()) mySerial.read(); // Clear buffer
}

bool WaitReply(int timeout) {
  // Waiting for reply
  int _timeOut = timeout; // Max wait time (mS)
  while(!mySerial.available() && _timeOut > 0) {
    delay(1);
    _timeOut--;
  }
  if (_timeOut == 0) {
    return false;
  }
  return true;
}

void ReadReply(bool *err, String *content) {
  *err = true;
  *content = "";
  
  // Read reply
  bool endContent = false;
  while(mySerial.available()) {
    String line = mySerial.readStringUntil('\r');
    mySerial.readStringUntil('\n');
    // Serial.println(line);
    // Serial.println(line.length());
    if (line.length() <= 0) {
      endContent = true;
      continue;
    }
    if (endContent) {
      if (line.indexOf("OK") >= 0) *err = false;
      else *content = line;
      break;
    }
    *content += line + "\n";
    delay(5);
  }
}

bool isValidNumber(String str) {
   bool isNum = true;
   if(!(str.charAt(0) == '+' || str.charAt(0) == '-' || isDigit(str.charAt(0)))) return false;
   
   for(int i=0;i<str.length();i++) {
       if(!(isDigit(str.charAt(i)) || str.charAt(i) == '.')) isNum = false;
   }
   return isNum;
}

bool RestartModule() {
  bool NowOnline = testOnline();
  for (int i=0;i<(NowOnline ? 2 : 1);i++) {
    digitalWrite(MODULEONOFF_PIN, LOW);
    delay(4000);
    digitalWrite(MODULEONOFF_PIN, HIGH);
    delay(2000);
  }
  delay(5000);
  return testOnline();
}

bool loopRestartModule() {
  while (RestartModule() == false) {
    Serial.println("Start module 3G for fail !");
    delay(100);
  }
}

