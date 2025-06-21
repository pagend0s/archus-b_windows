#!/bin/bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cp -R $script_dir /home/
sudo bash /home/arch_install/arch_main.sh
