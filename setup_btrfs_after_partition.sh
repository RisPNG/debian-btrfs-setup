#!/bin/sh
# Make a Debian "all-in-one" btrfs root layout compatible with Timeshift.
# Works in d-i/Calamares shells where /target is the future system root.

set -eu

die() { echo "ERROR: $*" >&2; exit 1; }

# --- discover current mounts ---
ROOT_SRC="$(awk '$2=="/target"{print $1}' /proc/mounts | tail -n1)"
ROOT_FSTYPE="$(awk '$2=="/target"{print $3}' /proc/mounts | tail -n1)"
EFI_SRC="$(awk '$2=="/target/boot/efi"{print $1}' /proc/mounts | tail -n1 || true)"

[ -n "${ROOT_SRC:-}" ] || die "/target is not mounted (run after partitioning, before reboot)."
[ "${ROOT_FSTYPE:-}" = "btrfs" ] || die "/target is not btrfs (got '${ROOT_FSTYPE}')."

echo "Detected root device: ${ROOT_SRC}"
[ -n "${EFI_SRC:-}" ] && echo "Detected EFI device:  ${EFI_SRC}"

# --- unmount target so we can touch the btrfs top-level ---
umount /target/boot/efi
umount /target

# Mount the TOP-LEVEL (ID=5) so subvols are visible at /mnt
mkdir -p /mnt
mount -t btrfs "${ROOT_SRC}" /mnt

cd /mnt

# --- rename/create subvolumes ---
if [ -d "@rootfs" ] && [ ! -d "@" ]; then
  echo "Renaming @rootfs -> @"
  mv @rootfs @
fi

[ -d "@" ] || die "No '@' subvolume found (and no @rootfs to rename)."

# Create extra subvolumes if missing
for sv in @home @snapshots @log @cache; do
  if [ ! -d "$sv" ]; then
    echo "Creating subvolume $sv"
    btrfs subvolume create "$sv"
  fi
done

# --- remount the live target layout under /target ---
mount -o noatime,compress=zstd,subvol=@ "${ROOT_SRC}" /target
mkdir -p /target/boot/efi /target/home /target/.snapshots /target/var/log /target/var/cache

mount -o noatime,compress=zstd,subvol=@home      "${ROOT_SRC}" /target/home
mount -o noatime,compress=zstd,subvol=@snapshots "${ROOT_SRC}" /target/.snapshots
mount -o noatime,compress=zstd,subvol=@log       "${ROOT_SRC}" /target/var/log
mount -o noatime,compress=zstd,subvol=@cache     "${ROOT_SRC}" /target/var/cache

# Remount EFI if we had it
if [ -n "${EFI_SRC:-}" ]; then
  mount "${EFI_SRC}" /target/boot/efi
fi

# --- update /target/etc/fstab safely ---
FSTAB="/target/etc/fstab"
[ -f "$FSTAB" ] || die "Missing $FSTAB (run after the installer has staged the base system)."

cp -a "$FSTAB" "${FSTAB}.pre-timeshift"

ROOT_UUID="$(blkid -s UUID -o value "${ROOT_SRC}")"
[ -n "${ROOT_UUID:-}" ] || die "Could not get UUID for ${ROOT_SRC}"

# Comment any existing btrfs root line, then append our block
awk '
  $2=="/" && $3=="btrfs" {print "# timeshiftify: " $0; next}
  {print}
' "$FSTAB" > "${FSTAB}.new"

cat >> "${FSTAB}.new" <<EOF

# Timeshift-friendly btrfs subvolumes
UUID=${ROOT_UUID}  /             btrfs  noatime,compress=zstd,subvol=@          0  1
UUID=${ROOT_UUID}  /home         btrfs  noatime,compress=zstd,subvol=@home      0  2
UUID=${ROOT_UUID}  /.snapshots   btrfs  noatime,compress=zstd,subvol=@snapshots 0  2
UUID=${ROOT_UUID}  /var/log      btrfs  noatime,compress=zstd,subvol=@log       0  2
UUID=${ROOT_UUID}  /var/cache    btrfs  noatime,compress=zstd,subvol=@cache     0  2
EOF

mv "${FSTAB}.new" "$FSTAB"

echo
echo "Done. Review ${FSTAB} (a backup is at ${FSTAB}.pre-timeshift)."
echo "You can now switch back to the installer and continue."
