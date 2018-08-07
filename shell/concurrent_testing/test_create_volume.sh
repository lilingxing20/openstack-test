#!/bin/bash

## 如下不可以修改
volume_prefix=test_volume
volume_count=25000
volume_created_count=0
volume_size=1
operation_batch_size=100

for i in `seq 1 $volume_count`
do
  cinder create --name ${volume_prefix}_$i $volume_size >/dev/null&
  echo "volume ${volume_prefix}_$i create operation invoked..."
  ((operation_count++))
  [[ $(($operation_count % $operation_batch_size)) -eq 0 ]] && sleep 10
done

echo "Checking the volume status..."
index=0
while :; do
  ((index++))
  volume_created_count=$(cinder list | grep ${volume_prefix} | grep available | wc -l)
  echo "$volume_created_count out of $volume_count volumes had been created successfully"
  if [[ $volume_created_count -eq $volume_count ]]; then
    echo "All the ${volume_count} volumes had been created successfully"
    exit 0
  fi
  
  sleep 10
done
