so you want a personal webserver:
### get source
``` sh
mkdir ~/src
cd ~/src
git clone https://gitlab.com/ix/pw
```
### install
install can be run as root or a regular user account. on Android+Termux the latter is the only option.
on a "Desktop distro", Ruby gem/bundler can be configured for user install in homedir. increasingly the default config. if not,

``` sh
export GEM_HOME=$HOME
export PATH=$PATH:$HOME/bin
```