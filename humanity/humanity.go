/*
  This hyperledger chaincode is to represent a humanity point system. Where users can reward each other with humanity
	points according to the level of thank they would give. There are three levels (small, medium, large) with
	point values 1,5 and 10 respectively. The names of the users are also stored at this point

	At the initiation of the chaincode, users are given an initial point value, must be given like ("username", "startpoint")
	pairs. At chaincode invocation users can give thank to another user in the following format:("Name of thankgiver", "type of thank",  "message").


	Laszlo Szoboszlai
*/

	package main

	import (
		"math/rand"
		"time"
		"fmt"
		"encoding/json"
		"strconv"
		"github.com/hyperledger/fabric/core/chaincode/shim"
		"github.com/hyperledger/fabric/protos/peer"
	)

// predefined points for each level of thank:
	const (
		small int = 1 << iota  	// 1 points
		medium = 5 * iota		    // 5 points
		large = 5 * iota		    // 10 points
	)

// Each user has an ID a balance and an array of thanks
// users can gain points by receiving thanks valued at different level (small, medium, large)
	type entity struct {
		UserID    string `json:"name"`
		Balance   int `json:"balance"`		// points received by thanks
		ThankList []thank `json:"thank"`	// list of the thanks received
	}

// keyList to contain all keys for the users, so we could select one randomly
	type keyList struct {
		Keys []string `json:"keys"`
	}

// Each thank contains:
// - the name of the "giver"
// - one of the three types of thanks: ta, thanks, bigthanks
// - and a message stating their good deed
	type thank struct{
		Thanker    string `json:"name"`		  // person who gives the "thank"
		ThankType  string `json:"type"`		  // number of points given
		Message    string `json:"message"`	// the reason for giving thanks
	}

// AddThank method adds a thank to the slice of thanks inside entity struct.
	func (e *entity) AddThank(t thank) []thank {
		e.ThankList = append(e.ThankList, t)
		return e.ThankList
	}

// HumanityChaincode is the receiver for chaincode functions
	type HumanityChaincode struct{
	}

	// Init function to initialize chaincode add entities and points to start with to the ledger.
