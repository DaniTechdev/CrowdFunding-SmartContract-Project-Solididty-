    // SPDX-License-Identifier: MIT

    pragma solidity ^0.8.0;


    contract  CrowdFunding {

        struct Request{
            string description;
            address payable recipient;
            uint value;
            bool completed;
            uint noOfVoters;
            mapping(address => bool) voters;
        }

    mapping(address=>uint) public contributors;
    mapping(uint=>Request) public requests;

    address public manager;
    uint public numRequests;
    uint public minimumContribution;
    uint public deadLine;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;


    constructor (uint _target, uint _deadLine) {
        target = _target;
        deadLine = block.timestamp + _deadLine; //500hr + 5hr = 505hr;
        minimumContribution =100 wei;
        manager=msg.sender;
    }


    modifier onlyManager(){
        require(msg.sender == manager, "You are not the manager");
        _;
    }



        function createRequest(string calldata _description, address payable _recipient, uint _value)public onlyManager {
        Request storage newRequest = requests[numRequests];
    //    numRequests= numRequests + 1;
            numRequests++;
            newRequest.description = _description;
            newRequest.recipient= _recipient;
            newRequest.value =_value;
            newRequest.completed =  false;
            newRequest.noOfVoters = 0;

    }

    function contribution() public payable{
        require(block.timestamp < deadLine, "Deadline has passed");
        require(msg.value>= minimumContribution, "Minimum Contribution Required is 100 wei");

        //For the first contributor in the contributor's maaping list or if there is no contributor value associated with the called address, then it is assummed it is the first time the contriutor is contributing;
        
        if(contributors[msg.sender]== 0){
            // noOfContributors= noOfContributors+1;
            noOfContributors++;
        }

        // contributors[msg.sender] = contributors[msg.sender] + msg.value;
        contributors[msg.sender] += msg.value;
        //We will raise the contributed amount;
        // raisedAmount = raisedAmount + msg.value;
        raisedAmount += msg.value;
    }

    function getContractBalance() public view returns(uint){
        return address(this).balance ;
    }



    //Refund function to refund to the contributors when certain conditions are not met

    function refund() public{
        require(block.timestamp > deadLine && raisedAmount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0, "You are not a contributor");
        payable(msg.sender).transfer(contributors[msg.sender]);
        //set his value to zero, if not he will keep asking for refund continously
        contributors[msg.sender]= 0;
    }


    //function for voting for a request

    function voteRequest(uint _requestNo) public {
        //First check if the caller is a contributor
        require(contributors[msg.sender]>0, "You are not a contributor");
        //we will vote on a particular request using the request's number of that request;
        

        //Getting the request to vote on;
        Request storage thisRequest = requests[_requestNo];
        
        //checking if the caller has voted before, the default of bool is false
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        
        //then letting the caller to vote;
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
        // if( thisRequest.voters[msg.sender] = true){
        //     // noOfVoters = noOfVoters+ 1;
        //     // thisRequest.noOfVoters = thisRequest.noOfVoters+ 1;
        //     thisRequest.noOfVoters++;
        // }
    }

    function makePayment(uint _requestNo) public onlyManager{
        //checking if tagrget is met
        require(raisedAmount>=target,"Target is not reached");
        //getting the particular request from requests' array using the request no;
        Request storage thisRequest = requests[_requestNo];
        //Checking if the request is completed or not;
        require(thisRequest.completed == false,"This request is completed");

        //Checking if the request has more than half the votes,
        //Checking if the no of votes gotten by this request is greater than half thise that vote, 

        require(thisRequest.noOfVoters> noOfContributors/2,"Majority does not support the request");
        //transfer the money to the recipient address
        thisRequest.recipient.transfer(thisRequest.value);
        
        //making the request completed

        thisRequest.completed = true;


    }

    }