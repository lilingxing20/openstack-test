#!/bin/bash

## 如下不可以修改
network_count=4000
network_created_count=0
network_prefix=test_network
network_list_not_complte=/root/network_not_finished.out
operation_batch_size=100

for i in `seq 1 $network_count` 
do
  neutron net-create ${network_prefix}_$i >/dev/null&

  echo "network ${network_prefix}_$i create operation invoked..."
  ((operation_count++))

  [[ $(($operation_count % $operation_batch_size)) -eq 0 ]] && sleep 20
done

while :; do 
  network_created_count=$(neutron net-list | grep ${network_prefix} | wc -l)

  if [[ $network_created_count -eq $network_count ]]; then
      echo "All the ${network_count} networks had been created successfully"
      exit 0
  fi

  echo "$network_created out of $network_count had been created"

  sleep 5
done

