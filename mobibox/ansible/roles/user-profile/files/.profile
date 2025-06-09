# BE AWARE to use ZSH-Shell syntax (not BASH)

###################################################################################################
# This script is
#     - executing phase 2 of mobibox provisioning during "vagrant ssh"
#       - phase 1 is done during initial "vagrant up" or "vagrant provision"
#       - phase 2 is optional, e. g. if you need access to passphrase-protected ssh keys to load
#         configuration (e. g. from GitHub)
#       - phase 3 (extensions.sh) is optional, when you integrate your own specific configuration/provisioning
#         tooling. you have to 
#       - phase 4 is optional, when you integrate your own specific configuration/provisioning
#         tooling. you have to 
#     - initializing shell
#
# Preparation on host side:
#     - if you want to contribute a ssh key into the mobibox SSH-Agent, ensure that it is available
#       on `~/.ssh/id_rsa` (e. g. by creating a symbolic link to your ssh key)
#     - if you want to use phase 3 add 
###################################################################################################

# no fail-fast
# ... otherwise it might happen that we cannot connect during "vagrant ssh"
# set -o errexit

###################################################################################################
#                                               functions
###################################################################################################

is_provisioning_needed() {
   if [ -f ~/.mobibox_fully_provisioned ]; then
      echo "false"
   else
      echo "true"
   fi
}

###################################################################################################
#                                            initialization
###################################################################################################

echo "########################################## basic shell initialization"

##########################
# Custom Scripting in PATH
# ... if you need scripts on the path ... create a link in /home/vagrant/.local/bin
#
export PATH="${PATH}:/home/vagrant/.local/bin"

###################
# adopt known_hosts
#

# ... to avoid user input when cloning from github
ssh-keygen -F "github.com" > /dev/null
if [ "${?}" != "0" ]; then
  mkdir -p ~/.ssh
  touch ~/.ssh/known_hosts
  ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>&1
fi

#################################################
# restore ~/.zsh_history
# ... history file should reside on the host machine
# ... this is a workaround ... was not working
#
[[ -f ~/ssh_host/.zsh_history ]] && touch ~/ssh_host/.zsh_history

if [ ! -L ~/.zsh_history ]; then
   if [ -f ~/.zsh_history ]; then
      rm ~/.zsh_history
   fi
   ln -s ~/ssh_host/.zsh_history ~/.zsh_history
fi

#################################################
# improve command auto-completion
# ... PgUp/PgDown support
#
bindkey    "\e[5~" history-beginning-search-backward
bindkey    "\e[6~" history-beginning-search-forward

#################################################
# load powerlevel10k zsh theme
# ... to customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#################################################
# alias definitions
# ... alphabetically ordered
#
alias cdhomelabhost="cd ~/homelab_host"
alias cdmobibox="cd ~/homelab_host/mobibox"
alias cdsshhost="cd ~/ssh_host"
alias cdtemp="cd /tmp"

alias dotfiles-bootstrap="source ~/homelab_host/mobibox/dotfiles/_scripts_/bootstrap"
alias dotfiles-install="bash ~/homelab_host/mobibox/dotfiles/_scripts_/install && ~/homelab_host/mobibox/dotfiles/_scripts_/configure"

alias gs="git status"

alias l="ls -alF"
alias la="ls -al"
alias ll="ls -l"
alias lt="ls -ltr"

#################################################
# configure/load SSH-Agent
#

if [ -f ~/.ssh/ssh-agent-at-mobibox.config ]; then
   source ~/.ssh/ssh-agent-at-mobibox.config > /dev/null
fi

# if proposed agent is not running ... create a new one and store its configuration
# for next login
if [ -z ${SSH_AGENT_PID} ] || [ ! -d /proc/${SSH_AGENT_PID} ]; then
   # agent not running ... create new one and store its config (for next login)
   if [ -S ~/.ssh/ssh-agent-at-mobibox ]; then
      # agent not running but socket existing (should usually not happen)
      # => remove socket first to create a new agent afterwards
      rm ~/.ssh/ssh-agent-at-mobibox
   fi
   ssh-agent -a ~/.ssh/ssh-agent-at-mobibox -s > ~/.ssh/ssh-agent-at-mobibox.config
   source ~/.ssh/ssh-agent-at-mobibox.config > /dev/null
fi

# ensure that private key (id_rsa) and potential passphrase is already contributed
ssh-add -l | grep "`ssh-keygen -lf ~/ssh_host/id_rsa | cut -d " " -f2`" > /dev/null 2>&1
if [ "${?}" != "0" ]; then
   # contribute private key (either with or without passphrase)
   echo "your private key is passphrase-protected"
   ssh-add ~/ssh_host/id_rsa
fi

if [ "$(is_provisioning_needed)" = "true" ]; then
   echo "#################################### provisioning (ansible) - phase 2"
   echo "                                            config in homelab/mobibox"

   _extra_variables="{\"globals\":{\"user_home\":\"/home/vagrant\"}}"
   echo "_extra_variables=${_extra_variables}"

   ANSIBLE_LOCALHOST_WARNING=false \
      ansible-playbook \
         --extra-vars "${_extra_variables}" \
         ~/homelab_host/mobibox/ansible/playbook-during-login.yml
fi

if [ "$(is_provisioning_needed)" = "true" ] && [ -f ~/homelab_host/mobibox/shell-provisioning/extension.sh ]; then
   echo "############################### provisioning (mobibox/shell-provisioning/extension.sh) - phase 3"

   ~/homelab_host/mobibox/shell-provisioning/extension.sh
fi

echo "################################### provisioning (dotfiles) - phase 4"

#################################################
# dotfiles
#
export DOTFILES_ROOT=~/homelab_host/mobibox/dotfiles
if [ -d ${DOTFILES_ROOT} ]; then
   # there is dotfile content => apply it
   if [ "$(is_provisioning_needed)" = "true" ]; then
      source ~/homelab_host/mobibox/dotfiles/_scripts_/install
   fi

   # ALWAYS execute bootstrap
   source ~/homelab_host/mobibox/dotfiles/_scripts_/bootstrap
fi

echo "####################################### extended shell initialization"

#################################################
# devbox global
# ... https://www.jetify.com/docs/devbox/devbox_global/
#
echo "############### devbox"
#
#eval "$(devbox global shellenv --init-hook)"
eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r

echo "############### pos1"

# this should be the last line
touch ~/.mobibox_fully_provisioned

echo "############### pos1"
