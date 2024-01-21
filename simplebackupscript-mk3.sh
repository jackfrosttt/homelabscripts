#!/bin/bash

# Define the source directory to be exported
source_dir="/home"

# Define the destination directory on the Windows machine using the hostname
windows_username="x"
windows_ip="x.x.x.x"
destination_dir="d:/backups/$(hostname)"

# Generate the backup file name based on the current date, time, and hostname
backup_filename="$(date +%Y-%m-%d-%H-%M-%S)-$(hostname)-backup.zip"

# Create the backup zip file
zip -r "$backup_filename" "$source_dir"

# Create the destination directory on the Windows machine if it doesn't exist
ssh -i /home/x/.ssh/id_rsa -o BatchMode=yes "$windows_username@$windows_ip" "mkdir -p \"$destination_dir\""

# Transfer the backup file to the Windows machine using SSH key authentication
scp -i /home/x/.ssh/id_rsa "$backup_filename" "$windows_username@$windows_ip:$destination_dir"

# Clean up the backup file
rm "$backup_filename"
