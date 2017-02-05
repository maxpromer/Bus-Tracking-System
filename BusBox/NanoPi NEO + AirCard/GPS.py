#!/usr/bin/python

# Codeing By IOXhop : www.ioxhop.com
# Sonthaya Nongnuch : www.fb.me/maxthai
#
# install Lib
#  - pip install pyserial

import time
import serial
import re

timeout = 0.1
on_update = None
on_error = None
global gps


latitude = 0
longitude = 0
speedkm = 0

def begin(port):
	return serial.Serial(port=port, baudrate=9600)

def ReadString():
	
	return stringAllLine

def loop(gps):
	if gps.in_waiting > 0:
		stringAllLine = ""
		timeout_t = time.time() + timeout
		while timeout_t > time.time():
			if gps.in_waiting > 0:
				stringAllLine = stringAllLine + gps.read()
				timeout_t = time.time() + timeout
		
		gpsString = stringAllLine
		regex = r"\$GPRMC,([0-9\.]+)?,([VA]),(([0-9.]+)([0-9]{2}\.[0-9]+))?,([NS])?,(([0-9.]+)([0-9]{2}\.[0-9]+))?,([EW])?,([0-9.]+)?,([0-9.]+)?,([0-9.]+)?,([0-9.]+)?,([0-9.]+)?,(.*)?"
			
		match = re.match(regex, gpsString)
		if match:
			mode = match.group(2)
			if mode == "A":
				latitude = round(float(match.group(4)) + float(match.group(5)) / 60, 6)
				longitude = round(float(match.group(8)) + float(match.group(9)) / 60, 6)
				speedkm = round(float(match.group(11)) * 1.852, 2)
				
				on_update(latitude=latitude, longitude=longitude, speedkm=speedkm)
				
			else:
				on_error("Not fixed")
		else:
			on_error("Not connect")