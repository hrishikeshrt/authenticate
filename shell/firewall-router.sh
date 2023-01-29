#!/bin/sh

trap logout 1 2 3 9 15

log() {
    export ts="`date +[%b\ %e\ %H:%M:%S]`"
    echo $ts $@ >> $LOGFILE
    logger -t Fortigate $@
}

# script (daemon) name
NAME=$(basename $0)

# check if log file is in place and of adequate size
LOGFILE="/var/log/iitk-fortigate.log"
[ -f $LOGFILE ] || touch $LOGFILE
[ -w $LOGFILE ] || LOGFILE="/tmp/`whoami`-fortigate.log"

LOGSIZE=$(du $LOGFILE | awk '{ print $1 }')
[ $LOGSIZE -lt 1024 ]  || ( mv ${LOGFILE} ${LOGFILE}.old && touch $LOGFILE )

# get pid
oldPID=""
myPID=`echo $$`

PIDDIR="/var/run/"
[ -w ${PIDDIR} ] || PIDDIR="${HOME}"
PIDFILE="${PIDDIR}/${NAME}.pid"

[ ! -f ${PIDFILE} ] || oldPID=$(cat $PIDFILE)
[ -z "$oldPID" ] || ((log "Error: Daemone with PID ${oldPID} already running. ($myPID)") && exit 1)
echo ${myPID} > ${PIDFILE}

log "Starting fortigate-authentication daemon ..($myPID)"

username=""
password=""

http_url="http://1.1.1.1"
curl_opts="-k -s --stderr /dev/null"

login() {
    fgt_redirect=$(
        curl ${curl_opts} --max-redirs 0 -D- ${http_url}
    )
    if [ -z "${fgt_redirect}" ];
    then
        state="fail"
    elif [ -z "$(echo ${fgt_redirect} | grep "HTTP\/1.1 200 OK")" ];
    then
        # status "200 OK" not found
        if [ -z "$(echo ${fgt_redirect} | grep "HTTP\/1.1 301 Moved Permanently")" ];
        then
            # status "301 Moved Permanently" not found
            state="fail"
        else
            state="login"
        fi
    else
        fgt_auth_url=$(
            echo "${fgt_redirect}" |
            sed -n -e 's/.*window.location="\(.*\)".*/\1/p' |
            tr -d '\r\n'
        )
        fgt_auth_resp=$(
            curl ${curl_opts} ${fgt_auth_url}
        )
        fgt_auth_magic=$(
            echo "${fgt_auth_resp}" |
            sed -n -e 's/.*name="magic" \+value="\([^"]\+\).*/\1/p'
        )
        fgt_post_resp=$(
            curl ${curl_opts} -d \
                "username=${username}&password=${password}&magic=${fgt_auth_magic}&4Tredir=/" \
                "${fgt_auth_url}"
        )
        fgt_keepalive_url=$(
            echo "${fgt_post_resp}" |
            sed -n -e 's/.*window.location="\(.*\)".*/\1/p' |
            tr -d '\r\n'
        )
        if [ -z "${fgt_keepalive_url}" ];
        then
            state="badauth"
        else
            log "Logged in"
            fgt_logout_url=$(
                echo "${fgt_post_resp}" |
                sed -n -e 's/.*<p><a href="\([^"]\+\).*/\1/p' |
                tr -d '\r\n'
            )
            state="keepalive"
        fi
    fi
}

keepalive() {
    fgt_keepalive_resp=$(
        curl ${curl_opts} -D- ${fgt_keepalive_url}
    )
    if [ -z "$(echo "${fgt_keepalive_resp}" | grep "HTTP\/1.1 200 OK")" ];
    then
        state="retry"
    else
        state="keepalive"
    fi
}

logout() {
    if [ -n "${fgt_logout_url}" ];
    then
        log "Logging out"
        curl ${curl_opts} ${fgt_logout_url} >/dev/null
    fi
    rm ${PIDFILE}
    exit
}

login
while :
do
    case ${state} in
        "fail")
            log "Network failure"
            sleep 60 & wait $!
            login
            ;;
        "login")
            log "Already logged in"
            sleep 240 & wait $!
            login
            ;;
        "badauth")
            log "Bad credentials"
            sleep 180 & wait $!
            login
            ;;
        "retry")
            log "Retrying login"
            sleep 1 & wait $!
            login
            ;;
        "keepalive")
            log "Keeping alive"
            sleep 240 & wait $!
            keepalive
            ;;
        *)
            log "Something went wrong"
            sleep 30 & wait $!
            login
            ;;
    esac
done
