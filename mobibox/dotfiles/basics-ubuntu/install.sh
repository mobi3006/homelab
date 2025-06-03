source $(dirname "$0")/../_scripts_/functions

_program="dos2unix" && is_installed ${_program} || (( sudo apt-get install -y ${_program} && success "${_program} installed") || fail "${_program} failed")
_program="btop" && is_installed ${_program} || (( sudo snap install ${_program} && success "${_program} installed") || fail "${_program} failed")