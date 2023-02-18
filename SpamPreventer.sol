// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SpamPreventer{

    /*
     *  Events
    */
    event TransferSent(address _from, address _destAddr, uint _amount);

    /*
     *  Storage
    */
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    struct receiver{
        uint256 amountDeposited;
        uint256 timestamp;
        bool spam;
        bool processed;
    }

    struct requestMember{
        uint256 amountDeposited;
        uint256 timestamp;
        address sender;
        address receiver;
    }

    uint256 public baseSPAmount;
    mapping (address => mapping(address => receiver)) public conversationGraph;
    mapping (address => Counters.Counter) public spCounter;
    mapping (address => address[]) public spamAddresses;
    mapping (address => address[]) public senderChatRequestAddresses;
    mapping (address => address[]) public receiversChatRequestAddresses;
    requestMember[] public requestStack;

    // Constructor.
    constructor(uint256 amount) {// 1e16 = 0.01 matic
        baseSPAmount = amount;
    }


    function getAllSpamAddresses() public view returns (address[] memory) {
        return spamAddresses[msg.sender];
    }

// getSenderChatRequestsAddresses.
    function getChatRequestAdresses() public view returns (address[] memory) {
        return senderChatRequestAddresses[msg.sender];
    }

    function getReceiversChatRequestAdresses() public view returns (address[] memory) {
        return receiversChatRequestAddresses[msg.sender];
    }

    // Functions
    function depositSPAmount(address _receiver) external payable {// msg.sender, msg.value, _receiver, 
        
        // Sanity checks
        require(conversationGraph[msg.sender][_receiver].processed == false, "The conversation is already processed for spam and the SPAmount is handled.");

        conversationGraph[msg.sender][_receiver].amountDeposited = msg.value;
        conversationGraph[msg.sender][_receiver].timestamp = block.timestamp;
        conversationGraph[msg.sender][_receiver].spam = false;
        conversationGraph[msg.sender][_receiver].processed = false;

        senderChatRequestAddresses[msg.sender].push(_receiver);// Add timestamp.
        receiversChatRequestAddresses[_receiver].push(msg.sender);

        requestMember memory member;
        member.amountDeposited = msg.value;
        member.timestamp = block.timestamp;
        member.sender = msg.sender;
        member.receiver = _receiver;

        requestStack.push(member);
        // Add event transfered happened.
    }

    function returnRefund24() external{
        // Check for unprocessed request first.
        
        for(uint256 i=0; i<requestStack.length;){
            bool mark = false;
            for(uint256 j=0; j<senderChatRequestAddresses[requestStack[i].sender].length; j++){
                if(senderChatRequestAddresses[requestStack[i].sender][j] == requestStack[i].receiver && (block.timestamp - requestStack[i].timestamp) >= 86400){
                    // Process.
                    // Send eth back to sender from contract.
                    mark  = true;
                    (bool success, ) = requestStack[i].sender.call{value: requestStack[i].amountDeposited}("");
                    require(success, "Failed to send Ether");

                    senderChatRequestAddresses[requestStack[i].sender][j] = senderChatRequestAddresses[requestStack[i].sender][senderChatRequestAddresses[requestStack[i].sender].length - 1];
                    senderChatRequestAddresses[requestStack[i].sender].pop();

                    uint256 k=0;

                    for(k=0; k<receiversChatRequestAddresses[requestStack[i].receiver].length; k++){
                        if(receiversChatRequestAddresses[requestStack[i].receiver][k] == requestStack[i].sender){
                            break;
                        }
                    }

                    receiversChatRequestAddresses[requestStack[i].receiver][k] = receiversChatRequestAddresses[requestStack[i].receiver][receiversChatRequestAddresses[requestStack[i].receiver].length - 1];
                    receiversChatRequestAddresses[requestStack[i].receiver].pop();

                    requestStack[i] = requestStack[requestStack.length - 1];
                    requestStack.pop();
                    break;

                }
            }
            if(!mark){
                i++;
            }
        }

    }

    function getSPAmount() external view returns(uint256 senderSPAmount) {

        // the value returned by getSPAmount needs to fed into depositSPAmount.
        senderSPAmount = baseSPAmount.mul(spCounter[msg.sender].current().add(1));

    }

    function declareSpam(address payable _sender) external {// Deposit the amount locked from contract to receiver.
        
        require(conversationGraph[_sender][msg.sender].processed == false, "Sender is already processed.");

        if(conversationGraph[_sender][msg.sender].timestamp.add(86400) >= block.timestamp){
            (bool success, ) = msg.sender.call{value: conversationGraph[_sender][msg.sender].amountDeposited}("");
            require(success, "Failed to send Ether");
        }

        spCounter[_sender].increment();
        conversationGraph[_sender][msg.sender].spam = true;
        conversationGraph[_sender][msg.sender].processed = true;

        conversationGraph[msg.sender][_sender].spam = true;
        conversationGraph[msg.sender][_sender].processed = true;

        spamAddresses[msg.sender].push(_sender);

        uint256 i = 0;
        
        for(i=0; i<senderChatRequestAddresses[_sender].length; i++){
            if(senderChatRequestAddresses[_sender][i] == msg.sender){
                break;
            }
        }

        senderChatRequestAddresses[_sender][i] = senderChatRequestAddresses[_sender][senderChatRequestAddresses[_sender].length - 1];
        senderChatRequestAddresses[_sender].pop();

        // Remove sender from the receivers request map.
        i = 0;
        
        for(i=0; i<receiversChatRequestAddresses[msg.sender].length; i++){
            if(receiversChatRequestAddresses[msg.sender][i] == _sender){
                break;
            }
        }

        receiversChatRequestAddresses[msg.sender][i] = receiversChatRequestAddresses[msg.sender][receiversChatRequestAddresses[msg.sender].length - 1];
        receiversChatRequestAddresses[msg.sender].pop();
    }

    function canSendMessage(address _receiver) external view returns(bool status){

        status = !conversationGraph[msg.sender][_receiver].spam;
    }

    function setApproval(address payable _sender) external {
        
        require(conversationGraph[_sender][msg.sender].processed == false, "Sender is already processed.");

        if(conversationGraph[_sender][msg.sender].timestamp.add(86400) >= block.timestamp){
            (bool success, ) = _sender.call{value: conversationGraph[_sender][msg.sender].amountDeposited}("");
            require(success, "Failed to send Ether");
        }

        conversationGraph[_sender][msg.sender].spam = false;
        conversationGraph[_sender][msg.sender].processed = true;

        uint256 i = 0;
        
        for(i=0; i<senderChatRequestAddresses[_sender].length; i++){
            if(senderChatRequestAddresses[_sender][i] == msg.sender){
                break;
            }
        }

        senderChatRequestAddresses[_sender][i] = senderChatRequestAddresses[_sender][senderChatRequestAddresses[_sender].length - 1];
        senderChatRequestAddresses[_sender].pop();

        // Remove sender from the receivers request map.
        i = 0;
        
        for(i=0; i<receiversChatRequestAddresses[msg.sender].length; i++){
            if(receiversChatRequestAddresses[msg.sender][i] == _sender){
                break;
            }
        }

        receiversChatRequestAddresses[msg.sender][i] = receiversChatRequestAddresses[msg.sender][receiversChatRequestAddresses[msg.sender].length - 1];
        receiversChatRequestAddresses[msg.sender].pop();
    }

    function undeclareSpam(address payable _sender) external payable{// Called by receiver

        require(conversationGraph[_sender][msg.sender].processed == true, "Sender should be already processed, meaning it should be blocked");
        require(conversationGraph[_sender][msg.sender].spam == true, "Sender is already approved and unblocked, no need to call unblock further.");

        (bool success, ) = _sender.call{value: conversationGraph[_sender][msg.sender].amountDeposited}("");
        require(success, "Failed to send Ether");

        spCounter[_sender].decrement();
        conversationGraph[_sender][msg.sender].spam = false;
        conversationGraph[msg.sender][_sender].spam = false;

        uint256 i = 0;
        
        for(i=0; i<spamAddresses[msg.sender].length; i++){
            if(spamAddresses[msg.sender][i] == _sender){
                break;
            }
        }

        spamAddresses[msg.sender][i] = spamAddresses[msg.sender][spamAddresses[msg.sender].length-1];
        spamAddresses[msg.sender].pop();

    }

    function blockContact(address _addrToBlock) external{

        conversationGraph[msg.sender][_addrToBlock].spam = true;
        conversationGraph[_addrToBlock][msg.sender].spam = true;

    }

    function unblockContact(address _addrToUnblock) external{

        conversationGraph[msg.sender][_addrToUnblock].spam = false;
        conversationGraph[_addrToUnblock][msg.sender].spam = false;

    }
}