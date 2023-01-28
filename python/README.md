# Firewall Authenticator

Improved version of the firewall authentication script.

* Structured
* Python3 Compatible
* Importable `FirewallAuthenticator` class that simulates the finite state machine

## Usage

```
usage: authenticator.py [-h] [-u USERNAME] [-p PASSWORD] [-n] [-v] [--error-retry ERROR_RETRY] [--login-retry LOGIN_RETRY] [--keep-alive KEEP_ALIVE]

Firewall Authenticator

optional arguments:
  -h, --help            show this help message and exit
  -u USERNAME, --username USERNAME
                        Username (default: None)
  -p PASSWORD, --password PASSWORD
                        Password (default: None)
  -n, --netrc           Read credentials from netrc file (default: False)
  --error-retry ERROR_RETRY
                        Retry interval (in case of an error) (default: 10)
  --login-retry LOGIN_RETRY
                        Retry interval (if already logged in) (default: 30)
  --keep-alive KEEP_ALIVE
                        Keep alive interval (default: 180)
  -v, --verbose         Print debugging information (default: False)
```

## Usage in other scripts

```
from authenticator import FirewallAuthenticator

username = None
password = None

Authenticator = FirewallAuthenticator(username, password)
```

Check `main()` for more detailed usage.

