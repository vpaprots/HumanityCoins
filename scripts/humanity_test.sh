#!/bin/bash

################################################################################################
#                     								               #
#                        Unit test for HumanityCoins Chaincode                                 #
#			                                                                       #
# The script will clear up the environment and deploy the HumanityCoins chaincode to a single  #
# peer, and test out the chaincode's different functions.                                      #
#                                                                                              #	
# Laszlo Szoboszlai                                                                            #
# 05/09/2016                                                                                   #
################################################################################################

Spinner () {
  i=1
  sp="/-\|"
  echo -n ' '
  ITERATION=$1
  ITERATION=$[ITERATION*10]
  while [ $i -lt $ITERATION ]
  do
    sleep 0.1
    printf "\b${sp:i++%${#sp}:1}"
  done
}

Banner () {
 echo -e "${CYAN}##################################################################################################"
 echo -e "#                               Unit test for HumanityCoins Chaincode                            #"
 echo -e "#    This script will deploy humanity chaincode to a single peer, and try to invoke and verify   #"
 echo -e "#    all chaincode functions via the CLI. At every test it will say if it has passed or failed,  #"
 echo -e "#    and at the end it will tell the summary as well. The test will take approx. 1 minute.       #"
 echo -e "##################################################################################################${NC}"
}


export GOROOT=/root/go
export GOPATH=/root/git
export HLDGPATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin
export CCROOT=/root/humanity

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
Banner

echo -e "${RED}"
#pass counter
PASS=0
#Clear things up:
read -p "This script will stop all running peers, and stop all running docker containers. Are you sure?(y/n)" -n 1 -r
echo -e "${NC}"
if [[ $REPLY =~ ^[Yy]$ ]] 
then
	echo -e "${CYAN}Clearing things up...${NC}"
	echo "-kill all previous processes 1/3"
	killall node > /dev/null 2>&1
	killall peer > /dev/null 2>&1
	killall membersrvc > /dev/null 2>&1
	
	sleep 2
	echo "-Docker clean up 2/3"
	docker stop $(docker ps -a -q)  > /dev/null 2>&1                #stop all containers
	docker rm $(docker ps -a -q)  > /dev/null 2>&1 	        	#remove all containers
	docker rmi $(docker images | grep dev-test) > /dev/null 2>&1    #remove all dev-test images
	docker rmi $(docker images | grep dev-jdoe) > /dev/null 2>&1    #remove all dev-jdoe images
	
	sleep 2
	echo "-delete all previous values in ledger database 3/3"
        rm -rf /var/hyperledger/production

	sleep 2
	echo "Archiving previous log files."
	TIMESTAMP=$(date +%d-%m-%Y-%H%M%S)
   	cd $CCROOT/logs
   	mkdir $TIMESTAMP
   	mv *.log $TIMESTAMP > /dev/null 2>&1
    	if [ $? -eq 0 ]; 
	then
        	echo -e  "${CYAN}Previous log files copied to $CCROOT/logs/$TIMESTAMP folder${NC}"
	else
      		echo -e "{CYAN}There were no previous log files.${NC}"
    	fi
else 
    exit 1 
fi

echo
echo -e "${GREEN}ENVIRONMENT READY FOR UNIT TESTS.${NC}"
sleep 5 

clear 
Banner

echo
echo -e "${CYAN}Starting a hyperledger peer.${NC}"
cd $HLDGPATH
peer node start --logging-level=debug > $CCROOT/logs/test_peer.log 2>&1 &
sleep 5
echo -e "${RED}Peer logs at $CCROOT/logs/test_peer.log${NC}"
echo

echo -e  "${CYAN}Testing HumanityCoins chaincode functions:${NC}"
echo -e "${RED}Deploying chaincode(registering users Ben with 99 and Alice with 20 points):${NC}"
CHAIN_NAME=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -c '{"Function":"Init", "Args": ["Ben","99","Alice","20"]}'`
echo $CHAIN_NAME >> $CCROOT/logs/test_cc.log
echo
echo -e "${RED}Chaincode hash = $CHAIN_NAME ${NC}"
echo -e "${CYAN}Waiting for docker to spin up containers...${NC}"
Spinner 30
echo

#check userlist
echo -e "${RED}Query registered users from ledger: ${NC}"
USERS=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getKeys", "Args": []}'`
echo "returned:  $USERS"
echo "expected:  {\"keys\":[\"Ben\",\"Alice\"]}"
if [ $USERS = "{\"keys\":[\"Ben\",\"Alice\"]}" ]
then
echo -e "${GREEN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi

echo
#check getRandomUser method
echo -e "${RED}Return a random user from ledger: ${NC}"
RUSER=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getRandomUser", "Args": []}'`
echo "returned:  $RUSER"
echo "expected:  {\"keys\":[\"Ben\"]} or {\"keys\":[\"Alice\"]}"
if [ $RUSER = "{\"keys\":[\"Ben\"]}" ] || [ $RUSER = "{\"keys\":[\"Alice\"]}" ]
then
echo -e "${GREEN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi

echo
#check Ben points 
echo -e "${RED}Checking Ben's points:${NC}"
BALANCE=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getUser", "Args": ["Ben"]}'`
sleep 2
echo "returned $BALANCE"
echo "expected: {\"name\":\"Ben\",\"balance\":99,\"thank\":[]}"
if [ $BALANCE = "{\"name\":\"Ben\",\"balance\":99,\"thank\":[]}" ]
then
echo -e "${GREEN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi


#add a ta to Ben's thanklist 
echo
echo -e "${RED}Invoke : Add a ta(1 point) to Ben's thanklist from Sam with message:for being good${NC}"
TA=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode invoke -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"addThanks", "Args": ["Ben","{\"name\":\"Sam\",\"type\":\"ta\",\"message\":\"for being good\"}"]}'`
echo $TA
sleep 2
echo

echo -e "${RED}Ben's balance again to see the change:${NC}"
NEW_BALANCE=`CORE_PEER_ADDRESS=0.0.0.0:30303 peer chaincode query -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getUser", "Args": ["Ben"]}'`
sleep 2
echo "returned : $NEW_BALANCE"
EXPECTED="{\"name\":\"Ben\",\"balance\":100,\"thank\":[{\"name\":\"Sam\",\"type\":\"ta\",\"message\":\"for being good\"}]}"
echo "expected : $EXPECTED"
EXPECTEDLENGTH=$(printf "%s" "$EXPECTED"| wc -c)
BALANCELENGTH=$(printf "%s" "$NEW_BALANCE"| wc -c) 
if [ $BALANCELENGTH = $EXPECTEDLENGTH ]
then
echo -e "${GREEN}PASSED ${NC}"
PASS=$[PASS+1]
else echo -e "${RED}FAILED ${NC}"
fi

if [ $PASS -lt 4 ]
then 
echo -e "${RED}"
else echo -e "${GREEN}"
fi

echo TESTS PASSED: $PASS /4
echo -e "${NC}"
