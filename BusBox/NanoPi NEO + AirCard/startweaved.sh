#!/bin/bash

# Cr. http://forum.weaved.com/t/urgent-weaved-does-not-work-after-reboot/1172/9
# Modify By Sonthaya Nongnuch (FB: http://fb.me/maxthai)

is_online () {
	# nc -z 8.8.8.8 53 >/dev/null 2>&1
	ping -c 1 google.com >> /dev/null 2>&1
	return "$?"
}
until is_online; do
	echo "offline"
	sleep 2;
done
echo "online"
# Add Weaved service starts for reboot
if [ -f "/usr/bin/Weavedssh22.sh" ]; then
   /usr/bin/Weavedssh22.sh start
fi