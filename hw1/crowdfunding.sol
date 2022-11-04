// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.15;

contract CrowdFunding{

    struct Contributor{
        string name;
        string message;
        uint deposit;
    }
    
    mapping(address => Contributor) contributors;
    address[] private sponsors;
    string[] private messages;

    enum Status {UNFUNDED, PREFUNDED, FUNDED}
    uint fundingGoal;
    uint currentSum;

    Status private status;
    string private cause;

    address payable private distributeFunding;
    address private owner;
    
    event fallbackCall(string);
    event receivedFunds(address, uint);

    
    constructor(uint _fundingGoal, string memory _cause, address payable _distributeFunding) {
        fundingGoal = _fundingGoal;
        cause = _cause;
        distributeFunding = _distributeFunding;
        owner = msg.sender;
        status = Status.UNFUNDED;
    }
    
    function deposit(string calldata _name, string calldata _message) external payable{
        if(msg.value == 0){
            revert("Cannot call function with no funds");
        }
        if(status != Status.UNFUNDED){
            revert("Crowdfund is already funded");
        }
        if(currentSum + msg.value > fundingGoal){
            revert("Cannot deposit more than the sum required to reach the funding goal");
        }

        messages.push(_message);
        currentSum+=msg.value;

        if(contributors[msg.sender].deposit > 0){
            contributors[msg.sender].deposit += msg.value; 
        }else{            
            if((bytes(_name).length > 0)){
                contributors[msg.sender] =  Contributor("annonymous",  _message, msg.value);
            }else{
                contributors[msg.sender] =  Contributor(_name,  _message, msg.value);
            }
        }
        
        if(currentSum >= fundingGoal){
            status = Status.PREFUNDED;

            for(uint i=0; i<sponsors.length; i++){
                SponsorFunding sf = SponsorFunding(payable(sponsors[i]));
                sf.transferMoneyToCrowdFunding();
            }
        }
    }
    
    function distributeFunds() external payable{
        require(msg.sender == owner, "Only the owner can transfer the funds");
        require(status == Status.PREFUNDED, "The cause should be prefunded to transfer");

        payable(distributeFunding).transfer(address(this).balance);
        status = Status.FUNDED;
    }

    function getCurrentFunds() public view returns(uint){
        return address(this).balance;
    }


    function getCurrentSum() public view returns(uint){
        return currentSum;
    }
    
    function showMyDeposit() public view returns(uint){
        address callerAddress = msg.sender;
        Contributor memory myContributor = contributors[callerAddress];
        return myContributor.deposit;
    }
    
    function getFundingGoal() public view returns(uint){
        return fundingGoal;
    }

    function getFundingAddress() public view returns(address){
        return distributeFunding;
    }

    function getRequiredFunding() public view returns(uint){
        return fundingGoal - currentSum;
    }

    function getCause() public view returns(string memory){
        return cause;
    }

    function getMessages() public view returns(string[] memory){
        return messages;
    }
    
    function withdraw(uint _value) external {
      
        require(status == Status.UNFUNDED, "Crowdfund is finished funding and cannot receive withdrawals");
        require(contributors[msg.sender].deposit < _value, "You cannot withdraw more than you deposited");
        
        payable(msg.sender).transfer(_value);
        contributors[msg.sender].deposit -= _value;
    }
    
    function isGoalReached() external view returns(string memory){
        if(status == Status.UNFUNDED){
            return "We are still collecting Funds!";
        }else if(status == Status.PREFUNDED){
            return "The Funding Goal was reached!";
        }else{
            return "Already sent";
        }
    }

    function addSponsor(address _addr) public{
        require(_addr == msg.sender, "Only a sponsor can add itself");

        sponsors.push(_addr);
    }
    
    receive () payable external {
      emit receivedFunds(msg.sender, msg.value);
    }
    
    fallback () external {
    emit fallbackCall("Falback Called!");
  }
  
}

