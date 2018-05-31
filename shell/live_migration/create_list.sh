#!/bin/bash
#

compute_list_file=$1
now_time=$(date  "+%Y%m%d%H%M%S")

test -z $compute_list_file && exit 1
test -f $compute_list_file || exit 2

src_compute_names=$(cat $compute_list_file)
dest_compute_names=$(cat $compute_list_file)
compute_num=$(cat $compute_list_file | wc -l)
for i in $(seq ${compute_num})
do
    # 随机取出一个计算节点
    src_get_node1=$(echo "$src_compute_names" | shuf -n1)
    src_get_node2=$src_get_node1
    src_compute_names=$(echo "$src_compute_names" | grep -v $src_get_node1)
    dest_get_node=$(echo "$dest_compute_names"| grep -v $src_get_node1 | grep -v $src_get_node2 | shuf -n1)
    dest_compute_names=$(echo "$dest_compute_names" | grep -v $dest_get_node)
    
    #echo "$i  vm: ${src_get_node1},node: $dest_get_node   $(echo "$src_compute_names"| wc -l),$(echo "$dest_compute_names"| wc -l)"
    echo "${src_get_node1}  ${src_get_node1}_to_${dest_get_node}  ${dest_get_node}"
    echo "${src_get_node1}  ${src_get_node1}_to_${dest_get_node}  ${dest_get_node}" >>$now_time
    #echo $src_compute_names
    #echo $dest_compute_names
done
