#!/system/bin/sh


stop_ironport() {
 i_pids="`busybox ps | grep ironport-android.sh | grep -v 'grep' | busybox awk '{ print $1 }' | busybox tr '\n' ' '`"

 if [ -z "${i_pids}" ]; then
    echo "No running ironport-daemon found."
 else
    echo "Killing ironport-daemon (${i_pids}) .."
    kill -s KILL ${i_pids}
 fi

 sleep 1

 if [ -f "${HOME}/ironport.pid" ]; then
    rm -v ${HOME}/ironport.pid
 else
    echo "No residual ironport.pid found."
 fi
}

stop_fortigate() {
 f_pids="`busybox ps | grep firewall-android.sh | grep -v 'grep' | busybox awk '{ print $1 }' | busybox tr '\n' ' '`"

 if [ -z "${f_pids}" ]; then                  
    echo "No running fortigate-daemon found."
 else                                
    echo "Killing fortigate-daemon (${f_pids}) .."
    kill -s KILL ${f_pids}
 fi

 sleep 1

 if [ -f "${HOME}/fortigate.pid" ]; then
    rm -v ${HOME}/fortigate.pid
 else
    echo "No residual fortigate.pid found."
 fi
}

case "$1" in
	"iron")
	    stop_ironport
	    ;;
	"fort")
	    stop_fortigate
	    ;;
	"")
	    stop_ironport
	    stop_fortigate
	    ;;
	*)
	    echo "Syntax: `busybox basename $0` (iron|fort|)"
	    ;;
esac
