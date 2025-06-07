# Homelab

> "The goal wasn’t perfection; it was understanding" ([blog post Reinout Wijnholds](https://medium.com/@reinoutwijnholds2002/building-the-ultimate-raspberry-pi-kubernetes-cluster-a-journey-into-cloud-scalability-from-zero-e5a75c107f0e))

This monorepo is used for my homelab ... a cheap playground for learning technology in the area of Cloud, Kubernetes, automation (Terraform, Ansible, CDK, GitHub, ...), software development (Python, ...).

It is operated on Raspberry PI's and outdated laptops/workstations - commodity hardware. I am appreciating the challenges around heterogenous (AMD, ARM) and less powerful devices to increase the learning effect.

Some years ago I had a small project creating a gaming console ([aka Pico Gaming Console](https://github.com/mobi3006/pico)) based on Raspberry Pi with students. The students were beginners in IT and we had much fun and the result was awesome.

---

# Hardware

* Macbook Air as a development environment based on [mobibox](./mobibox/README.md)
* Raspberry Pi version 5
* Raspberry Pi version 4

## Mobibox on Macbook Air

Development environment based on [mobibox](./mobibox/README.md) ... a virtual machine.

## Raspberry Pi 4 Model B

Zudem habe ich noch einen Pi Zero rumliegen und wahrscheinlich werde ich mir auch noch einen Pi 5 zulegen, damit ich zumindest ein richtiges Cluster haben, um auch mit der Pod-Verteilung zu spielen.

## Raspberry Pi 5 with NVMe

* [Unbox & Install Raspberry Pi 5: Compatible Active Cooler & 3D printed case](https://www.youtube.com/watch?v=C9TeGVl8Igg)
* [Boot Raspberry Pi 5 from NVMe Drive Setup with M.2 HAT+ & CanaKit Case](https://www.youtube.com/watch?v=tF85w9GW3r0)

I have read about issues with NVMe storage on Raspberry Pi 5 ... looks like the specification was late and some third party vendors released products which are not 100% compatible and results in strange issue. I dont want to investigate into such issues and therefore I will buy hardware that is recommended by the Raspberry Pi Foundation - even if I have to pay 10-20% more.

For the NVMe you need a _Raspberry Pi M.2 HAT+_. It supports devices that have the M.2 M key edge connector, in the 2230 and 2242 form factors. It is capable of supplying up to 3A to connected M.2 devices.

* https://www.raspberrypi.com/ is offering a _Raspberry Pi SSD Kit_ consisting of a _Raspberry Pi M.2 HAT+_, a _Samsung 970 EVO Plus 250GB NVMe SSD_ and a _USB-C power supply_.

I have decided to order the fan recommended by Raspberry Pi organization ... this is spinning like crazy and is quite loud.

### Assembly

The hardest part in assembly was to find out where to put the cooling pads ... looks like there are different opinions on the internet. Took me some time to find documentation about it.

### Setup

The typical installation instruction is based on **FULL** Pi OS - using the graphical Pi OS copy tool to setup the NVMe. But I prefer the Lite version to have as clean as possible.

In [this tutorial](https://darkwolfcave.de/raspberry-pi-5-starten-von-nvme-ssd/) a SD-card and a USB-Stick are used. Both have PI OS Lite installed. The USB-Stick is used to boot and the SD-card to copy (via `dd`) a clean - not running - OS to the NVMe. This worked fine for me.

It took me less than an hours but I would expect to do this several times for clean setup the next weeks. Therefore I'll keep the SD-card and USB-Stick ... this will reduce the effort to 15 minutes.

## Gehäuse - Keep it simple

* [Uctronics-Rack for Raspi](https://www.youtube.com/watch?v=prIBogX-N_k)

Mein aktueller Raspberry Pi 4 hat ein Gehäuse ... es ist allerdings nicht stackable. Früher oder später möchte ich die alle in einem rackähnlichen Gehäuse haben, so dass alles schön aufegräumt ist. Aktuell will ich mich nicht damit beschäftigen ... irgendwann weiss ich mehr in welche Richtung sich mein Homelab entwickelt und wie sehr es tatsächlich genutzt wird. Aus diesem Grund verwende ich erstmal ein ganz einfaches Einzelgehäuse, nur zum Schutz des Raspi.

## Power Supply

I use a Ugreen 100W power supply with 4 USB-C and 1 USB-A port. It is capable of delivering 3A per port.

## Power-over-Ethernet - Keep it simple

Ich werde mein Cluster zunächst via WLAN betreiben - keep it simple. Erst wenn ich hier an Grenzen stoße werde ich auf Netzwerkkabel mit einem PoE-Switch umsteigen.

## Networking

I go with the Wireless LAN ob-board only.

---

# Kubernetes Cluster

> more [details here](./k8s-nodes/README.md)

I've decided to build up a Kubernetes Cluster on two Raspberry Pi (version 4 and version 5) ... an AWS EKS Cluster would be much easier to use but I want to be closer on the technology and I am afraid of costs in case the monitoring might not work correctly (it is a playground that might even be unobserved for days/weeks).

Raspberry Pi has a big ecosystem to build interesting hard- and software projects.

My focus area around K8s is not administration but solution architecture, software development and automation.

[This blog post](https://medium.com/@reinoutwijnholds2002/building-the-ultimate-raspberry-pi-kubernetes-cluster-a-journey-into-cloud-scalability-from-zero-e5a75c107f0e) fits to to my motivation very well.

---

# Raspberry Pi in mobile environment

[TechCraft YouTube channel](https://www.youtube.com/@tech_craft) seems to be an expert in that.

## Monitor

Although I use the cluster headless I need a monitor in rare cases to analyze the problem (e. g. ssh-connect failing). On my desktop I have a monitor with HDMI input ... I can use it for the Raspberry Pi. But in some cases it would be nice to bringt a monitor next to the raspi.

## Cluster

... this is currently no real use-case because it needs quite a lot of hardware. If I need access my raspi cluster from remote ... I will make my cluster internet-facing.

The good new is that a power-bank would be good enough to make my raspi working. 

## Power Supply

My Inui Powerbank has 20.000 mAh with 1 USB-C and 2 USB-A ports. This should be enough to power the Raspberry Pi 4 for a quite a while.

Even my iPad Air 2024 has a USB-C port that can be used to power the Raspberry Pi 4.

* nothing I would recommend (unless your iPad gets charged in parallel) - my 35% charged ipad ran out-of-battery within 2 hours.

## iPad as Monitor

* [YouTube - iPad as Monitor](https://www.youtube.com/watch?v=0m8WrJg7IVA)

I have iPad which could be easily used as a monitor ... I will try it.

I need

* cable USB-C (output from raspi) to HDMI => HDMI-capture card => iPad USB-C input
* software on the iPad (e. g. Camo Studio) which is receiving the HDMI output from the capture card (which comes from iPad) and renders it on the iPad screen

## Mobile Networking

* Internet Router:
  * via Tethering from my iPhone
  * via a battery-based mobile router (e. g. GLiNet)
* Switch:
  * via a battery-based mobile router (e. g. GLiNet)

