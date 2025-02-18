# STR="192.168.1.100/pi0"
# IP=${STR%/*}
# NAME=${STR#*/}

# echo $IP
# echo $NAME

# N=4
# temp=5
# for ((i=0; i<$N; i++ ))
# do
#     temp=$((temp + 1))
#     echo $temp
# done





# TEST="down"

# if [ $TEST = "down" ];
# then
#     echo "true"
# fi




# PI_NAME="0"
# rm -rf /home/ubuntu/ldrd/upload/${PI_NAME}_*


# TESTFILE="/home/ubuntu/ldrd/files/example1.jpg"
# FILENAME="$(basename $TESTFILE)"

# echo $FILENAME





# n_procs=(1 2 3 4 5)
# for i in $n_procs; do
#     echo "test"
#     pids[${i}]=$i
# done

# for ((n=1; n<=4; n++))
# do
#     echo "start loop $n"
#     temp=6
#     for ((i=1; i<$temp; i++ ))
#     do
#         pids[${i}]=$(( $i * $n ))
#     done

#     for x in "${pids[@]}"; do
#         echo $x
#     done
# done


# #!/bin/bash
# while getopts c:p:a: flag
# do
#     case "${flag}" in
#         a) AUTH_ENABLED=true;;
#         c) CONFIGURATION_ID=${OPTARG};;
#         p) MAX_PI_COUNT=${OPTARG};;
#     esac
# done


# #!/bin/bash
# AUTH_ENABLED=false
# while getopts 'ac' flag
# do
#     case "${flag}" in
#         a) AUTH_ENABLED=true ;;
#         c) CONFIGURATION_ID=${OPTARG};;
#     esac
# done

# echo $CONFIGURATION_ID

# if $AUTH_ENABLED; then
#     echo "true"
# else
#     echo "false"
# fi


# i=1
# setup_script=$(sed -n ${i}p configurations)
# echo $setup_script




# Test switching from no auth to auth on the pi

temp='unknown'
if [[ $temp != "unknown" ]]; then
    echo "test"
fi