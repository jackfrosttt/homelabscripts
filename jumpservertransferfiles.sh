#!/bin/bash

# Function to check if last command was successful
check_status() {
    if [ $? -ne 0 ]; then
        echo "An error occurred. Exiting."
        exit 1
    fi
}

# Function to install dependencies
install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y zip gpg shred
}

# Function to zip and send directory or file
zip_and_send() {
    local item=$1
    local is_dir=$2

    # Check if directory or file exists
    if [ ! -e "$item" ]; then
        echo "$item does not exist."
        exit 1
    fi

    # Prompt for the name of the zip file
    read -p "Enter the name of the zip file: " zipfile

    # Zip the directory or file with compression using zip command 
    if [ "$is_dir" = true ]; then
        zip -r $zipfile.zip $item 
    else
        zip $zipfile.zip $item 
    fi

    check_status

    # Prompt for password protection option
    read -p "Do you want to password protect the zip file? (yes/no): " protect

    if [ "$protect" = "yes" ]; then
        # Zip the directory with password protection using zip command 
        read -sp "Enter password: " password
        zip -P $password -r $zipfile.zip $item 
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

   # Prompt for jump server option
   read -p "Do you want to use a jump server? (yes/no): " jump_server
   
   if [ "$jump_server" = "yes" ]; then
       read -p 'Enter your username on jump server: ' jump_username
       read -p 'Enter the IP address of jump server: ' jump_ip
   
       # Prompt for the username and destination IP address, and use scp with jump server to copy the zip file to the destination.
       read -p "Enter your username at destination: " username_dest
       read -p "Enter the destination IP address: " ip_dest
       read -p "Enter the destination path: " path_dest

       if [ "$encrypt" = "yes" ]; then 
           scp -o ProxyJump=${jump_username}@${jump_ip} $zipfile.zip.gpg ${username_dest}@${ip_dest}:${path_dest}/
           rm $zipfile.zip.gpg  
       else 
           scp -o ProxyJump=${jump_username}@${jump_ip} $zipfile.zip ${username_dest}@${ip_dest}:${path_dest}/
           rm $zipfile.zip  
       fi 
   else 
       # Prompt for the username and destination IP address, and use scp to copy the zip file to the destination.
       read -p "Enter your username: " username_no_jump
       read -p "Enter the destination IP address: " ip_no_jump
       read -p "Enter the destination path: " path_no_jump

       if [ "$encrypt" = "yes" ]; then 
           scp $zipfile.zip.gpg ${username_no_jump}@${ip_no_jump}:${path_no_jump}/
           rm $zipfile.zip.gpg  
       else 
           scp $zipfile.zip ${username_no_jump}@${ip_no_jump}:${path_no_jump}/
           rm $zipfile.zip  
       fi 
   fi 

   check_status

	delete_after_transfer ${zipfile}.zip
}

# Function to delete directory or file after transfer using secure deletion (shred command)
delete_after_transfer() {
   local item=$1
   
   read -p "Do you want to delete ${item} after transfer? (yes/no): " delete
   
   if [ "$delete" = "yes" ]; then
       shred -uz ${item}
       echo "${item} has been deleted securely!"
   fi
   
}

# Menu for user to choose action
while true; do
   echo "
   Please select an option:
   1. Send a directory.
   2. Send a file.
   3. Install dependencies.
   4. Exit.
   "
   read -p 'Option: ' option
   
   case ${option} in
       1)
           read -p 'Enter the directory you want to send: ' directory
           zip_and_send ${directory} true
           delete_after_transfer ${directory}
           ;;
       2)
           read -p 'Enter the file you want to send: ' file_name
           zip_and_send ${file_name} false
           delete_after_transfer ${file_name}
           ;;
       3)
           install_dependencies
           ;;
       4)
           echo 'Exiting...'
           exit 0
           ;;
       *)
           echo 'Invalid option.'
           ;;
   esac
   
done

