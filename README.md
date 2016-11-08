# HumanityCoins

<!--- [![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/vpaprots/HumanityCoins.git) --->


# Application background

This application will demonstrate a HumanityCoins point system where users can honour each other with HumanityCoins. Later HumanityCoins can also be collected by wearable devices, or smart meters, rewarding people saving resources (electricity, water, gas) or living a healthy lifestyle reported by their wearable device. To avoid abuse of the system these points are audited by a tweeting auditor (using twitter). The HumanityCoins points can be used by companies and government bodies to reward people doing good to their communities, health and to the environment.

#Some technical details:

Types of thanks:

	1.small =1 HumanityCoins 
	2.medium=5 HumanityCoins
	3.large =10 HumanityCoins
	
Attributes of a user:

	1. userID (unique string, will be used as key)
	2. balance (int, computed points from the type of thank)
	3. thanklist (string slice (array), array of the thanks recieved by the user)

Attributes of a thank:

	1.Thanker (the name of the person giving the thank)
	2.ThankType (type of the thank small, medium, large) 
	3.message (a small message explaining the thank, can be empty)

#Project setup:
In order to be able to try the project on your system, the hyperledger fabric needs to be set up:
https://github.com/hyperledger/fabric/blob/master/docs/dev-setup/devenv.md

The project should be placed under /root directory.
Once you set up the system, you can start the test script to verify the settings. 
/tests/humanity_test.sh

You should get the following output:
TESTS PASSED: 4/4

Now you can start up your network of peers with HumanityCoins chaincode to serve the backend of the application.
/scripts/4vpeers.sh

The script uses the dockerised version of the chaincode from :
szlaci83/humanitycoins_peer

The backend of this application is running GoLang code on the 4 peer blockchain network on the mainframe, similar to IBM's High Security Bussiness Network. The front end application (a mobile app) can connect to this network via Rest API calls.
