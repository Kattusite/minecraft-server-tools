#!/bin/bash

# We haven't read config yet, so this one piece of config must live here.
SERVER_DIR=$PWD

if [ -e "$SERVER_DIR/serverconf.sh" ]
then
  source "$SERVER_DIR/serverconf.sh"
else
  echo No configuration found in PWD. Exiting.
  exit 1
fi

# import backup helpers for the active backend, including:
#   - init_backups
#   - create_backup
#   - pre_backup_hook
#   - post_backup_hook
#   - ls_backups
#   - restore_backup
source $BACKUP_SCRIPTS_DIR/$BACKUP_BACKEND-backup.sh

function send_cmd () {
  tmux -S $TMUX_SOCKET send -t $TMUX_WINDOW "$1" enter
}

function assert_not_running() {
  if server_running; then
    echo "It seems a server is already running."
    echo "If this is not the case, manually attach to the running tmux session and close it."
    exit 1
  fi
}

function assert_running() {
  if ! server_running; then
    echo "Server not running"
    exit 1
  fi
}

function add_to_bashrc() {
  # If the command already exists in bashrc, don't add it again.
  local CMD=$1
  if [ `grep -c "$CMD" "$BASHRC"` -eq 0 ]; then
    echo "Adding to $BASHRC: '$CMD'"
    echo "$CMD" >> $BASHRC
    BASHRC_MODIFIED=yes
  fi
}

function init_bashrc() {
  if [ -n "$ALIAS_TMUX_IN_BASHRC" ]; then
    add_to_bashrc "alias tmux=\"tmux -S $TMUX_SOCKET\""
  fi

  if [ -n "$ALIAS_SCRIPT_IN_BASHRC" ]; then
    add_to_bashrc "alias ${ALIAS_SCRIPT_IN_BASHRC}=\"$PWD/server.sh\""
  fi

  if [ -n "$BASHRC_MODIFIED" ]; then
    echo "Run \'source $BASHRC\' for changes to take effect."
  fi
}

function init_services() {
  # The default services assume a server dir of /var/minecraft,
  # and a user/group both equal to "minecraft".
  # Overwrite these defaults with values pulled from the config.
  for svc in `ls $SERVICES_DIR/*.service`; do
    sed -i "s|/var/minecraft|$SERVER_DIR|" "$svc"
    sed -i 's|User=.*|'"User=$SERVICE_USER"'|' "$svc"
    sed -i 's|Group=.*|'"Group=$SERVICE_GROUP"'|' "$svc"
  done

  # Symlink services into appropriate system dirs
  # Remove existing files if they exist
  for svc in `ls $SERVICES_DIR`; do
    sudo ln -sf $SERVICES_DIR/$svc /etc/systemd/system/$svc
  done

  # Enable auto-start for the various services
  # (But don't start them yet!)
  for svc in minecraft mc-backup.timer daily-mc-backup.timer; do
    sudo systemctl enable "$svc"
  done
}

function server_init() {
  $INSTALL_PKG $JAVA_PKG
  if [ ! -f $JAR ]; then
    if [ -z "$JAR_URL" ]; then
      echo "Error: place $JAR in this script's directory and try again."
      return
    else
      wget $JAR_URL -O $JAR
    fi
  fi

  init_backups
  init_services
  init_bashrc
}

function server_start() {
  assert_not_running

  if [ ! -f "eula.txt" ]
  then
    echo "eula.txt not found. Creating and accepting EULA."
    echo "eula=true" > "eula.txt"
  fi

  tmux -S $TMUX_SOCKET new-session -s $TMUX_WINDOW -d \
    $JRE_JAVA $JVM_ARGS -jar $JAR $JAR_ARGS
  pid=`tmux -S $TMUX_SOCKET list-panes -t $TMUX_WINDOW -F "#{pane_pid}"`
  echo $pid > $PIDFILE
  echo Started with PID $pid
  exit
}

function server_stop() {
  # Allow success even if server is not running
  #trap "exit 0" EXIT

  assert_running

  echo "Stopping the server in $STOP_WARNING_TIME seconds!"
  send_cmd "say Stopping the server in $STOP_WARNING_TIME seconds!"
  sleep $STOP_WARNING_TIME
  echo "Stopping the server now!"
  send_cmd "stop"

  local RET=1
  while [ ! $RET -eq 0 ]
  do
    sleep 1
    ps -p $(cat $PIDFILE) > /dev/null
    RET=$?
  done

  echo "stopped the server"

  rm -f $PIDFILE

  exit
}

function server_attach() {
  assert_running
  tmux -S $TMUX_SOCKET attach -t $TMUX_WINDOW
  exit
}

function server_running() {
  if [ -f $PIDFILE ] && [ "$(cat $PIDFILE)" != "" ]; then
    ps -p $(cat $PIDFILE) > /dev/null
    return
  fi

  false
}

function server_status() {
  if server_running
  then
    echo "Server is running"
  else
    echo "Server is not running"
  fi
  exit
}

function players_online() {
  send_cmd "list"
  sleep 1
  while [ $(tail -n 3 "$LOGFILE" | grep -c "There are") -lt 1 ]
  do
    sleep 1
  done

  [ `tail -n 3 "$LOGFILE" | grep -c "There are 0"` -lt 1 ]
}


function server_backup_safe() {
  force=$1
  echo "Detected running server. Checking if players online..."
  if [ "$force" != "true" ] && ! players_online; then
    echo "Players are not online. Not backing up."
    return
  fi

  echo "Disabling autosave"
  send_cmd "save-off"
  send_cmd "save-all flush"
  echo "Waiting for save... If froze, run /save-on to re-enable autosave!!"

  sleep 1
  while [ $(tail -n 3 "$LOGFILE" | grep -c "Saved the game") -lt 1 ]
  do
    sleep 1
  done
  sleep 2
  echo "Done! starting backup..."

  create_backup

  local RET=$?

  echo "Re-enabling auto-save"
  send_cmd "save-on"

  return $RET
}

function server_backup_unsafe() {
  echo "No running server detected. Running Backup"
  create_backup
}

function backup_running() {
  systemctl is-active --quiet mc-backup.service
}

function fbackup_running() {
  systemctl is-active --quiet mc-fbackup.service
}

function server_backup() {
  force=$1

  if [ "$force" = "true" ]; then
        if backup_running; then
            echo "A backup is running. Aborting..."
            return
        fi
  else
        if fbackup_running; then
            echo "A force backup is running. Aborting..."
            return
        fi
  fi

  echo "Running pre-backup hook"
  pre_backup_hook

  if server_running; then
    server_backup_safe "$force"
  else
    server_backup_unsafe
  fi

  if [ $? -eq 0 ]; then
    echo "Running post-backup hook"
    post_backup_hook
  fi

  exit
}

function server_restore() {
  assert_not_running
  restore_backup $@
}

#cd $(dirname $0)

case $1 in
  "init")
    server_init
    ;;
  "start")
    server_start
    ;;
  "stop")
    server_stop
    ;;
  "attach")
    server_attach
    ;;
  "backup")
    server_backup
    ;;
  "restore")
    server_restore ${@:2}
    ;;
  "status")
    server_status
    ;;
  "fbackup")
    server_backup "true"
    ;;
  "ls")
    ls_backups ${@:2}
    ;;
  *)
    echo "Usage: $0 start|stop|attach|status|backup|fbackup|ls"
    ;;
esac
