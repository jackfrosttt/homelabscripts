#!/bin/bash

REMOTE_USERNAME="x"
REMOTE_MACHINE="x"
REMOTE_DHCPCD_CONF="/etc/dhcpcd.conf"
LOCAL_DHCPCD_CONF="/home/x/dhcpcd.conf"
SSH_TIMEOUT=0.5

# Function to replace the dhcpcd.conf file on the remote machine
function replace_dhcpcd_conf {
    scp_output=$(scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/x/.ssh/id_rsa $LOCAL_DHCPCD_CONF $REMOTE_USERNAME@$REMOTE_MACHINE:$REMOTE_DHCPCD_CONF 2>&1)
    if [ $? -eq 0 ]; then
        echo "dhcpcd.conf file replaced successfully."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i /home/x/.ssh/id_rsa $REMOTE_USERNAME@$REMOTE_MACHINE "sudo reboot"
        echo "Transfer and reboot command sent."
        break
    else
        echo "Failed to replace dhcpcd.conf file. Error: $scp_output"
    fi
}

# Main script logic
while : ; do
    replace_dhcpcd_conf
    sleep 1
done
