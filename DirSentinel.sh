#!/bin/bash

# File to store hashed passwords
PASSWORD_FILE="/etc/DirSentinel/hashed_passwords.txt"

# Ensure the directory exists and has proper permissions
setup_directory() {
	if [ ! -d "/etc/DirSentinel" ]; then
    	sudo mkdir -p /etc/DirSentinel
    	sudo chown root:root /etc/DirSentinel
    	sudo chmod 700 /etc/DirSentinel
	fi
}

# Ensure the password file has restricted permissions
setup_password_file() {
	setup_directory
	if [ ! -f "$PASSWORD_FILE" ]; then
    	sudo touch "$PASSWORD_FILE"
    	sudo chown root:root "$PASSWORD_FILE"
    	sudo chmod 600 "$PASSWORD_FILE"
	fi
}

# Function to hash a password with a salt
hash_password() {
	local password="$1"
	local salt="$2"
	echo -n "$salt$password" | sha256sum | awk '{print $1}'
}

# Register a user
register_user() {
	for attempt in {1..3}; do
    	username=$(zenity --entry --title="Register" --text="Enter username:" --width=400)

	# Check if the user clicked "Cancel"
    	if [ $? -ne 0 ]; then
    	# Return to main menu
        	return
    	fi

    	if [[ -z "$username" || ! "$username" =~ ^[a-zA-Z0-9_]+$ ]]; then
        	zenity --error --text="Invalid username. Only alphanumeric characters and underscores are allowed. Attempt $attempt/3." --width=400
        	continue
    	fi
    
	# Check if the username already exists
    	if sudo grep -q "^$username:" "$PASSWORD_FILE"; then
        	zenity --error --text="Error: Username already exists. Attempt $attempt/3." --width=400
        	continue
    	fi

    	password=$(zenity --password --title="Register" --text="Enter password:")
    	if [ $? -ne 0 ]; then
        	# Return to main menu if "Cancel" is clicked
        	return;
    	fi

    	confirm_password=$(zenity --password --title="Register" --text="Confirm password:")
    	if [ $? -ne 0 ]; then
        	# Return to main menu if "Cancel" is clicked
        	return;
    	fi

    	if [ "$password" != "$confirm_password" ]; then
        	zenity --error --text="Error: Passwords do not match. Attempt $attempt/3." --width=400
        	continue
    	fi
    
	# Generate a random salt
    	salt=$(openssl rand -hex 16)
    	hashed_password=$(hash_password "$password" "$salt")

    	echo "$username:$salt:$hashed_password" | sudo tee -a "$PASSWORD_FILE" > /dev/null
    	zenity --info --text="User registered successfully." --width=400
    	return
	done
}

# Set up the password file before starting
setup_password_file

# Authenticate a user
authenticate_user() {
	for attempt in {1..3}; do
    	username=$(zenity --entry --title="Login" --text="Enter username:" --width=400)
   	 
    	# Check if the user clicked "Cancel"
    	if [ $? -ne 0 ]; then
        	# Exit to main menu
        	return 1
    	fi

    	user_data=$(sudo grep "^$username:" "$PASSWORD_FILE")

    	if [ -z "$user_data" ]; then
        	zenity --error --text="Error: User not found. Attempt $attempt/3." --width=400
        	continue
    	fi

    	salt=$(echo "$user_data" | cut -d':' -f2)
    	stored_hash=$(echo "$user_data" | cut -d':' -f3)
   	 
    	password=$(zenity --password --title="Login" --text="Enter password:")
   	 
    	# Check if the user clicked "Cancel"
    	if [ $? -ne 0 ]; then
        	# Exit to main menu
        	return 1
    	fi

    	input_hash=$(hash_password "$password" "$salt")

    	if [ "$input_hash" == "$stored_hash" ]; then
        	zenity --info --text="Authentication successful." --width=400
        	return 0
    	else
        	zenity --error --text="Authentication failed. Attempt $attempt/3." --width=400
    	fi
	done
	return 1
}


