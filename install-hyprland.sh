#!/usr/bin/env bash
# an installation and deployment script for hyprland.
# requirement
# - yay pre-installed
# - NetworkManager installed

if [ "$(id -u)" = 0 ]; then
	echo "##################################################################"
	echo "This script MUST NOT be run as root user since it makes changes"
	echo "to the \$HOME directory of the \$USER executing this script."
	echo "The \$HOME directory of the root user is, of course, '/root'."
	echo "We don't want to mess around in there. So run this script as a"
	echo "normal user. You will be asked for a sudo password when necessary."
	echo "##################################################################"
	exit 1
fi

error() {
	clear
	printf "ERROR:\\n%s\\n" "$1" >&2
	exit 1
}

# installing paru as aur package manager

# check if yay installed
ISYAY=/sbin/yay
if [ -f "$ISYAY" ]; then
	echo -e "yay was located, moving on.\n"
	yay -Suy
else
	echo -e "yay was not located, please install yay. Exiting script.\n"
	exit
fi

# disable wifi powersave mode
read -n1 -rep 'Would you like to disable wifi powersave? (y,n)' WIFI
if [[ $WIFI == "Y" || $WIFI == "y" ]]; then
	LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
	echo -e "The following has been added to $LOC.\n"
	echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC
	echo -e "\n"
	echo -e "Restarting NetworkManager service...\n"
	sudo systemctl restart NetworkManager
	sleep 3
fi

# install all of the below packages
read -n1 -rep 'Would you like to install the packages? (y,n)' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
	yay -S --noconfirm hyprland-bin alacritty fish sddm-git btop cava \
		swaybg swaylock-effects rofi wlogout dunst thunar neovim-nightly-bin \
		ttf-jetbrains-mono-nerd noto-fonts-emoji sddm-sugar-candy-git \
		polkit-gnome python-requests starship wl-clipboard-history-git \
		swappy grim slurp pamixer brightnessctl gvfs fd ripgrep \
		bluez bluez-utils lxappearance xfce4-settings \
		dracula-gtk-theme dracula-icons-git xdg-desktop-portal-hyprland-git

	# Start the bluetooth service
	echo -e "Starting the Bluetooth Service...\n"
	sudo systemctl enable --now bluetooth.service
	sleep 2

	# clean out other portals
	echo -e "Cleaning out conflicting xdg portals...\n"
	yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk
fi

# copy config files
read -n1 -rep 'Would you like to copy config files? (y,n)' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
	echo -e "Copying config files...\n"
	cp -R hypr ~/.config/
	cp -R alacritty ~/.config/
	cp -R dunst ~/.config/
	cp -R swaylock ~/.config/
	cp -R rofi ~/.config/

	# set files as executable
	chmod +x ~/.config/hypr/xdg-portal-hyprland
	chmod +x ~/.config/waybar/scripts/waybar-wttr.py

	#copy fonts
	mkdir -p ~/.local/share
	tar xf fonts.tar.gz --directory=$HOME/.local/share/
fi

# setup starship prompt
read -n1 -rep 'Would you like to install the starship shell? (y,n)' STAR
if [[ $STAR == "Y" || $STAR == "y" ]]; then
	# install the starship shell
	echo -e "Updating .bashrc...\n"
	echo -e '\neval "$(starship init bash)"' >>~/.bashrc
	echo -e "copying starship config file to ~/.confg ...\n"
	cp starship.toml ~/.config/
fi

# disable current login manager
sudo systemctl disable $(grep '/usr/s\?bin' /etc/systemd/system/display-manager.service | awk -F / '{print $NF}') || echo "Cannot disable current display manager."
# enable sddm as login manager
sudo systemctl enable sddm

# make sugar-candy the default sddm theme
[ -f "/usr/lib/sddm/sddm.conf.d/default.conf" ] &&
	sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /usr/lib/sddm/sddm.conf.d/default.conf.backup &&
	sudo sed -i 's/^Current=*.*/Current=sugar-candy/g' /usr/lib/sddm/sddm.conf.d/default.conf

# sddm local configuration file.
[ -f "/etc/sddm.conf" ] &&
	sudo cp /etc/sddm.conf /etc/sddm.conf.backup &&
	sudo sed -i 's/^Current=*.*/Current=sugar-candy/g' /etc/sddm.conf

# create a local configuration file if it doesn't exist.
[ ! -f "/etc/sddm.conf" ] &&
	sudo cp /usr/lib/sddm/sddm.conf.d/default.conf /etc/sddm.conf || echo "Default sddm system config file is not found."

# setup fish as default shell
sudo chsh $USER -s "/usr/bin/fish" && echo -e "fish has been set as your default USER shell. Logging out is required for this take effect."

# completion
echo "hyprland has been installed!"

while true; do
	read -p "Do you want to reboot? [Y/n] " yn
	case $yn in
	[Yy]*) reboot ;;
	[Nn]*) break ;;
	"") reboot ;;
	*) echo "Please answer yes or no." ;;
	esac
done
