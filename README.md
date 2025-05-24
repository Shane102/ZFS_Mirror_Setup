# ZFS Mirror Setup Script

This script automates the process of securely wiping two disks and creating a mirrored ZFS pool on Linux systems (Debian/Ubuntu). It is gives a repeatable, safe, and robust way to set up a ZFS mirror.

## Notes
- If you have previously used the disks on this system (for example, as part of another ZFS pool, RAID array, or with other filesystems such as EXT4), you may need to manually remove old mount points or entries from `/etc/fstab` and `/etc/zfs/zfs-list.cache/` to avoid conflicts.  
  - Check for existing mount points with `mount | grep /dev/sd` or `lsblk`.
  - Remove or comment out any related lines in `/etc/fstab` that reference the old disks, mount points, or EXT4 filesystems.
  - If ZFS pools were previously imported, run `zpool export <old_pool_name>` to cleanly remove them.
  - For EXT4 or other filesystems, unmount them with `umount <mount_point>` before proceeding.
  - Delete any stale directories in `/mnt`, `/media`, or your custom mount locations if they are no longer needed.

  This ensures a clean environment for the new ZFS mirror setup.

- Then end result should be that you have a new folder in the systems root folder called `[POOL_NAME/data/]` 
  - Use the `[POOL_NAME/data/]` folder for storing data, not `[POOL_NAME]` as this makes proper use of ZFS functionalities like snapshotting etc.  

## Features
- **Safety checks**: Prompts for confirmation and verifies disk existence before proceeding.
- **Disk wiping**: Removes all signatures, partitions, and overwrites the first 100MB of each disk.
- **ZFS installation**: Installs ZFS utilities if not already present.
- **Idempotent**: Skips pool/dataset creation if they already exist.
- **Ownership**: Sets the new pool and dataset to the current user.
- **Summary**: Shows the final ZFS pool and dataset status.

## Usage

1. **Edit the script**: Open `ZFS_mirror_setup.sh` and set the following variables at the top:
   - `DISK_ID_1` and `DISK_ID_2`: The `/dev/disk/by-id/` names of your two disks. Use `ls -l /dev/disk/by-id/` to find them.
   - `POOL_NAME`: The name for your new ZFS pool (e.g., `SG6tb_zfs_pool`). This must start with a letter.

2. **Run the script**:
   ```bash
   chmod +x ZFS_mirror_setup.sh
   ./ZFS_mirror_setup.sh
   ```

3. **Follow the prompts**: The script will warn you and ask for confirmation before making any changes.

## What the Script Does
- Installs ZFS utilities (`zfsutils-linux`) if needed.
- Wipes all data, signatures, and partitions from the specified disks.
- Creates a mirrored ZFS pool with the given name.
- Creates a default dataset (`<pool_name>/data`).
- Sets ownership of the pool and dataset to the current user.
- Prints a summary of the new pool and dataset.

## Warnings
- **ALL DATA ON THE SPECIFIED DISKS WILL BE LOST.**
- Double-check your disk IDs before running.
- Only use this script on new or empty disks.

## Example
```bash
DISK_ID_1="ata-ST6000DM003-2CY186_ZCT25Q8C"
DISK_ID_2="ata-ST6000DM003-2CY186_ZCT25QFT"
POOL_NAME="SG6tb_zfs_pool"
```

## Requirements
- Linux (Debian/Ubuntu recommended)
- Root/sudo privileges
- Two disks (not partitions) available via `/dev/disk/by-id/`

## License
MIT License

---
**Use at your own risk.**
