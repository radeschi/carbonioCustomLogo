#!/bin/bash

# This script configures custom logos and wallpapers for the Carbonio CE webmail login page.
# It automatically captures configured domains with 'carbonio gad' and also allows additional 
# domains to be specified via command line arguments. For each domain, it sets up directories 
# with specific logos and wallpapers, modifies JavaScript files to ensure the login page displays 
# the custom images, and updates the page title and logo SVG. The script avoids recreating directories 
# and configurations if they already exist.
#
# Author: Maicon Radeschi
# Email: radeschi@me.com
# Date: 2024-10-31
# Version: 0.1
#
# Usage example:
#   ./configure_carbonio_logos.sh
#   ./configure_carbonio_logos.sh additionaldomain.com anotherdomain.net
#
# This example will automatically configure logos for all domains detected by 'carbonio gad'
# and, if specified, for any additional domains provided as arguments.

# Directory variables
base_logo_dir="/opt/zextras/web/logos"
login_dir="/opt/zextras/web/login"
iris_dir="/opt/zextras/web/iris/carbonio-shell-ui"
backup_dir="/opt/zextras/web/backup_orig"

# Image file names
logo_name="inside_logo.png"
wallpaper_name="wallpaper.jpg"
login_image="login.png"

# Verify if image files exist before running the script
if [[ ! -f "$logo_name" ]] || [[ ! -f "$wallpaper_name" ]] || [[ ! -f "$login_image" ]]; then
  echo "! Error: Required image files ($logo_name, $wallpaper_name, $login_image) are missing."
  echo "! Please make sure all required images are in the current directory before running the script."
  exit 1
fi

# Backup the original login directory and any modified files (only once)
_backupOriginalFiles() {
  if [ ! -d "$backup_dir" ]; then
    echo "> Creating backup directory at $backup_dir..."
    mkdir -p "$backup_dir" || { echo "! Failed to create backup directory"; return 1; }

    echo "> Backing up the original login directory..."
    cp -a "$login_dir" "$backup_dir/" || echo "! Failed to backup the original login directory"

    # Identify files to modify for custom images and page titles
    login_js_file=$(_findLoginJsFile)
    logo_svg_file=$(_findLogoSvgFile)
    page_title_file=$(_findPageTitleFile)

    # Copy identified files to backup directory
    if [ -n "$login_js_file" ]; then
      cp "$login_js_file" "$backup_dir/" || echo "! Failed to backup $login_js_file"
    fi
    if [ -n "$logo_svg_file" ]; then
      cp "$logo_svg_file" "$backup_dir/" || echo "! Failed to backup $logo_svg_file"
    fi
    if [ -n "$page_title_file" ]; then
      cp "$page_title_file" "$backup_dir/" || echo "! Failed to backup $page_title_file"
    fi

    echo "> Backup completed successfully."
  else
    echo "> Backup directory already exists. Skipping backup process."
  fi
}

# Capture configured domains automatically using 'carbonio gad'
echo "> Capturing configured domains with 'carbonio gad'..."
configured_domains=$(su - zextras -c "carbonio gad")

# Combine domains from parameters with captured domains
all_domains=("$@")
for domain in $configured_domains; do
  all_domains+=("$domain")
done

# Function to check if the domain directory already exists
_domainDirExists() {
  [ -d "$base_logo_dir/$1" ]
}

# Function to create the domain directory with logo and wallpaper files
_createDomainDirectory() {
  local domain="$1"
  local domain_dir="$base_logo_dir/$domain"

  if _domainDirExists "$domain"; then
    echo "! Directory for $domain already exists. Skipping creation."
  else
    echo "> Creating directory for $domain..."
    mkdir -p "$domain_dir" || echo "! Failed to create directory for $domain"
    cp "$logo_name" "$domain_dir/" || echo "! Failed to copy $logo_name to $domain_dir"
    cp "$wallpaper_name" "$domain_dir/" || echo "! Failed to copy $wallpaper_name to $domain_dir"
    cp "$login_image" "$domain_dir/" || echo "! Failed to copy $login_image to $domain_dir"
  fi
}

# Function to find the JavaScript file needing login modifications (for wallpaper and logo)
_findLoginJsFile() {
  grep -l "8b90fe7b942c6f389f1ddd01103d3b0e.jpg" "$login_dir"/*.js
}

# Function to find the file containing the logo SVG
_findLogoSvgFile() {
  grep "M306.721 72.44c-2.884-5.599" "$iris_dir"/* -rl | grep -v .map
}

# Function to find the file containing the page title
_findPageTitleFile() {
  grep "Carbonio Client" "$iris_dir"/* -rl | grep -v .map
}

# JavaScript modifications for login
_modifyLoginJs() {
  local login_js_file="$1"
  echo "> Modifying $login_js_file to load new logos and wallpapers..."
  sed -i '2 i const multidomain = window.location.hostname.toString();' "$login_js_file" || echo "! Failed to modify $login_js_file"
  sed -i s@assets/8b90fe7b942c6f389f1ddd01103d3b0e.jpg@'../logos/"+multidomain+"/wallpaper.jpg'@g "$login_js_file" || echo "! Failed to replace wallpaper in $login_js_file"
  sed -i s@assets/a2ca34c391de073172d480fe7977954a.jpg@'../logos/"+multidomain+"/wallpaper.jpg'@g "$login_js_file" || echo "! Failed to replace wallpaper in $login_js_file"
  sed -i s@assets/c469e23959fd19cc40fbb5e56c083c86.png@'../logos/"+multidomain+"/login.png'@g "$login_js_file" || echo "! Failed to replace login image in $login_js_file"
}

# SVG logo modification
_modifyLogoSvg() {
  local svg_file="$1"
  echo "> Modifying $svg_file to replace SVG logo with new PNG file..."
  sed -i '2 i const multidomain = window.location.hostname.toString();' "$svg_file" || echo "! Failed to add hostname to $svg_file"
  sed -i s@createElement\(\"svg\".*402-35.626\"@'createElement("img",(({src:"/static/logos/" + multidomain + "/inside_logo.png",height:"30"'@g "$svg_file" || echo "! Failed to replace SVG in $svg_file"
}

# Page title modification
_modifyPageTitle() {
  local title_file="$1"
  echo "> Modifying page title in $title_file..."
  sed -i s/"Carbonio Client"/"YourSiteName"/g "$title_file" || echo "! Failed to modify page title in $title_file"
}

# Main function to process each domain
_processDomain() {
  local domain="$1"
  _createDomainDirectory "$domain"
}

# Run the backup function
_backupOriginalFiles

# If the backup is completed successfully, execute file modification functions
if [ -d "$backup_dir" ]; then
  login_js_file=$(_findLoginJsFile)
  [ -n "$login_js_file" ] && _modifyLoginJs "$login_js_file"

  logo_svg_file=$(_findLogoSvgFile)
  [ -n "$logo_svg_file" ] && _modifyLogoSvg "$logo_svg_file"

  page_title_file=$(_findPageTitleFile)
  [ -n "$page_title_file" ] && _modifyPageTitle "$page_title_file"
fi

# Process each individual domain
for domain in "${all_domains[@]}"; do
  _processDomain "$domain"
done

echo "> Configuration successfully applied for all domains!"
