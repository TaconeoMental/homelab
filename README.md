# homelab

Still WIP :)

```
.
├── dns:   Pi-hole + BIND9 local DNS servers
├── metal: Scripts for seting up physical hardware
│   ├── legacy: Legacy scripts... no longer used in favor of SDM
│   └── sdm:    Scripts that make use of https://github.com/gitbls/sdm
│       ├── customize.sh: Create base OS image
│       ├── burn.sh:      Flash image to device
│       ├── config:       SDM plugin configuration
│       └── plugins:      Custom SDM plugins
│           └── ssh:      Plugin for setting up SSH
└── wiki:  wiki.js docker configuration
```
