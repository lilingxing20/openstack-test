#!/bin/bash
# by lixx 2018-5-25
# set -x

# nova boot vm1 --flavor 2 --image redhat7.2 --nic net-name=net125,v4-fixed-ip=172.30.125.102 --nic net-name=net10 --availability-zone nova:compute03 --key-name key26
VM_UUID=$1
vm_name=$1
FLAVOR=$2
IMAGE=$3
NETNAME=$4
ZONENAME=$5
COMPUTENAME=$6
KEYNAME=$7

FLAVOR=2
IMAGE='redhat7.2'
#NETNAME='net125;net10'
NETNAME='net125'
ZONENAME='nova'
COMPUTENAME='compute01'
KEYNAME='key26'
attach_net_id='0cd36db1-b06f-4a2c-be0a-4bb5d678a065'

# boot timeout minutes/2
BOOT_TIMEOUT_M=10

function record_info_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time INFO $@" >> '/var/log/test_check.log'
}
function record_error_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time ERROR $@" >> '/var/log/test_check.log'
}


function get_vm_status(){
    # local vm_name=$1
    # local vm_state=$(nova list --name ${vm_name} | tail -2 | head -1 | awk '{print $6"_"$10}')
    local vm_uuid=$1
    local vm_state=$(nova list | grep ${vm_uuid} | tail -2 | head -1 | awk '{print $6"_"$10}')
    echo $vm_state
}

function boot_vm(){
    local vm_name=$1
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
        if [ -n "$COMPUTENAME" ]
        then
        zone_compute_param="${zone_compute_param}:${COMPUTENAME}"
        fi 
    fi
    if [ -n "$KEYNAME" ]
    then
        keyname_param=" --key-name ${KEYNAME}"
    fi

    boot_ret=$(nova boot ${vm_name} ${flavor_param} ${image_param} ${nic_param} ${zone_compute_param} ${keyname_param})
    if [ "$?" == "0" ]
    then
        local vm_uuid=$(echo "$boot_ret" | grep " id " | awk '{print $4}')
        echo "$vm_uuid"
        record_info_log "boot vm $vm_name($vm_uuid) success."
    else
        record_error_log "boot vm $vm_name($vm_uuid) error: $boot_ret"
    fi
}

function delete_vm(){
    local vm_uuid=$1
    delete_ret=$(nova delete ${vm_uuid})
    if [ "$?" == "0" ]
    then
        record_info_log "delete vm $vm_name($vm_uuid) success."
    else
        record_error_log "delete vm $vm_name($vm_uuid) error: $delete_ret"
        echo "$delete_ret"
    fi
}

