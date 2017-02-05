#!/bin/bash

# Add this to /etc/rc.local ex. /home/app/boot.sh&

usb_modeswitch -c /etc/usb_modeswitch.conf # Switch AirCard to modem mode
python /home/app/imei2file.py # read imei to file : /etc/imei.txt
python /home/app/app.py &
bash /home/app/startweaved.sh &

while : ; do
	wvdial 3gconnect
	sleep 10
done
