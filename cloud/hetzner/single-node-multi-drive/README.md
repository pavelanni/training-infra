# Single-node multi-drive

This environment can be used to install a single-node multi-drive MinIO configuration
described in the [documentation](https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-multi-drive.html)

This environment includes Docker as well so it can be used both the Linux and Docker installation labs.

## Scripts

A useful one-liner to run a command on all the nodes as the `minio` user.
A poor man's Ansible, so to speak.

```shell
for n in $(seq 1 50) ; do hostnum=$(printf "%02d" ${n}); ssh -i ./output/miniolab-${hostnum}-private-key -l minio  miniolab-${hostnum}.miniolabs.net bash -c 'hostname; last'; done
```

Remove all host keys from the local known hosts file.

```shell
for n in $(seq 1 50) ; do hostnum=$(printf "%02d" ${n}); ssh-keygen -R miniolab-${hostnum}.miniolabs.net ; done
```

Scan all host keys from the nodes and add them to the local known hosts file.

```shell
for n in $(seq 1 50) ; do hostnum=$(printf "%02d" ${n}); ssh-keyscan -H miniolab-${hostnum}.miniolabs.net >> ~/.ssh/known_hosts ; done
```


