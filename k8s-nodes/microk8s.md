# Kubernetes Distribution Microk8s

> DEPRECATED - no more used

* [install microk8s on Ubuntu](https://microk8s.io/docs/install-raspberry-pi)
* [microk8s@pierreinside](kubernetes-microK8s.md)

---

# Installation

> "Note: Running Kubernetes can cause a lot of I/O requests and pressure on storage. It is not recommended to use a USB stick as primary storage when running MicroK8s. [...] Running MicroK8s on some ARM hardware may run into difficulties because cgroups (required!) are not enabled by default."

Ich folge also den [Anweisungen zur Installation von MicroK8s](https://microk8s.io/docs/install-raspberry-pi) auf einem Raspberry PI 4 Model B:

```bash
sudo vi /boot/firmware/cmdline.txt
```

und folgendes hinzufügen:

```
cgroup_enable=memory cgroup_memory=1
```

Dann mal rebooten.

Ich werde `microk8s` per `snap` installieren und deshalb (https://snapcraft.io/docs/installing-snap-on-raspbian):

```bash
sudo apt install snapd
sudo reboot

sudo snap install core
```

Anschließend sollte `snap install hello-world && hello-world` funktionieren.

Nun `microk8s` installieren:

```bash
sudo snap install microk8s --classic --channel=1.32
```

und den aktuellen User zur `microk8s` Gruppe hinzufügen:

```bash
sudo usermod -a -G microk8s $USER
mkdir -p ~/.kube
chmod 0700 ~/.kube
```

Nach einem `su - $USER` (um die neue Gruppenzugehörigkeit zu aktivieren) wird MicroK8s per `microk8s start` gestartet und der Status per `microk8s status` überprüft.

> Der Start dauert schon eher lange ... auf meinem MacBook Pro M1 ist das in 12 Sekunden erledigt. 

Microk8s bringt `kubectl` mit, so dass das schon funktioniert:

```bash
microk8s kubectl get nodes
```

Anschließend noch die Konfiguration in `~/.kube/config` kopieren (das braucht später auch `k9s`):

```bash
microk8s config > ~/.kube/config
```

> Microk8s bringt mit `containerd` schon eine Docker-Engine mit und benötigt kein separates Docker. Man kann Docker aber zusätzlich installieren und verwenden , z. B. um Images zu bauen.

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

Das Deployment erfolgt per `microk8s kubectl apply -f nginx-deployment.yaml` und der Status per `microk8s kubectl get pods`.

Da ich nicht ständig `microk8s kubectl` schreiben möchte, habe ich mir ein Alias `k` angelegt:

```bash
alias k=`microk8s kubectl`
```