#!/usr/bin/python

# Codeing By IOXhop : www.ioxhop.com
# Sonthaya Nongnuch : www.fb.me/maxthai
#
# install Lib
#  - pip install pyserial
#
# Test GPS before run this with command
# > python -m serial.tools.miniterm /dev/ttyS1
# 

import time
import serial
import random
import urllib2
import json
import GPS
from Arduino import *

global err

# Config wireing
LED_GPS_PIN = 66 # Pin connect to LED GPS
LED_INT_PIN = 67 # Pin connect to LED INTERNET

latitude_n = -1
longitude_n = -1
speedkm_n = -1

imei = open('/etc/imei.txt', 'r').read()

def on_update_fn(latitude, longitude, speedkm):
	global latitude_n
	global longitude_n
	global speedkm_n
	
	latitude_n = latitude
	longitude_n = longitude
	speedkm_n = speedkm

def on_error_fn(msg):
	global latitude_n
	global longitude_n
	global speedkm_n
	
	# print "Error is {}".format(msg)
	latitude_n = -1
	longitude_n = -1
	speedkm_n = -1

GPS.on_update = on_update_fn
GPS.on_error = on_error_fn



def main():
	global latitude_n
	global longitude_n
	global speedkm_n
	
	pinMode(LED_GPS_PIN, OUTPUT)
	pinMode(LED_INT_PIN, OUTPUT)
	digitalWrite(LED_GPS_PIN, LOW)
	digitalWrite(LED_INT_PIN, LOW)
	
	print "Imei is {}".format(imei)
	
	open = GPS.begin(port="/dev/ttyS1")
	
	NextRun = 0
	while True:
		GPS.loop(open)

		if time.time() >= NextRun:
			if latitude_n != -1 and longitude_n != -1 and speedkm_n != -1:
				digitalWrite(LED_GPS_PIN, HIGH)
				digitalWrite(LED_INT_PIN, HIGH)
				
				print "Send to internet..."
				verify = <Can not be revealed>
				
				url = "http://<Can not be revealed>/api/addtrack.php?imei={imei}&latitude={latitude}&longitude={longitude}&speedkm={speedkm}&verify={verify}".format(imei=imei, latitude=latitude_n, longitude=longitude_n, speedkm=speedkm_n, verify=verify)
				
				sendToSV = False
				try:
					ros = urllib2.urlopen(url).read()
					sendToSV = True
				except Exception as the_exception:
					print the_exception
				
				if (sendToSV):
					jsonRos = json.loads(ros)

					if jsonRos['e'] == False:
						digitalWrite(LED_INT_PIN, LOW)
						print "OK."
						NextRun = time.time() + 28
						continue
					else:
						print "Error ! : {e}".format(e=jsonRos['msg'])
				
				for num in range(4):
					digitalWrite(LED_INT_PIN, HIGH)
					delay(50)
					digitalWrite(LED_INT_PIN, LOW)
					delay(50)
				
				NextRun = time.time() + 0.5
				
			else:
				digitalWrite(LED_GPS_PIN, (digitalRead(LED_GPS_PIN) + 1) % 2)
				print "Not fixed now"
				NextRun = time.time() + 0.5
		
		time.sleep(0.1)

if __name__ == '__main__':
	main()