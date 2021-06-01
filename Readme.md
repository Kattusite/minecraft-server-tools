# minecraft-server-tools

My Minecraft server management script with safe online backup.

## Configuration

Config variables are sourced from `serverconf.sh`.

## Usage

`./server.sh start|stop|attach|status|backup|fbackup|ls`

### start

Creates a `tmux` session and starts a Minecraft server within.
Fails, if a session is already running with the same session name.

### stop

Sends `stop` command to running server instance to safely shut down.

### attach

Attaches to `tmux` session. Exit with `CTRL + B d`.

### status

Display whether the server is currently running.

### backup

Backs up the world as a `tar.gz` archive in `./backup/`.
If a running server is detected,
the world is flushed to disk and autosave is disabled temporarily to prevent chunk corruption.

The command specified in `$BACKUP_HOOK` is executed on every successful backup.
`$ARCHNAME` contains the relative path to the archive.
This can be used to further process the created backup.

If the server is online but there are no players connected,
this command will have no effect, as an optimization.

### fbackup

Force an immediate backup of the world, regardless of whether any players are connected.

### ls

List existing backups.

## Start automatically

Create user and group `minecraft` with home in `/var/minecraft`.
Populate the directory with server.sh and a server jar.

Place `minecraft.service` in `/etc/systemd/system/`
and run `systemctl start minecraft` to start once or
`systemctl enable minecraft` to enable autostarting.

To backup automatically, place or symlink `mc-backup.service` and
`mc-backup.timer` in `/etc/systemd/system/`. Run the following:

```
sudo systemctl  enable mc-backup.timer
sudo sytemctl start mc-backup.timer
```

This will start the enable the timer upon startup and start the timer
to run the backup after every interval specified in `mc-backup.timer`.

## Disclaimer

The scripts are provided as-is at no warranty.
They are in no way idiot-proof.

Improvements are welcome.
