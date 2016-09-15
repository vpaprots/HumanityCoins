#!/bin/bash
####################################################################################################
#                                                                                                  #
# Shell script to start up 2 non validating peers using their .env files as environment variables. #
# Prerequisits: HSBN (High Security Business Network) or a simulation running on the address       #
# defined in the .env file (nvp0.env and nvp1.env)                                                 #
#												   #											
# Laszlo Szoboszlai # 12/09/2016                                                                   #
####################################################################################################

export GOROOT=/root/go 
export GOPATH=/root/git 
export HLDGPATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin 
export PATH=$PATH:$GOPATH/src/github.com/hyperledger/fabric 
export PATH=$PATH:/root/git/src/github.com/hyperledger/fabric/build/bin
export CCROOT=/root/humanity

RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

Banner () {
 echo -e "${CYAN}##################################################################################################"
 echo -e "#             This script will start up 2 non validating Hyperledger fabric peers                #"
 echo -e "#      connecting to a HSBN (or a simulation) and log in 2 users. Deploy HumanityCoins           #"
 echo -e "#                 chaincode remotely, and try to invoke some of its functions                    #"
 echo -e "##################################################################################################${NC}"
}

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

#Clear things up:
clear
Banner
echo -e "${RED}"
read -p "This script will stop all running peers. Do you wish to continue?(y/n)" -n 1 -r
echo -e "${NC}"
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
        clear
        Banner
        echo Clearing things up:
        echo -Kill all previous processes 1/3
        killall node > /dev/null 2>&1
        killall peer > /dev/null 2>&1
        killall membersrvc > /dev/null 2>&1
        sleep 2

        echo -Docker clean up 2/3
        docker stop $(docker ps -a -q)  > /dev/null 2>&1                #stop all containers
        docker rm $(docker ps -a -q)  > /dev/null 2>&1                  #remove all containers
        docker rmi $(docker images | grep dev-test) > /dev/null 2>&1    #remove all dev-test images
        docker rmi $(docker images | grep dev-jdoe) > /dev/null 2>&1    #remove all dev-jdoe images
        sleep 2

        echo -Delete all previous values in Hyperledger database 3/3
        rm -rf /var/hyperledger/production/client

        TIMESTAMP=$(date +%d-%m-%Y-%H%M%S)
        cd $CCROOT/logs
        mkdir $TIMESTAMP
        mv *.log $TIMESTAMP > /dev/null 2>&1
               if [ $? -eq 0 ];
               then
                       echo -e  "${CYAN}Previous log files copied to $CCROOT/logs/$TIMESTAMP folder${NC}"
               else
                       echo There were no previous log files.
               fi

else
    exit 1
fi

echo
echo -e "${CYAN}Environment ready for starting the NON validating peers.${NC}"

#copy most recent chaincode to Fabric handler
cd $CCROOT/humanity
cp -u humanity.go ~/git/src/github.com/hyperledger/fabric/examples/chaincode/go/humanity/humanity.go

echo
cd $HLDGPATH
#Start non validating peers, each with its own .env file
echo "Starting non validating peers:" 
echo "Starting HyperLedger Fabric NON Validating Peer 1/2" 
docker run --rm -p 0.0.0.0:50051:50051 -p 0.0.0.0:30303:30303 --env-file $CCROOT/env/nvp0.env szlaci83/humanitycoins_peer peer node start --logging-level=debug >  $CCROOT/logs/nvp0.log 2>&1 & 
sleep 2 

echo "Starting HyperLedger Fabric NON Validating Peer 2/2" 
docker run --rm --env-file $CCROOT/env/nvp1.env szlaci83/humanitycoins_peer peer node start --logging-level=debug >  $CCROOT/logs/nvp1.log 2>&1 & 
sleep 2 
echo 

echo -e "${CYAN}Logging users in:${NC}"

echo -e "${CYAN}login a test auditor 1/2${NC}"
CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer network login test_auditor0 -p password0
sleep 2

echo -e "${CYAN}log JIM in 2/2${NC}"
CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer network login jim -p 6avZQLwcUe9b
sleep 2
echo

echo -e "${CYAN}JIM deploying HumanityCoins chaincode remotely:(Initiating Ben and Sam both with 100 HumanityCoins)"
echo -e "NOTE:The chaincode will not start in a docker container on this machine as only NON-validating peers hosted."
echo -e "This will take about a minute or two to start containers on remote host.${NC}"
CHAIN_NAME=`CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer chaincode deploy -u jim -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -c '{"Function":"Init", "Args": ["Ben","100","Sam","100"]}'`
Spinner 100
echo

echo "Writing chaincode hash to file: $CCROOT/logs/chain_name.log"
echo $CHAIN_NAME >> $CCROOT/logs/chain_name.log

echo -e "${CYAN}HumanityCoins chain:$CHAIN_NAME ${NC}"
echo

echo -e "${CYAN}Attempting to query the chaincode:(get a userlist)${NC}"
USERS=`CORE_PEER_ADDRESS=0.0.0.0:30303 CORE_SECURITY_ENABLED=true CORE_SECURITY_PRIVACY=true peer chaincode query -u jim -p github.com/hyperledger/fabric/examples/chaincode/go/humanity -n $CHAIN_NAME -c '{"Function":"getKeys", "Args": []}'`
echo
echo -e "${CYAN}returned : $USERS${NC}"

echo if there is an error check log files in $CCROOT/logs, otherwise:
echo -e "${CYAN}Demo ready.${NC}"
