#!/bin/bash

set -x

bm_name=$1
FLAVORID=$2
IMAGEID=$3
NETID=$4

# bm47 test | baremetal-net | RHEL-7.4-baremetal-heat-zabbix-X86_64-lvm-20171226.qcow2
FLAVORID='576d5d18-9898-42aa-8649-641c305a115a'
NETID='4c68f792-aafd-46f9-a20a-9711435fee9c'
IMAGEID='8592f0ed-9881-4272-9116-956aceb82bcd'

## vm test
#FLAVORID='3'
#NETID='84b38a36-8b3a-4a35-802a-81283cbf3998'
#IMAGEID='ed296822-98bf-4521-933f-b0ef3bf04c7b'

# boot timeout minutes
BOOT_TIMEOUT_M=20
# delete sleep seconds
DELETE_SLEEP_S=30
# boot check times
BOOT_CHECK_TIMES=3

# nova boot bm47 --image 8592f0ed-9881-4272-9116-956aceb82bcd --flavor 576d5d18-9898-42aa-8649-641c305a115a --nic net-id=4c68f792-aafd-46f9-a20a-9711435fee9c
# nova boot --image RHEL-7.4-baremetal-heat-zabbix-lvm-20180425 --flavor node200-2 --nic net-id=23872673-df25-4c67-b8b8-d2776cdf6d52 node200-2

function record_check_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time $@" >> '/var/log/bm_check.log'
}

function record_state_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time $@" >> '/var/log/bm_state.log'
}

function get_bm_status(){
    bm_name=$1
    bm_state=$(nova list --name ${bm_name} | tail -2 | head -1 | awk '{print $6"_"$10}')
    echo $bm_state
}

function boot_bm(){
    bm_name=$1
    boot_state=$(nova boot --flavor ${FLAVORID} --nic net-id=${NETID} --image ${IMAGEID} ${bm_name})
    echo $boot_state
}

function delete_bm(){
    bm_name=$1
    boot_state=$(nova delete ${bm_name})
    echo $boot_state
}

function check_bm_state_timeout(){
    bm_name=$1
    for i in `seq $BOOT_TIMEOUT_M`
    do
        sleep 60
        bm_state=$(get_bm_status ${bm_name})
        record_check_log "times:$i $bm_name state:$bm_state"
        case $bm_state in
        'ACTIVE_Running')
            echo  0
            return
        ;;
        #'BUILD_NOSTATE')
        #    echo 1
        #;;
        'ERROR_NOSTATE')
            echo 1
            return
        ;;
        '_')
            echo 2
            return
        ;;
        esac 
    done
    echo 1
}


function test_bm_main(){
    bm_name=$1
    test -z $bm_name && exit 1
    success_times=0
    error_times=0

    for i in `seq $BOOT_CHECK_TIMES`
    do
        boot_bm $bm_name
        check_ret=$(check_bm_state_timeout "$bm_name")
        case $check_ret in
            '0')
            success_times=`expr $success_times + 1`
            ;;
            '1')
            error_times=`expr $error_times + 1`
            ;;
            '2')
            record_state_log "$bm_name boot error."
            return
            ;;
        esac
        delete_bm $bm_name
        sleep $DELETE_SLEEP_S
    done
    record_state_log "$bm_name check_times:$BOOT_CHECK_TIMES,success_times:$success_times,error_times:$error_times"
}


test_bm_main 'test_bm47'
#test_bm_main $bm_name

