#!/system/bin/sh

ironport() {
  i_pids="`busybox ps | grep ironport-android.sh | grep -v 'grep' | busybox awk '{ print $1 }' | busybox tr '\n' ' '`"

  if [ -z "${i_pids}" ]; then
    echo "No running ironport-daemon found."
    sh ${HOME}/bin/ironport-android.sh &
    sleep 1
    echo "Starting ironport: $(cat ${HOME}/ironport.pid)"
  else
    echo "Running ironport-daemon: ${i_pids}"
    echo "ironport.pid: $(cat ${HOME}/ironport.pid)"
  fi
}

fortigate() {
  f_pids="`busybox ps | grep firewall-android.sh | grep -v 'grep' | busybox awk '{ print $1 }' | busybox tr '\n' ' '`"

  if [ -z "${f_pids}" ]; then
    echo "No running fortigate-daemon found."
    sh ${HOME}/bin/firewall-android.sh &
    sleep 1
    echo "Starting fortigate: $(cat ${HOME}/fortigate.pid)"
  else
    echo "Running fortigate-daemon: ${f_pids}"
    echo "fortigate.pid: $(cat ${HOME}/fortigate.pid)"
  fi
}

case "$1" in
	"iron")
	   ironport
	   ;;
	"fort")
	   fortigate
	   ;;
	"")
	   ironport
	   fortigate
	   ;;
	 *)
	   echo "Syntax: `busybox basename $0` (iron|fort|)"
	   exit 1
	   ;;
esac
