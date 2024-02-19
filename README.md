# mkiso

Create a bootable Debian ISO with a preseed file embedded for fully automatic installation and configuration.

**mkiso** supports Debian 9, 10, 11 and 12 amd64/arm64 images.

Can it do LUKS encrypted drives? *Absolutely!*
How about encrypted `/boot` support? *Youbetcha!*

All you need to get started is a netinst iso from the Debian page:
https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/


----

Use the resulting ISO images for:

  - Creating KVM virtual machines in [Proxmox](https://proxmox.com/en/proxmox-virtual-environment/overview) (amd64)
  - Creating KVM virtual machines in MacOS using [UTM](https://github.com/utmapp/UTM) (arm64)
  - Installing Debian on Lenovo P50, x230 and x200 or other workstations
  - Whatever else you want to install Debian on ..within reason of course :)

I prefer to use preseed for initial convenience setup: installing common packages, configure ssh, set passwords, set vim as default.

After installation, I run [Anisble playbooks](https://docs.ansible.com/ansible/latest/playbook_guide/index.html) to provision any services the machines will be used for.

If you _really_ wanted to, you could configure the preseed file to fully provision any desired services instead.

## Requirements
1. Be logged in to a Debian based machine.

2. Install prerequisites:

        $ sudo apt install git whois xorriso

The `whois` package is not required but provides **mkpasswd** which is useful for generating password hashes.

## Installation
The following method uses [git worktrees](https://git-scm.com/docs/git-worktree) -- Totally optional.

With the git worktree method, you can use/modify local branches with custom variables and preseed files while keeping the main branch clean.

1. Create directory:

        $ mkdir mkiso

2. Change to the new directory:

        $ cd mkiso
3. Clone the bare repo to a `.git` directory:

        $ git clone --bare git@github.com:cn246-admin/mkiso.git .git

4. Create a worktree of the main branch (optional):

        $ git worktree add main

4. Create a worktree branch:

        $ git worktree add local

5. Change to the `local` dir:

        $ cd local

6. Do your work in there :)


## Usage Instructions
1. Edit one (or all) of the included preseed files with your preferences for the Debian version:

        files/preseed_files/kvm-bookworm-encrypted.cfg
        files/preseed_files/kvm-bookworm.cfg
        files/preseed_files/kvm-bullseye-encrypted.cfg
        files/preseed_files/kvm-bullseye.cfg
        files/preseed_files/kvm-buster-encrypted.cfg
        files/preseed_files/kvm-buster.cfg
        files/preseed_files/kvm-stretch-encrypted.cfg
        files/preseed_files/kvm-stretch.cfg
        files/preseed_files/utm-bookworm-encrypted.cfg
        files/preseed_files/utm-bookworm.cfg
        files/preseed_files/utm-bullseye.cfg
        files/preseed_files/workstation-bookworm-encrypted_boot.cfg
        files/preseed_files/workstation-bullseye-encrypted.cfg
        files/preseed_files/workstation-bullseye-encrypted_boot.cfg
        files/preseed_scriptsdt/encrypt_boot   # script to encrypt boot and update the LUKS password
        files/preseed_scripts/in-target_final  # shell scripts to run on the fresh installation
        files/preseed_scripts/fde_passphrase   # file to set permanent encrypted boot password
        files/preseed_scripts/temp_passphrase  # file should contain same LUKS password defined in the preseed.cfg

2. Download an ISO image using the included script:

        # Get lastest amd64 iso
        $ ./get_lastest_iso amd64
        
        # Get lastest arm64 iso
        $ ./get_lastest_iso arm64


3. Embed the preseed file to the ISO:

        ./mkiso debian-12.4.0-arm64-netinst.iso


4. Check the output directory for the results:

        $ ls -1 ./output
        Debian-12.4.0-PRESEED-kvm.iso
        Debian-12.4.0-PRESEED-kvm_encrypted.iso
        Debian-12.4.0-PRESEED-utm.iso
        Debian-12.4.0-PRESEED-ws-full_encrypted.iso
        SHA512SUMS

5. Upload the ISO wherever you want to use it (or add it to a USB stick).

6. Boot the ISO - It should automatically select the GRUB menu item and install. No user input necessary.


## Variables
The `mkiso` script has variables at the top that can (and probably should) be defined:
```bash
username=""
fullname=""
hostname="unassigned-hostname"
ntp_server="pool.ntp.org"
domain="unassigned-domain"
sha_hash='$6$WjjqADCT0feX14dj$92eqN/ppL2gEZhU6Mcua5QOAaY5BPkt5GDRQKEUt9Y0UDABX9fo1XVI6BTkv4bYH36IWhZovdG/uMDhckAwvI0'
yes_hash='$y$j9T$CdKjTO4U8eKs4Pz3tgtCl.$Qqd7a5bMDx5oU3bM6ur6zWmJ6fRSoJFyVpjBxu4oaH/'
```

### Password Hashes
User passwords are hashed with the following commands:

  - Debian Buster and below:

        mkpasswd -m sha-512 -S $(pwgen -ns 16 1) mypassword

  - Bullseye and above:

        mkpasswd -m yescrypt -R 11

Add the output of the **mkpasswd** command to the appropriate `_hash` variable in the script.


## LUKS
> NOTE:
> Currently, the LUKS password is only changed on encrypted boot installations.
> You will have to update the LUKS password manually on non-encrypted boot installs.
> I need to create a script to do this for non-encrypted boots.

The encryption password is set in cleartext in the preseed file then changed during the `encrypt_boot` preseed step.

The `preseed.cfg` entry:
```
d-i partman-crypto/passphrase password mypassword
d-i partman-crypto/passphrase-again password mypassword
```

Two files are required to change the encryption password during preseeding.
`temp_passphrase` and `fde_passphrase`

The formatting of these files is very important!
They should be formatted as ASCII text, with no line terminators.

To accomplish this, you can use the following command:
```bash
# create file containing temp passphrase from preseed.cfg
printf '%s' "mypassword" > ./files/preseed_scripts/temp_passphrase

# create file containing desired fde passphrase
printf '%s' "Sup3R8p4s5wErd" > ./files/preseed_scripts/fde_passphrase
```


## Further Details
The **mkiso** script unpacks the iso, then copies over the files from the `preseed_files` directory, which includes post-install scripts and the FDE passphrase.

It then adds a preseed.cfg to the initrd, generates new MD5 sums, copies the MBR from the ISO and creates a new ISO.

The preseed.cfg file installs the following packages which you can update as you see fit:
```
d-i pkgsel/include string bash-completion curl git gnupg gnupg-agent \
    python3-apt qemu-guest-agent stow screen spice-vdagent vim wget
```

There is more preseed goodness at the bottom of the preseed.cfg files where the *late_command* string runs commands on the OS to further configure it.

If you opt for encrypted boot, the preseed file sets a temporary FDE passphrase and calls the **encrypt_boot** script.

The **encrypt_boot** script adds the FDE key to `/root/keys/scrap` and uses the passphrase files to add the desired passphrase and remove the temporary passphrase.

The passphrase echoed to cryptsetup and any key files read to read in typed passphrases *must not* have a line break (unless the typed passphrase will somehow also have a line break).

Add any additional shell commands you would like to run on the system to the **in_target_final** script.

In it's current form:
- Home directory permissions are set
- Sets default editor to vim
- Enables vi mode for the created user's terminal
- Created user is added to the **adm** group
- Passwordless SSH is configured with SSH public keys for the created user

The sky is really the limit with what is possible..

## Contributing
I look forward to receiving constructive criticism and/or ideas on how to improve my code.

Feel free to create issues or pull requests and I'll be sure to respond.
