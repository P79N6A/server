### get source
``` sh
dest=$HOME/src
mkdir $dest
cd $dest
git clone https://gitlab.com/ix/pw
cd pw
```
### install
run install as superuser (system install) or regular user (on Android/Termux the only option)
``` sh
export GEM_HOME=$HOME
export PATH=$PATH:$HOME/bin
sh install
```
