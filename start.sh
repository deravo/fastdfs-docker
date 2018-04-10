#!/bin/bash
#set -e
if [ "$1" = "monitor" ] ; then
    if [ -n "$TRACKER_SERVER" ] ; then
        sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/client.conf
    fi
    fdfs_monitor /etc/fdfs/client.conf
    exit 0
elif [ "$1" = "storage" ] ; then
    FASTDFS_MODE="storage"
    if [ -n "$DATA_PATH" ] ; then
        sed -i "s|^base_path=.*$|base_path=/var/fdfs/${DATA_PATH}|g" /etc/fdfs/storage.conf
    fi
    if [ -n "$GROUP_NAME" ] ; then
        sed -i "s|group_name=.*$|group_name=${GROUP_NAME}|g" /etc/fdfs/storage.conf
        sed -i "s|group_name=.*$|group_name=${GROUP_NAME}|g" /etc/fdfs/mod_fastdfs.conf
    fi
elif [ "$1" = "tracker" ] ; then
    FASTDFS_MODE="tracker"
else 
    FASTDFS_MODE="all"
fi

if [ -n "$TRACKER_SERVER" ] ; then
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/storage.conf
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/client.conf
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/mod_fastdfs.conf
else
    host_ip="`hostname -I | awk -F '[ ]' '{print $1}'`";
    TRACKER_SERVER="${host_ip}:22122"
    if [ -n "$TRACKER_PORT" ] ; then
        TRACKER_SERVER="${host_ip}:${TRACKER_PORT}"
    fi
    export TRACKER_SERVER

    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/storage.conf
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/client.conf
    sed -i "s|tracker_server=.*$|tracker_server=${TRACKER_SERVER}|g" /etc/fdfs/mod_fastdfs.conf
fi

if [ "$FASTDFS_MODE" != "all" ]; then
    if [ -n "$PORT" ] ; then
        sed -i "s|^port=.*$|port=${PORT}|g" /etc/fdfs/"$FASTDFS_MODE".conf
        sed -i "s|^storage_server_port=.*$|storage_server_port=${PORT}|g" /etc/fdfs/mod_fastdfs.conf
    fi
    # specific the pid and log file path
    if [ -n "$DATA_PATH" ] ; then
    # by DATA_PATH given
        FASTDFS_LOG_FILE="${FASTDFS_BASE_PATH}/${DATA_PATH}/logs/${FASTDFS_MODE}d.log"
        PID_NUMBER="${FASTDFS_BASE_PATH}/${DATA_PATH}/data/fdfs_${FASTDFS_MODE}d.pid"
    else
    #by default
        FASTDFS_LOG_FILE="${FASTDFS_BASE_PATH}/${FASTDFS_MODE}/logs/${FASTDFS_MODE}d.log"
        PID_NUMBER="${FASTDFS_BASE_PATH}/${FASTDFS_MODE}/data/fdfs_${FASTDFS_MODE}d.pid"
    fi

    echo "try to start the $FASTDFS_MODE node..."
    if [ -f "$FASTDFS_LOG_FILE" ] ; then 
        rm "$FASTDFS_LOG_FILE"
    fi
    echo
    echo
    echo "try to start the nginx server..."
    # start the nginx server with fdfs_trackerd;
    if [ "$1" = "tracker" ] ; then
        /usr/sbin/nginx
    fi
    # start the fastdfs node.	
    fdfs_${FASTDFS_MODE}d /etc/fdfs/${FASTDFS_MODE}.conf start

    # wait for pid file(important!),the max start time is 5 seconds,if the pid number does not appear in 5 seconds,start failed.
    TIMES=5
    while [ ! -f "$PID_NUMBER" -a $TIMES -gt 0 ]
    do
        sleep 1s
        TIMES=`expr $TIMES - 1`
    done

    # if the storage node start successfully, print the started time.
    # if [ $TIMES -gt 0 ]; then
    #         echo "the ${FASTDFS_MODE} node started successfully at $(date +%Y-%m-%d_%H:%M)"
        
    # 	# give the detail log address
    #         echo "please have a look at the log detail at $FASTDFS_LOG_FILE"

    #         # leave balnk lines to differ from next log.
    #         echo
    #         echo
        
    # 	# make the container have foreground process(primary commond!)
    #         tail -F --pid=`cat $PID_NUMBER` /dev/null
    # # else print the error.
    # else
    #         echo "the ${FASTDFS_MODE} node started failed at $(date +%Y-%m-%d_%H:%M)"
    # 	echo "please have a look at the log detail at $FASTDFS_LOG_FILE"
    # 	echo
    #         echo
    # fi
    tail -f "$FASTDFS_LOG_FILE"
else
    if [ -n "$STORAGE_PORT" ] ; then
        sed -i "s|^port=.*$|port=${STORAGE_PORT}|g" /etc/fdfs/storage.conf
        sed -i "s|^storage_server_port=.*$|storage_server_port=${STORAGE_PORT}|g" /etc/fdfs/mod_fastdfs.conf
    fi
    if [ -n "$TRACKER_PORT" ] ; then
        sed -i "s|^port=.*$|port=${TRACKER_PORT}|g" /etc/fdfs/tracker.conf
    fi
    if [ -f "/var/fdfs/tracker/logs/trackerd.log" ] ; then
        rm /var/fdfs/tracker/logs/trackerd.log
    fi
    if [ -f "/var/fdfs/storage/logs/storaged.log" ] ; then
        rm /var/fdfs/storage/logs/storaged.log
    fi

    fdfs_trackerd /etc/fdfs/tracker.conf start
    fdfs_storaged /etc/fdfs/storage.conf start

    /usr/sbin/nginx

    tail -f /var/fdfs/tracker/logs/trackerd.log
fi


