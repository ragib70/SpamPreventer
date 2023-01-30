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

    function declareSpam(address _sender) external {// Deposit the amount locked from contract to receiver.
        
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

    // Function in case of approval.

    // function get_login_status(address _wallet_address) external view returns (bool status){

    //     status = false;

    //     if(spCounter[_wallet_address].current()>=0){
    //         status = true;
    //     }
    // }

    // function set_create_user(address _wallet_address) external {

    //     // Sanity checks for spCounter.
    //     require(spCounter[_wallet_address].current() !=0, "Wallet Address already present, no need to create user");
    //     spCounter[_wallet_address].reset();

    // }

    // function get_milestone_list(uint256 _idx) public view returns(milestone[] memory _milestone_list){
    //     _milestone_list = dao_bounties[_idx].milestones_list;
    // }

    // // Function to enter as contributor 
    // function push_contributor(uint256 _idx, string memory _by, string memory _name, string memory _title, string memory _email, address _wallet_address) public {
        
    //     bounty storage _bounty = dao_bounties[_idx];

    //     // Sanity checks for contributors.
    //     require(_bounty.is_bounty_closed == false, "Bounty is closed, choose a different bounty");

    //     contributor memory _contributor;
    //     _contributor.by = _by;
    //     _contributor.name = _name;
    //     _contributor.title = _title;
    //     _contributor.email = _email;
    //     _contributor.wallet_address = _wallet_address;

    //     _bounty.contributor_list.push(_contributor);
    // }

    // function get_contributor_list(uint256 _idx) public view returns(contributor[] memory _contributor_list){
    //     _contributor_list = dao_bounties[_idx].contributor_list;
    // }

    // // Function to revoke the bounty.
    // function revoke_bounty(uint256 _idx, IERC20 token) external onlyOwner{
    //     bounty storage _bounty = dao_bounties[_idx];

    //     // Sanity checks
    //     require(_bounty.is_bounty_closed == false, "Bounty is closed, choose a different bounty");

    //     for(uint256 i=0; i<_bounty.milestones_list.length; i++){
    //         uint256 erc20balance = token.balanceOf(address(this));
    //         require(_bounty.milestones_list[i].is_milestone_acheived == false, "Milestone already acheived, payed to the contributor cannot revoke");
    //         require(_bounty.milestones_list[i].amount <= erc20balance, "balance is low");
    //         token.transfer(msg.sender, _bounty.milestones_list[i].amount);
    //         emit TransferSent(address(this), msg.sender, _bounty.milestones_list[i].amount);
    //     }

    //     _bounty.is_bounty_closed = true;
    // }

    // // Function to approve the bounty depending upon the milestone.
    // function approve_bounty(uint256 _idx, uint256 _milestone_idx, uint256 _contributor_idx, IERC20 token) external onlyOwner{
    //     bounty storage _bounty = dao_bounties[_idx];

    //     // Sanity checks
    //     require(_bounty.is_bounty_closed == false, "Bounty is closed, choose a different bounty");
    //     require(_bounty.milestones_list[_milestone_idx].is_milestone_acheived == false, "Milestone already acheived, choose a different milestone");
    //     require(_bounty.milestones_list[_milestone_idx].timestamp <= block.timestamp, "Milestone deadline yet not acheived");

    //     token.transfer(_bounty.contributor_list[_contributor_idx].wallet_address, _bounty.milestones_list[_milestone_idx].amount);
    //     emit TransferSent(address(this), _bounty.contributor_list[_contributor_idx].wallet_address, _bounty.milestones_list[_milestone_idx].amount);

    //     _bounty.milestones_list[_milestone_idx].is_milestone_acheived = true;
    // }
}
