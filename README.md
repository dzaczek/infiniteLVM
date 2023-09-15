# InfiniteLVM

## Overview

This script is designed to automatically manage Logical Volumes (LVs) and Volume Groups (VGs) in an LVM-managed Linux system.

## Features

- Automatically extend LVs if the available space falls below a certain percentage.
- Checks and validates VG free space before extending LVs.
- Supports `ext2`, `ext3`, and `ext4` filesystems for LVs.
- Supports verbose output for debugging.

## Requirements

- Linux system with LVM installed
- `awk`, `blkid`, `df`, `lvdisplay`, `lvextend`, `resize2fs`, `vgs` tools should be installed
- Root access

## Installation

1. Clone this repository:

   ```bash
   git clone <repository_url>

2. Navigate to the cloned directory:
   
  ``` bash

  cd <repository_folder>
```
3. Make the script executable:
```bash

chmod +x my_script.sh
```
## Usage

Basic usage:
``` bash

./my_script.sh
```
Run in verbose mode:
```bash

./my_script.sh -v
```
Run in dry-run mode (with verbose):
```bash
./my_script.sh -d -v
```
Show help:
```bash

./my_script.sh -h
```
## Options

- `-v`: Enable verbose output
- `-d`: Enable dry-run mode. Checks without executing commands.
- `-h`: Show help message

## Configuration

1. **Volume Group (VG) Name**: Modify the `VG_NAME` variable in the script to set the VG name.
2. **Minimum Free Space for LVs**: Set the `MIN_FREE_PERCENTAGE_LV` to define the minimum free space in percentage to start LV extension.
3. **Minimum Free Space for VG**: Set the `MIN_GB_LEFT_VG` to define the minimum free space in GB for the VG.



