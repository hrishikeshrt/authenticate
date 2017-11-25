#!/system/bin/sh

trap logout 1 2 3 9 12 15 19 20

log() {
 export ts="`date +[%b\ %e\ %H:%M:%S]`"
 echo $ts $@ >> ${LOGFILE}
}

logout() {
    curl -s --form "logout='Log Out Now'" $refurl  > /dev/null 2> /dev/null
    log "Logged out."
    rm ${PIDFILE}
    exit 0
}


LOGFILE="${HOME}/ironport.log"
[ -f ${LOGFILE} ] || touch ${LOGFILE}

LOGSIZE=$(du $LOGFILE | busybox awk '{ print $1 }')
[ $LOGSIZE -lt 1024 ]  || ( mv ${LOGFILE} ${LOGFILE}.old && touch $LOGFILE )

# get pid
oldPID=""
myPID=`echo $$`

PIDDIR="${HOME}"
PIDFILE="${PIDDIR}/ironport.pid"

[ ! -f ${PIDFILE} ] || oldPID=$(cat $PIDFILE)
if [ ! -z "${oldPID}" ]; then
    log "Error: Daemone with PID ${oldPID} already running. ($myPID)"
    exit 1
fi
echo ${myPID} > ${PIDFILE}

log "Starting ironport-authentication daemon .. ($myPID)"

export ip="172.22.1.1" # any ironport ip
export refurl='http://authenticate.iitk.ac.in/netaccess/connstatus.html'
export authurl='http://authenticate.iitk.ac.in/netaccess/loginuser.html'
export authurl1='https://ironport1.iitk.ac.in/B0001D0000N0000N0000F0000S0000R0004/'${ip}'/http://www.google.co.in/'
export authurl2='https://ironport2.iitk.ac.in/B0001D0000N0000N0000F0000S0000R0004/'${ip}'/http://www.google.co.in/'

export user=""
export pass=""
export loop_every=4 # minutes

while true; do
    refresh=${loop_every}

    # Cisco Authentication
    curl -s --form "sid=0" --form "login='Log In Now'" $refurl  > /dev/null 2> /dev/null
    sleep 1

    cisco=$(
        curl -s --form "username=$user" --form "password=$pass" --form "Login=Continue" --referer $refurl $authurl --stderr /dev/null
    )

    if [ "`echo $cisco | grep 'You are logged in'`" ]; then
        log "Auth succesful."
    else 
        if [ "`echo $cisco | grep "Credentials Rejected"`" ]; then
            log "Error: Credentials rejected. (auth)"
        else
            log "Error: Something went wrong. (auth)"
            refresh=1
        fi
    fi 
    sleep 1

    # HTTPS Authentication
    auth1=$(
        curl -s --insecure --user "${user}:${pass}" $authurl1 --stderr /dev/null
    )
    auth2=$(
        curl -s --insecure --user "${user}:${pass}" $authurl2 --stderr /dev/null
    )
    if [ "`echo $auth1 | grep AUTH_REQUIRED`" ]; then
        log "Error: Auth1 failed."
        refresh=1
    else
        if [ "`echo $auth1 | grep 'request is being redirected'`" ]; then
            log "Auth1 successful."
        else
            log "Error: `echo $auth1 | grep 'Notification: ' | grep -v '<title>'` (auth1)"
        fi
    fi

    if [ "`echo $auth2 | grep AUTH_REQUIRED`" ]; then
        log "Error: Auth2 failed."
        refresh=1
    else
        if [ "`echo $auth2 | grep 'request is being redirected'`" ]; then
            log "Auth2 successful."
        else
            log "Error: `echo $auth2 | grep 'Notification: ' | grep -v '<title>'` (auth2)"
        fi
    fi

    log "Refreshing in ${refresh} min"
    sleep $(( ${refresh} * 60 ))

done
