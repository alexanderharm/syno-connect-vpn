#!/bin/bash

# check if run as root
if [ $(id -u "$(whoami)") -ne 0 ]; then
	echo "SynoConnectVpn needs to run as root!"
	exit 1
fi

# check if git is available
if ! command -v /usr/bin/git > /dev/null && ! command -v /usr/local/git/bin/git > /dev/null  && ! command -v /opt/bin/git > /dev/null; then
	echo "Git not found. Please install the official package \"Git Server\", SynoCommunity's \"git\" or Entware-ng's."
	exit 1
fi
# set git
if command -v /usr/bin/git > /dev/null; then
	git="/usr/bin/git"
elif command -v /usr/bin/git > /dev/null; then
	git="/usr/local/git/bin/git"
else
	git="/opt/bin/git"
fi

# check for arguments
if [ -z $1 ]; then
	echo "No VPN connections passed to SynoConnectVpn!"
	exit 1
else

	echo "This was passed: $*."
	vpnConnections=( "$@" )
fi

# save today's date
today=$(date +'%Y-%m-%d')

# self update run once daily
if [ ! -f /tmp/.synoConnectVpnUpdate ] || [ "${today}" != "$(date -r /tmp/.synoConnectVpnUpdate +'%Y-%m-%d')" ]; then
	echo "Checking for updates..."
	# touch file to indicate update has run once
	touch /tmp/.synoConnectVpnUpdate
	# change dir and update via git
	cd "$(dirname "$0")" || exit 1
	$git fetch
	commits=$($git rev-list HEAD...origin/master --count)
	if [ $commits -gt 0 ]; then
		echo "Found a new version, updating..."
		$git pull --force
		echo "Executing new version..."
		exec "$(pwd -P)/synoConnectVpn.sh" "$@"
		# In case executing new fails
		echo "Executing new version failed."
		exit 1
	fi
	echo "No updates available."
else
	echo "Already checked for updates today."
fi

# stale check
stale=$false

# loop through passed VPN connections
for (( i=0; i<${#vpnConnections[@]}; i++ )); do

	# check if VPN connections are up and if so continue
	if synovpnc get_conn | grep -q "Config Name : ${vpnConnections[$i]}"; then
		continue
	fi

	echo "${vpnConnections[$i]} is down."
	stale=$true

	# determine ID
	# split config files per connection
	cat /usr/syno/etc/synovpnclient/**/*.conf | csplit --elide-empty-files --quiet - '/^\[[a-z][0-9][0-9]*\]$/' '{*}'
	# determine file that hosts config
	while IFS= read -r fname; do
		connectionId="$(grep -Eo '^\[[a-z][0-9]{10}\]$' ${fname} | grep -Eo '[a-z][0-9]{10}')"
		break
	done < <(grep -l "${vpnConnections[$i]}" xx*)
	# determine VPN protocol
	case "$(echo ${connectionId} | grep -Eo '^[a-z]')" in
		l)
			proto=l2tp
		;;
		o)
			proto=openvpn
		;;
		p)
			proto=pptp
		;;
	esac
	# connect
	echo "Connect ${vpnConnections[$i]} using ID ${connectionId} and proto ${proto}."
	echo conf_id="${connectionId}" > /usr/syno/etc/synovpnclient/vpnc_connecting
	echo conf_name=HIDE >> /usr/syno/etc/synovpnclient/vpnc_connecting
	echo proto="${proto}" >> /usr/syno/etc/synovpnclient/vpnc_connecting
	synovpnc connect --id="${connectionId}"

	# cleanup
	rm xx*
done

# re-run if stale connection detected to make sure it is up
if $stale; then
	sleep 30
	exec "$(pwd -P)/synoConnectVpn.sh" "$@"
fi

# exit
exit 0