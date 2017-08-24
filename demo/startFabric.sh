#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -e

starttime=$(date +%s)

if [ ! -d ~/.hfc-key-store/ ]; then
	mkdir ~/.hfc-key-store/
fi
cp $PWD/creds/* ~/.hfc-key-store/
# launch network; create channel and join peer to channel
cd basic-network
./start.sh

# Now launch the CLI container in order to install, instantiate chaincode
# and prime the ledger with two users bob and alice with 20 and 10 initial points 
docker-compose -f ./docker-compose.yml up -d cli

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode install -n humanity -v 1.0 -p github.com/humanity
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n humanity -v 1.0 -c '{"Args":["alice","10", "bob","20"]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
sleep 10
# invoke the addThank method to simulate a medium thank (5 points) is given from bob to alice in the system
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp" cli peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n humanity -c '{"Function":"addThanks", "Args": ["bob","{\"name\":\"alice\",\"type\":\"thankyou\",\"message\":\"for being good\"}"]}'

printf "\nTotal execution time : $(($(date +%s) - starttime)) secs ...\n\n"
