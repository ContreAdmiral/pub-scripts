#!/usr/bin/env bash
# Add Zabbix Repo
case "$1" in
  install)

echo Installing and configuring zabbix on the system
echo
echo " +---------------------------------------------------+"
echo " |            Installing Zabbix Agent                |"
echo " |            FOR: BaseStation or Intake Servers     |"
echo " |            This Script must be run as root user   |"
echo " +---------------------------------------------------+"
echo
echo
# Basic OS Information
version=`lsb_release --release | cut -f2`
codename=`lsb_release --codename | cut -f2`
zabbixservername=host.server.com
#echo " +---------------------------------------------------+"
#sudo lsb_release -a
#echo " +---------------------------------------------------+"
#echo $version
#echo $codename

# ask the user questions about his/her preferences
echo -e "\e[31m"
echo " +---------------------------------------------------+"
echo " | Please update script with hostmetadata value     |"
echo " | This host metadata will be used in zabbix auto   |"
echo " | registration rule. Make sure it matches the rule.|"
#read -ep "What is the hostmetadata" -i "" hostmetadata
echo " +------------------Thank you!-----------------------+"
echo -e "\e[39m"
case "$codename" in
   "xenial")
        echo "Installing Xenial Zabbix Package"
        echo "Ubuntu 16.04 Xenial"
        wget https://repo.zabbix.com/zabbix/4.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.4-1+xenial_all.deb
        dpkg -i zabbix-release_4.4-1+xenial_all.deb
   ;;
   "bionic") 
        echo "Installing Bionic Zabbix Package"
        echo "Ubuntu 18.04 Bionic"
        wget https://repo.zabbix.com/zabbix/4.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.4-1+bionic_all.deb
        dpkg -i zabbix-release_4.4-1+bionic_all.deb 
   ;;
   "buster") 
        echo "Installing Buster Zabbix Package"
        echo "Raspbian 10 Buster"
        wget https://repo.zabbix.com/zabbix/4.4/raspbian/pool/main/z/zabbix-release/zabbix-release_4.4-1+buster_all.deb
        dpkg -i zabbix-release_4.4-1+buster_all.deb
   ;;
   "stretch") 
        echo "Installing Stretch Zabbix Package"
        echo "Raspbian 9 Stretch"
        sudo wget https://repo.zabbix.com/zabbix/4.2/raspbian/pool/main/z/zabbix-release/zabbix-release_4.2-2+stretch_all.deb
        sudo dpkg -i zabbix-release_4.2-2+stretch_all.deb
   ;;
    *)
     echo "Cannot find sutible package for you system"
     exit
esac

echo "Instaling Zabbix agent and configuring agent"

sudo apt update
sudo apt install zabbix-agent zabbix-get -y

#Update Zabbix Configuration File
systemctl stop zabbix-agent.service
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.backup

