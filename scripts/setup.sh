#!/bin/sh

echo "hi"
npm i
echo "npm i"
dfx identity new codespace_dev --storage-mode=plaintext
dfx identity use codespace_dev
echo "identity crap done"
dfx start --background
echo "dfxx start background done"
dfx stop
echo "dfxx stop background done"
npm i -g ic-mops
echo "npm"
mops install
echo "mops install"

sleep infinity