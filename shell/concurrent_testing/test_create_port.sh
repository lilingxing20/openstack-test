#!/bin/bash

##如下参数可以修改
port_count=50000
network_name=test_network 

for i in `seq  1 $port_count`; do
  neutron port-create ${network_name} >/dev/null &
done
echo "Port Creating Finished!"
