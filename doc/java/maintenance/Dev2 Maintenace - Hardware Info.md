# Dev2 Maintenance-Hardware Info

## CPU
- Cores
```shell
cat /proc/cpuinfo | grep -i processor | wc -l
```

- Base frequency
```shell
cat /proc/cpuinfo | grep -i "model name" | head -1
```

- Turbo Boost
  - 需要root用户权限
  - 方法1：通过运行turbostat命令，查看Bzy_MHz列
  - 方法2：通过运行`watch -n 1 cpupower monitor -m "Mperf"`，查看Freq列

以上两种方法可以看到CPU各个core实时运行的频率

## Disk
- SSD
```shell
lsblk -do name,rota
```
如果rota=0，磁盘为SSD，如果rota=1，磁盘为非SSD

- Size
```
df -h
```

- IO
```
iotop
```
iotop需要安装，并使用root权限执行

```shell
iostat -x -p -h 3
```
iostat可以是非root用户执行

## Memory
- Size
```
free -h
```

free=buff/cache+free
