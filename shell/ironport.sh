#!/bin/bash

export authfile="${HOME}/.ironauth"
export logfile="${HOME}/.ironlog"

touch $logfile

if [ "$1" ]; then
  if [ "$1" == "clean" ];then
    /bin/rm -v $authfile
    exit 0
  fi

  if [ "$1" == "cleanall" ];then
    /bin/rm -v $authfile $logfile
    exit 0
  fi

  if [ "$1" == "fresh" ];then
    /bin/rm -v $authfile
  fi
fi

# timestamp echo
function techo  {
  export ts=`date +[%b\ %e\ %H:%M:%S]`
  echo $ts $@ >> $logfile
  tail -n1 $logfile
}

function firstrun {
  echo -n "Enter IITK username: "
  read user
  echo -n "Enter IITK password: "
  read -s pass

  echo $user > ${authfile}
  echo $pass >> ${authfile}

  echo ""
  techo "Auth Details Saved."
}


clear

if [ ! -f $authfile ];then
 techo "Initiating.."
 firstrun
fi


export ip="`curl -s http://home.iitk.ac.in/~hrishirt/ip/?clean`"
export refurl='http://authenticate.iitk.ac.in/netaccess/connstatus.html'
export authurl='http://authenticate.iitk.ac.in/netaccess/loginuser.html'
export authurl1='https://ironport1.iitk.ac.in/B0001D0000N0000N0000F0000S0000R0004/'${ip}'/http://www.google.co.in/'
export authurl2='https://ironport2.iitk.ac.in/B0001D0000N0000N0000F0000S0000R0004/'${ip}'/http://www.google.co.in/'

export user="`head -n1 ${authfile}`"
export pass="`tail -n1 ${authfile}`"

export refresh='9'



# If using httpie instead of cURL
# sudo apt-get install httpie


while true; do
  
  refresh=5

  # Cisco Authentication
  # http --form $refurl sid="0" login="Log In Now" > /dev/null
  curl -s --form "sid=0" --form "login='Log In Now'" $refurl  > /dev/null 2> /dev/null

  sleep 1

  # http --form POST $authurl1 username="$user" password="$pass" Login='Continue' Referer:$refurl > /tmp/auth1
  curl -s --form "username=$user" --form "password=$pass" --form "Login=Continue" --referer $refurl $authurl > /tmp/auth 2> /dev/null

  if [ "`cat /tmp/auth | grep 'You are logged in'`" ]; then
    techo "Auth successful."
  else 
#    if [ "`cat /tmp/auth1 | grep 'Credentials rejected'`" ]; then
       techo "Auth failed".
       refresh=1
#    fi
  fi 
  sleep 1

  # HTTPS Authentication
  # http --verify=no $authurl2 --auth "${user}:${pass}" > /tmp/auth2
  curl -s --insecure --user "${user}:${pass}" $authurl1 > /tmp/auth1 2> /dev/null
  curl -s --insecure --user "${user}:${pass}" $authurl2 > /tmp/auth2 2> /dev/null

  if [ "`cat /tmp/auth1 | grep AUTH_REQUIRED`" ]; then
    techo "Auth1 failed."
    refresh=1
  else
    if [ "`cat /tmp/auth1 | grep 'request is being redirected'`" ]; then
      techo "Auth1 successful."
    fi
  fi

  if [ "`cat /tmp/auth2 | grep AUTH_REQUIRED`" ]; then
    techo "Auth2 failed."
    refresh=1
  else
    if [ "`cat /tmp/auth2 | grep 'request is being redirected'`" ]; then
      techo "Auth2 successful."
    fi
  fi


  techo "Refreshing at '`date +[%H:%M:%S] --date="${refresh}min"`'"
  sleep $(( ${refresh} * 60 ))

done
