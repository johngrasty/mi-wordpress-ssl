# Setting ZFS plan from mdata. This could be more programatic, but setting
# a variable from metadata gives me control. Maybe combo?
log "Checking zfs plans from mdata"

ZFS_DATASET=${ZFS_DATASET:-$(mdata-get zfs_dataset 2>/dev/null)} || \
ZFS_DATASET="true";

if [[ ${ZFS_DATASET} == "true" ]] && [[ ! -e "/data/zfs_move" ]]; then

	#Exit on error rather than plowing on.
	set -o errexit

	#Save errors to file (I think)
	set -o xtrace

	echo "Moving the mount point for the delegated dataset."
	zfs set mountpoint=/data zones/`zonename`/data

	touch /data/zfs_move

fi
