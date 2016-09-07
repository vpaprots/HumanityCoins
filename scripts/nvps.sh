#!/bin/bash
####################################################################################################
#                                                                                                  #
# Shell script to start up 2 non validating peers using their .env files as environment variables. #
# Prerequisits: validating peer(s) running on the address defined in the .env files, this script   #
# should be run on a different machine to that, as it kills previous peer processes.               #
#                                                                                                  #
# Laszlo Szoboszlai # 16/08/2016                                                                   #
####################################################################################################

#TODO : check if PATHs are correct
export NODEPATH=/root/ibm/node/bin 
export GOROOT=/root/go 
export GOPATH=/root/git 
export HLDGPATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin 
export PATH=$PATH:$GOPATH/src/github.com/hyperledger/fabric 
export PATH=$PATH:/root/git/src/github.com/hyperledger/fabric/build/bin
export CCROOT=/root/humanity



#Clear things up:
	
echo Clearing things up... 
echo Kill all previous processes 
killall node > /dev/null 2>&1 
killall peer > /dev/null 2>&1 
killall membersrvc > /dev/null 2>&1 echo 
Delete all previous values in Ledger Database... 
rm -rf /var/hyperledger/production/client
	
echo Docker clean up: 
docker stop $(docker ps -a -q) #stop all containers 
docker rm $(docker ps -a -q) #remove all containers 
docker rmi $(docker images | grep dev-test) > /dev/null 2>&1 #remove all dev-test images 


cd $HLDGPATH
#Start non validating peers, each with its own .env file
echo "Starting non validating peers:" 
echo "Starting HyperLedger Fabric NON Validating Peer 1/2" 
docker run --rm --env-file $CCROOT/env/nvp0.env szlaci83/humanitycoins_peer peer node start --logging-level=debug >  $CCROOT/logs/nvp0.log 2>&1 & 
sleep 2 

echo "Starting HyperLedger Fabric NON Validating Peer 2/2" 
docker run --rm --env-file $CCROOT/env/nvp1.env szlaci83/humanitycoins_peer peer node start --logging-level=debug >  $CCROOT/logs/nvp1.log 2>&1 & 
sleep 2 
echo 

echo login an auditor
CORE_PEER_ADDRESS=172.17.0.2:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer network login test_auditor0 -p password0
sleep 5



echo Demo ready, users can log in using: