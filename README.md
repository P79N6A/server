```
mkdir -p ~/src ~/web/log
cd ~/src
git clone https://gitlab.com/ix/pw
cd pw
sh install
cd ~/web
ln -s ../src/pw/config .conf
~/src/pw/sh/pw
```
