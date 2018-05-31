# eg:
计算节点列表文件: ssd_compute.list

## step 1
bash ./create_list.sh ssd_compute.list
生成测试计划列表: 20180530162304

## step 2
测试创建虚机，注意定义创建虚机所需要的镜像，网络，主机zone，keypair
bash ./boot_vm.sh 20180530162304

## step 3
测试热迁移
bash ./test_vm_live_migration.sh 20180530162304