echo '
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
#DebugLevel=5
Timeout=3
Server=127.0.0.1,%zabbixservername%
ServerActive=%zabbixservername%
HostnameItem=system.hostname
HostMetadata=BaseStations
Include=/etc/zabbix/zabbix_agentd.d/*.conf
' >> /etc/zabbix/zabbix_agentd.conf
sudo egrep -v "^$|^#" /etc/zabbix/zabbix_agentd.conf


#Setting Zabbix custom parameters
cat > /etc/zabbix/zabbix_agentd.d/userparameter_inspiren_custom.conf  <<- "EOF"
UserParameter=ipaddress[*],ip addr show $1 | grep 'inet ' | cut -f1 -d'/' | tr --delete inet
UserParameter=inspirensoftwareversion,cat /home/deployer/inspiren/.git_tag
EOF


# Install Supervisor 

#Check if Perl installed
#Install deps
apt install git zabbix-sender libswitch-perl -y
systemctl stop zabbix-agent.service
cat > /etc/zabbix/supervisor_check.pl <<- "EOF"
#!/usr/bin/perl

use strict;
use Switch;
use Sys::Hostname;

# --------- base config -------------
my $ZabbixServer = "%zabbixservername%";
my $HostName = hostname;
# ----------------------------------

switch ($ARGV[0])
{
case "discovery" {
my $first = 1;

print "{\n";
print "\t\"data\":[\n\n";


my $result = `/usr/local/bin/supervisorctl status`;

my @lines = split /\n/, $result;
foreach my $l (@lines) {
        my @stat = split / +/, $l;
#        my $status = substr($stat[1], 0, -1);

                print ",\n" if not $first;
                $first = 0;

                print "\t{\n";
                print "\t\t\"{#NAME}\":\"$stat[0]\",\n";
                print "\t\t\"{#STATUS}\":\"$stat[1]\"\n";
                print "\t}";
}

print "\n\t]\n";
print "}\n";
}

case "status" {
my $result = `/usr/local/bin/supervisorctl pid`;

if ( $result =~ m/^\d+$/ ) {
        $result = `/usr/bin/zabbix_sender -z $ZabbixServer -s $HostName -k "supervisor.status" -o "OK"`;
        print $result;

        $result = `/usr/local/bin/supervisorctl status`;

        my @lines = split /\n/, $result;
        foreach my $l (@lines) {
                my @stat = split / +/, $l;

                $result = `/usr/bin/zabbix_sender -z $ZabbixServer -s $HostName -k "supervisor.check[$stat[0],Status]" -o $stat[1]`;
                print $result;
        }
}
else {
        # error supervisor not runing
        $result = `/usr/bin/zabbix_sender -z $ZabbixServer -s $HostName -k "supervisor.status" -o "FAIL"`;
        print $result;
}


}
}

EOF

cat > /etc/sudoers.d/zabbix   <<- "EOF"
#zabbix
Cmnd_Alias MON = /etc/zabbix/supervisor_check.pl
Defaults:zabbix !requiretty
Defaults:zabbix !syslog

zabbix ALL = NOPASSWD: MON
EOF

chown root:root /etc/sudoers.d/zabbix ; chmod 440 /etc/sudoers.d/zabbix
chmod 755 /etc/zabbix/supervisor_check.pl

cat >> /etc/zabbix/zabbix_agentd.d/userparameter_inspiren_custom.conf  <<- "EOF"
UserParameter=supervisor.discovery,sudo /etc/zabbix/supervisor_check.pl discovery
UserParameter=supervisor.statuscheck,sudo /etc/zabbix/supervisor_check.pl status && systemctl status supervisor.service | grep Active
EOF

#Linux service monitoring using systemctl
cat >> /etc/zabbix/zabbix_agentd.d/userparameter_inspiren_custom.conf  <<- "EOF"
UserParameter=services.systemctl,echo "{\"data\":[$(systemctl list-unit-files --type=service|grep \.service|grep -v "@"|sed -E -e "s/\.service\s+/\",\"{#STATUS}\":\"/;s/(\s+)?$/\"},/;s/^/{\"{#NAME}\":\"/;$ s/.$//")]}"
UserParameter=systemctl.status[*],systemctl status $1
EOF

# NTP Time Monitor
#https://share.zabbix.com/operating-systems/linux/ntp-time-monitor
apt install ntpdate -y
cat >> /etc/zabbix/zabbix_agentd.d/userparameter_inspiren_custom.conf  <<- "EOF"
UserParameter=time.offset[*],ntpdate -p 1 -q pool.ntp.org | grep -oP '(?<=offset ).*?(?= sec)'
EOF

### Docker Monitoring
cat >> /etc/zabbix/zabbix_agentd.d/userparameter_inspiren_custom.conf  <<- "EOF"
Timeout=10
UserParameter=docker.containers.discovery,/etc/zabbix/docker.py
UserParameter=docker.containers[*],/etc/zabbix/docker.py $1 $2
EOF

cat > /etc/zabbix/docker.py  <<- "EOF"
#!/usr/bin/python3
# originaly from 
import os
import json
import argparse
import sys
import time
import re
from datetime import datetime
import glob

_STAT_RE = re.compile("(\w+)\s(\w+)")
# check debug mode given in container startup
_DEBUG = os.getenv("DEBUG", False)

# discover containers
def discover():
  d = {}
  d["data"] = []
  with os.popen("docker ps -a --format \"{{.Names}} {{.ID}}\"") as pipe:
    for line in pipe:
      ps = {}
      ps["{#CONTAINERNAME}"] = line.strip().split()[0]
      ps["{#CONTAINERID}"] = line.strip().split()[1]
      d["data"].append(ps)
  print (json.dumps(d))

def count_running():
  with os.popen("docker ps -q | wc -l") as pipe:
    print (pipe.readline().strip())

# status: 0 = no container found, 1 = running, 2 = closed, 3 = abnormal
def status(args):
  with os.popen("docker inspect -f '{{.State.Status}}' " + args.container + " 2>&1") as pipe:
    status = pipe.read().strip()

  if "Error: No such object:" in status:
    print ("0")
  elif status == 'running':
    print ("10")
  elif status == 'created':
    print ("1")
  elif status == 'restarting':
    print ("2")
  elif status == 'removing':
    print ("3")
  elif status == 'paused':
    print ("4")
  elif status == 'exited':
    print ("5")
  elif status == 'dead':
    print ("6")
  else: print ("0")
  
# get the uptime in seconds, if the container is running
def uptime(args):
  with os.popen("docker inspect -f '{{json .State}}' " + args.container + " 2>&1") as pipe:
    status = pipe.read().strip()
  if "No such image or container" in status:
    print ("0")
  else:
    statusjs = json.loads(status)
    if statusjs["Running"]:
      uptime = statusjs["StartedAt"]
      start = time.strptime(uptime[:19], "%Y-%m-%dT%H:%M:%S")
      print (int(time.time() - time.mktime(start)))
    else:
      print ("0")

def disk(args):
  with os.popen("docker inspect -s -f {{.SizeRootFs}} " + args.container + " 2>&1") as pipe:
    stat = pipe.read().strip()
  pipe.close()
  # test that the docker command succeeded and pipe contained data
  if not 'stat' in locals():
    stat = ""
  print (stat.split()[0])

def cpu(args):
  #container_dir = glob.glob("/host/cgroup/cpuacct/docker/" + args.container)
  container_dir = "/sys/fs/cgroup/cpuacct"
  # cpu usage in nanoseconds
  cpuacct_usage_last = single_stat_check(args, "cpuacct.usage")
  cpuacct_usage_new = single_stat_update(args, container_dir, "cpuacct.usage")
  last_change = update_stat_time(args, "cpuacct.usage.utime")
  # time used in division should be in nanoseconds scale, but take into account
  # also that we want percentage of cpu which is x 100, so only multiply by 10 million
  time_diff = (time.time() - float(last_change)) * 10000000

  cpu = (int(cpuacct_usage_new) - int(cpuacct_usage_last)) / time_diff
  print ("{:.2f}".format(cpu))

def net_received(args):
  container_dir = "/sys/devices/virtual/net/eth0/statistics"
  eth_last = single_stat_check(args, "/rx_bytes")
  eth_new = single_stat_update(args, container_dir, "/rx_bytes")
  last_change = update_stat_time(args, "rx_bytes.utime")
  # we are dealing with seconds here, so no need to multiply
  time_diff = (time.time() - float(last_change))
  eth_bytes_per_second = (int(eth_new) - int(eth_last))/ time_diff
  print (int(eth_bytes_per_second))

def net_sent(args):
  container_dir = "/sys/devices/virtual/net/eth0/statistics"
  eth_last = single_stat_check(args, "/tx_bytes")
  eth_new = single_stat_update(args, container_dir, "/tx_bytes")
  last_change = update_stat_time(args, "tx_bytes.utime")
  # we are dealing with seconds here, so no need to multiply
  time_diff = (time.time() - float(last_change))
  eth_bytes_per_second = (int(eth_new) - int(eth_last))/ time_diff
  print (int(eth_bytes_per_second))

# helper, fetch and update the time when stat has been updated
# used in cpu calculation
def update_stat_time(args, filename):
  try:
    with open("/tmp/" + args.container + "/" + filename, "r+") as f:
      stat_time = f.readline()
      f.seek(0)
      curtime = str(time.time())
      f.write(curtime)
      f.truncate()

  except Exception:
    if not os.path.isfile("/tmp/" + args.container + "/" + filename):
      # bootstrap with one second (epoch), which makes sure we dont divide
      # by zero and causes the stat calcucation to start with close to zero value
      stat_time = 1
      f = open("/tmp/" + args.container + "/" + filename,"w")
      f.write(str(stat_time))
      f.close()
  return stat_time

# helper function to gather single stats
def single_stat_check(args, filename):

  try:
    with open("/tmp/" + args.container + "/" + filename, "r") as f:
      stat = f.read().strip()
  except Exception:
    if not os.path.isdir("/tmp/" + args.container):
      os.mkdir("/tmp/" + args.container)

    # first time running for this container, bootstrap with empty zero
    stat = "0"
    f = open("/tmp/" + args.container + "/" + filename,"w")
    f.write(str(stat) + '\n')
    f.close()

  return stat

# helper function to update single stats
def single_stat_update(args, container_dir, filename):

  pipe = os.popen("docker exec " + args.container + " cat " + container_dir + "/" + filename  + " 2>&1")
  for line in pipe:
    stat = line
  pipe.close()
  # test that the docker command succeeded and pipe contained data
  if not 'stat' in locals():
    stat = ""
  try:
    f = open("/tmp/" + args.container + "/" + filename,"w")
    f.write(stat)
    f.close()
  except Exception:
    if not os.path.isdir("/tmp/" + args.container):
      os.mkdir("/tmp/" + args.container)
    with open("/tmp/" + args.container + "/" + filename, "w") as f:
      f.write(stat)

  return stat

# helper function to gather stat type data (multiple rows of key value pairs)
def multi_stat_check(args, filename):
  dict = {}
  try:
    with open("/tmp/" + args.container + "/" + filename, "r") as f:
      for line in f:
        m = _STAT_RE.match(line)
        if m:
          dict[m.group(1)] = m.group(2)
  except Exception:
    if not os.path.isdir("/tmp/" + args.container):
      os.mkdir("/tmp/" + args.container)
    debug(args.container + ": could not get last stats from " + filename)
    debug(str(e))

    # first time running for this container create empty file
    open("/tmp/" + args.container + "/" + filename,"w").close()
  return dict

def multi_stat_update(args, container_dir, filename):
  dict = {}
  try:
    pipe = os.popen("docker exec " + args.container + " cat " + container_dir + "/" + filename  + " 2>&1")
    for line in pipe:
      m = _STAT_RE.match(line)
      if m:
        dict[m.group(1)] = m.group(2)
    pipe.close()
    f = open("/tmp/" + args.container + "/" + filename,"w")

    for key in dict.keys():
      f.write(key + " " + dict[key] + "\n")
    f.close()
  except Exception:
    debug(args.container + ": could not update " + filename)
    debug(str(sys.exc_info()))
  return dict


def memory(args):
  container_dir = "/sys/fs/cgroup/memory"
  memory_stat_last = {}
  memory_stat_new = {}
  memory_usage_last = single_stat_update(args, container_dir, "memory.usage_in_bytes")
  print (memory_usage_last.strip())

def debug(output):
  if _DEBUG:
    if not "debuglog" in globals():
      global debuglog
      debuglog = open("debuglog","a")
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S : ", time.gmtime())
    debuglog.write(timestamp + str(output)+"\n")

if __name__ == "__main__":


  if len(sys.argv) > 2:

    parser = argparse.ArgumentParser(prog="discover.py", description="discover and get stats from docker containers")
    parser.add_argument("container", help="container id")
    parser.add_argument("stat", help="container stat", choices=["status", "uptime", "cpu","mem", "disk", "netin", "netout"])
    args = parser.parse_args()
    # validate the parameter for container
    m = re.match("(^[a-zA-Z0-9-_]+$)", args.container)
    if not m:
      print ("Invalid parameter for container id detected")
      debug("Invalid parameter for container id detected" + str(args.container))
      sys.exit(2)

    # call the correct function to get the stats
    if args.stat == "status":
      debug("calling status for " + args.container)
      status(args)
    elif args.stat == "uptime":
      debug("calling uptime for " + args.container)
      uptime(args)
    elif args.stat == "cpu":
      debug("calling cpu for " + args.container)
      cpu(args)
    elif args.stat == "mem":
      debug("calling memory for " + args.container)
      memory(args)
    elif args.stat == "disk":
      debug("calling disk for " + args.container)
      disk(args)
    elif args.stat == "netin":
      debug("calling net_received for " + args.container)
      net_received(args)
    elif args.stat == "netout":
      debug("calling net_sent for " + args.container)
      net_sent(args)
  elif len(sys.argv) == 2:
    if sys.argv[1] == "count":
      debug("calling count")
      count_running()
  else:
    debug("discovery called.")
    discover()

  if "debuglog" in globals():
    debuglog.close()
EOF

chmod 755 /etc/zabbix/docker.py
sudo usermod -a -G docker zabbix

systemctl enable zabbix-agent.service
systemctl start zabbix-agent.service
systemctl restart zabbix-agent.service

exit
##remove
    ;;
  remove)

echo removing zabbix files and repositories from the system
sudo apt autoremove git zabbix-agent zabbix-get zabbix-sender ntpdate libswitch-perl -y
sudo rm -rf /etc/zabbix/
sudo rm -rf /etc/sudoers.d/zabbix
sudo apt purge zabbix-agent zabbix-get zabbix-sender -y
dpkg --remove zabbix-release
dpkg --purge zabbix-release
exit

# troubleshooting
    ;;
  troubleshooting)
echo "zabbix_get -s 127.0.0.1 -k ipaddress[ens5]"
echo "zabbix_get -s 127.0.0.1 -k net.if.discovery"
echo "zabbix_get -s 127.0.0.1 -k supervisor.discovery"
echo "zabbix_get -s 127.0.0.1 -k net.udp.service[ntp]"
echo "zabbix_get -s 127.0.0.1 -k time.offset"
echo "zabbix_get -s 127.0.0.1 -k docker.containers.discovery"
echo "zabbix_get -s 127.0.0.1 -k docker.containers[frosty_albattani, status]"
echo "zabbix_get -s 127.0.0.1 -k docker.containers[ble, cpu]"
echo "/usr/bin/zabbix_sender -z %zabbixservername% -s baseb827eb5de6a4 -k "leptonresetstatus" -o "1""
echo "sudo /etc/zabbix/supervisor_check.pl discovery"
echo "/etc/zabbix/supervisor_check.pl status"
echo "/usr/bin/zabbix_sender -z %zabbixservername% -s "CallBell02ca11000028" -k "callbellreview" -o "1"
exit

;;
    *)
echo please select a proper action
echo "./zabbix-installation.sh install"
echo "./zabbix-installation.sh remove"
echo "./zabbix-installation.sh troubleshooting"
esac
