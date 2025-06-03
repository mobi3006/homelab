# dotfiles

> **STATUS:** ready-to-use

---

# Organization

There is a separation of

* dotfiles scripts residing in mobibox `homelab/mobibox/dotfiles/_scripts_` (ready to use)
* OPTIONAL custom dotfiles `~/mobibox-contribs/.dotfiles` reside on host system ... you can configure a different folder by `export MOBIBOX_CONTRIBS_FOLDER=~/this-is-my-personal-folder` BEFORE initial `vagrant up`

---

# Bootstrap

The command (= alias) `dotfiles-bootstrap` is sourcing all `*.zsh` within `MOBIBOX_CONTRIBS_FOLDER`.

---

# Install

The command (= alias) `dotfiles-install` is executing all `install.sh` within `MOBIBOX_CONTRIBS_FOLDER`.