#!/bin/bash

openssl ec -in ../chainend/nodejs-sdk/packages/cli/conf/accounts/$1.pem -text -noout | sed -n '7,11p' | tr -d ": \n" | awk '{print substr($0,3);}' | ../chainend/utils/keccak-256sum -x -l | tr -d ' -' | tail -c 41