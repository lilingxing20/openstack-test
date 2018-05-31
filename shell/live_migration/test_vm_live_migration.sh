#!/bin/bash
# 2018-05-30

COMPUTE_LIST_FILE=$1


function record_info_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time INFO $@" >> '/var/log/test_check.log'
}
function record_error_log(){
    now_time=$(date  "+%Y%m%d-%H:%M:%S")
    echo "$now_time ERROR $@" >> '/var/log/test_check.log'
}

function live_migrate_vm(){
    local vm_name=$1
    local migrate_node=$2
    local ret=$(nova live-migration $vm_name $migrate_node)
    if [ "$?" == "0" ]
    then
        record_info_log "migrating vm $vm_name ok"
    else
        record_error_log "migrating vm $vm_uuid error !"
    fi
}


function test_main(){
    local compute_list_file=$1
    test -z $compute_list_file && exit 1
    test -f $compute_list_file || exit 2
    while read src_node vm_name dest_node
    do
        # 执行热迁移
        # live_migrate_vm $vm_name $dest_node
        echo "live migrate vm: ${vm_name}, dest node: $dest_node"
    done<$compute_list_file
}

record_info_log "Test virtual machine live migrate"
test_main $COMPUTE_LIST_FILE
