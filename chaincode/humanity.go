/*  This chaincode represents a humanity point system.....
  TODO:add more description

 */
package main

import (
	"errors"
	"fmt"
	"encoding/json"
	"strconv"
	"github.com/hyperledger/fabric/core/chaincode/shim"
)

//predefined points for each level of thank:
const (
	small int = 1 << iota //1
	medium = 5 * iota //5
	large = 5 * iota //10
)

//users can recieve 3 types of thanks: ta, thanks, bigthanks
//and a message stating their good deed
type thank struct{
	Thanker string `json:"name"`    //person who gives the "thank"
	ThankType string `json:"type"`  //number of points given
	Message string `json:"message"` //the reason for giving thanks
}

//each user has an ID a balance and an array of thanks
//users can gain points by receiving thanks valued at different level (1,5,10 poinst)
type entity struct {
	UserID string `json:"name"`
	Balance int `json:"balance"`   //points received by thanks
	Thanks []thank `json:"thanks"` //list of the thanks received
}


//helper method to add a thank to the slice of thanks inside entity struct
func (e *entity) AddThank(t thank) []thank {
	e.Thanks = append(e.Thanks, t)
	return e.Thanks
}

//receiver for functions
type HumanityChaincode struct{
}


//init function
//Function to initialize chaincode (add a single entity and points to start with)
//TODO: make it work for more entities
func (t *HumanityChaincode) Init(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	var userID string // name of the user to be registered on the chain
	var pointsToAdd int //points to start with (default=0)
	var err error

	//get attributes from args
	if len(args) < 1 {
		return nil, errors.New("Incorrect number of args. Minimum one expected.(entity name)")
	}
	if len(args) > 2 {
		return nil, errors.New("Incorrect number of args. Maximum 2 expected:(entity name, points)")
	}
	if len(args) == 1 {
		pointsToAdd = 0
	}else{
		pointsToAdd, err = strconv.Atoi(args[1])
		if err != nil {
			return nil, errors.New("Expecting integer value for initial points")
		}
	}

	//fill the struct from args
	userID = args[0]
	entityObj := entity{}
	entityObj.Thanks = []thank{}
	entityObj.Balance = pointsToAdd
	entityObj.UserID = userID

	//convert struct to JSON
	entityJson, err := json.Marshal(entityObj)
	if err != nil || entityJson == nil {
		return nil, errors.New("Converting entity struct to JSON failed")
	}


	//write attributes into ledger
	err = stub.PutState(userID, entityJson)
	if err != nil {
		fmt.Printf("Error: could not update ledger")
		return nil, err
	}

	fmt.Printf("Humanity points chaincode ready.\n")
	return nil, nil
}


//get a random user who is at a certain level...
func (t *HumanityChaincode) getRandomUser(stub *shim.ChaincodeStub,function string,args []string) ([]byte, error) {

	return nil,nil
}

//function to receive a thank
//we expect:
//arg 0: ID (string)
//arg 1: thank (json)
func (t *HumanityChaincode) addThanks(stub *shim.ChaincodeStub,function string, args []string) ([]byte, error) {
	var userID string
	//var oldBalance int
	var pointsToAdd int

	//check arguments number and type
	if len(args) != 2 {
		return nil, errors.New("Incorrect number of arguments. Expecting 2")
	}
	userID = args[0]
	//convert JSON to struct
	thankJson := []byte(args[1])

	var thankObj thank

	err := json.Unmarshal(thankJson, &thankObj)
	if err != nil {
		return nil, errors.New("Invalid thank JSON")
	}

	//simple sanity check (message part can be ""):
	if thankObj.ThankType != "ta" && thankObj.ThankType != "thankyou" && thankObj.ThankType != "bigthanks"{
		return nil, errors.New("Invalid thank type! Valids are: ta(1), thankyou(5), bigthanks(10)")
		//return nil, errors.New(thankObj)
	}

	if thankObj.Thanker =="" {
		return nil, errors.New("No thanker name!")
	}

	//calculate how many points to add according to "thank level":
	switch thankObj.ThankType {
	case "ta" : pointsToAdd = small
	case "thankyou" : pointsToAdd = medium
	case "bigthanks" : pointsToAdd = large
	}

	//get entity data from ledger:
	entityJSON, err := stub.GetState(userID)
	if entityJSON == nil {
		return nil, errors.New("Error: No account exists for user.")
		//TODO
	}
	
	//convert JSON to struct
	entityObj := entity{}
	err = json.Unmarshal(entityJSON, &entityObj)
	if err != nil {
		return nil, errors.New("Invalid entity data pulled from ledger.")
	}

	//add points:
	entityObj.Balance = entityObj.Balance + pointsToAdd
	

	//add the thankObject to the thank array of the entityObject:
	entityObj.AddThank(thankObj)

	entityJSON = nil

	entityJSON, err = json.Marshal(entityObj)
	if err != nil || entityJSON == nil {
		return nil, errors.New("Converting entity struct to JSON failed")
	}

	//write entity back to ledger
	err = stub.PutState(userID, entityJSON)
	if err != nil {
		return nil, errors.New("Writing updated entity to ledger failed")
	}
	jsonResp := "{\"msg\": \"Thank added\"}"
	fmt.Printf("Invoke Response:%s\n", jsonResp)
	return []byte(jsonResp), nil

}

func (t *HumanityChaincode) Invoke(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	if function == "addThanks" {
		//Add points to a member
		return t.addThanks(stub,function, args)
	}else if function == "getRandomUser" {

			return t.getRandomUser(stub,function, args)

	}
	return nil, errors.New("Received unknown function invocation")
}

//query returns the whole JSON for the userID
func (t *HumanityChaincode) Query(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	if len(args) != 1 {
		return nil, errors.New("Invalid number of arguments, expected 1")
	}
	userID := args[0]
	//get user data from ledger
	dataJson, err := stub.GetState(userID)
	if dataJson == nil || err != nil {
		return nil, errors.New("Cannot get user data from chain.")
	}


	fmt.Printf("Query Response: %s\n", dataJson)
	return dataJson, nil
}

//Main function
func main() {
	err := shim.Start(new(HumanityChaincode))
	if err != nil {
		fmt.Printf("Error starting Humanity chaincode: %s", err)
	}
}