#!/bin/bash

# ============================================
# DevOps Patching Script with Email Alert
# ============================================

# Log file path (stores all output)
LOG_FILE="/var/log/devops-patching.log"

# Email where alert will be sent
EMAIL="nagarajuthota951@gmail.com"   # 🔴 change this

# Current timestamp
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$DATE] Starting patching process..." | tee -a $LOG_FILE


# ============================================
# CHECK ROOT PERMISSION
# ============================================
# Only root user can run updates
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run as root or sudo" | tee -a $LOG_FILE
    exit 1
fi


# ============================================
# DETECT OS
# ============================================
detect_os() {

    # If Debian/Ubuntu file exists
    if [ -f /etc/debian_version ]; then
        OS="debian"

    # If RHEL/CentOS file exists
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"

    # Unknown OS
    else
        OS="unknown"
    fi
}


# ============================================
# PATCH SYSTEM
# ============================================
patch_system() {

    if [ "$OS" == "debian" ]; then
        echo "Updating Debian/Ubuntu..." | tee -a $LOG_FILE

        # Update package list
        apt update -y >> $LOG_FILE 2>&1

        # Upgrade installed packages
        apt upgrade -y >> $LOG_FILE 2>&1

        # Remove unused packages
        apt autoremove -y >> $LOG_FILE 2>&1

    elif [ "$OS" == "rhel" ]; then
        echo "Updating RHEL/CentOS..." | tee -a $LOG_FILE

        # Clean yum cache
        yum clean all >> $LOG_FILE 2>&1

        # Update packages
        yum update -y >> $LOG_FILE 2>&1

    else
        echo "ERROR: Unsupported OS" | tee -a $LOG_FILE
        exit 1
    fi
}


# ============================================
# CHECK IF REBOOT IS REQUIRED
# ============================================
check_reboot() {

    # Debian-based systems create this file if reboot needed
    if [ -f /var/run/reboot-required ]; then
        echo "Reboot required!" | tee -a $LOG_FILE
        REBOOT="yes"
    else
        echo "No reboot required" | tee -a $LOG_FILE
        REBOOT="no"
    fi
}


# ============================================
# SEND EMAIL ALERT
# ============================================
send_alert() {

    SUBJECT="Patching Report - $(hostname)"

    MESSAGE="Hello,

Patching has been completed successfully.

Server: $(hostname)
Date: $(date)

Reboot Required: $REBOOT

Log File: $LOG_FILE

Regards,
DevOps Team
"

    # Send email using mail command
    echo "$MESSAGE" | mail -s "$SUBJECT" $EMAIL

    echo "Email sent to $EMAIL" | tee -a $LOG_FILE
}


# ============================================
# MAIN EXECUTION
# ============================================

# Step 1: Detect OS
detect_os
echo "Detected OS: $OS" | tee -a $LOG_FILE

# Step 2: Patch system
patch_system

# Step 3: Check reboot
check_reboot

# Step 4: Send email
send_alert

echo "[$DATE] Patching completed successfully." | tee -a $LOG_FILE


# ============================================
# OPTIONAL REBOOT
# ============================================

# If reboot required, restart system
if [ "$REBOOT" == "yes" ]; then
    echo "System will reboot in 60 seconds..." | tee -a $LOG_FILE
    sleep 60
    reboot
fi
