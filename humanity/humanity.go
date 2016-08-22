/*  This chaincode represents a humanity point system.....
    TODO:add more description
*/

package main

import (
	"math/rand"
	"time"
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

//Each user has an ID a balance and an array of thanks
//users can gain points by receiving thanks valued at different level (small, medium, large)
type entity struct {
	UserID    string `json:"name"`
	Balance   int `json:"balance"`   //points received by thanks
	ThankList []thank `json:"thank"` //list of the thanks received
}

//Each thank contains:
//- the name of the "giver"
//- one of the three types of thanks: ta, thanks, bigthanks
//- and a message stating their good deed
type thank struct{
	Thanker    string `json:"name"`    //person who gives the "thank"
	ThankType  string `json:"type"`  //number of points given
	Message    string `json:"message"` //the reason for giving thanks
}

//AddThank method adds a thank to the slice of thanks inside entity struct.
func (e *entity) AddThank(t thank) []thank {
	e.ThankList = append(e.ThankList, t)
	return e.ThankList
}

//HumanityChaincode is the receiver for chaincode functions
type HumanityChaincode struct{
}

//Init function to initialize chaincode add entities and points to start with to the ledger.
//TODO: check the work for more entities
func (t *HumanityChaincode) Init(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	var userID string // name of the user to be registered on the chain
	var pointsToAdd int //points to start with (default=0)
	var err error

	//get attributes from args
	if len(args) %2 != 0  {
		return nil, errors.New("Incorrect number of args. Needs to be even: (ID, points)")
	}

	//fill the db from args
	for index := 0; index < len(args); index += 2{
		userID = args[index]
		pointsToAdd, err = strconv.Atoi(args[index + 1])
		if err != nil {
	    		return nil, errors.New("Expecting integer value for initial points")
	    	}
		entityObj := entity{}
		entityObj.ThankList = []thank{}
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
	}

	fmt.Printf("Humanity points chaincode initialization ready.\n")
	return nil, nil
}

//getRandomUser returns a random user (who is at a certain level).
func (t *HumanityChaincode) getRandomUser(stub *shim.ChaincodeStub,function string,args []string) ([]byte, error) {
	//set the source for generating a random number
	source := rand.NewSource(time.Now().UnixNano())
	random := rand.New(source)
	//placeholder operation
	fmt.Print(random.Intn(100))

	return nil,nil
}

//addThanks function enables user to receive a "thank", adds points according to the thank level, and adds the "thank"
//to the person's thank list(name of "thanker", type and message).
func (t *HumanityChaincode) addThanks(stub *shim.ChaincodeStub,function string, args []string) ([]byte, error) {
	var userID string
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

//Invoke function to invoke addThanks, and getRandomUser functions
func (t *HumanityChaincode) Invoke(stub *shim.ChaincodeStub, function string, args []string) ([]byte, error) {
	if function == "addThanks" {
		//Add points to a member
		return t.addThanks(stub,function, args)
	}else if function == "getRandomUser" {

			return t.getRandomUser(stub,function, args)

	}
	return nil, errors.New("Received unknown function invocation")
}

//Query queries the ledger for a given ID and returns the whole JSON for the userID
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

//main function to start chaincode
func main() {
	err := shim.Start(new(HumanityChaincode))
	if err != nil {
		fmt.Printf("Error starting Humanity chaincode: %s", err)
	}
}