# Bootstrapping the NixOS Installation

### Steps:
1) Partition the target disk and mount it at `/mnt`. The disk should ideally contain at least these two partitions:
    - Root partition with label `NIXOS` (any supported type, for example ext4); mounted at `/mnt`
    - EFI partition with label `EFI` (type vfat, recommended size 500MB); mounted at `/mnt/boot`
2) Download the installation script and run it, for example:
`curl -sSL https://raw.githubusercontent.com/andreasbrouwer/nixos-bootstrap/refs/heads/main/install.sh | bash`
3) Reboot and configure the installation as usual (create SSH keys, create custom configuration, etc.)

