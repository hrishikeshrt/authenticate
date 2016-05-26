# IITK ironport and fortigate Authentication

### Greasemonkey Script for IronPort Authentication at IIT Kanpur

* You need following extensions to use this script
- **Firefox**: [Greasemonkey](https://addons.mozilla.org/en-US/firefox/addon/greasemonkey/)
- **Google Chrome**: [Tampermonkey](https://chrome.google.com/webstore/detail/tampermonkey/dhdgffkkebhmkfjojejmpbldmpobfkfo?hl=en)

## Shell Scripts

### Bash Script for Ironport Authentication
- cp shell/ironport.sh {somewhere/in/path}

### Router suitable versions
- cp shell/*-router.sh {somewhere/in/path}

## Daemon

This is based on ubuntu's upstart

### Install
- cd ubuntu/upstart
- chmod +x install.sh
- ./install.sh -i

After this, you can start/stop services using "sudo start ironport", "sudo stop fortigate" etc. (initctl)
