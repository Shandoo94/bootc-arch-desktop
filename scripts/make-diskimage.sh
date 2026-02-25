# Create a blank file (this will be our virtual hard drive)
IMAGE_PATH="install-image.raw"
truncate -s 8G "$IMAGE_PATH"

# Attach it as a loop device so Linux treats it like a real disk
LOOPDEV=$(sudo losetup -f --show "$IMAGE_PATH")

# Partitioning
sudo parted -s "$LOOPDEV" mklabel gpt
sduo parted -s "$LOOPDEV" mkpart ESP fat32 1MiB 1GiB
sduo parted -s "$LOOPDEV" set 1 esp on
sudo parted -s "$LOOPDEV" mkpart swap linux-swap 1GiB 3GiB
sudo parted -s "$LOOPDEV" mkpart pool 3GiB 100%

# Get the partition paths
sudo partprobe "$LOOPDEV"
EFI_PART="${LOOPDEV}p1"
ROOT_PART="${LOOPDEV}p2"

# Format partitions
sudo mkfs.fat -F 32 "$EFI_PART"
sudo mkfs.btrfs -f -L poolfs "$ROOT_PART"

# Mount and create subvolumes
mkdir -p /mnt
sudo mount -t btrfs -o subvol=/ "$ROOT_PART" /mnt
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/var
sudo umount /mnt

# Remount in correct layout for installation
mount -t btrfs -o subvol=/root "$ROOT_PART" /mnt
mount --mkdir -t btrfs -o subvol=/var "$ROOT_PART" /mnt/var
mount --mkdir "$EFI_PART" /mnt/boot
