# Cloud configurations for Hetzner

This directory contains Terraform configurations and scripts to create MinIO lab environments
on Hetzner Cloud.

## Quick start

Use the `snmd.env` file as an example and set the variables in it.
Most importantly, set the `TF_VAR_hcloud_token` to the token you created in your project on Hetzner.

Then set `ENV_NAME` to one of the directories in this (`hetzner`) directory that contains the
Terraform files for the lab environment you want to create.
Currently the following environments are available:

* `single-node-multi-drive`


The `deployment_name` will be set to `miniolab-YYYY-MM-DD` to avoid naming conflicts on the cloud.
All cloud resources will be prefixed with this name.

After setting the necessary variables run this (replace `YOUR_ENV.env` with your actual file name):

```shell
source YOUR_ENV.env
terraform -chdir=$ENV_NAME plan
```

If everything is okay, apply the config:

```shell
terraform -chdir=$ENV_NAME apply
```

After you are done with the labs, destroy them:

```shell
terraform -chdir=$ENV_NAME destroy
```

## Hetzner cloud options

### Location

```none
ID   NAME   DESCRIPTION             NETWORK ZONE   COUNTRY   CITY
1    fsn1   Falkenstein DC Park 1   eu-central     DE        Falkenstein
2    nbg1   Nuremberg DC Park 1     eu-central     DE        Nuremberg
3    hel1   Helsinki DC Park 1      eu-central     FI        Helsinki
4    ash    Ashburn, VA             us-east        US        Ashburn, VA
5    hil    Hillsboro, OR           us-west        US        Hillsboro, OR
6    sin    Singapore               ap-southeast   SG        Singapore
```

### Server type

Note: not all server types are available in all locations.
The type we use by default, `cx22`, is available in `fsn1`, `nbg1`, `hel1`.
In the US locations (`hil`, `ash`) the `cpx21` type is recommended.

Only the shared CPU types are shown below.

```none
ID    NAME    CORES   CPU TYPE    ARCHITECTURE   MEMORY     DISK     STORAGE TYPE
22    cpx11   2       shared      x86            2.0 GB     40 GB    local
23    cpx21   3       shared      x86            4.0 GB     80 GB    local
24    cpx31   4       shared      x86            8.0 GB     160 GB   local
25    cpx41   8       shared      x86            16.0 GB    240 GB   local
26    cpx51   16      shared      x86            32.0 GB    360 GB   local
45    cax11   2       shared      arm            4.0 GB     40 GB    local
93    cax21   4       shared      arm            8.0 GB     80 GB    local
94    cax31   8       shared      arm            16.0 GB    160 GB   local
95    cax41   16      shared      arm            32.0 GB    320 GB   local
104   cx22    2       shared      x86            4.0 GB     40 GB    local
105   cx32    4       shared      x86            8.0 GB     80 GB    local
106   cx42    8       shared      x86            16.0 GB    160 GB   local
107   cx52    16      shared      x86            32.0 GB    320 GB   local
```



## Single-node Multi-drive

This configuration creates a `student_count` number of environments, each with a single server
and `hcloud_volume_count` drives.

By default, it uses the `cx22` type of servers (2 x Intel x64, 4 GB RAM, 40 GB SSD) and four 10 GB drives.
The default server location is `fsn1` (Falkenstein, Germany).

