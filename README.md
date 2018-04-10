# FastDFS Service All In One
## Services includes
- FastDFS Tracker with Port 22122 by default
- FastDFS Storage with Port 23000 by default
    - store_path set as `/var/fdfs/storage`  by default
- Nginx With FastDFS Module Support and with Port 23080 by default

## Prepare works
- make sure the path `/var/fdfs` (could be other) has sub-folders `storage` and `tracker`

## Command To Run
### Build
```bash
git clone http://b.dev.ycdmm.com:7990/scm/ycc/fastdfs.git .
cd fastdfs
docker build -t deravo/fastdfs .
```

### Start all-in-one Service With docker-compose
**simply run command `docker-compose up -d` to start the FastDFS docker service**
**before run this command, you should modify the `TRACKER_SERVER`'s value to your host machine's IPv4 address since it used the HOST NETWORK option**
```bash
docker-compose up -d
```

### Start Specifc Service Manually
**all-in-one mode**
```bash
docker run -dti --network=host --name fastdfs -v /var/fdfs:/var/fdfs -e TRACKER_SERVER=YourTrackerIp:TrackerPort deravo/fastdfs all
```

**FastDFS tracker service only, it's also start a nginx service**
```bash
docker run -dti --network=host --name tracker -v /var/fdfs:/var/fdfs deravo/fastdfs tracker
```

**FastDFS storage service with default setting, storage path point to /var/fdfs/storage**
```bash
docker run -dti --network=host --name storage -e TRACKER_SERVER=YourTrackerIp:22122 -v /var/fdfs:/var/fdfs deravo/fastdfs storage
```

**FastDFS storage service with specific group and storage path**
```bash
 docker run -dti --network=host --name storage0 -e TRACKER_SERVER=YourTrackerIp:22122 -p 23001:23001 -e GROUP_NAME=group2 -e PORT=23001 -e DATA_PATH=storage0 -v /var/fdfs:/var/fdfs deravo/fastdfs storage

docker run -dti --network=host --name storage1 -e TRACKER_SERVER=YourTrackerIp:22122 -p 23001:23001 -e GROUP_NAME=group2 -e PORT=23001 -e DATA_PATH=storage1 -v /var/fdfs:/var/fdfs deravo/fastdfs storage
```

### Mapped config files to a local(host machine) path
**use the `tracker service only` as a example**
```bash
docker run -dti --network=host --name tracker -v /var/fdfs:/var/fdfs -v /path/to/conf/fdfs:/etc/fdfs deravo/fastdfs tracker
```
