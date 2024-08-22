# Using Lima (Linux Machines) for MinIO labs

Lima is a lightweight Linux virtual machine that runs on top of
the [QEMU virtualization emulator](https://qemu.org/docs/master/system/qemu-virt.html)
or VZ [OpenVZ](https://www.linode.com/docs/guides/openvz-installation-guide/).
There are several templates that can be used to create Lima virtual machines, such as Ubuntu, Fedora, Docker, etc.

It is also possible to create drives to attach them to Lima VMs.
That will help us to demonstrate how to use drives with Linux machines and containers.

## Install Lima

### macOS

The easiest way to install Lima on macOS is to use Homebrew:

```shell
brew install lima
```

### Linux

Download the binary archive of Lima from <https://github.com/lima-vm/lima/releases>, and extract it under `/usr/local` (or somewhere else).

```shell
# First, install jq and curl using apt, dnf, apk, etc. depending on your Linux distribution
# Then run this:
VERSION=$(curl -fsSL https://api.github.com/repos/lima-vm/lima/releases/latest | jq -r .tag_name)
curl -fsSL "https://github.com/lima-vm/lima/releases/download/${VERSION}/lima-${VERSION:1}-$(uname -s)-$(uname -m).tar.gz" | sudo tar Cxzvm /usr/local
```

## Docker labs

For Docker labs we use a `docker-rootful` template (<https://github.com/lima-vm/lima/blob/master/examples/docker-rootful.yaml>)
with additional drives and packages.

1. Create four 1 GB drives to be attached to the lab VM:

    ```shell
    limactl disk create disk1 --size 1G
    limactl disk create disk2 --size 1G
    limactl disk create disk3 --size 1G
    limactl disk create disk4 --size 1G
    ```

1. Use the `docker-4drives.yaml` file to create the VM:

   ```shell
   limactl create --name miniolabs docker-4drives.yaml
   ```

1. Enter the VM:

    ```shell
    limactl shell miniolabs
    ```

1. Check if the drives are there and mounted:

    ```shell
    lsblk
    ```

    Expected ouput:

    ```
    NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    vda     253:0    0   10G  0 disk
    ├─vda1  253:1    0    9G  0 part /
    ├─vda15 253:15   0   99M  0 part /boot/efi
    └─vda16 259:0    0  923M  0 part /boot
    vdb     253:16   0    1G  0 disk
    └─vdb1  253:17   0 1022M  0 part /mnt/lima-disk1
    vdc     253:32   0    1G  0 disk
    └─vdc1  253:33   0 1022M  0 part /mnt/lima-disk2
    vdd     253:48   0    1G  0 disk
    └─vdd1  253:49   0 1022M  0 part /mnt/lima-disk3
    vde     253:64   0    1G  0 disk
    └─vde1  253:65   0 1022M  0 part /mnt/lima-disk4
    vdf     253:80   0 37.9M  1 disk /mnt/lima-cidata
    ```

    Check if they use the XFS file system:

    ```shell
    mount -t xfs
    ```

    Expected output:

    ```none
    /dev/vdb1 on /mnt/lima-disk1 type xfs (rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota)
    /dev/vdc1 on /mnt/lima-disk2 type xfs (rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota)
    /dev/vdd1 on /mnt/lima-disk3 type xfs (rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota)
    /dev/vde1 on /mnt/lima-disk4 type xfs (rw,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota)
    ```

Now you are ready to run the Docker lab. Make sure you use the correct paths for `MINIO_VOLUMES`.
