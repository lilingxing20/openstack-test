#!/bin/bash

## 如下不可以修改
network_count=4000
subnet_count=8000
subnet_created_count=0
network_prefix=test_network
subnet_prefix=test_subnet
operation_batch_size=100

generate_cidr_1()
{
  sequence=$1
 
  let num1=$sequence/256
  let num2=$sequence%256
 
  cidr="1.$num1.$num2.0/24"
  echo $cidr
}  

generate_cidr_2()
{
  sequence=$1

  let num1=$sequence/256
  let num2=$sequence%256

  cidr="2.$num1.$num2.0/24"
  echo $cidr
}

for i in `seq  1 $network_count`; do
  ((operation_count++))
  neutron subnet-create --name ${subnet_prefix}_$operation_count ${network_prefix}_$i $(generate_cidr_1 $i) >/dev/null &
  echo "subnet ${subnet_prefix}_$operation_count create operation invoked..."
  ((operation_count++))
  neutron subnet-create --name ${subnet_prefix}_$operation_count ${network_prefix}_$i $(generate_cidr_2 $i) >/dev/null &
  echo "subnet ${subnet_prefix}_$operation_count create operation invoked..."

  [[ $(($operation_count % $operation_batch_size)) -eq 0 ]] && sleep 20
done

while :; do
  subnet_created_count=$(neutron subnet-list | grep ${subnet_prefix} | wc -l)
  if [[ $subnet_created_count -eq $subnet_count ]]
  then
    echo "All the ${subnet_count} subnet had been created successfully"
    exit 0
  fi 

  echo "$subnet_created_count out of $subnet_count subnet had been created successfully"

  sleep 5
done