contract SponsorFunding{
    
    uint private percentage;
    event fallbackCall(string);
    event receivedFunds(address, uint);
    address payable crowdFundingAddress;
    address private ownerAddress;    
    
    constructor(address payable _crowdFundingAddress , uint _percentage) payable{
        percentage = _percentage;
        crowdFundingAddress = _crowdFundingAddress;
        ownerAddress = msg.sender;
        
        CrowdFunding(crowdFundingAddress).addSponsor(address(this));
    }

    function topUp(uint _percentage) public payable {
        require(ownerAddress == msg.sender, "Only the owner of the contract can modify the balance or percentage");
        if(_percentage != 0){
            percentage = _percentage;
        }
    }

    function withdraw(uint _value) public payable {
        require(ownerAddress == msg.sender, "Only the owner of the contract can withdraw money");
        payable(msg.sender).transfer(_value);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getCrowdFundingCurrentFunds() public view returns(uint){
        return CrowdFunding(crowdFundingAddress).getCurrentSum();
    }
    
    function transferMoneyToCrowdFunding() external payable{
        require(msg.sender == crowdFundingAddress, "Only the crowdfunding address can require the transfer");

        uint fundingGoal = CrowdFunding(crowdFundingAddress).getFundingGoal();
        require(CrowdFunding(crowdFundingAddress).getCurrentSum() == fundingGoal, "Funding goal not reached");

        uint sumToPay = percentage * fundingGoal / 100;
        if(sumToPay < address(this).balance){
            crowdFundingAddress.transfer(sumToPay);
        }

    }
    
    function getCrowdFundingGoal() public view returns(uint){
        return CrowdFunding(crowdFundingAddress).getFundingGoal();
    }
    
    receive () payable external {
      emit receivedFunds(msg.sender, msg.value);
    }
    
    fallback () external {
    emit fallbackCall("Falback Called!");
    }
}

contract DistributeFunding{
    
    uint private totalPercentage;
    uint private fundedSum;
    address private owner;
    event receivedFunds(address, uint);
    
    struct Stakeholder{
        address addr;
        uint percentage;
    }
    
    Stakeholder[] stakeholders;

    constructor(){
        owner = msg.sender;
    }
    
    function getBalanceThis() public view returns(uint){
        return address(this).balance;
    }

    function withdraw() public payable{
        require(address(this).balance > 0, "This cause was not funded yet");

        if(fundedSum == 0){
            fundedSum = address(this).balance;
        }
        

        for(uint i=0; i<stakeholders.length; i++){
            if(stakeholders[i].addr == msg.sender){
                payable(msg.sender).transfer(stakeholders[i].percentage * fundedSum / 100);
                stakeholders[i].percentage = 0;
            }
        }
    }

    function sumToWithdraw() public view returns(uint){
        require(address(this).balance > 0, "This cause was not funded yet");

        uint valueToCompute;
        if(fundedSum == 0){
            valueToCompute = address(this).balance;
        }else{
            valueToCompute = fundedSum;
        }

        for(uint i=0; i<stakeholders.length; i++){
            if(stakeholders[i].addr == msg.sender){
                return (stakeholders[i].percentage * valueToCompute / 100);
            }
        }

        return 0;
    }
    
    function addStakeholder(address _addr, uint _percentage) external {
        require(msg.sender == owner, "Only the owner of the contract can add a stakeholder");
        for(uint i=0; i<stakeholders.length; i++){
            require(stakeholders[i].addr != _addr, "The stakeholder already exists!");
        }
        require(_percentage + totalPercentage <= 100, "The total percentage cannot be more than 100%");

        totalPercentage += _percentage;
        stakeholders.push(Stakeholder(_addr, _percentage));
    }

    function getPercentageRemaining() public view returns(uint){
        return 100 - totalPercentage;
    }
    
    receive () payable external {
        emit receivedFunds(msg.sender, msg.value);
    } 
    
}
