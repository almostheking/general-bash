# Add if -z $name after getopts loop to give usage info if no options are given



#!/bin/bash

# This script gives several options for easily configuring SSH on a Debian system.
# From generating RSA keypairs to editing the sshd_config file, it performs basic functions for both ssh clients and servers.
# Largely written for educational purposes, but it's useful when needing to test various new VMs.

# This function simply removes the current /root/.ssh directory if it exists.
deldir () {
	verbose="$1"
	dircheck=/root/.ssh

	if [ "$verbose" -eq 1 ]; then
		echo 'Attempting to remove .ssh/ directory...'
	fi

	if [ -d "$dircheck" ]; then	# Check for existence of directory specified
		echo 'ERROR: Directory /root/.ssh already exists.'
	else
		if [ "$verbose" -eq 1 ]; then
			echo 'Directory removed.'
		fi
		rm -r /root/.ssh/
	fi
}

# This function starts ssh and gives the option to start ssh on startup.
beginssh () {
	verbose="$1"

	if [ "$verbose" -eq 1 ]; then
		echo "Starting ssh service..."
	fi

	service ssh start

	echo "Would you like to enable ssh on startup? y|n: "; read answ
	if [ "$answ" == 'y' ] || [ "$answ" == 'yes' ]; then
		if [ "$verbose" -eq 1 ];then
			echo "Enabling ssh on startup..."
		fi

		systemctl enable ssh	# System must use systemd for this option to work
	fi
}

# This function creates the /root/.ssh directory and the authorized_keys file as well as assign them the correct permissions
makedir () {
	verbose="$1"
	dircheck=/root/.ssh

	if [ "$verbose" -eq 1 ]; then
		echo 'Creating .ssh/ directory and authorized_keys file...'
	fi

	if [ -d "$dircheck" ]; then	# If directory already exists, option is given to cancel command or remove and recreate
		echo 'Directory ~/.ssh/ already exists. Would you like to remove and recreate? y|n: '; read inp

		if [ "$inp" == 'y' ]||[ "$inp" == 'yes' ]; then
			rm -r /root/.ssh/
			echo "Deleting and recreating /root/.ssh..."
		else
			echo "Canceling directory and file creation..."
			return	# Return immediately returns default value for function and ends the function
		fi
	fi

	mkdir /root/.ssh/
	chmod 700 /root/.ssh/
	touch /root/.ssh/authorized_keys
	chmod 600 /root/.ssh/authorized_keys

	if [ "$verbose" -eq 1 ]; then
		echo "Directory and key file created."
	fi
}

# This function generates an rsa keypair and asks if user would like to add generate public key to local keys file.
genkey () {
	verbose="$1"
	
	if [ "$verbose" -eq 1 ]; then
		echo 'Generating RSA keypair...'
	fi

	ssh-keygen -t rsa

	echo 'Would you like to add generated public key to local authorized_keys file? y|n: '; read yn
	
	if [ "$yn" == 'y' ] || [ "$yn" == 'yes' ]; then
		cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
	else
		if [ "$verbose" -eq 1 ]; then
			echo 'Not adding public key to local keys file.'
		fi
	fi
}

# This function is for ssh servers primarily; it makes a backup of and edits the sshd_config file to reflect proper, secure asymmetric authentication
editconf () {
	verbose="$1"

	echo "Placing backup of sshd_config in home directory..."
	cp /etc/ssh/sshd_config ~/sshd_config.bak

	if [ "$verbose" -eq 1 ]; then
		echo "Modifying PermitRootLogin..."
		echo "Modifying PubkeyAuthentication..."
		echo "Modifying PasswordAuthentication..."
		echo "Modifying ChallengeResponseAuthentication..."
		echo "Modifying UsePAM..."
	fi

	sed -i -r 's/^#?PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
	sed -i -r 's/^#?PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
	sed -i -r 's/^#?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
	sed -i -r 's/^#?ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
	sed -i -r 's/^#?UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
}

# This function attempts to share client public key with a designated ssh server using the ssh-copy-id command.
# Proper configuration is required server-side, and ssh-copy-id relies on the client being able to connect to the server already via public key or password.
sendpub () {
	if [ -f /root/.ssh/id_rsa.pub ]; then
		echo 'Sending pubkey to remote server...'
		echo 'Be sure server is configured to connect to this client via password authentication first.'
		echo "Server's IP address: "; read ipadd
		ssh-add
		ssh-copy-id -f "$ipadd"
	else
		echo 'ERROR: No file named /root/.ssh/id_rsa.pub'
	fi
}

# This function simply displays usage information
usage () {
	echo "Usage (run as root!):"
	echo "-v: verbose"
	echo "-m: mkdir /root/.ssh and touch authorized_keys file"
	echo "-b: start ssh service, optionally enable on startup"
	echo "-r: remove /root/.ssh directory"
	echo "-g: generate rsa keypair"
	echo "-e: edit /etc/ssh/sshd_config to reflect proper pubkey authentication configuration"
	echo "-s: send public key via ssh-copy-id command to specified ssh server"
	echo "-a: performs -mgebs, not verbose by default"
	echo "-h: displays this usage info"
}

unset name

verbose=0

# The following sentinel variables ensure no option is executed twice in the same command, even if they're called by the user.
mcount=0
rcount=0
bcount=0
gcount=0
ecount=0
scount=0
acount=0

# This getopts structure provides the means for option parsing.
while getopts ':vrbmgesah' opt; do
	case "$opt" in
		v)
			verbose=1
			;;
		r)
			if [ "$rcount" -eq 0 ]; then
				deldir "$verbose"
				rcount=1
			else
				continue
			fi
			;;
		b)
			if [ "$bcount" -eq 0 ]; then
				beginssh "$verbose"
				bcount=1
			else
				continue
			fi
			;;
		m)
			if [ "$mcount" -eq 0 ]; then
				makedir "$verbose"
				mcount=1
			else
				continue
			fi
			;;
		g)
			if [ "$gcount" -eq 0 ]; then
				genkey "$verbose"
				gcount=1
			else
				continue
			fi
			;;
		e)
			if [ "$ecount" -eq 0 ]; then
				editconf "$verbose"
				ecount=1
			else
				continue
			fi
			;;
		s)
			if [ "$scount" -eq 0 ]; then
				sendpub "$verbose"
				scount=1
			else
				continue
			fi
			;;
		a)
			if [ "$acount" -eq 0 ]; then
				makedir "$verbose"
				genkey "$verbose"
				editconf "$verbose"
				beginssh "$verbose"
				sendpub "$verbose"
				acount=1
			else
				continue
			fi
			;;
		h)
			usage
			;;
		\?)
			usage
			exit 1
			;;

	esac
done

# Finally, we check to see if no options were given at all - if none were given, usage instructions given.
if [ -z "$name" ]; then
	echo -e "\nUse options!\n"
	usage
fi
