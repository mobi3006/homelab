# Raspberry Nodes

---

# Core Setup

> **Spoiler:** am besten verwendet man das _Raspberry Pi OS Lite_ ... die Lite Version kommt ohne Desktop Environment und grafische Oberfläche. Ich habe mit der normalen Version gestartet und da gabs schon ein paar Aussetzer. Da war ich froh schon alles in Ansible gegossen zu haben, so dass der Wechsel in 10 Minuten erledigt war (ein großartiger Test für mein Playbook).

* Raspberry Pi Imager Software auf MacOS installieren und starten
* SD Karte einschieben
* in Raspberry Pi Imager Software folgendes konfigurieren
  * OS auswählen: Raspberry Pi OS Lite (64-bit)
  * **hostname**
  * **Benutzername und Passwort**
  * **Wifi**
  * **ssh Dienst aktivieren**
  * Spracheinstellungen
* SD-Karte in den Raspi einstecken und booten
  * zunächst kamen ein paar Reboots (gefühlt), doch irgendwann war das System da (vielleicht hatte es auch positive Auswirkungen, dass ich mal auf der Tastatur rumgetippt habe)

Alles war vorhanden:

* Ausgabe per HDMI ... auch wenn ich das System zumeist headless verwende ist es für die Fehleranalyse gut, wenn man mal einen Monitor anschließen kann
* Bluetooth-Anbindung der Tasteatur
* ssh Dienst

Anschließend wurden die Packages aktualisiert:

```bash
sudo apt update
sudo apt full-upgrade
```

Zur Sicherheit noch mal ein abschließender Reboot (`sudo reboot`).

Viola, das war einfach ... 2020 hatte ich hier mit Raspbian mehr Probleme.

## systemd

Raspberry Pi OS is using `systemd` to start services (using `systemctl`). Some useful commands

* `systemctl status`: list all services and their state
* `systemctl status snap.microk8s.daemon-k8s-dqlite.service`: list status of service `snap.microk8s.daemon-k8s-dqlite.service`

## journald

If you are searching for logs in `/var/log` ... keep in mind:

> "You are running a systemd-based OS where traditional syslog has been replaced with the Journal. The journal stores the same (and more) information as classic syslog. To make use of the journal and access the collected log data simply invoke "journalctl", which will output the logs in the identical text-based format the syslog files in /var/log used to be. For further details, please refer to journalctl(1)."

Use it like that:

```
journalctl -u snap.microk8s.daemon-k8s-dqlite.service
```

You get the list of services by `systemctl status`.

## snapd

Raspberry Pi OS is supporting `snap` as package manager which is supported by a lot of famous software. It does not come out-of-the-box but I install it via `apt install snap`. 

## Tuning - NVMe Storage

If the lags are remaining it might be related to the I/O ... the SD-card might be an issue and could be replaced by NVMe storage.

## Raspberry Pi Connect

> aktuell nicht genutzt

Hierüber kann man sich aus dem Internet auf den Raspberry Pi per Terminal und grafischer Oberfläche verbinden.

* Raspberry Pi Connect Account anlegen und damit im Raspberry Pi anmelden
* `sudo apt update && sudo apt full-upgrade && apt install rpi-connect`

Anschließend kann man über https://connect.raspberrypi.com eine Verbindung zum Raspberry Pi aufbauen.

## Wireless LAN - in Raspi OS Release Bookworm

