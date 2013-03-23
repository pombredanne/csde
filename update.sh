#!/usr/bin/env bash

# fix the bug
# Warning: can not check `/etc/sudoers` for `secure_path`, falling back to call via `/usr/bin/env`, 
# this breaks rules from `/etc/sudoers`. export rvmsudo_secure_path=1 to avoid the warning.
export rvmsudo_secure_path=1

rvmsudo git pull --no-commit
