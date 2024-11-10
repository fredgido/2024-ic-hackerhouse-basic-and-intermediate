#!/bin/sh

echo "hi"
npm i
echo "npm i"
dfx identity new local_dev_fredgido --storage-mode=plaintext
dfx identity use local_dev_fredgido
echo "identity crap done"
dfx start --background
echo "dfxx start background done"
dfx stop
echo "dfxx stop background done"
#npm set progress=true &&  npm i -g ic-mops --verbose
#echo "npm"
#mops install
#echo "mops install"

sleep infinity