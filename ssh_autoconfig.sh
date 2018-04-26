#!/bin/bash

deldir () {
	verbose="$1"
	dircheck=/root/.ssh

	if [ "$verbose" -eq 1 ]; then
		echo 'Attempting to remove .ssh/ directory...'
	fi

	if [ -d "$dircheck" ]; then
		echo 'ERROR: Directory /root/.ssh already exists.'
	else
		if [ "$verbose" -eq 1 ]; then
			echo 'Directory removed.'
		fi
		rm -r /root/.ssh/
	fi
}


makedir () {
	verbose="$1"
	dircheck=/root/.ssh

	if [ "$verbose" -eq 1 ]; then
		echo 'Creating .ssh/ directory and authorized_keys file...'
	fi

	if [ -d "$dircheck" ]; then
		echo 'Directory ~/.ssh/ already exists. Would you like to remove and recreate? y|n: '; read inp

		if [ "$inp" == 'y' ]||[ "$inp" == 'yes' ]; then
			rm -r /root/.ssh/
			echo "Deleting and recreating /root/.ssh"
		else
			echo "Exiting program..."
			return
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

 

verbose=0
mcount=0	#keeps track of -m opts so that user can't run it twice in same command
rcount=0
gcount=0
ecount=0
scount=0
acount=0
while getopts ':vrmgesa' opt; do
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
				makedir
				genkey
				editconf
				sendpub
				acount=1
			else
				continue
			fi
			;;
		\?)
			echo "Usage:"
			echo "-v: verbose"
			echo "-m: mkdir /root/.ssh and touch authorized_keys file"
			echo "-r: remove /root/.ssh directory"
			echo "-g: generate rsa keypair"
			echo "-e: edit /etc/ssh/sshd_config to reflect proper pubkey authentication configuration"
			echo "-s: send public key via ssh-copy-id command to specified ssh server"
			echo "-a: performs -mges, not verbose"
			exit 1
			;;

	esac
done
