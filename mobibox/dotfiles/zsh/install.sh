source $(dirname "$0")/../_scripts_/functions

#################################################
# install zsh-autosuggestions
#
# on top of that there is a ^x^x history search configured on Vanilla Speedbox
#
if [ ! -d ~/.config/zsh-autosuggestions ]; then
   git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.config/zsh-autosuggestions
fi
