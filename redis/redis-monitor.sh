#!/bin/bash
#set -x

#使用说明：默认情况下，仅需要修改5-7行的SERVER、PORT、PASSWORD的值，即可执行脚本进行对redis服务的可用性监控
readonly SERVER="10.0.0.1"
readonly PORT="6379"
readonly PASSWORD="11111111"



#key的定义要尽量复杂，避免和业务的key冲突了
readonly KEY="monitor_saas_ops"
readonly VALUE="saas_ops"

readonly TTL="5"
readonly COMMAND="redis-cli"
readonly TIMESEC="3"
result="-1"
redis_status="-1"

#判断是否安装了redis-cli工具，如果没有安装则先安装完毕
#安装redis-cli工具，需要先安装epel源才可以
function check_tools
{
    if [ ! -f /usr/bin/redis-cli ];then
        nohup yum install -y epel-release >/dev/null 2>&1
        nohup yum install -y redis >/dev/null 2>&1
    fi
}

# 往redis中添加一个key，并设置key的过期时间较短
# 设置过期时间的目的是，避免服务异常不能写入而无法发现
# 增加timeout命令，限制执行时间，避免超时卡死
# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function redis_set_key
{
    timeout $TIMESEC $COMMAND -h $SERVER -p $PORT -a $PASSWORD set $KEY $VALUE ex $TTL >/dev/null 2>&1
}

# 从redis中读取一个key
# 增加timeout命令，限制执行时间，避免超时卡死
# 取出一个key之后不能直接删除这个key，通过过期时间删除即可，防止del掉这个key的时候，各种异常导致误删除业务上的key
function redis_get_key
{
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -p $PORT -a $PASSWORD get $KEY )
}

#对获取的value和预先定义好的value进行对比，判断redis是否正常
function check_result
{
    if [ "$result" == "$VALUE" ];then
        echo "status : 0"
    else
        echo "status : 1"
    fi
}

function main
{
    check_tools
    redis_set_key
    redis_get_key
    check_result
}

main
