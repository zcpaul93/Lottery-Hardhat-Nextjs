// SPDX-License-Identifier: GPL-3.0
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    uint256 public constant ticketPrice = 0.01 ether;
    uint256 public constant maxTickets = 100;
    uint256 public constant ticketCommission = 0.001 ether;
    uint256 public constant duration = 30 minutes;

    uint256 public expiration;
    address public lotteryOperator;
    uint256 public operatorTotalComission = 0;
    address public lastWinner;
    uint256 public lastWinnerAmount;

    mapping(address => uint256) public winnings;
    address[] public tickets;

    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator" 
        );
        _;
    }

    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    constructor(){
        // lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }
    
    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets() public payable {
        require(
            msg.value % ticketPrice == 0,
            string.concat(
                "the value must be multiple of ",
                Strings.toString(ticketPrice),
                " Ether"
            )
        );

        uint256 numOfTicketsToBuy = msg.value / ticketPrice;

        require(
            numOfTicketsToBuy <= RemainingTickets(),
            "Not enough tickets avaible."
        );

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }
    }

 
    function DrawWinnerTicket() public isOperator {
        require(
            tickets.length > 0, "No tickets were purchased"
        );

        bytes32 blockHash = blockhash(block.number - tickets.length);

        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, blockHash))
        );
        
        uint256 winnigTicket = randomNumber % tickets.length;
        address winner = tickets[winnigTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
        lastWinnerAmount = winnings[winner];
        operatorTotalComission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public isOperator{
        require(
            tickets.length == 0, "Cannot Restart Draw as Draw is in play"
        );

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256){
        address payable winner = payable(msg.sender);
        uint256 reward2Transfer = winnings[winner];
        
        return reward2Transfer;
    }

    function WithdrawWinnings() public isWinner {
        address payable winner = payable(msg.sender);
        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;

        winner.transfer(reward2Transfer);
    }

    function RefundAll() public{
        require(
            block.timestamp >= expiration, "the lottery not expired yet"
        );

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
    }

    function WithdrawCommission() public isOperator {
        address payable operator = payable(msg.sender);
        uint256 commission2Transfer = operatorTotalComission;
        operatorTotalComission = 0;

        operator.transfer(commission2Transfer);
    }

    function IsWinner() public view returns (bool) {
        return  winnings[msg.sender] > 0;
    }   

    function CurrentWinningReward() public view returns (uint256){
        return tickets.length * ticketPrice;
    }

    function RemainingTickets() public view returns (uint256){
        return maxTickets - tickets.length;
    }    

}
   