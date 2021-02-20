#!/bin/bash
#-----------------------
#--Required Packages-
#-ufw
#-fail2ban
#-netstat/net-tools

#https://www.golinuxcloud.com/get-script-name-get-script-path-shell-script/
script_path=$(dirname $(readlink -f $0))

echo "Script path: $script_path"

# --- Check ufw & gufw
echo
read -p "Check ufw & gufw (sudo) (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    sudo ufw status verbose
    sudo ufw --force enable

    if [[ $(compgen -c) == *"apparmor"* ]]; then
        echo "AppArmor installed"
        aa-status
    else
        echo "AppArmor not detected"
    fi
fi

# --- Setup UFW rules
echo 
read -p "Setup UFW rules? (sudo) (y/n) " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    sudo ufw limit 22/tcp  
    sudo ufw allow 80/tcp  
    sudo ufw allow 443/tcp  
    sudo ufw default deny incoming  
    sudo ufw default allow outgoing
    sudo ufw enable
fi

# --- Harden /etc/sysctl.conf
# sudo sysctl mib - sysctl: cannot stat /proc/sys/mib: No such file or directory
echo
read -p "Harden /etc/sysctl.conf? (sudo) (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo sysctl kernel.modules_disabled=1
    sudo sysctl -a
    sudo sysctl -A
    sudo sysctl mib
    sudo sysctl net.ipv4.conf.all.rp_filter
    sudo sysctl -a --pattern 'net.ipv4.conf.(eth|wlan)0.arp'
fi

# --- PREVENT IP SPOOFS
echo
read -p "PREVENT IP SPOOFS? (sudo) (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo cat << EOF > /etc/host.conf
        order bind,hosts
        multi on
EOF
fi

# --- Enable fail2ban
echo
read -p "Enable fail2ban? (sudo) (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    sudo cp $script_path/fail2ban.local /etc/fail2ban/
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
fi

# --- Listening Ports -tnlp????
echo
read -p "Listening Ports? (sudo) (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    sudo netstat -tunlp
fi

# --- Check for Drovorub Malware 
echo
read -p "Check for Drovorub Malware? (If error removing file => Malware) (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    touch testfile
    echo “ASDFZXCV:hf:testfile” > /dev/zero
    rm testfile
fi

# --- Check for unsigned kernel modules
echo
read -p "Check for unsigned kernel modules? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
	touch UnsignedKernelModules.txt
	touch UnsignedKernelModulesSorted.txt
	echo > UnsignedKernelModules.txt
	for mod in $(lsmod | tail -n +2 | cut -d' ' -f1); do modinfo ${mod} | grep -q "signature" || echo; echo "no signature for module: ${mod}" || $(mod) > UnsignedKernelModules.txt ; done
	#|| $(mod) >> UnsignedKernelModules.txt 
	sort UnsignedKernelModules.txt > UnsignedKernelModulesSorted.txt
fi

# --- Make sure kernel headers up to date
#TODO Only update if new version
echo
read -p "Update ManjaroKernelHeaders? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    updateMKHadr=$(find ../ -type f -name "updateManjaroKernelHeaders.sh" 2>&1 | head -n 1)
    echo "Launching update Kernel Headers at $updateMKHadr"
    $updateMKHadr
    echo
fi

# --- Check gufw Installed
echo
if [[ $(compgen -c) == *"gufw"* ]]; then
	echo "Firewall Config GUI (gufw) installed"
	read -p "Would you like to open it now? (y/n) " -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		aa-status
		gufw
	fi
else
	echo "Firewall Config GUI not detected"
	echo "Please install gufw package"
fi

echo
exit
