### get source
``` sh
dest=$HOME/src
mkdir $dest
cd $dest
git clone https://gitlab.com/ix/pw
cd pw
```
### install
install can be run as root or a regular user account. on Android+Termux the latter is the only option.
on a "Desktop distro" installing as ordinary user, be sure to scope your ruby library paths to $HOME 

``` sh
export GEM_HOME=$HOME
export PATH=$PATH:$HOME/bin
sh install
```
