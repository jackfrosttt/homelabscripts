#!/bin/bash

# Function to check if last command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "An error occurred. Exiting."
        exit 1
    fi
}

# Prompt for the directory to zip
read -p "Enter the directory you want to zip: " directory

# Check if directory exists
if [ ! -d "$directory" ]; then
    read -p "Directory does not exist. Do you want to create it? (yes/no): " create
    if [ "$create" = "yes" ]; then
        mkdir -p $directory
        check_status
        echo "Directory created."
    else
        echo "Exiting."
        exit 1
    fi
fi

# Prompt for the name of the zip file
read -p "Enter the name of the zip file: " zipfile

# Prompt for compression option
read -p "Do you want to compress the zip file? (yes/no): " compress

if [ "$compress" = "yes" ]; then
    # Zip the directory with compression using zip command 
    zip -r $zipfile.zip $directory 
else
    # Zip the directory without compression using zip command 
    zip -r $zipfile.zip $directory 
fi

check_status

# Prompt for password protection option
read -p "Do you want to password protect the zip file? (yes/no): " protect

if [ "$protect" = "yes" ]; then
    # Zip the directory with password protection using zip command 
    read -sp "Enter password: " password
    zip -P $password -r $zipfile.zip $directory 
fi

check_status

# Prompt for encryption option
read -p "Do you want to encrypt the zip file? (yes/no): " encrypt

if [ "$encrypt" = "yes" ]; then
    # Encrypt the zip file using gpg (GNU Privacy Guard)
    read -sp "Enter encryption password: " enc_password
    gpg --batch --passphrase $enc_password -c $zipfile.zip 
    rm $zipfile.zip  # remove original zip file after encryption 
fi

check_status

# Prompt for the username and destination IP address, and use scp to copy the zip file to the destination.
read -p "Enter your username: " username
read -p "Enter the destination IP address: " ip
read -p "Enter the destination path: " path

# Determine OS type for scp destination path format 
read -p "Enter the OS type of the destination (windows/linux/mac): " os_type 

if [ "$os_type" = "windows" ]; then 
    dest_path="/cygdrive/${path}"
elif [ "$os_type" = "linux" ] || [ "$os_type" = "mac" ]; then 
    dest_path="${path}"
else 
    echo "${os_type} is not a valid OS type. Exiting."
    exit 1 
fi 

if [ "$encrypt" = "yes" ]; then 
    scp $zipfile.zip.gpg $username@$ip:$dest_path/
else 
    scp $zipfile.zip $username@$ip:$dest_path/
fi 

check_status

# Remove the zip file from local system after sending it.
if [ "$encrypt" = "yes" ]; then 
    rm $zipfile.zip.gpg  
else 
    rm $zipfile.zip  
fi 

echo "The directory has been zipped and sent successfully!"
