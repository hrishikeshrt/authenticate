#!/bin/sh

trap logout 1 2 3 9 15 19 20

LOGFILE="/var/log/iitk-fortigate.log"
[ -f $LOGFILE ] || touch $LOGFILE
[ -w $LOGFILE ] || LOGFILE="/tmp/`whoami`-fortigate.log"

log() {
    export ts="`date +[%b\ %e\ %H:%M:%S]`"
    echo $ts $@ >> $LOGFILE
    logger -t Fortigate $@
}

log "Starting fortigate-authentication daemon .."

CONFIG="$HOME/.iitk-config"
[ -f $CONFIG ] || CONFIG="/usr/share/iitk-auth/config"
[ -f $CONFIG ] || (logger -sit Fortigate "No config file found." && exit 1)

username="`sed -n '1 p' ${CONFIG}`"
password="`sed -n '2 p' ${CONFIG}`"

([ -z "$username" ] || [ -z "$password" ]) &&  (logger -sit Fortigate "Invalid config." && exit 1)

google="http://216.58.220.3"
curl_opts="-k -m3 -s --stderr /dev/null"

login() {
    fgt_redirect=$(
        curl ${curl_opts} --max-redirs 0 -D- ${google}
    )
    if [ -z "${fgt_redirect}" ];
    then
        state="fail"
    elif [ -z "$(echo ${fgt_redirect} | grep "HTTP\/1.1 303 See Other")" ];
    then
        state="login"
    else
        fgt_auth_url=$(
            echo "${fgt_redirect}" |
            sed -n -e 's/.*Location: \(.*\).*/\1/p' |
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
            sed -n -e 's/.*location.href="\([^"]\+\).*/\1/p' |
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
            sleep 300 & wait $!
            login
            ;;
        "badauth")
            log "Bad credentials"
            sleep 240 & wait $!
            login
            ;;
        "retry")
            log "Retrying login"
            sleep 1 & wait $!
            login
            ;;
        "keepalive")
            log "Keeping alive"
            sleep 300 & wait $!
            keepalive
            ;;
        *)
            log "Something went wrong"
            sleep 30 & wait $!
            login
            ;;
    esac
done
