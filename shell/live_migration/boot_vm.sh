#!/bin/bash
# 2018-5-30
# set -x

COMPUTE_LIST_FILE=$1

FLAVOR=$2
IMAGE=$3
NETNAME=$4
ZONENAME=$5
KEYNAME=$6

FLAVOR=1
RESIZE_FLAVOR=2
IMAGE='cirros'
#NETNAME='net125;net10'
NETNAME='net125'
ZONENAME='nova'
KEYNAME='key26'


function record_info_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time INFO $@" >> '/var/log/test_check.log'
}
function record_error_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time ERROR $@" >> '/var/log/test_check.log'
}

function boot_vm(){
    local vm_name=$1
    local compute_name=$2
    flavor_param=" --flavor ${FLAVOR}"
    image_param=" --image ${IMAGE}"
    for net in ${NETNAME//;/ }
    do
        if [[ "$net" =~ "," ]]
        then
            local net_name=${net%,*}
            local static_ip=${net#*,}
            nic_param="${nic_param} --nic net-name=${net_name},v4-fixed-ip=${static_ip}"
        else
            nic_param="${nic_param} --nic net-name=${net}"
        fi
    done
    if [ -n "$ZONENAME" ]
    then
        zone_compute_param=" --availability-zone ${ZONENAME}"
        if [ -n "$compute_name" ]
        then
        zone_compute_param="${zone_compute_param}:${compute_name}"
        fi 
    fi
    if [ -n "$KEYNAME" ]
    then
        keyname_param=" --key-name ${KEYNAME}"
    fi

    # nova boot vm1 --flavor 2 --image redhat7.2 --nic net-name=net125,v4-fixed-ip=172.30.125.102 --nic net-name=net10 --availability-zone nova:compute03 --key-name key26
    boot_ret=$(nova boot ${vm_name} ${flavor_param} ${image_param} ${nic_param} ${zone_compute_param} ${keyname_param})
    if [ "$?" == "0" ]
    then
        local vm_uuid=$(echo "$boot_ret" | grep " id " | awk '{print $4}')
        echo "$vm_uuid"
        record_info_log "boot vm $vm_name($vm_uuid) ok."
    else
        record_error_log "boot vm $vm_name($vm_uuid) error: $boot_ret"
    fi
}

function test_main(){
    local compute_list_file=$1
    test -z $compute_list_file && exit 1
    test -f $compute_list_file || exit 2
    while read src_node vm_name dest_node
    do
        # 执行热迁移
        # boot_vm $vm $src_node
        echo "vm name: ${vm_name}, in node: $src_node"
    done<$compute_list_file
}

record_info_log "Test virtual machine boot"
test_main $COMPUTE_LIST_FILE

