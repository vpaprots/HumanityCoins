#!/bin/bash

################################################################################################
#                                                                                              #
# Shell script to deploy humanity chaincode to a single peer, and test out the chaincode's     #
# different functions.                                                                          #
#                                                                                              #	
# Laszlo Szoboszlai                                                                            #
# 24/08/2016                                                                                   #
################################################################################################

#TODO : check if PATHs are correct
export GOROOT=/root/go
export GOPATH=/root/git
#export HLDGPATH=/root/git/src/github.com/hyperledger/fabric/build/bin
export HLDGPATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin
export CCROOT=/root/humanity

RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

#pass counter
PASS=0
#Clear things up:
clear
read -p "This script will stop all running peers. Are you sure?(y/n)" -n 1 -r
echo 
if [[ $REPLY =~ ^[Yy]$ ]] 
then
	echo Clearing things up...
	echo Kill all previous processes
	killall node > /dev/null 2>&1
	killall peer > /dev/null 2>&1
	killall membersrvc > /dev/null 2>&1

	echo Delete all previous values in Ledger Database... 
	rm -rf /var/hyperledger/production
	
	echo Docker clean up:
	docker stop $(docker ps -a -q)  > /dev/null 2>&1      #stop all containers
	docker rm $(docker ps -a -q)  > /dev/null 2>&1 		#remove all containers
	#docker rmi $(docker images | grep dev-test) > /dev/null 2>&1    #remove all dev-test images
	docker rmi dev-jdoe-0020b9277a4f1809bed5f9e3d65b0fe58e7032782bb7c6f1855da7049e851659e69be790a5324d431d0859c91fdd075f63b0cebe4edf662ba3d6b641dce64cd6 
	 TIMESTAMP=$(date +%d-%m-%Y-%H%M%S)
   	 cd $CCROOT/logs
   	 mkdir $TIMESTAMP
   	 mv *.log $TIMESTAMP > /dev/null 2>&1
    	if [ $? -eq 0 ]; 
	then
        	echo -e  "${CYAN}Previous log files copied to $TIMESTAMP folder${NC}"
	else
      		echo There were no previous log files.
    	fi
else 
    exit 1 
fi

cd $HLDGPATH
peer node start --logging-level=debug > $CCROOT/logs/test_peer.log 2>&1 &
sleep 5
echo -e "${RED}Peer logs at $CCROOT/logs/test_peer.log ${NC}"
echo

CHAIN_NAME=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -c '{"Function":"Init", "Args": ["Ben","99","Alice","20"]}'`
echo $CHAIN_NAME >> $CCROOT/logs/test_cc.log
echo
echo -e "${RED}Init - Chaincode Name = $CHAIN_NAME ${NC}"
sleep 30
echo

#check userlist
echo "Query registered users:"
USERS=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getKeys", "Args": []}'`
echo "returned:  $USERS"
echo "expected:  {\"keys\":[\"Ben\",\"Alice\"]}"
if [ $USERS = "{\"keys\":[\"Ben\",\"Alice\"]}" ]
then
echo -e "${CYAN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi

echo
#check Ben points 
echo -e "${RED}Checking Ben's points: ${NC}"
echo HumanityCoins Chaincode - Query...
BALANCE=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getUser", "Args": ["Ben"]}'`
sleep 5
echo "returned $BALANCE"
echo "expected: {\"name\":\"Ben\",\"balance\":99,\"thank\":[]}"
if [ $BALANCE = "{\"name\":\"Ben\",\"balance\":99,\"thank\":[]}" ]
then
echo -e "${CYAN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi


#add a ta to Ben's thanklist 
echo
echo -e "${RED}Invoke : Add a ta(1 point) to Ben's points: ${NC}"
echo HumanityCoins Chaincode - Invoke...
CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode invoke -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"addThanks", "Args": ["Ben","{\"name\":\"Sam\",\"type\":\"ta\",\"message\":\"for being good\"}"]}'
sleep 5

#check Ben points again
echo
echo HumanityCoins Chaincode - Query...
NEW_BALANCE=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getUser", "Args": ["Ben"]}'`
sleep 5
echo "returned : $NEW_BALANCE"
EXPECTED="{\"name\":\"Ben\",\"balance\":100,\"thank\":[{\"name\":\"Sam\",\"type\":\"ta\",\"message\":\"for being good\"}]}"
echo "expected : $EXPECTED"
EXPECTEDLENGTH=$(printf "%s" "$EXPECTED"| wc -c)
BALANCELENGTH=$(printf "%s" "$NEW_BALANCE"| wc -c) 
if [ $BALANCELENGTH = $EXPECTEDLENGTH ]
then
echo -e "${CYAN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi

echo TESTS PASSED: $PASS /3