function check_vm_state_timeout(){
    local vm_uuid=$1
    for i in `seq $BOOT_TIMEOUT_M`
    do
        sleep 30
        vm_state=$(get_vm_status ${vm_uuid})
        case $vm_state in
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

# nova interface-attach de65020f-8bc2-43b1-aabe-8b4f1b18af1d --net-id  0cd36db1-b06f-4a2c-be0a-4bb5d678a065
function attach_interface(){
    local vm_uuid=$1
    local net_id=$2
    local ret=$(nova interface-attach ${vm_uuid} --net-id ${net_id})
    if [ "$?" == "0" ]
    then
        record_info_log "attaching interface($net_id) for vm $vm_uuid"
        check_vm_interface $vm_uuid $net_id
    else
        record_error_log "attaching interface($net_id) for vm $vm_uuid error !"
    fi
}

# # nova interface-list de65020f-8bc2-43b1-aabe-8b4f1b18af1d
# +------------+--------------------------------------+--------------------------------------+---------------+-------------------+
# | Port State | Port ID                              | Net ID                               | IP addresses  | MAC Addr          |
# +------------+--------------------------------------+--------------------------------------+---------------+-------------------+
# | ACTIVE     | 66a747ff-7b9c-407f-9e0a-f6084a756b62 | 0cd36db1-b06f-4a2c-be0a-4bb5d678a065 | 10.10.10.17   | fa:16:3e:1e:af:51 |
# | ACTIVE     | 8834e6dc-a91e-4f1a-998c-6aa0d3b0d516 | 87541021-94f5-407f-a5a2-448d0dd4be0b | 172.30.125.68 | fa:16:3e:77:4b:bf |
# +------------+--------------------------------------+--------------------------------------+---------------+-------------------+
function check_vm_interface(){
    local vm_uuid=$1
    local net_id=$2
    local ret=$(nova interface-list ${vm_uuid} | grep ${net_id})
    if [ "$?" == "0" ]
    then
        record_info_log "attach interface($net_id) for vm $vm_uuid succeeded."
    else
        record_error_log "attach interface($net_id) for vm $vm_uuid failed: $ret"
    fi
}

function create_test_volume(){
    local volume_name=$1
    local ret=$(cinder create 1 --name $volume_name)
    if [ "$?" == "0" ]
    then
        local volume_id=$(echo "$ret" | grep " id " | awk '{print $4}')
        echo "$volume_id"
    fi
}
function delete_test_volume(){
    local volume_id=$1
    local ret=$(cinder delete $volume_id)
}

# # nova volume-attachments e92a9520-4bdc-4efe-8d62-f697506dc839 
# +--------------------------------------+----------+--------------------------------------+--------------------------------------+
# | ID                                   | DEVICE   | SERVER ID                            | VOLUME ID                            |
# +--------------------------------------+----------+--------------------------------------+--------------------------------------+
# | 921bf904-bac6-4c52-954d-a8bdb5d833d1 | /dev/vdb | e92a9520-4bdc-4efe-8d62-f697506dc839 | 921bf904-bac6-4c52-954d-a8bdb5d833d1 |
# +--------------------------------------+----------+--------------------------------------+--------------------------------------+
function check_vm_attach_volume(){
    local vm_uuid=$1
    local volume_id=$2
    local ret=$(nova volume-attachments ${vm_uuid} | grep ${volume_id})
    if [ "$?" == "0" ]
    then
        record_info_log "attach volume($volume_id) for vm $vm_uuid succeeded."
    else
        record_error_log "attach volume($volume_id) for vm $vm_uuid failed: $ret"
    fi
}

# # nova  volume-attach e92a9520-4bdc-4efe-8d62-f697506dc839 921bf904-bac6-4c52-954d-a8bdb5d833d1
# +----------+--------------------------------------+
# | Property | Value                                |
# +----------+--------------------------------------+
# | device   | /dev/vdb                             |
# | id       | 921bf904-bac6-4c52-954d-a8bdb5d833d1 |
# | serverId | e92a9520-4bdc-4efe-8d62-f697506dc839 |
# | volumeId | 921bf904-bac6-4c52-954d-a8bdb5d833d1 |
# +----------+--------------------------------------+
function attach_volume(){
    local vm_uuid=$1
    local volume_id=$(create_test_volume 'use_test_vm_attach_volume')
    test -z "$volume_id" && return
    local ret=$(nova volume-attach ${vm_uuid} ${volume_id})
    if [ "$?" == "0" ]
    then
        record_info_log "attaching volume($volume_id) for vm $vm_uuid"
        check_vm_attach_volume $vm_uuid $volume_id
    else
        record_error_log "attaching volume($volume_id) for vm $vm_uuid error !"
    fi
    echo $volume_id
}

function test_vm_main(){
    local vm_name=$1
    test -z $vm_name && exit 1
    success_times=0
    error_times=0

    local vm_uuid=$(boot_vm $vm_name)
    check_ret=$(check_vm_state_timeout "$vm_uuid")
    case $check_ret in
        '0')
        echo "boot $vm_name success"
        ;;
        *)
        echo "boot $vm_name error"
        return
        ;;
    esac

    attach_interface $vm_uuid $attach_net_id
    sleep 10

    local volume_id=$(attach_volume $vm_uuid)
    sleep 10

    delete_vm $vm_uuid
    sleep 10

    delete_test_volume $volume_id
}

record_info_log "Test virtual machine $vm_name"
test_vm_main $vm_name

