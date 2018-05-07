#!/bin/bash

# This script uses a select structure to let the user customize the terminal prompt. It allows the user to assign prompt items in any order and choose the color.

# This function allows you to select the color of your prompt item. It's all bold. Get over it.
colorize () {

	# The PS3 variable is displayed after the select construct prints out all of the available options.
	PS3='Select a Color: #'

	# Each color in the menu is associated with its PS1 code, then the desired code is appended to a running file that keeps track of your options in order.
	# This is the submenu of the add_prompt menu.
	select color in "Blue" "Cyan" "Green" "Purple" "Red" "White" "Yellow" "Default"; do
		case $color in
			Blue) echo "\[\033[01;34m\]" >> rollingps1; break;;
			Cyan) echo "\[\033[01;36m\]" >> rollingps1; break;;
			Green) echo "\[\033[01;32m\]" >> rollingps1; break;;
			Purple) echo "\[\033[01;35m\]" >> rollingps1; break;;
			Red) echo "\[\033[01;31m\]" >> rollingps1; break;;
			White) echo "\[\033[01;37m\]" >> rollingps1; break;;
			Yellow) echo "\[\033[01;33m\]" >> rolling ps1; break;;
			Default ) echo "\[\033[00m\]" >> rollingps1; break;;
		esac
	done
}

# Just like the colorize function, only this function adds the actual prompt item.
add_prompt () {
	PS3='Select a Prompt Display: #'
	select option in "Date" "Time" "Jobs" "Colon" "Space" "L.Brack" "R.Brack" "User" "@" "Host" "Directory" "Exit"; do 
		case $option in
			Date) colorize; echo "\d" >> rollingps1; break;;
			Time) colorize; echo "\t" >> rollingps1; break;;
			Jobs) colorize; echo "\j" >> rollingps1; break;;
			Colon) colorize; echo ':' >> rollingps1; break;;
			Space) echo " " >> rollingps1; break;;
			L.Brack) colorize; echo '[' >> rollingps1; break;;
			R.Brack) colorize; echo ']' >> rollingps1; break;;
			User) colorize; echo "\u" >> rollingps1; break;;
			@) colorize; echo "@" >> rollingps1; break;;
			Host) colorize; echo "\h" >> rollingps1; break;;
			Directory) colorize; echo "\w" >> rollingps1; break;;
			Exit) tr -d "\n" < rollingps1 >> rollingps1; break;;
		esac
	done
}

# This function makes the new configuration permanent for the user running the script.
edit_bashrc () {

	# Set the current user to a variable
	me=`whoami`

	# Creates a temp file and formats it to be read in the .bashrc file
	echo -n -e "\nPS1='" > /tmp/ps1

	# Adds your new configuration to the temp file and closes the single-quotes
	echo -n $PS1 >> /tmp/ps1; echo "'" >> /tmp/ps1

	# Creates a backup of your current .bashrc and saves it on the user home directory
	cp /$me/.bashrc /$me/.bashrc.bak

	# Adds your new configuration to the .bashrc
	cat /tmp/ps1 >> /$me/.bashrc
}

main () {

	# This variable acts as a sentinel.
	backout=0
	
	# Loop allows user to continue selecting prompt items until they back out.
	while [ $backout -eq 0 ] || [ $backout -eq 1 ]; do

		# This if structure simply allows for different prompts depending on whether this is your first loop or a subsequent loop.
		if [ $backout -eq 0 ]; then
			echo "Follow instructions to customize your prompt."
			echo "Would you like to add a prompt display item?"
			backout=1
		else
			echo "Would you like to add another prompt item?"
		fi
		
		# The select construct that allows you to choose when you want to stop adding items
		PS3="Select the corresponding number: "
		select opt in "yes" "no"; do
			case $opt in
				yes) add_prompt; break;;
				# The next line adds the final piece of the prompt, trims out the newlines, assigns the PS1 variable, removes the junk, then trips the sentinel
				no) echo '\[\033[00m\]\\$ ' >> rollingps1; tr -d "\n" < rollingps1 > /tmp/finishedps1;
					PS1=`cat /tmp/finishedps1`; rm /tmp/finishedps1; rm rollingps1; backout=$((backout+1)); break;;
			esac
		done
	done

	echo "Would you like to make this configuration permanent by appending it to your .bashrc file? y|n: "; read inp
	
	# This last if construct gives the option to make changes permanent across shells for the current user.
	if [ $inp == "y" ] || [ $inp == "yes" ]; then
		edit_bashrc
		echo "Backup bashrc.bak sent to home directory."
	else
		echo 'Once you close this terminal, you will lose this configuration. If you change your mind, append your $PS1 variable to your /home/.bashrc'
	fi
}

main
