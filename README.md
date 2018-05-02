# SynoConnectVpn

This scripts automatically connects VPN if not connection is down.

#### 1. Notes

- The script will automatically update itself using `git`.

#### 2. Installation:

1. Install `git`

  a) Install Synology's package `Git Server` and make sure it is running (requires `SSH`)
  
  b) Add SynoCommunity's packages to `Package Center` and install the `Git` package ([https://synocommunity.com/](https://synocommunity.com/#easy-install))
  
  c) Setup `Entware-ng` and do `opkg install git` ([https://github.com/Entware-ng/Entware-ng/](https://github.com/Entware-ng/Entware-ng/wiki/Install-on-Synology-NAS))
  
2. Create a shared folder called e. g. `sysadmin` (you want to restrict access to administrators and hide it in the network)

3. Connect via `ssh` to the NAS and execute the following commands

```bash
# navigate to the shared folder
cd /volume1/sysadmin

# clone the repo
# Synology's Git Server
git clone https://github.com/alexanderharm/syno-connect-vpn
# Synocommunity's Git
/usr/local/git/bin/git clone https://github.com/alexanderharm/syno-connect-vpn
# Entware-ng's Git
/opt/bin/git clone https://github.com/alexanderharm/syno-connect-vpn
```

#### 3. Usage:

- create a new task in the `Task Scheduler`

```
# Type
Scheduled task > User-defined script

# General
Task:    SynoConnectVpn
User:    root
Enabled: yes

# Schedule
Run on the following days: Daily
First run time:            00:00
Frequency:                 Every 1 minute(s)
Last run time:				23:59

# Task Settings
Send run details by email:      yes
Email:                          (enter the appropriate address)
Send run details only when
  script terminates abnormally: yes
  
User-defined script: /volume1/sysadmin/syno-connect-vpn/synoConnectVpn.sh "<VPN Connection 1>" "<VPN Connection 2>"
```
