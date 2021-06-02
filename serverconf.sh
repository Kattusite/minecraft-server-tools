# serverconf.sh
# configuration file for server.sh minecraft server
# management script

# SERVER
JRE_JAVA="java"
JVM_ARGS="-Xms4096M -Xmx6144M"
JAR="fabric-server-launch.jar"
JAR_ARGS="-nogui"

SERVER_DIR=$PWD             # Path to the server directory
WORLD_NAME="world"          # Name of the active world directory ("level-name")
LOGFILE="logs/latest.log"   # Where is the latest.log file located?

# SETUP
INSTALL_PKG="sudo apt install -y"

# TMUX
TMUX_WINDOW="minecraft"
TMUX_SOCKET="mc_tmux_socket"
PIDFILE="server-tmux.pid"

# BACKUPS
BACKUP_BACKEND="borg"             # Choices: borg|bup|tar|no
BACKUP_DIR="backups"              # Where backups will be stored
WORLD_BACKUP_NAME="$WORLD_NAME"   # Prepended to names of world backups
CONFIG_BACKUP_NAME="_config"      # Prepended to names of config backups.

# Which config files should be backed up?
CONFIG_BACKUP_FILES="*.{jar,json,properties,py,sh,txt} logs"

# Some backup schemes offer password protection.
# If left blank, password protection will not be used.
# Otherwise, you will be prompted to enter a password durings
BACKUP_PASSWORD=
