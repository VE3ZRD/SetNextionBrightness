#!/bin/bash
#################################################################
#  This script will automate the process of                	#
#  Setting the Nextion Screen Brightness                   	#
#  Based on Lat Lon gps coordiates and sunrise/sunset times	#
#								#
#                                                        	#
#  VE3RD                                      2021/09/17   	#
#################################################################
#
#  This script requires the installation of sunwait
#  Installation:    "sudo apt-get install sunwait"
#
#set -o errexit
#set -o pipefail
ver="20211007"

dval=99
nval=10

sudo mount -o remount,rw /

latlon=$(./aprsquery.php)
lat=$(echo "$latlon" | cut -d ' ' -f1)N
lon=$(echo "$latlon" | cut -d ' ' -f2 | tr -d - )W 
lmode=$(echo "$latlon" | cut -d ' ' -f3)

#echo "Location: $latlon"
echo "Location: $lat $lon  Mode=$lmode"


 daym=$(sed -nr "/^\[General\]/ { :l /^Day[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" /etc/nextionbrightness)
 nightm=$(sed -nr "/^\[General\]/ { :l /^Night[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" /etc/nextionbrightness)
 call=$(sed -nr "/^\[General\]/ { :l /^Call[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" /etc/nextionbrightness)
 apik=$(sed -nr "/^\[General\]/ { :l /^ApiKey[ ]*=/ { s/.*=[ ]*//; p; q;}; n; b l;}" /etc/nextionbrightness)

echo "Setting Day=$daym or Night=$nightm"

 
DN=$(/home/pi-star/sunwait/sunwait -poll "$lat" "$lon")
echo "DN: $DN"
if [ -f /home/pi-star/DN.txt ]; then
   line=$(head -n 1 /home/pi-star/DN.txt)
	if [ "$line" == "$DN" ]; then
		echo "No Change"
		exit
	fi

fi
   
echo "$DN" >/home/pi-star/DN.txt
y=`echo "\`date +%N\` / 100000" | bc`
sudo touch /var/log/pi-star/Nextion-Brightness-Adjusted/log
if [ "$DN" == "DAY" ]; then
        sudo sed -i '/^\[/h;G;/Nextion/s/\(Brightness=\).*/\1'"$dval"'/m;P;d'  /etc/mmdvmhost
        sudo sed -i '/^\[/h;G;/Nextion/s/\(IdleBrightness=\).*/\1'"$dval"'/m;P;d'  /etc/mmdvmhost
        echo "Setting Brightness=$dval"
        echo "$y Setting Brightness to $dval" >> /var/log/pi-star/Nextion-Brightness-Adjusted/log
else
        sudo sed -i '/^\[/h;G;/Nextion/s/\(Brightness=\).*/\1'"$nval"'/m;P;d'  /etc/mmdvmhost
        sudo sed -i '/^\[/h;G;/Nextion/s/\(IdleBrightness=\).*/\1'"$nval"'/m;P;d'  /etc/mmdvmhost
        echo "Setting Brightness=$nval"
        echo "$y Setting Brightness to $dval" >> /var/log/pi-star/Nextion-Brightness-Adjusted/log
fi

sudo mmdvmhost.service restart &> null
