#!/bin/bash

##如下参数可以修改
image_file_path=/root/TestVM.qcow2

## 如下不可以修改
image_prefix=test_image
image_count=1000
image_created_count=0
operation_batch_size=20

[ ! -f $image_file_patch ] && echo "image file of $image_file_path not exists" && exit 1

for i in $(seq 1 $image_count); do
  glance image-create --name ${image_prefix}_$i --file $image_file_path --disk-format qcow2 --container-format bare >/dev/null&
  echo "image ${image_prefix}_$i create operation invoked..."
  ((operation_count++))

  [[ $(($operation_count % $operation_batch_size)) -eq 0 ]] && sleep 10
done

while :; do
  image_created_count=$(nova image-list | grep ${image_prefix} | grep ACTIVE | wc -l) 
  echo "$image_created_count out of ${image_count} images had been created successfully"

  if [[ $image_created_count -eq $image_count ]];  then
    echo "All the ${image_count} images had been created successfully"
    exit 0
  fi 

  sleep 5
done
