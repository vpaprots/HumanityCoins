#!/bin/bash
################################################################################################
#                                                                                              #
# Shell script to start up 4 validating peers using their .env files as environment variables. #
# Deploy humanity chaincode to the ledger, and write the hash received to a file.              #
#                                                                                              #	
# Laszlo Szoboszlai                                                                            #
# 16/08/2016                                                                                   #
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

	echo Docker clean up:
	docker stop $(docker ps -a -q)  > /dev/null 2>&1      #stop all containers
	docker rm $(docker ps -a -q)  > /dev/null 2>&1 		#remove all containers
	#docker rmi $(docker images | grep dev-test) > /dev/null 2>&1    #remove all dev-test images 
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
	
	sleep 5
	#Delete all previous values in Ledger Database
	rm -rf /var/hyperledger/production


else 
    exit 1 
fi

#Copy most recent chaincode to Fabric handler
#cd $CCROOT/humanity
#\cp -u humanity.go ~/git/src/github.com/hyperledger/fabric/examples/chaincode/go/humanity/humanity.go

cd $HLDGPATH
#Start Membership and Security Services
echo "Starting Membership and Security Server.."
./membersrvc > $CCROOT/logs/MemberSrvc.log 2>&1 &

#Start validating peers, each with its own .env file
echo "Starting validating peers:"
#VP0:
echo "Starting HyperLedger Fabric Validating Peer 1/4"
docker run --rm -p 0.0.0.0:30303:30303 --env-file $CCROOT/env/vp0.env hyperledger/fabric-peer peer node start > $CCROOT/logs/vp0.log 2>&1 &
echo "Waiting for initialization..."
sleep 10

#VP1:
echo "Starting HyperLedger Fabric Validating Peer 2/4"
docker run --rm --env-file $CCROOT/env/vp1.env hyperledger/fabric-peer peer node start  > $CCROOT/logs/vp1.log 2>&1 &
echo "Waiting for initialization..."
sleep 20

#VP2:
echo "Starting HyperLedger Fabric Validating Peer 3/4"
docker run --rm --env-file $CCROOT/env/vp2.env hyperledger/fabric-peer peer node start >  $CCROOT/logs/vp2.log 2>&1 &
echo "Waiting for initialization..."
sleep 10

#VP3:
echo "Starting HyperLedger Fabric Validating Peer 4/4"
docker run --rm --env-file $CCROOT/env/vp3.env hyperledger/fabric-peer peer node start >  $CCROOT/logs/vp3.log 2>&1 &
echo "Waiting for initialization..."
sleep 10

echo login JIM to deploy
CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer network login jim -p 6avZQLwcUe9b
sleep 5

echo "deploying HumanityCoins chaincode:"
CHAIN_NAME=`CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer chaincode deploy -u jim -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -c '{"Function":"Init", "Args": ["Laszlo","100","Juci","100"]}'`

#echo ex02
#CHAIN_NAME=`CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer chaincode deploy -u jim -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Function":"init", "Args": ["a","100", "b", "200"]}'`


#write chaincode hash to file
echo $CHAIN_NAME >> $CCROOT/logs/chain_name.log

echo -e "${CYAN}HumanityCoins chain:$CHAIN_NAME ${NC}"

echo "Humanity chaincode ready." 
