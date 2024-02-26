// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// to raise funds for a particular campaign or event
/* we are using interface because we are minting crypto for this campaign, since ERC20 is the 
acceptable standard for minting token, its the legal tender for the campaign
it will contain function transfer, campaign address, amount, bool for true or false
transfer from the senders address, to the campaignaddress and the amount, bool for true or false of the
transaction*/

interface IERC20 {
    function transfer(address, uint) external returns(bool); 
    function transferFrom(address, address, uint)
    external returns(bool);
}
//lets create a contract to implement it, as it wont be implemented with the interface
contract CrowdFund{  
    //create a contract for the crowdfund  and also event for each "functionalities" of this contract 
    //event will make the contract visible to the front end
    event Launch(              //functionality launch, to launch the campaign.
    uint id,                   // identity number of this particular campaign, as there can be many
    address indexed creator,    //name of the creator of this campaign
    uint goal,                 //reason for the campaign
    uint startAt,   //when the campaign is starting
    uint endAt      //when the campaign  is ending
);

    event Cancel(uint id);     //to enable canceling of the campaign, will require the identity no of this campaign
    event Pledge(uint indexed id,address indexed caller,uint amount );
    //event pledge will allow people to pledge for the campaign, will require, campaign ID,
    // address of the contributor and amount to be contributed
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    //unpledge is when the contributor want to unpledge the amount pledge earlier for the campaign
    //the campaign Id, address of the contributor, amount contributed
    event Claim(uint id);   // this will allow the owner of the campaign withdraw the money 
    //the ID of the campaign is required
    event Refund(uint id,address indexed caller,uint amount); // in the case of a refund , 
    //campaign ID is required, address of the contributor and the amount to be refunded
    //note- indexed is used to highlight a particular input, 
    // or to filter a particular input to be located easily

    //struct will save all the data for this campaign
    struct Campaign{
    address creator;
    //the address of the creator of this campaign
    uint goal;
    //the amount to be raised in this campaign
    uint pledged;
    //the amount pledge for this campaign
    uint startAt;
    //the time the campaign will start
    uint endAt;
    //the time the campain will end
    bool claimed;
    //to check true or false if the amount raised has been claimed or not by the owner of the campaign
}
    // now we will create a link bewteen the "token" and "IERC20"

    IERC20 public immutable token;
    //note-immutable means not changing, the ERC20token is not changing(legal tender)

    uint public count;  //create a state variable,to create ID for the campaign. with count to takein as many campaign we have for the owner 
    mapping(uint => Campaign) public campaigns; //create a mapping to locate the particular campaign you are funding
    // where the key is the uint, the campaign ID 
    //and the value is the name of the struct, where campaigns represent name of the mapping, then make public.

    mapping(uint => mapping(address =>uint)) public pledgedAmount; 
    //create a nested mapping to allow us capture address of the contributor for this particluar campaign
    //this include campaign ID, address of contributor and the amount to be pledge. make public

    constructor(address _token) {
        //create a constructor, with the token address
    token = IERC20(_token);  //synchronise/establish the interface with token address
    //note the token is the ERC20 you have created. the money for the campaign
}

    //create a function to launch the campaign
    function launch(uint _goal, uint _startAt,uint _endAt) external {
    //include input for the goal of the campaign, the starting time and the end time  
    //note the time cannaot be in the past, it must be in the future

    require(_startAt >= block.timestamp,"startAt is less than now");
    //check the time the campaign will start , which must be greater than or equal to current time
    //The time for the campaign is it in the past or in the future, else send error "startAt is less than now"
    //note block.timestamp== current time on your watch
    
    require(_endAt >= _startAt, "endAt < startAt");
    //check that the end time is greater than or equal to the start time,
    // else send error, endat < startAT
    
    require(_endAt <= block.timestamp + 90 days, "end at > max duration");
    //check that end time is less than or equal to current time, plus the next 90 days(you can set to any date)
    //else send error, if endtime is > the duration stated

    count += 1; //add to the number of the campaign if available,
    // we can have lots of campaign for an owner


//lets save these inputs in a struct
    campaigns[count] = Campaign ({   //a dynamic array, which shows the number of campaigns
    creator:msg.sender, //specify the creators address
    goal: _goal,  //specify the amount to be raised
    pledged:0,   //this is 0 by default, cause theres no money before the campaign
    startAt: _startAt,  //specify the time to start
    endAt: _endAt,      //specify the time to end
    claimed : false     //set by default to be false, cos the money hasnt being cashed out.
    });
    emit Launch(count,msg.sender,_goal,_startAt,_endAt);  
    //communicate to frontend that the campaign is launched, making these inputs visible
    //with the input, count for the campaignID, msg.sender(the creator), goal (the amount to be raised)
    // start at( the start time), endAT (the end time).
    //note = emit 'Launch' is different the function 'launch' so it wont conflict
}

//create function cancel, to enable us cancel the contract we created, in case of an error
    function cancel(uint _id) external {      //the campaign ID required
    Campaign memory campaignStruct = campaigns[_id];   //capture the campaign ID, save it to a variable (campaignstruct) and
    //make reference to the struct (Campaign),
    //note = memory will enable you to call it later

    require(campaignStruct.creator == msg.sender, "you are not the creator");
    //check that only the creator can cancel the contract,else send an error "you are not the creator"

    require(block.timestamp < campaignStruct.startAt, "the campaign has started ");
    //check that that current time is less than the campaign start time, else send error
    //the campaign has started and means the campaign cannot be cancelled again

    delete campaigns[_id];
    // this will enable the contract to be deleted using the name of the array

    emit Cancel(_id); 
    //now lets communicate this to the front end 
    }

    //to enable donation for the campaign 
    function pledged (uint _id,uint _amount) external {
        Campaign memory campaignStruct = campaigns[_id]; //to enable acess to the campaign variables stated in the struct
    //to know the campaign ID you are pledging into, a variable ""campaignstruct"" (which will give acess to the inputs of the contract)
    //make reference to the struct Campaign

        require(block.timestamp >= campaignStruct.startAt,"campaign has not started");
    //check that the campaign has started before you can donate, else send error campaign has not started

    require(block.timestamp <= campaignStruct.endAt, "campaign has ended");
    //check that the current time is less than or equal to campaign time, before donating
    //else send error campaign has ended

    campaignStruct.pledged += _amount; //updating the pledge amount to the campaign, call the campaignStruct
   
   pledgedAmount[_id][msg.sender] += _amount;
   //the amount to be pledged, the campaign ID, the campaignaddress, all updated in the pledge account

    token.transferFrom(msg.sender, address(this), _amount);
    //initiate the token transfer, from the sender to the campaign address

    emit Pledge(_id, msg.sender, _amount);
     //show to the front end the pledge transaction
       
    }
    //lets create unpledge function.
     function unpledge(uint _id, uint _amount) external { 
         //to unpledge, the campaignid and amount is required

         Campaign storage campaign = campaigns[_id]; //this will enable acess to the inputs/details of the campaign
    require(block.timestamp <= campaign.endAt, "ended");
    //check that the current time is less than or equal to the time the campign will end 
    //else send error, the campaign has ended. the user cant unpledge
     campaign.pledged -= _amount;
     //the amount unpledged to be deducted from total amount
      pledgedAmount[_id][msg.sender] -= _amount;
      //the amount to be deducted from the total pledge amount, will require the campaign Id and the addres of the sender
       token.transfer(msg.sender, _amount);
       //transfer the token/amount unpledged to the sender

     emit Unpledge(_id, msg.sender, _amount);
    //communicate with front end the unpledged transaction
 }

//lets create function claim, whereby the owner of the campiagn can claim the money
     function claim(uint _id) external {     //the campaign Id is required, make external
     Campaign storage campaign = campaigns[_id];  //this will enable acess to the campaign detals/inputs
     require(campaign.creator == msg.sender, "not creator");   
     //to claim, check that the creator of the contract is same with the creators address,
     //else send error not creator 
     require(block.timestamp > campaign.endAt, "not ended");
     //check that the current time is greater than the time the campaign ended,else send error not ended
     require(campaign.pledged >= campaign.goal, "pledged < goal");
     //check that the amount pledged is greater than or equal to the amount to be raised
     //else send error pledged is less than goal
     require(!campaign.claimed, "claimed");
     //check that the money has not been claimed, else send error claimed

     campaign.claimed = true;
    //if the criteria to claim the money has been met, return true
     token.transfer(campaign.creator, campaign.pledged);
     //transfer the token/money to the owner of the campaign

    emit Claim(_id);
    //communicate the claim to the frontend
    }

    //lets create function refund, incase the goal is not reached
     function refund(uint _id) external {       //the campaign Id is required, make external
    Campaign memory campaign = campaigns[_id]; //enable access to te inputs/details of the campaign
     require(block.timestamp > campaign.endAt, "not ended"); 
     //to refund, check that the current time is greater than the end time of the campaign
     //else send error not ended

      require(campaign.pledged < campaign.goal, "pledged >= goal");
      //check that the amount pledged is less than the goal of the campaign,
      //else send error, that the amount pledged is greater or equal to the goal

    //lets save the pledge amount to variable bal
     uint bal = pledgedAmount[_id][msg.sender];
     //check the balance of the pledged amount ,using the campaign ID and the campaignaddress
     pledgedAmount[_id][msg.sender] = 0;
    //the pledgeamount for the contract will go back to zero by default, after refunding
     token.transfer(msg.sender, bal);
     //transfer the token to the sender from the default bal. thats where the money was saved
     //when we wanted to refund

     emit Refund(_id, msg.sender,bal);
     //comminucate the refund to the frontend
}
}

/*  to deploy, you would have created an ERC20 earlier, go to the contract 
    and deploy ERC20, go to the deployed contracts section and copy the address 
    paste the address on the deploy section where address was requested from the crowdfunding contract
    deploy the contract*/
    
    //create how to generate time contract
    // input the startat time from this moment to the next 0ne minute for example,
    //input the end time,
    // input the goal, in the launch column, call.
    // number this campaign as 1. call
    //copy the crowdfunding account and paste in the approve section of ERC20 token, and approve an amount
    //come back to crowdfunding and pledge
    //to chcek pledgeamount, copy the creators address on the lauch section and paste in pledgeamount.
    // and use the numner of the campaign to get the pledge amount
    