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

    uint256 public baseSPAmount;
    mapping (address => mapping(address => receiver)) public conversationGraph;
    mapping (address => Counters.Counter) public spCounter;

    // Constructor.
    constructor(uint256 amount) {// 1e16 = 0.01 matic
        baseSPAmount = amount;
    }

    // Functions
    function depositSPAmount(address _receiver) external payable {// msg.sender, msg.value, _receiver, 
        
        // Sanity checks
        require(conversationGraph[msg.sender][_receiver].processed == false, "The conversation is already processed for spam and the SPAmount is handled.");

        conversationGraph[msg.sender][_receiver].amountDeposited = msg.value;
        conversationGraph[msg.sender][_receiver].timestamp = block.timestamp;
        conversationGraph[msg.sender][_receiver].spam = false;
        conversationGraph[msg.sender][_receiver].processed = false;

        // Add event transfered happened.
    }

    function getSPAmount() external view returns(uint256 senderSPAmount) {

        // the value returned by getSPAmount needs to fed into depositSPAmount.
        senderSPAmount = baseSPAmount.mul(spCounter[msg.sender].current().add(1));

    }

    function declareSpam(address payable _sender) external {// Deposit the amount locked from contract to receiver.
        
        require(conversationGraph[_sender][msg.sender].processed == false, "Sender is already processed.");

        if(conversationGraph[_sender][msg.sender].timestamp.add(86400) <= block.timestamp){
            (bool success, ) = msg.sender.call{value: conversationGraph[_sender][msg.sender].amountDeposited}("");
            require(success, "Failed to send Ether");
        }

        spCounter[_sender].increment();
        conversationGraph[_sender][msg.sender].spam = true;
        conversationGraph[_sender][msg.sender].processed = true;

    }

    function canSendMessage(address _receiver) external view returns(bool status){
        status = conversationGraph[msg.sender][_receiver].spam;
    }

    function setApproval(address payable _sender) external {
        
        require(conversationGraph[_sender][msg.sender].processed == false, "Sender is already processed.");

        if(conversationGraph[_sender][msg.sender].timestamp.add(86400) <= block.timestamp){
            (bool success, ) = _sender.call{value: conversationGraph[_sender][msg.sender].amountDeposited}("");
            require(success, "Failed to send Ether");
        }

        conversationGraph[_sender][msg.sender].spam = false;
        conversationGraph[_sender][msg.sender].processed = true;
    }

    function unblock(address payable _sender) external payable{

        require(conversationGraph[_sender][msg.sender].processed == true, "Sender should be already processed, meaning it should be blocked");
        require(conversationGraph[_sender][msg.sender].spam == true, "Sender is already approved and unblocked, no need to call unblock further.");

        _sender.transfer(conversationGraph[_sender][msg.sender].amountDeposited);

        conversationGraph[_sender][msg.sender].spam = false;
        
    }
}
