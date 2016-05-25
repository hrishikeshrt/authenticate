#!/bin/sh

# This is a skeleton of a bash daemon. To use for yourself, just set the
# daemonName variable and then enter in the commands to run in the doCommands
# function. Modify the variables just below to fit your preference.

daemonName="DAEMON-NAME"

pidDir="."
pidFile="$pidDir/$daemonName.pid"
pidFile="$daemonName.pid"

logDir="."
# To use a dated log file.
# logFile="$logDir/$daemonName-"`date +"%Y-%m-%d"`".log"
# To use a regular log file.
logFile="$logDir/$daemonName.log"

# Log maxsize in KB
logMaxSize=1024   # 1mb

runInterval=60 # In seconds

doCommands() {
  # This is where you put all the commands for the daemon.
  echo "Running commands."
}

################################################################################
# Below is the skeleton functionality of the daemon.
################################################################################

myPid=`echo $$`

setupDaemon() {
  # Make sure that the directories work.
  if [ ! -d "$pidDir" ]; then
    mkdir "$pidDir"
  fi
  if [ ! -d "$logDir" ]; then
    mkdir "$logDir"
  fi
  if [ ! -f "$logFile" ]; then
    touch "$logFile"
  else
    # Check to see if we need to rotate the logs.
    size=$((`ls -l "$logFile" | cut -d " " -f 8`/1024))
    if [[ $size -gt $logMaxSize ]]; then
      mv $logFile "$logFile.old"
      touch "$logFile"
    fi
  fi
}

startDaemon() {
  # Start the daemon.
  setupDaemon # Make sure the directories are there.
  if [[ `checkDaemon` = 1 ]]; then
    echo " * \033[31;5;148mError\033[39m: $daemonName is already running."
    exit 1
  fi
  echo " * Starting $daemonName with PID: $myPid."
  echo "$myPid" > "$pidFile"
  log '*** '`date +"%Y-%m-%d"`": Starting up $daemonName."

  # Start the loop.
  loop
}

stopDaemon() {
  # Stop the daemon.
  if [[ `checkDaemon` -eq 0 ]]; then
    echo " * \033[31;5;148mError\033[39m: $daemonName is not running."
    exit 1
  fi
  echo " * Stopping $daemonName"
  log '*** '`date +"%Y-%m-%d"`": $daemonName stopped."

  if [[ ! -z `cat $pidFile` ]]; then
    kill -9 `cat "$pidFile"` &> /dev/null
  fi
}

statusDaemon() {
  # Query and return whether the daemon is running.
  if [[ `checkDaemon` -eq 1 ]]; then
    echo " * $daemonName is running."
  else
    echo " * $daemonName isn't running."
  fi
  exit 0
}

restartDaemon() {
  # Restart the daemon.
  if [[ `checkDaemon` = 0 ]]; then
    # Can't restart it if it isn't running.
    echo "$daemonName isn't running."
    exit 1
  fi
  stopDaemon
  startDaemon
}

checkDaemon() {
  # Check to see if the daemon is running.
  # This is a different function than statusDaemon
  # so that we can use it other functions.
  if [ -z "$oldPid" ]; then
    return 0
  elif [[ `ps aux | grep "$oldPid" | grep -v grep` > /dev/null ]]; then
    if [ -f "$pidFile" ]; then
      if [[ `cat "$pidFile"` = "$oldPid" ]]; then
        # Daemon is running.
        # echo 1
        return 1
      else
        # Daemon isn't running.
        return 0
      fi
    fi
  elif [[ `ps aux | grep "$daemonName" | grep -v grep | grep -v "$myPid" | grep -v "0:00.00"` > /dev/null ]]; then
    # Daemon is running but without the correct PID. Restart it.
    log '*** '`date +"%Y-%m-%d"`": $daemonName running with invalid PID; restarting."
    restartDaemon
    return 1
  else
    # Daemon not running.
    return 0
  fi
  return 1
}

loop() {
  # This is the loop.
  now=`date +%s`

  if [ -z $last ]; then
    last=`date +%s`
  fi

  # Do everything you need the daemon to do.
  doCommands

  # Check to see how long we actually need to sleep for. If we want this to run
  # once a minute and it's taken more than a minute, then we should just run it
  # anyway.
  last=`date +%s`

  # Set the sleep interval
  if [[ ! $((now-last+runInterval+1)) -lt $((runInterval)) ]]; then
    sleep $((now-last+runInterval))
  fi

  # Startover
  loop
}

log() {
  # Generic log function.
  echo "$1" >> "$logFile"
}


################################################################################
# Parse the command.
################################################################################

if [ -f "$pidFile" ]; then
  oldPid=`cat "$pidFile"`
fi
checkDaemon
case "$1" in
  start)
    startDaemon
    ;;
  stop)
    stopDaemon
    ;;
  status)
    statusDaemon
    ;;
  restart)
    restartDaemon
    ;;
  *)
  echo "\033[31;5;148mError\033[39m: usage $0 { start | stop | restart | status }"
  exit 1
esac

exit 0