# Function to check and install dependencies
check_and_install() {
	PACKAGE=$1
	COMMAND=$2

	if ! command -v $COMMAND &> /dev/null; then
    	zenity --info --text="$PACKAGE is not installed. Installing it now..." --width=400
    	if command -v apt-get &> /dev/null; then
        	sudo apt-get update
        	sudo apt-get install -y $PACKAGE
    	elif command -v yum &> /dev/null; then
        	sudo yum install -y $PACKAGE
    	elif command -v dnf &> /dev/null; then
        	sudo dnf install -y $PACKAGE
    	elif command -v pacman &> /dev/null; then
        	sudo pacman -Syu $PACKAGE --noconfirm
    	else
        	zenity --error --text="Unsupported package manager. Please install $PACKAGE manually." --width=400
        	exit 1
    	fi
	fi
}

# Check for and install required tools
check_and_install "auditd" "auditctl"
check_and_install "inotify-tools" "inotifywait"
check_and_install "zenity" "zenity"

# Main menu for authentication
while true; do
	AUTH_OPTION=$(zenity --list --title="Authentication" --text="Choose an option:" --radiolist --column="Select" --column="Option" TRUE "Register a User" FALSE "Log In" --width=400 --height=450)
    
	if [ $? -ne 0 ]; then
	zenity --info --text="Exiting script. User canceled the operation." --width=500
	exit 0
fi

case "$AUTH_OPTION" in
	"Register a User")
    	register_user
    	;;
	"Log In")
    	if authenticate_user; then
        	break
    	fi
    	;;
esac

done

# Function to display the main menu once logged in
user_menu() {
    while true; do
        CHOICE=$(zenity --list --title="Main Menu" --text="Choose an option:" \
            --radiolist --column="Select" --column="Option" \
            TRUE "Start Logging" FALSE "Settings" FALSE "Sign Out" --width=400 --height=500)

        if [ $? -ne 0 ]; then
            # Handle cancel or close, exit the script
            exit 0
        fi

        case "$CHOICE" in
        "Start Logging")
            zenity --info --text="Logging started!" --width=300
            return 0
            ;;
        "Settings")
            settings_menu
            ;;
        "Sign Out")
            zenity --info --text="Signing out..." --width=300
            exit 0
            ;;
        esac
    done
}

# Function to display the settings menu
settings_menu() {
    while true; do
        SETTINGS_CHOICE=$(zenity --list --title="Settings Menu" --text="Choose an option:" \
            --radiolist --column="Select" --column="Option" \
            TRUE "Change Log Format" FALSE "Default Log Folder" FALSE "Back to Main Menu" --width=400 --height=500)

        if [ $? -ne 0 ]; then
            # Handle cancel or close, return to main menu
            return
        fi

        case "$SETTINGS_CHOICE" in
        "Change Log Format")
            change_log_format
            ;;
        "Default Log Folder")
            change_default_log_folder
            ;;
        "Back to Main Menu")
            return
            ;;
        esac
    done
}

# Function to change the log format
change_log_format() {
    while true; do
        LOG_FORMAT=$(zenity --list --title="Log Format" --text="Choose a log format:" \
            --radiolist --column="Select" --column="Format" \
            TRUE "txt" FALSE "csv" FALSE "html" --width=300 --height=500)

        if [ $? -ne 0 ]; then
            # Handle cancel or close, return to settings menu
            return
        fi

        # Update log format and display confirmation
        CURRENT_LOG_FORMAT=$LOG_FORMAT
        zenity --info --text="Log format changed to $CURRENT_LOG_FORMAT." --width=300
        return
    done
}

# Function to change the default log folder
change_default_log_folder() {
    CONFIG_FILE="$HOME/log_config.conf"  # Path to the .conf file

    while true; do
        LOG_FOLDER=$(zenity --file-selection --directory --title="Select Default Log Folder" --width=400)

        if [ $? -ne 0 ]; then
            # Handle cancel or close, return to settings menu
            return
        fi

        # Save the selected folder to the configuration file
        echo "LOG_FOLDER=$LOG_FOLDER" > "$CONFIG_FILE"

        # Update the current log folder in memory
        CURRENT_LOG_FOLDER=$LOG_FOLDER

        # Confirm the change to the user
        zenity --info --text="Default log folder changed to $CURRENT_LOG_FOLDER.\nSaved in $CONFIG_FILE." --width=300
        return
    done
}


# Initialize variables
CURRENT_LOG_FORMAT="txt"
CURRENT_LOG_FOLDER="$HOME"

# Start the main menu
user_menu

