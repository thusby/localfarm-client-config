# Testing Localfarm Client Config

Instruksjonar for å teste på Mac og Windows.

## Standard Lokasjon

Alle Localfarm-repos skal liggje i **same lokasjon på alle maskiner**:

```
~/Development/localfarm/
├── localfarm-client-config/    # Dette repoet
├── infrastructure/             # (kun på devserver)
└── localfarm-platform/         # (kun på devserver)
```

På Mac: `/Users/BRUKERNAVN/Development/localfarm/`
På Linux: `/home/BRUKERNAVN/Development/localfarm/`
På Windows WSL: `/home/BRUKERNAVN/Development/localfarm/`

## Førebuing

Før du startar, treng devserver vere tilgjengeleg på nettverket (192.168.68.29).

---

## Testing på Mac

### Metode 1: Via lokal filsti (raskast for testing)

**På Mac:**

```bash
# 1. Installer Ansible
pip3 install ansible

# 2. Mount devserver via SMB eller lag lokal klon
# Alternativ A: SMB mount
mkdir -p ~/mnt/devserver
mount -t smbfs //thusby@devserver.localfarm.no/Development ~/mnt/devserver

# Alternativ B: Git clone over SSH (til standard lokasjon)
mkdir -p ~/Development/localfarm
git clone thusby@devserver.localfarm.no:/home/thusby/Development/localfarm/localfarm-client-config ~/Development/localfarm/localfarm-client-config

# 3. Test bootstrap (lokal fil)
export LOCALFARM_REPO="file:///Users/$(whoami)/Development/localfarm/localfarm-client-config"
sudo ansible-pull \
  -U "$LOCALFARM_REPO" \
  -i localhost, \
  playbooks/bootstrap.yml

# 4. Verifiser /etc/hosts
tail -15 /etc/hosts

# Skal vise:
# # BEGIN LOCALFARM MANAGED HOSTS
# 192.168.68.29  monitor.localfarm.no
# ...
```

### Metode 2: Via GitHub (når repo er pusha)

```bash
# Éin kommando:
curl -fsSL https://raw.githubusercontent.com/thusby/localfarm-client-config/main/scripts/bootstrap.sh | bash

# Eller manuelt:
sudo ansible-pull \
  -U https://github.com/thusby/localfarm-client-config.git \
  -i localhost, \
  playbooks/bootstrap.yml
```

### Verifisering på Mac

```bash
# 1. Sjekk /etc/hosts
tail -20 /etc/hosts

# 2. Sjekk LaunchDaemon
sudo launchctl list | grep localfarm
# Skal vise: no.localfarm.ansible-pull

# 3. Sjekk at script finst
ls -lh /usr/local/bin/localfarm-ansible-pull
cat /usr/local/bin/localfarm-ansible-pull

# 4. Test manuell kjøring
sudo /usr/local/bin/localfarm-ansible-pull

# 5. Sjekk logg
tail -f /var/log/ansible-pull.log

# 6. Test DNS-oppslag
ping -c 1 monitor.localfarm.no
# Skal returnere: 192.168.68.29

# 7. Test HTTPS
curl -I https://monitor.localfarm.no
# Skal returnere: HTTP/2 302 (redirect til /login)
```

---

## Testing på Windows 11

### Metode 1: Via WSL2 (anbefalt)

**I PowerShell (admin):**

```powershell
# 1. Installer WSL2
wsl --install

# Restart Windows når ferdig
```

**I WSL Ubuntu terminal:**

```bash
# 2. Installer Ansible
sudo apt update
sudo apt install -y ansible

# 3. Test bootstrap (lokal fil via WSL path)
# Først: Klon repo i WSL til standard lokasjon
mkdir -p ~/Development/localfarm
git clone file:////wsl.localhost/Ubuntu/mnt/devserver/Development/localfarm/localfarm-client-config ~/Development/localfarm/localfarm-client-config

# Eller over SSH:
git clone thusby@devserver.localfarm.no:/home/thusby/Development/localfarm/localfarm-client-config ~/Development/localfarm/localfarm-client-config

# 4. Køyr bootstrap
sudo ansible-pull \
  -U file:///home/$(whoami)/Development/localfarm/localfarm-client-config \
  -i localhost, \
  playbooks/bootstrap.yml

# 5. Verifiser
tail -15 /etc/hosts
```

