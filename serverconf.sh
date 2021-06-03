# serverconf.sh
# configuration file for server.sh minecraft server
# management script

# JAR auto-download settings
MC_VERSION='1.16.5'

# If JAR_URL is provided, automatically download a .jar from that URL
# when no $JAR file exists. If left blank, disable automatic downloads.
JAR_URL="https://papermc.io/api/v1/paper/$MC_VERSION/latest/download"
JAR="paper-$MC_VERSION.jar"

# JAVA SETTINGS
JAVA_PKG="openjdk-16-jdk-headless"
JRE_JAVA="java"
MIN_RAM="4G"
MAX_RAM="6144M"
JVM_ARGS="-Xms$MIN_RAM -Xmx$MAX_RAM"
JAR_ARGS="-nogui"

# AIKAR'S FLAGS
# An optimized set of Java / JVM flags designed
# to make your server as efficient as possible.
# See https://mcflags.emc.gs/ for more information.
USE_AIKARS_FLAGS=yes
if [ "$USE_AIKARS_FLAGS" = "yes" ]; then
  JVM_ARGS="-Xms$MIN_RAM -Xmx$MAX_RAM -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
fi

# SERVER FILES
SERVER_DIR=$PWD             # Path to the server directory
WORLD_NAME="world"          # Name of the active world directory ("level-name")
LOGFILE="logs/latest.log"   # Where is the latest.log file located?

# SETUP
INSTALL_PKG="sudo apt install -y"

# TMUX
TMUX_WINDOW="minecraft"             # Title of minecraft tmux session
TMUX_SOCKET="$PWD/.mc_tmux_socket"  # Socket file to be used by tmux
PIDFILE="server-tmux.pid"           # File storing PID of tmux session

# BACKUPS
BACKUP_BACKEND="borg"               # Choices: borg|bup|tar|no
BACKUP_DIR="backups"                # Where backups will be stored
WORLD_BACKUP_NAME="$WORLD_NAME"     # Prepended to names of world backups
CONFIG_BACKUP_NAME="_config"        # Prepended to names of config backups.

# Which config files should be backed up?
CONFIG_BACKUP_FILES="*.{jar,json,properties,py,sh,txt} logs"

# Some backup schemes offer password protection.
# If left blank, password protection will not be used.
# Otherwise, you will be prompted to enter a password during setup
BACKUP_PASSWORD=

# BASHRC SETTINGS
BASHRC=$HOME/.bashrc
ALIAS_TMUX_IN_BASHRC="yes"  # If non-empty, alias `tmux` -> `tmux -S $TMUX_SOCKET`
ALIAS_SCRIPT_IN_BASHRC="mc" # If non-empty, add as an alias for ./server.sh
