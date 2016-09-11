# HumanityCoins

[![Deploy to Bluemix](https://bluemix.net/deploy/button.png)](https://bluemix.net/deploy?repository=https://github.com/vpaprots/HumanityCoins.git)


# Application background

This application will demonstrate a HumanityCoins point system where users can honour each other with HumanityCoins points. Points can also be collected by wearable devices, or smart meters, rewarding people saving resources (electricity, water, gas) or living a helthy lifestyle reported by their wearable device. To avoid abuse of the system these points are audited by a tweeting auditor (using twitter). The HumanityCoins points can be used by companies and government bodies to reward people doing good to their communities, health and to the environment.

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

The backend of this application will be the GoLang code running in our blockchain network. The chaincode itself will create users at the init method call. The user names are stored in a separate part of the database too, in order to get a random name for simulating the selection for a reward. 

Example use case: Coffe bar rewards every 5th person coming in with a free drink with HumanityCoins greater than 1000 this week.