### Metode 2: PowerShell + hosts-fil (utan Ansible)

Om du berre vil ha `/etc/hosts` oppdatert:

```powershell
# I PowerShell (admin):

# 1. Hent network_registry.yml
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/thusby/localfarm-client-config/main/network_registry.yml" `
  -OutFile "$env:TEMP\network_registry.yml"

# 2. Parser YAML og legg til i hosts-fil
# (Krever PowerShell script - kan lage om nødvendig)

# Eller manuelt:
# Rediger: C:\Windows\System32\drivers\etc\hosts
# Legg til:
192.168.68.29  monitor.localfarm.no
192.168.68.29  localfarm.no
192.168.68.29  api.localfarm.no
```

### Verifisering på Windows

**I WSL:**
```bash
# Same som Linux:
tail -20 /etc/hosts
sudo crontab -l | grep ansible-pull
tail -f /var/log/ansible-pull.log
```

**I Windows (PowerShell):**
```powershell
# Test DNS
Test-Connection -ComputerName monitor.localfarm.no -Count 1

# Eller:
ping monitor.localfarm.no
```

---

## Feilsøking

### Mac: "Operation not permitted" når skriv til /etc/hosts

**Løysing:**
```bash
# macOS Ventura+ krever Full Disk Access for Terminal
# 1. System Preferences → Privacy & Security → Full Disk Access
# 2. Legg til Terminal.app
# 3. Restart Terminal
```

### Windows: "Access denied" i WSL

**Løysing:**
```bash
# Køyr med sudo:
sudo ansible-pull ...
```

### Git clone feiler

**Løysing A: Bruk file:// path**
```bash
# Mac: Mount devserver via Finder først
# Windows WSL: Mount via SMB

sudo mount -t cifs //192.168.68.29/Development /mnt/devserver -o user=thusby
```

**Løysing B: Bruk SSH**
```bash
# Sett opp SSH keys først:
ssh-copy-id thusby@devserver.localfarm.no

# Deretter:
git clone thusby@devserver.localfarm.no:/home/thusby/Development/localfarm/localfarm-client-config
```

---

## Avinstallering

### Mac

```bash
# Stop og fjern LaunchDaemon
sudo launchctl unload /Library/LaunchDaemons/no.localfarm.ansible-pull.plist
sudo rm /Library/LaunchDaemons/no.localfarm.ansible-pull.plist

# Fjern script
sudo rm /usr/local/bin/localfarm-ansible-pull

# Fjern frå /etc/hosts (manuelt)
sudo nano /etc/hosts
# Slett seksjonen mellom:
# # BEGIN LOCALFARM MANAGED HOSTS
# ...
# # END LOCALFARM MANAGED HOSTS
```

### Linux/WSL

```bash
# Fjern cron job
sudo crontab -e
# Slett linja med "ansible-pull"

# Fjern script
sudo rm /usr/local/bin/localfarm-ansible-pull

# Fjern frå /etc/hosts (same som Mac)
```

---

## Neste steg etter vellykka test

1. **Push til GitHub:**
   ```bash
   cd /home/thusby/Development/localfarm/localfarm-client-config
   git remote add origin https://github.com/thusby/localfarm-client-config.git
   git push -u origin main
   ```

2. **Test frå GitHub:**
   ```bash
   # På Mac:
   curl -fsSL https://raw.githubusercontent.com/thusby/localfarm-client-config/main/scripts/bootstrap.sh | bash
   ```

3. **Legg til nye maskiner:**
   - Køyr bootstrap-script
   - Venter 60 min, eller force update: `sudo /usr/local/bin/localfarm-ansible-pull`

4. **Oppdater DNS-mappings:**
   - Rediger `network_registry.yml` i `infrastructure` repo
   - Sync til `client-config` repo
   - Alle klientar oppdaterer seg automatisk innan 60 min
