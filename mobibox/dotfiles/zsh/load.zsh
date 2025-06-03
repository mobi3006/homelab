source ${DOTFILES_ROOT}/_scripts_/functions

#################################################
# install zsh-autosuggestions
#
# you can accept a suggestion by arrow-right
#
if [ -d ~/.config/zsh-autosuggestions ]; then
   source ~/.config/zsh-autosuggestions/zsh-autosuggestions.zsh
else
   echo "not installed: ~/.config/zsh-autosuggestions/zsh-autosuggestions.zsh"
   echo "run: dotfiles-install"
fi
