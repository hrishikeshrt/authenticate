# IITK ironport and fortigate Authentication

## Python Script

Python script has been, and will continue to be, available at Gist: https://gist.github.com/hrishikeshrt/cc71b97077ab1018c4c9bbe22b85c2fa

```
python3 authenticator.py
```

## Greasemonkey Script for IronPort Authentication at IIT Kanpur

* You need following extensions to use this script
- **Firefox**: [Greasemonkey](https://addons.mozilla.org/en-US/firefox/addon/greasemonkey/)
- **Google Chrome**: [Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=en)

## Shell Scripts

### Bash Script for Ironport Authentication (old)
- ``cp shell/ironport.sh {somewhere/in/path}``

### Router suitable versions
Tested with TP-Link WR841N router. Needs ``curl`` installed.

Modified version of original fortigate-gateway shell script by [vikraman](https://github.com/vikraman/firewall-auth-sh)

- ``cp shell/*-router.sh {somewhere/in/path}``

### Android
This will require you to have some sort of terminal emulator available. 
 
**Termux** is possibly the best terminal emulator around [Termux on Google Play](https://play.google.com/store/apps/details?id=com.termux).

- ``start_auth.sh`` and ``kill_auth.sh`` can invoke and kill authentication daemons.
- ``start_auth.sh`` assumes that your ``-android.sh`` scripts are located in ``${HOME}/bin``

### Getting SSH Access to your phone with Termux 
Put your public-key of PC that you want to access phone from, into your phone's storage somewhre.

- ``apt install openssh``
- ``cat {path_to_pubkey} >> ~/.ssh/authorized_keys``
- ``sshd``

Now, from your PC, ``ssh -p 8022 {phone_ip}``.

## As Ubuntu daemons

This is based on ubuntu's upstart / systemd

### Install
- ``cd ubuntu/upstart`` OR ``cd ubuntu/upstart``
- ``chmod +x install.sh``
- ``./install.sh -i``

For upstart, you can start/stop services using ``sudo start ironport``, ``sudo stop fortigate`` etc. (``initctl``)
For systemd, you can start/stop services using ``sudo service ironport start``, ``sudo service fortigate stop`` etc. (``systemctl``)
