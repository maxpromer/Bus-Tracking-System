#!/usr/bin/python

# Codeing By IOXhop : www.ioxhop.com
# Sonthaya Nongnuch : www.fb.me/maxthai
#
# install Lib
#  - pip install pyserial
#  - 

import time
import serial
import re

timeout = 50

# gsm = serial.Serial('COM14')
gsm = serial.Serial(port='/dev/ttyUSB0', baudrate=9600)

def getImei():
	gsm.reset_input_buffer()
	gsm.write("AT+CGSN\r\n")
	time.sleep(0.1)
	if gsm.in_waiting > 0:
		timeout_t = timeout
		stringAllLine = ""
		while timeout_t > 0:
			if gsm.in_waiting > 0:
				stringAllLine = stringAllLine + gsm.read()
				timeout_t = timeout
			else:
				timeout_t = timeout_t - 1
			time.sleep(0.001)
		rosString = stringAllLine

		regex = re.compile(r"^\s*?([0-9]+)\s+?OK\s+?$", re.MULTILINE)
		matches = [m.groups() for m in regex.finditer(rosString)]
		if matches:
			return matches[0][0]
		else:
			return False

def main():
	imei = getImei()
	print "AirCard imei is {}".format(imei)
	if imei:
		file = open("/etc/imei.txt", "w")
		file.write(imei)
		file.close()
	else:
		print "Error read imei"

if __name__ == '__main__':
	main()