# Localfarm Client Configuration

Automatisk konfigurasjon for klientmaskiner i Localfarm-nettverket.

## Kva dette gjer

- ✅ Oppdaterer `/etc/hosts` med alle Localfarm-tenester
- ✅ Setter opp automatisk synkronisering (ansible-pull)
- ✅ Støttar macOS, Linux og Windows (WSL)

## Quick Start

### macOS / Linux

```bash
# 1. Installer Ansible (éin gong)
pip3 install ansible

# 2. Bootstrap (køyrer ansible-pull første gong)
curl -fsSL https://raw.githubusercontent.com/thusby/localfarm-client-config/main/scripts/bootstrap.sh | bash

# Eller manuelt:
ansible-pull \
  -U https://github.com/thusby/localfarm-client-config.git \
  -i localhost, \
  playbooks/bootstrap.yml
```

### Windows (WSL)

```powershell
# 1. Installer WSL2
wsl --install

# 2. I WSL terminal:
sudo apt update && sudo apt install -y ansible
ansible-pull \
  -U https://github.com/thusby/localfarm-client-config.git \
  -i localhost, \
  playbooks/bootstrap.yml
```

## Kva skjer etter bootstrap?

Ansible-pull blir sett opp til å køyre **kvar time** (macOS: LaunchDaemon, Linux: cron).

Kvar gong oppdaterer maskina si `/etc/hosts`-fil frå `network_registry.yml`.

## Testing lokalt (utan GitHub)

```bash
# Bruk lokal kopi i staden for GitHub
ansible-pull \
  -U file:///home/thusby/Development/localfarm/localfarm-client-config \
  -i localhost, \
  playbooks/bootstrap.yml
```

## Filer

```
localfarm-client-config/
├── README.md
├── network_registry.yml         # DNS mappings (synced frå infrastructure)
├── playbooks/
│   ├── bootstrap.yml            # Initial setup
│   └── update.yml               # Dagleg oppdatering (køyres av ansible-pull)
├── roles/
│   ├── local_dns/               # Oppdater /etc/hosts
│   └── ansible_pull_client/     # Sett opp ansible-pull
└── scripts/
    └── bootstrap.sh             # One-liner bootstrap script
```

## DNS Mappings

Etter bootstrap vil `/etc/hosts` innehalde:

```
192.168.68.29  monitor.localfarm.no     # Grafana
192.168.68.29  prometheus.localfarm.no  # Prometheus
192.168.68.29  localfarm.no             # Frontend
192.168.68.29  api.localfarm.no         # Backend API
... og fleire
```

## Troubleshooting

### Sjekk om ansible-pull køyrer

**macOS:**
```bash
sudo launchctl list | grep localfarm
tail -f /var/log/ansible-pull.log
```

**Linux:**
```bash
sudo crontab -l | grep ansible-pull
tail -f /var/log/ansible-pull.log
```

### Force oppdatering no

```bash
sudo /usr/local/bin/localfarm-ansible-pull
```

### Avinstallere

**macOS:**
```bash
sudo launchctl unload /Library/LaunchDaemons/no.localfarm.ansible-pull.plist
sudo rm /Library/LaunchDaemons/no.localfarm.ansible-pull.plist
sudo rm /usr/local/bin/localfarm-ansible-pull
```

**Linux:**
```bash
sudo crontab -r  # Fjern cron job
sudo rm /usr/local/bin/localfarm-ansible-pull
```

## Oppdatering frå infrastructure

`network_registry.yml` blir automatisk synkronisert frå `localfarm-infrastructure` repoet.

**Manuell sync:**
```bash
# I localfarm-infrastructure:
cp network_registry.yml ../localfarm-client-config/
cd ../localfarm-client-config
git add network_registry.yml
git commit -m "Sync from infrastructure"
git push
```

## Sikkerheit

- Repoet er **public** (ingen hemmeligheter)
- Ansible-pull køyrer som **root** (nødvendig for /etc/hosts)
- Alle endringar er **git-versjonerte** (audit trail)

## Support

- macOS: 11+ (Big Sur)
- Linux: Ubuntu 20.04+, Debian 11+
- Windows: WSL2 med Ubuntu