func (t *HumanityChaincode) Init(stub shim.ChaincodeStubInterface)  peer.Response {
	var userID string       // name of the user to be registered on the chain
	var pointsToAdd int     // points to start with
	var err error
	keyListObj := keyList{}

	// get attributes from args
	args := stub.GetStringArgs()
	if len(args) %2 != 0  {
		return shim.Error(fmt.Sprintf("Incorrect number of args. Needs to be even: (ID, points)"))
	}

	// fill the db from args
	for index := 0; index < len(args); index += 2{
		userID = args[index]
		pointsToAdd, err = strconv.Atoi(args[index + 1])
		if err != nil {
			return shim.Error(fmt.Sprintf("Expecting integer value for initial points"))
		}
	  entityObj := entity{}
		// add the username to the list of users
		keyListObj.Keys = append(keyListObj.Keys, userID)

  	// fill entity struct
  	entityObj.UserID = userID
	  entityObj.ThankList = []thank{}
  	entityObj.Balance = pointsToAdd

	  // convert entity struct to entityJSON
  	entityJson, err := json.Marshal(entityObj)
  	if err != nil || entityJson == nil {
   		return shim.Error(fmt.Sprintf("Converting entity struct to entityJSON failed"))
		}

  	// write entity attributes into ledger
  	err = stub.PutState(userID, entityJson)
  	if err != nil {
  		return shim.Error(fmt.Sprintf("Error: could not update ledger"))
	  }
	}

	// convert keylist struct to keyListJSON
	keyListJson, err := json.Marshal(keyListObj)
	if err != nil || keyListJson == nil {
		return shim.Error(fmt.Sprintf("Converting entity struct to keyListJSON failed"))
	}

	// write keylist into ledger
	err = stub.PutState("keys", keyListJson)
	if err != nil {
		return shim.Error(fmt.Sprintf("Error: could not update ledger"))
	}
	  return shim.Success(nil)
}

	// getRandomUser returns a random user from the ledger
	func (t *HumanityChaincode) getRandomUser(stub shim.ChaincodeStubInterface, args []string) (string, error) {
			if len(args) != 0 {
					return "", fmt.Errorf("Invalid number of arguments, expected 0")
				}
	 // set the source for generating a random number
	 source := rand.NewSource(time.Now().UnixNano())
	 random := rand.New(source)

	 // get list of keys from ledger
	 keysJSON, err := stub.GetState("keys")
	 if keysJSON == nil || err != nil {
	  	return "", fmt.Errorf("Cannot get user list data from chain.")
	 }

	 // convert JSON to struct
	 keyListObj := keyList{}
	 err = json.Unmarshal(keysJSON, &keyListObj)
	 if err != nil {
		 return "", fmt.Errorf("Invalid userlist data pulled from ledger.")
	 }

	 // print and return an element in json form, from the slice containing a random  name
	 randomUserObj := keyList{}
	 randomUserObj.Keys = append(randomUserObj.Keys, keyListObj.Keys[random.Intn(len(keyListObj.Keys))])
	 randomUserJson, err := json.Marshal(randomUserObj)
	 if err != nil || randomUserJson == nil {
	  	return "", fmt.Errorf("Converting struct to JSON failed")
	 }

	 fmt.Printf("Query Response:%s\n", randomUserJson)
	   return string(randomUserJson), nil
 }

	// addThanks function enables user to receive a "thank", adds points according to the thank level, and adds the "thank"
	// to the person's thank list(name of "thanker", type and message).
	func (t *HumanityChaincode) addThanks(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	  var userID string
	  var pointsToAdd int

	  // check arguments number and type
	  if len(args) != 2 {
	  	return "", fmt.Errorf("Incorrect number of arguments. Expecting 2")
	  }
	  userID = args[0]

	  // convert JSON to struct
  	thankJson := []byte(args[1])
	  var thankObj thank

	  err := json.Unmarshal(thankJson, &thankObj)
	  if err != nil {
	   	return "", fmt.Errorf("Invalid thank JSON")
  	}

	  // simple sanity check (message part can be ""):
	  if thankObj.ThankType != "ta" && thankObj.ThankType != "thankyou" && thankObj.ThankType != "bigthanks"{
			return "", fmt.Errorf("Invalid thank type! Valids are: ta(1), thankyou(5), bigthanks(10)")
   	}

	  if thankObj.Thanker =="" {
			return "", fmt.Errorf("No thanker name!")
		}

	  // calculate how many points to add according to "thank level":
	  switch thankObj.ThankType {
			case "ta" : pointsToAdd = small
			case "thankyou" : pointsToAdd = medium
			case "bigthanks" : pointsToAdd = large
		}

	  // get entity data from ledger:
	  entityJSON, err := stub.GetState(userID)
	  if entityJSON == nil {
			return "", fmt.Errorf("Error: No account exists for user.")
		}

	  // convert JSON to struct
	  entityObj := entity{}
	  err = json.Unmarshal(entityJSON, &entityObj)
	  if err != nil {
			return "", fmt.Errorf("Invalid entity data pulled from ledger.")
		}

	  // add points:
	  entityObj.Balance = entityObj.Balance + pointsToAdd

	  // add the thankObject to the thank array of the entityObject:
	  entityObj.AddThank(thankObj)
	  entityJSON = nil
	  entityJSON, err = json.Marshal(entityObj)

    if err != nil || entityJSON == nil {
		  return "", fmt.Errorf("Converting entity struct to JSON failed")
		}

	  // write entity back to ledger
	  err = stub.PutState(userID, entityJSON)
	  if err != nil {
	    return "", fmt.Errorf("Writing updated entity to ledger failed")
	 	}
	  jsonResp := "{\"msg\": \"Thank added\"}"
	  fmt.Printf("Invoke Response:%s\n", jsonResp)
	  return string(jsonResp), nil
  }

	// Invoke function to invoke addThanks, and getRandomUser functions
	func (t *HumanityChaincode) Invoke(stub shim.ChaincodeStubInterface) peer.Response {
		var err error
		var result string
	  // Extract the function and args from the transaction proposal
    fn, args := stub.GetFunctionAndParameters()
	  if fn == "addThanks" {
			// Add points to a member
			result, err = t.addThanks(stub, args)
		} else {
		  err = fmt.Errorf("Received unknown function invocation: %s", fn)
		}

		if err != nil {
				 return shim.Error(err.Error())
			}
			return shim.Success([]byte(result))
	}

	// getUser queries the ledger for a given ID and returns the whole JSON for the userID
	func (t *HumanityChaincode) getUser(stub shim.ChaincodeStubInterface, args []string) (string, error) {
	  if len(args) != 1 {
	     return "", fmt.Errorf("Invalid number of arguments, expected 1")
	  }
	  userID := args[0]

	  // get user data from ledger
	  dataJson, err := stub.GetState(userID)
	  if dataJson == nil || err != nil {
	     return "", fmt.Errorf("Cannot get user data from chain.")
	  }

	  fmt.Printf("Query Response: %s\n", dataJson)
	 return string(dataJson), nil
 }

	// getKeys queries the ledger for all user keys and returns it as a JSON
	func (t *HumanityChaincode) getKeys(stub shim.ChaincodeStubInterface, args []string) (string, error)  {
	   if len(args) != 0 {
	       return "", fmt.Errorf("Invalid number of arguments, expected 0")
 	   }

	  // get list of keys from ledger
	  keysJSON, err := stub.GetState("keys")
	  if keysJSON == nil || err != nil {
	    return "", fmt.Errorf("Cannot get user list data from chain.")
	  }

	  fmt.Printf("Query Response: %s\n", keysJSON)
	  return string(keysJSON), nil
	}

	// query function to return a user, or a list of all user's keys
	func (t *HumanityChaincode) Query(stub shim.ChaincodeStubInterface) peer.Response {
		var err error
		var result string
	  // Extract the function and args from the transaction proposal
	  fn, args := stub.GetFunctionAndParameters()
	  if fn == "getUser" {
	    result, err = t.getUser(stub, args)
	  } else if fn == "getKeys" {
	     result, err = t.getKeys(stub, args)
	  } else if fn == "getRandomUser" {
       result, err = t.getRandomUser(stub, args)
    } else {
		   err = fmt.Errorf("Received unknown function invocation: %s", fn)
		}
		if err != nil {
            return shim.Error(err.Error())
    }
		// Return the result as success payload
		return shim.Success([]byte(result))
	}

	// main function to start chaincode
	func main() {
		err := shim.Start(new(HumanityChaincode))
		if err != nil {
			fmt.Printf("Error starting Humanity chaincode: %s", err)
		}
}
