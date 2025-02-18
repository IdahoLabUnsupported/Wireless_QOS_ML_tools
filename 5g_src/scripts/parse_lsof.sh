read data
while IFS=$'\t' read -r -a myArray
do
	echo "${myArray[0]}"
done < data
