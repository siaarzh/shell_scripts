#!/bin/bash

# UBUNTU 14 +
# This script installs the fancy fish shell and oh-my-fish framework

# 1. Install fish
# https://github.com/fish-shell/fish-shell
sudo apt-get update
sudo apt-get install -y -qq fish

# 2. Create config file
mkdir -p ~/.config/fish
touch ~/.config/fish/config.fish

echo "# Remove fish welcome message" >> ~/.config/fish/config.fish
echo "set -g -x fish_greeting ''" >> ~/.config/fish/config.fish
echo "# Enable powerline fonts" >> ~/.config/fish/config.fish	
echo "set -g theme_powerline_fonts yes" >> ~/.config/fish/config.fish

# 3. Install powerline fonts
sudo apt-get install -y -qq fonts-powerline

# 4. Install oh-my-fish
# https://github.com/oh-my-fish/oh-my-fish
curl -L https://get.oh-my.fish | fish

# 5. Enable bobthefish theme
# https://github.com/oh-my-fish/theme-bobthefish
rm -rf ~/.cache/omf
omf install bobthefish

# 6. (OPTIONAL) Set fish as default shell
chsh -s /usr/bin/fish