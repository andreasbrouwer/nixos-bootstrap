#!/usr/bin/env bash
#set -e # exit after any failure

echo "Welcome to the NixOS installation!"
echo "Before we start please make sure that you have created the appropriate disk layout (EFI + root partition) and mounted them to /mnt"
read -p "Continue? (Y/N): " CONFIRM && [[ $CONFIRM == [yY] || $CONFIRM == [yY][eE][sS] ]] || exit 1
if ! mountpoint -q /mnt; then
  echo "/mnt is not a mount point!"
  exit 1
fi

echo "Starting the installation process:"

echo "Step 1) Decrypting the private key for GitHub"
# Note: the text below is a base64 encode of the encrypted ssh key, create it with:
# >> openssl enc -aes-256-cbc -salt -pbkdf2 -in id_ed25519_github | base64
read -r -d '' GITHUB_PRIVATE_KEY_ENCRYPTED << EOM
U2FsdGVkX1/AiNZPObLCc2j3FC3D+B8GpnPajvPDZ4R09M8Yirj/GW/wmZOhNKwTWhHPqDvd6EIT
SiJx9U6bVOQTdjvy1AVoAGNMdBQ2jrKIcjcf506fWcmdmMp+HibgyuUxKHfmV/Exl42UJkFN2kc6
vOl6hGypgHxWEsnMQRDtbhDBITVDgbeCoEsqCBegKVfpiR4f+spAoZ76z6djTjQCvfWu03sPvOJI
Y/XrfGtbdQKJGj7pQp2R1R9Wmw0Xy6svarME1VRls77NQqkD7c7Jv8KaaYPJ2wXBUkMcLgxSJ6cA
0idLnxgdAOm7dgfMdQD3atVWVghBeamDkJqsdD+llBrhwKvaSeq44bYpO6GnzY1LSX78vsH2Ba1p
ZQhGCjoqX9kyivtbpnmTcp0JMppNqKuOvwQ9yKvhAvLb2hz0mLzgycA7ytqCs0nQ7oKKhIO/adPU
EFM6lpxedHpNozIv3I6LI0d58aAmTJR+2tlqhS/atJY8tz0758omYjZd46y9jXIzkl5qtdrdhztA
xutRDURk//eRpKBXf4tv8CWa2NylHAEJKMNTv1Syj3u3oo+4uNRZByxiWA8SNCJrkBqorf+9jAVC
h0YxYSjfu39MfYrwA4ucpZRXbqQ9042f98o1NJxfqic8dQQhc6hUI54CInXpeEU13Aqo7o0DWkao
B9orBpQYHslharYuYmNc
EOM
echo "$GITHUB_PRIVATE_KEY_ENCRYPTED" | base64 --decode | nix-shell -p openssl --run "openssl enc -aes-256-cbc -salt -pbkdf2 -out id_ed25519_github_tmp -d"
chmod 600 id_ed25519_github_tmp

echo "Step 2) Cloning the target repository (nixos-config)"
export GIT_SSH_COMMAND='ssh -i id_ed25519_github_tmp -o IdentitiesOnly=yes'
nix-shell -p git --run "git clone git@github.com:andreasbrouwer/nixos-config.git ./nixos-config"

echo "Step 3) Building a minimal installation (note: make sure to have enough space on tmpfs)"
# # check if there is at least 4 GB memory available
# if [[ $(grep -oP '^MemTotal:\s+\K\d+' /proc/meminfo) -gt 3906250 ]]; then
# 	echo "yep"
# else
# 	echo "nope"
# fi
sudo mount -o remount,size=4G /nix/.rw-store

nix build --extra-experimental-features "nix-command flakes" ./nixos-config#nixosConfigurations.minimal.config.system.build.toplevel

echo "Step 4) Installing NixOS"
sudo nixos-install --root /mnt --system ./result

echo "Bootstrap process completed! You can now reboot into the minimal installation and proceed from there."

