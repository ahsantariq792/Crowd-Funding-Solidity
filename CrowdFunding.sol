// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint256) public contributors; //contributor[msg.sender] = 100
    address public manager;
    uint256 public minimumContibution;
    uint256 public deadline;
    uint256 public target;
    uint256 public raisedAmount;
    uint256 public noOfContributors;


//constructing contribution
    constructor(uint256 _target, uint256 _deadline) {
        target = _target;
        deadline = block.timestamp + _deadline;
        // deadline = _deadline;
        minimumContibution = 100 wei;
        manager = msg.sender;
    }


//requests to use money for something 
//can be used only by manager
    struct Requests {
        address payable receiptant;
        string description;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }
    mapping(uint256 => Requests) public request;
    uint256 public numReq;


//send ether to crowd funding
    function sendEth() public payable {
        require(block.timestamp < deadline, "Deadline has been passed");
        require(
            msg.value >= minimumContibution,
            "Minimum contribution is 100 wei"
        );

        //agr contributor ne phle kabhi contribute nhi kia tu add krdenge
        //wrna add nhi hoga contributor ki list me
        //if contributor has contributed before he will not be added in list
        if (contributors[msg.sender] == 0) {
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
    }

    //checking balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


//if a contributor wants to refund after the deadline has been passed and target is not achieved
    function refund() public payable {
        require(
            block.timestamp > deadline && raisedAmount < target,
            "you cant refund before dealine"
        );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]); //contributor ko amount wapis krdi
        contributors[msg.sender] = 0; //amount wapis krne k baad contribution 0 krdi
    }


//modifier can be used to give access to sepecific users
    modifier onlyManager() {
        require(msg.sender == manager, "only manager can access this function");
        _;
    }


//creating request to use money can be used by manager only
    function createRequests(
        string memory _description,
        address payable _receiptant,
        uint256 _value
    ) public onlyManager {
        // using mapping inside structure we use storage
        Requests storage newRequest = request[numReq]; // data type is requests
        newRequest.description = _description;
        newRequest.receiptant = _receiptant;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }
  

  //if more than half contributors voted for the request manager can use money
    function voteRequest(uint256 _requestNo) public {
        require(contributors[msg.sender] > 0, "You must be contributor");
        Requests storage thisRequest = request[_requestNo]; //pointing to request number we want to vote
        require(
            thisRequest.voters[msg.sender] == false, //checking that voter has not already voted to avoid double voting
            "You have already voted"
        );
        thisRequest.voters[msg.sender] = true; //setting voter status true
        thisRequest.noOfVoters++;
    }

    function makePayment(uint256 _requestNo) public payable onlyManager {
        require(raisedAmount >= target);
        Requests storage thisRequest = request[_requestNo];
        require(
            thisRequest.completed == false,
            "The request has been completed"
        );
        require(
            thisRequest.noOfVoters > noOfContributors / 2,
            "Majority does not support"
        );
        thisRequest.receiptant.transfer(thisRequest.value);
        thisRequest.completed = true; // voting to this request is trus so it cannot be voted again
    }
}
