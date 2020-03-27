FROM centos:7.5.1804

ADD bin/tiflash/tiflash /tiflash
ADD bin/tiflash/flash_cluster_manager /flash_cluster_manager
ADD bin/tiflash/libtiflash_proxy.so /libtiflash_proxy.so

RUN yum -y install bind-utils
