#!/bin/ash

# For OpenWRT
export ip="" # local WAN ip of router
export refurl='http://authenticate.iitk.ac.in/netaccess/connstatus.html'
export authurl='http://authenticate.iitk.ac.in/netaccess/loginuser.html'
export authurl1='https://ironport1.iitk.ac.in/B0001D0000N0000N0000F0000S0000R0004/'${ip}'/http://www.google.com/'
export authurl2='https://ironport2.iitk.ac.in/B0001D0000N0000N0000F0000S0000R0004/'${ip}'/http://www.google.com/'

export user=""
export pass=""

export refresh='5'


while true; do
  
  refresh=5

  # Cisco Authentication
  curl -s --form "sid=0" --form "login='Log In Now'" $refurl  > /dev/null 2> /dev/null

  sleep 1

  curl -s --form "username=$user" --form "password=$pass" --form "Login=Continue" --referer $refurl $authurl > /tmp/auth 2> /dev/null

  if [ "`cat /tmp/auth | grep 'You are logged in'`" ]; then
    logger -t IronPort "Auth successful."
  else 
       logger -t IronPort "Auth failed."
       refresh=1
  fi 
  sleep 1

  # HTTPS Authentication
  curl -s --insecure --user "${user}:${pass}" $authurl1 > /tmp/auth1 2> /dev/null
  curl -s --insecure --user "${user}:${pass}" $authurl2 > /tmp/auth2 2> /dev/null

  if [ "`cat /tmp/auth1 | grep AUTH_REQUIRED`" ]; then
    logger -t IronPort "Auth1 failed."
    refresh=1
  else
    if [ "`cat /tmp/auth1 | grep 'request is being redirected'`" ]; then
      logger -t IronPort "Auth1 successful."
    fi
  fi

  if [ "`cat /tmp/auth2 | grep AUTH_REQUIRED`" ]; then
    logger -t IronPort "Auth2 failed."
    refresh=1
  else
    if [ "`cat /tmp/auth2 | grep 'request is being redirected'`" ]; then
      logger -t IronPort "Auth2 successful."
    fi
  fi

  logger -t IronPort "Refreshing in ${refresh} minutes."
  sleep $(( ${refresh} * 60 ))

done
