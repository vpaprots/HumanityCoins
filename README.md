# HumanityCoins

<!--- [![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/vpaprots/HumanityCoins.git) --->


# Application background

This application will demonstrate a HumanityCoins point system where users can honour each other with HumanityCoins. Later HumanityCoins can also be collected by wearable devices, or smart meters, rewarding people saving resources (electricity, water, gas) or living a healthy lifestyle reported by their wearable device. To avoid abuse of the system these points are audited by a tweeting auditor (using twitter). The HumanityCoins points can be used by companies and government bodies to reward people doing good to their communities, health and to the environment.

### NOTE: This version is compatible with Hyperledger v1.0 docker containers
# Some technical details:

Types of thanks:

	1.small =1 HumanityCoins 
	2.medium=5 HumanityCoins
	3.large =10 HumanityCoins
	
Attributes of a user:

	1. userID (unique string, used as primary key)
	2. balance (int, sum of the calculated points from the type of thanks received)
	3. thanklist (string array of the thanks recieved)

Attributes of a thank:

	1.Thanker (the name of the person giving the thank)
	2.ThankType (type of the thank small/ medium/ large) 
	3.message (a small message explaining the thank, can be empty)

# Project setup:
To try out the project, follow the following guide to install the perequisits:
https://hyperledger-fabric.readthedocs.io/en/latest/prereqs.html

Using the following tutorial it can be deployed into a chaincode development docker network:
https://hyperledger-fabric.readthedocs.io/en/latest/chaincode4ade.html

## Replace the Terminal 2 and 3 parts with the following:
### Terminal 2:

cd humanity

go build

CORE_PEER_ADDRESS=peer:7051 CORE_CHAINCODE_ID_NAME=mycc:0 ./humanity

### Terminal 3:
docker exec -it cli bash

peer chaincode install -p chaincodedev/chaincode/humanity -n mycc -v 0

peer chaincode instantiate -n mycc -v 0 -c '{"Args":["alice","10", "bob","20"]}' -C myc

peer chaincode invoke -n mycc -c '{"Function":"addThanks", "Args": ["bob","{\"name\":\"alice\",\"type\":\"thankyou\",\"message\":\"for being good\"}"]}' -C myc

peer chaincode query -n mycc -c '{"Function":"getUser", "Args":["alice"]}' -C myc