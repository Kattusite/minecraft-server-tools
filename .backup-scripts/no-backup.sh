#!/usr/bin/env bash
#
#   no-backup.sh
#
# This backup backend does nothing, effectively disabling backups.
# It is useful as a template for creating other backup strategies,
# but it's not recommended to use it in a production environment.

function init_backups() {
  echo "Backups are disabled. Skipping initialization..."
}

function create_backup() {
  echo "Backups are disabled. Skipping backup..."
}

function pre_backup_hook() {
  return 0
}

function post_backup_hook() {
  return 0
}

function ls_backups() {
  echo "Backups are disabled. No backups to show."
}

function restore_backup() {
  echo "Backups are disabled. No backups to restore."
}
