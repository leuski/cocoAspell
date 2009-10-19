#/bin/sh -f

installer_log=$1
installer_root=$2

./list_installed.pl "$installer_log" | sort | uniq > files.txt
echo "/usr/local/etc/aspell.conf" >> files.txt

sudo ./make_root_dir.sh files.txt "$installer_root/Packages/aspell/root"

rm files.txt