#!/bin/bash
set -euo pipefail # Exit on error, unset variable, or failed pipeline


######## Variables - IMPORTANT ########
# --- Configuration ---
# IMPORTANT: Replace these with the actual /dev/disk/by-id/ paths for your disks.
# Use 'ls -l /dev/disk/by-id/' to find them.
# Example: ata-ST6000DM003-2CY186_ZCT25Q8C
DISK_ID_1="ata-ST6000DM003-2CY186_ZCT25Q8C"
DISK_ID_2="ata-ST6000DM003-2CY186_ZCT25QFT"

# Name for your new ZFS pool (e.g., 'two_tb_pool' or 'six_tb_pool')
# This has to start with a letter and can contain letters, numbers, and underscores.
POOL_NAME="SG6tb_zfs_pool"

########## End of Variables ########


# --- Pre-checks and Confirmation ---

echo "------------------------------------------------------------------"
echo "WARNING: This script will ERASE ALL DATA on the following disks:"
echo "  Disk 1: /dev/disk/by-id/$DISK_ID_1"
echo "  Disk 2: /dev/disk/by-id/$DISK_ID_2"
echo "All data on these disks will be LOST PERMANENTLY."
echo "------------------------------------------------------------------"

read -p "Are you absolutely sure you want to proceed? (yes/no): " CONFIRMATION
if [[ ! "$CONFIRMATION" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Operation cancelled by user."
    exit 1
fi


# Verify disks exist before proceeding
if [ ! -e "/dev/disk/by-id/$DISK_ID_1" ] || [ ! -e "/dev/disk/by-id/$DISK_ID_2" ]; then
    echo "Error: One or both specified disk IDs do not exist."
    echo "Please verify the DISK_ID_1 and DISK_ID_2 variables."
    exit 1
fi

echo "Proceeding with disk preparation and ZFS pool creation..."


# --- Step 1: Install ZFS Utilities (if not already installed) ---
echo "Checking and installing zfsutils-linux..."
sudo apt update
sudo apt install -y zfsutils-linux


# --- Step 2: Wipe Existing Partitions/Signatures ---
echo "Wiping existing partitions and signatures from disks..."
sudo wipefs --all --force "/dev/disk/by-id/$DISK_ID_1"
sudo wipefs --all --force "/dev/disk/by-id/$DISK_ID_2"

sudo sgdisk --zap-all "/dev/disk/by-id/$DISK_ID_1"
sudo sgdisk --zap-all "/dev/disk/by-id/$DISK_ID_2"


# Overwrite the beginning of the disk with zeros to ensure a clean slate
echo "Overwriting first 100MB of each disk with zeros (this may take a moment)..."
sudo dd if=/dev/zero of="/dev/disk/by-id/$DISK_ID_1" bs=1M count=100 || true # || true to prevent script from exiting on dd error if disk is busy
sudo dd if=/dev/zero of="/dev/disk/by-id/$DISK_ID_2" bs=1M count=100 || true # || true to prevent script from exiting on dd error if disk is busy

echo "Disk wiping complete."


# --- Step 3: Create the ZFS Mirrored Pool ---
# Check if pool already exists
if sudo zpool list | grep -qw "$POOL_NAME"; then
    echo "ZFS pool '$POOL_NAME' already exists. Skipping creation."
else
    echo "Creating ZFS mirrored pool '$POOL_NAME'..."
    sudo zpool create "$POOL_NAME" mirror "/dev/disk/by-id/$DISK_ID_1" "/dev/disk/by-id/$DISK_ID_2"
    echo "ZFS pool '$POOL_NAME' created successfully."
fi


# --- Step 4: Verify Pool Creation ---
echo "Verifying ZFS pool status..."
sudo zpool status "$POOL_NAME"


# --- Step 5: Adjust Permissions ---
# ZFS automatically mounts the pool at /<POOL_NAME>
echo "Setting ownership of /$POOL_NAME to current user ($USER)..."
sudo chown -R "$USER":"$USER" "/$POOL_NAME"


# --- Step 6: Create a default dataset (optional but recommended) ---
# Only create dataset if it doesn't already exist
if ! sudo zfs list | grep -qw "$POOL_NAME/data"; then
    echo "Creating default dataset '$POOL_NAME/data'..."
    sudo zfs create "$POOL_NAME/data"
    sudo chown -R "$USER":"$USER" "/$POOL_NAME/data"
else
    echo "Dataset '$POOL_NAME/data' already exists. Skipping creation."
fi

# --- Step 7: Final Summary ---
echo "\nZFS pool list:" && sudo zpool list

echo "\nZFS dataset list:" && sudo zfs list

echo "ZFS mirror setup complete!"
echo "Your new ZFS pool '$POOL_NAME' is mounted at '/$POOL_NAME'."
echo "You can start storing data in '/$POOL_NAME/data'."
echo "Remember to regularly check 'sudo zpool status' for disk health."

# --- Step 8: Create a symlink to the ZFS dataset in the user's home directory ---
read -p "Do you want to create a symlink to the ZFS dataset in your home directory? (y/n): " CREATE_SYMLINK
if [[ "$CREATE_SYMLINK" =~ ^[Yy]$ ]]; then
    SYMLINK_PATH="$HOME/$POOL_NAME/data"
    TARGET_PATH="/$POOL_NAME/data"
    if [ -L "$SYMLINK_PATH" ] || [ -e "$SYMLINK_PATH" ]; then
        echo "Symlink or file $SYMLINK_PATH already exists. Skipping symlink creation."
    else
        echo "Creating symlink: $SYMLINK_PATH -> $TARGET_PATH"
        ln -s "$TARGET_PATH" "$SYMLINK_PATH"
    fi
else
    echo "Skipping symlink creation."
fi