# Increase the number of inotify watches
zenity --info --text="Increasing the number of inotify watches..." --width=400
sudo sysctl fs.inotify.max_user_watches=524288
sudo sysctl -p

# Prompt the user to enter the directory to monitor
MONITOR_DIR=$(zenity --file-selection --directory --title="Select a Directory to Monitor" --width=500)
if [ -z "$MONITOR_DIR" ]; then
	zenity --error --text="No directory selected. Exiting." --width=400
	exit 1
fi

# Configuration file path
CONFIG_FILE="$HOME/log_config.conf"

# Read log folder from the configuration file
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"  # Load the configuration file
    if [ -z "$LOG_FOLDER" ]; then
        zenity --error --text="Log folder is not set in the configuration file. Using default folder." --width=300
        LOG_FOLDER="$HOME"
    elif [ ! -d "$LOG_FOLDER" ]; then
        zenity --error --text="Configured log folder ($LOG_FOLDER) does not exist. Using default folder." --width=300
        LOG_FOLDER="$HOME"
    fi
else
    # Fall back to the default log folder if config file is missing
    zenity --error --text="Configuration file not found. Using default folder." --width=300
    LOG_FOLDER="$HOME"
fi

# Set the log file location based on the log folder
LOG_FILE="$LOG_FOLDER/file_monitor_log.txt"

# Confirm the logging location
zenity --info --text="Logs will be saved to: $LOG_FILE" --width=300


# Ensure the log file exists and has the proper permissions
if [ ! -f "$LOG_FILE" ]; then
	sudo touch "$LOG_FILE"  # Create the file if it doesn't exist
	sudo chmod 600 "$LOG_FILE"  # Set restrictive permissions on the log file
fi

# Ensure the log file is owned by the current user (not root)
sudo chown $(whoami):$(whoami) "$LOG_FILE"

# Add the auditd rule to monitor the specified directory
zenity --info --text="Adding audit rule for monitoring $MONITOR_DIR..." --width=500
sudo auditctl -w "$MONITOR_DIR" -p wa -k file_monitor



# Graceful shutdown
cleanup() {
	zenity --info --text="Cleaning up and stopping monitoring..." --width=400
	sudo auditctl -W "$MONITOR_DIR" 2>/dev/null
	zenity --info --text="Monitoring stopped. Exiting." --width=400
	exit
}
trap cleanup SIGINT SIGTERM

# Start monitoring the directory
zenity --info --text="Monitoring directory '$MONITOR_DIR'...\nLogs will be saved to $LOG_FILE." --width=400

# Use inotifywait to monitor CREATE and DELETE events for files and directories
inotifywait -m -r --format '%w %e %f' "$MONITOR_DIR" -e create -e delete |
while read path action file; do
	FULL_PATH="$path$file"

	# Check if it's a directory or a file
	if [ -d "$FULL_PATH" ]; then
    	ITEM_TYPE="directory"
	elif [ -f "$FULL_PATH" ]; then
    	ITEM_TYPE="file"
	else
    	ITEM_TYPE="unknown"
	fi

	# Determine the event type and set color
	case "$action" in
	CREATE*)
    	EVENT_TYPE="created"
    	if [ "$ITEM_TYPE" == "directory" ]; then
        	COLOR="\033[1;34m" # Light Blue for directory creation
    	else
        	COLOR="\033[0;32m" # Green for file creation
    	fi
    	;;
	DELETE*)
    	EVENT_TYPE="deleted"
    	if [ "$ITEM_TYPE" == "directory" ]; then
        	COLOR="\033[0;35m" # Violet for directory deletion
    	else
        	COLOR="\033[0;31m" # Red for file deletion
    	fi
    	;;
	*)
    	# Skip other events
    	continue
    	;;
	esac

	# Retrieve the user who triggered the event
	USER=$(stat -c '%U' "$FULL_PATH" 2>/dev/null || echo "unknown")
	LOG_MESSAGE="[$(date)] $ITEM_TYPE '$file' was $EVENT_TYPE in '$path' by user $USER"
	echo "$LOG_MESSAGE" >> "$LOG_FILE"

	# Print log message to terminal with color
	echo -e "${COLOR}$LOG_MESSAGE\033[0m"

	# Display the event in a Zenity notification
	zenity --notification --text="$LOG_MESSAGE"
done