* [How to Configure Wi-Fi on Raspberry Pi?](https://raspberrytips.com/raspberry-pi-wifi-setup)

My approach was to configure WLAN in _Raspberry Pi Imager_ to have it working out-of-the-box after fresh installation. But this setup was not reliable - I had to restart the WLAN interface from time to time by 

```
sudo ifconfig wlan0 down && sudo ifconfig wlan0 up
```

... I had to dig deeper into internals.

There are several options how to configure WLAN ... some or even outdated when you google for it - maybe they are even conflicting. The tutorial [tutorial 'How to Configure Wi-Fi on Raspberry Pi?'](https://raspberrytips.com/raspberry-pi-wifi-setup) recommended to use `sudo nmtui` and pretended that it is easy to use ... not for me because the Wifis were not listed. But `sudo nmcli dev wifi list` showed me the available WLANs.

It turned out that on my Bookworm OS release I had to have `wpa_supplicant` service running (`sudo systemctl status wpa_supplicant`) - same for NetworkManager `sudo systemctl status NetworkManager`. The `NetworkManager` seems to use the `wpa_supplicant` under the hood. The recommendation was to ensure this configuration in `/etc/NetworkManager/NetworkManager.conf`:

```
[device]
wifi.scan-rand-mac-address=no
```

If you have to change that file restart the `NetworkManager` service (`sudo systemctl status NetworkManager`).

Ensure that the wifi's are listed

```
sudo nmcli dev wifi list
```

If not trigger a rescan by `sudo nmcli dev wifi rescan`. Afterwards configure the network connection by

```
sudo nmcli dev wifi connect "your_SSID" password "your_password"
```

### Option 1: Interactive Configuration via raspi-config

Use `sudo raspi-config` to configure WLAN.

> This option is configuring the `wpa_supplicant.conf` file.

### Option 2: via NetworkManager `nmcli`

This is the configuration working for me ... see description in the section intro.

### Option 3: via `wpa_supplicant.conf` - NO MORE SUPPORTED on Raspi OS release bookworm

> Due to [this tutorial](https://raspberrytips.com/raspberry-pi-wifi-setup) this option is no more supported on Raspberry Pi OS 'bookworm'. But we still need the `wpa_supplicant` service running.

Put the following content into `/etc/wpa_supplicant/wpa_supplicant.conf` - adjust the `network` configuration to your needs:

```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
    ssid="your_SSID"
    psk="your_password"
    key_mgmt=WPA-PSK
}
```

and restart the WLAN interface:

```bash
sudo systemctl restart wpa_supplicant
```

### Option 4: via `dhcpcd.conf`

> never tried

Put the following content into `/etc/dhcpcd.conf` - adjust the `interface` and `static ip_address` configuration to your needs:

```
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1

# WiFi configuration
ssid="your_SSID"
psk="your_password"
```

and restart `dhcpd` service:

```bash
sudo systemctl restart dhcpcd
```

---

# ssh access

> I will need this ssh access for VSCode Remote (see below)

* create folder `~/.ssh` on Raspi

  ```bash
  mkdir ~/.ssh
  chmod 700 ~/.ssh
  ```

* create `~/.ssh/authorized_keys` on Raspi (e. g. hostname `pi4`) and add the public key of your ssh-key

On your host system put this into `~/.ssh/config`:

```
Host pi4
     Hostname pi4
     User pi
     IdentityFile ~/.ssh/my-ssh-private-key
 ```

Afterwards you should be able to connect via `ssh pi4` without providing a password and without using an explicit ssh key to use (`-i ~/.ssh/my-ssh-private-key`).

---

# Kubernetes Distribution k3s

> After some trouble with `microk8s` (trouble that was reported by other users as well - see FAQ) I was checking the requirements of `k3s` in more detail. Raspberry Pi OS is supported explicitly.

##  Minimum Hardware Requirements

* https://docs.k3s.io/installation/requirements?os=pi

Hardware requirements are minimal:

* master:
  * 2 cores
  * 2 GB RAM
* worker:
  * 1 core
  * 0,5 GB RAM

My Raspi Pi has 4 cores and 4 GB - should be a fit. The Pi Zero would fit at least for a worker node ... not sure if this really make sense - maybe only for testing a real cluster setup but not for real workload.

> It is explicitly recommended to use an SSD ... "etcd is write intensive; SD cards and eMMC cannot handle the IO load."

... I will start with my SD card ... currently I do not have much to deploy.

## Preparation

```bash
sudo vi /boot/firmware/cmdline.txt
```

und folgendes hinzufügen:

```
cgroup_enable=memory cgroup_memory=1
```

Dann mal rebooten.

> `k3s` bringt mit `containerd` schon eine Docker-Engine mit und benötigt kein separates Docker. Man kann Docker aber zusätzlich installieren, z. B. um Images zu bauen.

## Installation Master

Mit einem Einzeiler `curl -sfL https://get.k3s.io | sh -` ist die Installation auch schon getan. Anschließend lege ich die Cluster-Konfiguration noch eben in `~/.kube/config` ab:

```bash
mkdir -p /home/pi/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/pi/.kube/config
sudo chown pi:pi /home/pi/.kube/config
```

Anschließend kann ich per `k3s kubectl get nodes` den Status des Clusters abfragen.

Einen ersten Pod deploye ich mit dieser `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

Das Deployment erfolgt per `k3s kubectl apply -f nginx-deployment.yaml` und der Status per `k3s kubectl get pods`.

Da ich nicht ständig `k3s kubectl` schreiben möchte, habe ich mir einen `alias` angelegt:

```bash
alias k=`k3s kubectl`
```

Zudem kopiere ich die `/home/pi/.kube/config` auf meinen Laptop unter `~/.kube/config-k3s`, und ändere `server: https://127.0.0.1:6443` nach `server: https://pi4:6443` ab, so dass ich vom Laptop nach einem `export KUBECONFIG=~/.kube/config-k3s` das k3s-Cluster mit `kubectl` steuern kann.

## Installation Worker

In contrast to a master node the worker node needs the `k3s-agent` installed that is used by the K8s-control-plane to manage the worker node (e. g. orchestrate pods) and to get information about health-status.

The worker node needs to communicate with the master. The needed permission is given by the `K3S_TOKEN` that is stored on the master node.

```
sudo cat /var/lib/rancher/k3s/server/node-token
```

On the worker node install the k3s with the `K3S_TOKEN` and the `K3S_URL` of the master node: **DO NOT EXECUTE THIS COMMAND (for sake of security)**

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 K3S_TOKEN=<NODE_TOKEN> sh -
```

**BE AWARE (SECURITY ISSUE):** this command (and the secure token) would be part of the command history (`~/.zsh_history`) => security flaw. It's better to set those values as environment variables via a sourced file that you can delete afterwards. Therefore create a file `/tmp/temp_k3s_token` with this content:

```bash
export K3S_TOKEN=foobar
```

and source it by `source /tmp/temp_k3s_token`. Then use this command to install the worker node:

```bash
curl -sfL https://get.k3s.io | K3S_URL=https://<SERVER_IP>:6443 sh -
```

and `rm /tmp/temp_k3s_token` afterwards.

**Background info:** This install-script is the same as for the master node ... the only difference is the `K3S_URL` and `K3S_TOKEN` environment variables which makes it a worker node. If you want to uninstallit you have to use `/usr/local/bin/k3s-agent-uninstall.sh` instead of `/usr/local/bin/k3s-uninstall.sh` (for a `master` uninstall).

After installation there should be the agent running. Check with

```
sudo systemctl status k3s-agent
```

and the master node should show the worker node with

```bash
k3s kubectl get nodes
```

When this looks fine execute `rm /tmp/temp_k3s_token` on the worker to delete the master token.

---

# K9s

Ich verwende am liebsten `k9s` um das Kubernetes Cluster zu verwalten. Leider bietet `snap` keine passenden Pakete für ARM64. Deshalb habe ich das Binary manuell runtergeladen und in den PATH gelegt:

```bash
cd /tmp
wget https://github.com/derailed/k9s/releases/download/v0.25.18/k9s_Linux_arm64.tar.gz
tar -xzf k9s_Linux_arm64.tar.gz
sudo mv k9s /usr/local/bin/
```

jetzt startet `k9s` auch.

---

# Docker

> **ACHTUNG:** mein `microk8s`-Cluster braucht kein Docker ... es verwendet `containerd` als Container-Engine. Ich installiere Docker nur, um Images zu bauen.

```bash
sudo apt update
sudo apt upgrade -y
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Anschließend neu anmelden und einen ersten Docker Container starten

```bash
docker run hello-world
```

---

# ZSH Shell

Ich mag die ZSH-Shell lieber als Bash ...

```bash
sudo apt install zsh
zsh
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```

Anschließend die ZSH als Standard-Shell setzen ... evtl. macht das aber auch schon das Installationsskript von `oh-my-zsh`:

```bash
sudo vim /etc/passwd
```

und statt `/bin/bash` bei dem User `/bin/zsh` eintragen.

Kommt man von einer Bash, dann muß man die per `snap` installierten Binaries /`snap/bin` noch in der `~/.zashrc` in den `PATH` hängen.












---

# VSCode Remote

* [YouTube Video by VSCode](https://www.youtube.com/watch?v=rh1Ag41J6IA)

The Raspberry is not made for heavy applications like VSCode. But I do not want to edit on my laptop, commit to git, push to GitHub and pull on raspi. Console editors (e. g. `vi`) are no option for refactorings or more complex changes (I favor GitHub Copilot to be around) ... ok for small changes.

Rsync would be an option but the fastest feedback loop is to change files directly on the Raspi filesystem.

VSCode offers remote support via ssh (see core configuration above).

![vscode-remote-raspi.png](images/vscode-remote-raspi.png)

The yellow way is during development ... the green for persistence.

> when I first tried to connect via _Remote Explorer_ Extension the connection was successfully established but it was stuck during "Downloading VSCode Server" (on my Raspi I've found files like this `/home/pi/.vscode-server/*`) ... after several attempts it was working. Maybe the first initialization took some time.

---

# Ansible Provisioning 

Wie man an dieser Dokumentation sieht ist es relativ aufendig, die ganzen Schritte zu befolgen und dabei keinen Fehler zu machen.

Mit einem halb-automatisierten Workflow reduziere ich den Aufwand und mache aus der Dokumentation ein ausführbares Skript. Das hat mir schon beim Wechsel zur Lite Version geholfen ... und der nächste Node meines Clusters muss ja auch aufgesetzt werden.

Hat man die Anweisung im Abschnitt "ssh Access" befolgt, dann kann man sich mit dem Kommando `ssh pi4` und dem im Raspberry Pi Imager angegebenen Passwort auf den Raspi verbinden.

## Konfiguration - manueller Teil

Vorbereitungen für den automatischen Teil auf dem Raspi:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo apt install ansible git -y

sudo vi /boot/firmware/cmdline.txt
... append: cgroup_enable=memory cgroup_memory=1
```

Anschließend rebooten, um die letzte Kernel Version zu verwenden.

> In der "Lite" version musste **ICH** anschließend noch WLAN manuell neu konfigurieren per `sudo raspi-config` ([see here](https://forums.raspberrypi.com/viewtopic.php?t=352001)). Da ich keinen Zugriff via remote connect bekommen habe, musste ich den Raspi per HDMI an einen Monitor anschließen und eine Tastatur verbinden.

## Konfiguration - automatischer Teil

> Man kann Ansible lokal oder gegen Remote Hosts laufen lassen. Ich werde es vorerst auf dem Host selbst laufen lassen.

Auf dem Raspi folgende Kommandos ausführen:

```bash
mkdir -p ~/src
cd src
git clone https://github.com/mobi3006/homelab-ansible.git
cd homelab-ansible

ansible-playbook -i hosts playbook-raspi.yaml`
```

---

# FAQ

## Problem 1: no access via ssh - WLAN not working

After reboot there is no WLAN available - seems that it happens from time to time.

**Solution 1:** wait 1 minute ... initialization may take some time

**Solution 1.1:** Use the ip-address if you have it, e. g. `ssh pi@192.168.178.70`.

**Solution 1.2:** Connected the Raspi via HDMI to a monitor and a keyboard. Check `ifconfig` if the wlan is visible and has a ip-address assigned. I've restarted the WLAN interface via `sudo ifconfig wlan0 down && sudo ifconfig wlan0 up` ... this fixed the issue.

**Solution 1.3:** Connected the Raspi via HDMI to a monitor and a keyboard. Checked the WLAN log by `sudo journalctl -u wpa_supplicant`. I've found `WPA: 4-Way Handshake failed - pre-shared key may be incorrect ... auth_failures=1`.

**Solution 1.4:** reconfigure WLAN with `sudo reboot`.

**Solution 1.5:** reconfigure WLAN with `sudo raspi-config`.

**Solution 1.6:** configure `/etc/wpa_supplicant/wpa_supplicant.conf` like this

```
network={
    ssid="Your_SSID"
    psk="Your_Password"
    key_mgmt=WPA-PSK
}
```

configure `/etc/dhcpcd.conf`

## Problem 2: Raspberry Pi OS slow

**Analysis:** I've started with the full version of Pi OS which is offering a desktop environment and graphical user interface ... aspects that I do not need but consuming resources. `htop` has shown that the `pcmanfm` process was consuming a lot of CPU time. This process belongs to the _LXDE desktop environment_ ... that I do not need for my K8s cluster.

> After booting there were already 1,5 GB RAM used ... there were only the base tools running, e. g. `microk8s`. 

**Solution 2:** I've switched to the lite version to save resources and to have a more stable system.

... the first impression is positive. After some days I ran into similar issues again - see FAQ.

## Problem 3: slow after reboot - k8s-dqlite locked mit Raspberrz Pi OS

Mein System war sehr langsam - kaum zu bedienen. Ein `kubectl delete -f nginx-deployment.yaml` hat nicht funktioniert ... der Prozess `k8s-dqlite` war gelocked:

> Error from server: error when deleting "nginx-deployment.yaml": rpc error: code = Unknown desc = exec (try: 500): database is locked

Ein stoppen von MicroK8s (`microk8s stop`) blieb lange hier hängen:

> Waiting for "snap.microk8s.daemon-k8s-dqlite.service" to stop

... hat dann aber funktioniert. Leider funktionierte anschließend der Start nicht mehr. Ein `microk8s inspect` brauchte ewig - nach 25 Minuten habe ich es abgebrochen und den Raspi rebootet ... CPU schien nicht das Problem zu sein.

Nach einem Reboot war das gesamte System so zäh, dass es nicht mehr nutzbar war.

**Solution 3:** switch to Raspberry Pi Lite

## Problem 4: slow after reboot - k8s-dqlite locked mit Raspberrz Pi OS Lite

Randomly after reboot the system is extremely slow ... a login on the machine (no ssh) takes 10-20 minutes to proceed.

**Analytics:** `htop` is reporting "state=r" on some `microk8s` processes ... an indicator that there is an I/O operation not yet finished. I only have an sd-card everything is running on ... might be that it is too slow or broken. I had similar issues when I've used the full-version of Raspberry PI OS ...

The `microk8s status` is `NOT RUNNING` although there are microk8s processes. In `kubectl get events -A` I can see some warnings

* `InvalidDiskCapacity 0`
* `Liveness probe failed`
* `Readyness probe failed`
* `Error reaching apiserver`
* `Error verifying datastore`

> TL;DR: after some time investigating `microk8s stop` made my system responsive again ... but I was not able to start it again. A `microk8s start` made it cheesy again. I had to 

On the filesystem there is enough space (`df -h`). Only on `/dev/loopX` there is no space available. I can see that there are no Inode available (`df -i /dev/loop0`) - these filesystems are used by `snap` ... the package manager I've used to install `microk8s`. The processes in `state=D` are all using the command `/snap/microk8s/7602/*`.

> "Snap applications are mounted as loop devices [...]"

It seems to be no uncommon if they are full if used as read-only devices. From my pov I should not configure explicitly the "Inode" setup of those filesystems created by `snap`. This is a dead end.

I executed `microk8s inspect` and found in `/var/snap/microk8s/current/inspection-report/snap.microk8s.daemon-k8s-dqlite/systemctl.log`:

```
level=error msg="error in txn: query (try: 0): context canceled"
level=error msg="failed to create key" error="exec (try: 500): database is locked"
level=error msg="error in txn: exec (try: 500): database is locked"
level=error msg="error in txn: query (try: 0): context canceled"
level=error msg="error in txn: query (try: 0): context deadline exceeded"
```

and some more details in `/var/snap/microk8s/current/inspection-report/snap.microk8s.daemon-k8s-dqlite`:

* `warning: setlocale: LC_ALL: cannot change locale (en_US.utf8) no such file or directory`
* `database is locked`
* `context deadline exceeded`
* `/registry/health : context canceled`
* `failed to create dqlite connection : no available dqlite leader server found`
* `tls: bad record MAC`

Looks like the cluster is broken again (I had the `database is locked` issue with full _Pi OS_ operating system - the reason why I switched to _Pi OS Lite_)... a locked dqlite (containing the kubernetes specifications) sounds like a disaster. The disaster happened during the night ... this cannot be a change related to changes I've made - I was sleeping at this point in time.

Uninstalling and reinstalling `microk8s` does not fix the issue ... `microk8s status` still in `NOT RUNNING` and system cheesy again.

Houston we have a problem.

**Solution 4:** 

I found this guy in trouble as well:

* https://github.com/canonical/microk8s/issues/3735#issuecomment-1422952950

priyashpatil's conclusion

> "Even on single node cluster it crashes after reboot. I'm moving to k3s."

This is the same for me - I agree. Nevertheless I am currently using sd-cards which might be with any kubernetes distribution no good choice ... even not without load in a single node setup.

# Problem 5: k3s kubectl - permission denied

The homepages is offering a one-liner that is really installing the `k3s` on my system but when using `k3s kubectl nodes` I am running into

```
WARN[0000] Unable to read /etc/rancher/k3s/k3s.yaml, please start server with --write-kubeconfig-mode or --write-kubeconfig-group to modify kube config permissions
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
```

**Solution 5:** The problem is that `/etc/rancher/k3s/k3s.yaml` is containing the cluster-access configuration that unpriviledged users usually have in their `~/.kube/config`. By default the file is only readable by root. I've changed the permissions to `644` and now it is working **BUT** after the next reboot the permissions are reset to `600`.

**Solution 5.1:** In gneral I am preferring to use `export KUBECONFIG=~/.kube/config-k3s` to configure the cluster to use with `kubectl`. This makes it very convenient when you have to switch between different clusters. Therefore I've configured it this way ... in my Ansible Playbook I copy `/etc/rancher/k3s/k3s.yaml` to `~/.kube/config-k3s` and set the permissions to `644`.

# Problem 7: ssh connect `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`

I'm running into `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` when connecting via ssh.

**Solution 7:** This is because the host key has changed. This can happen when you have reinstalled the Raspi and the host key has changed. You have to remove the old key from your `~/.ssh/known_hosts` file.

# Problem 8: ansible playbook is stuck

**Analysis 8:**

* start `ansible-playbook` with option `-vvv` to get more verbose output.
* is your raspi slow in general
* do you have issues with internet connection
* measure temperatur `vcgencmd measure_temp`

# Problem 9: reconfigure ~/.kube/config

**Problem 8:** My `k3s kubectl get nodes` (or whatever `kubectl` command) results in `couldn't get current server API group list: Get "https://127.0.0.1:6443/api?timeout=32s"`

**Solution 8:** Maybe you have reinstalled k3s and the configuration has to be changed. Copied `/etc/rancher/k3s/k3s.yaml` to `~/.kube/config` and adjust the owner/permissions.
