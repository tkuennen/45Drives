BAYS=$((cat /etc/zfs/vdev_id.conf| awk "NR>2" | wc -l) 2>/dev/null)

i=0
j=3
## LOOP THROUGH BAYS
while [ "$i" -lt $BAYS ];do
	bay=$(cat /etc/zfs/vdev_id.conf | awk -v j=$j 'NR==j{print $2}')
	BAY[$i]=$bay
	let i=i+1
	let j=j+1
done

i=0
while [ "$i" -lt $BAYS ];do 
	parted -s /dev/disk/by-vdev/${BAY[$i]} mklabel loop 2&>/dev/null
	if [ $? -eq 0 ]; then
		echo -e "device ${BAY[$i]} has been wiped"
	fi
	let i=i+1
done
