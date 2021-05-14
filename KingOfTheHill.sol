// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol" ;

contract KingOfTheHill {
    using Address for address payable;
    
    mapping(address => uint256) private _balances;
    
    // variable state concernant que le owner
    address private _owner;
    uint256 private _profit;
    
    //variable initialisé au lors du constructor
    uint private _tax;
    uint256 private _winningBlocks;
    uint private _kingBlocks;
    uint256 private _maxBid;
    address private _kingOfTheHill;
    
    
    constructor(uint tax_, uint winningBlocks_) payable {
        require(tax_ <= 10, "KingOfTheHill: tax cannot exceed 10 percent");
        _owner = msg.sender;
        _tax = tax_;
        _winningBlocks = winningBlocks_;
        _kingBlocks = block.number;
        _kingOfTheHill = msg.sender;
        _maxBid = msg.value;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "KingOfTheHill: Only the owner can use it");
        _;
    }
    
    function iAmTheKing() public payable {
        require(msg.value >= (_maxBid * 2), "KingOfTheHill: you must put twice higher than the current king to be king");
        require(msg.sender != _kingOfTheHill, "KingOfTheHill: you are already the boss ;)");
        
        if(block.number - _kingBlocks > _winningBlocks) {           // le roi a GAGNE 
            _profit += (_maxBid * _tax) / 100;                      // le createur récupere ses profits
            payable(_kingOfTheHill).sendValue(_maxBid * 80 / 100); // le roi aussi
            
            _maxBid = (_maxBid * (100 - (80 + _tax) / 100)) * 2;    // recommence la partie avec le reste de l'ancienne partie + le nouveau king qui a * 2 le pot Totall
            _kingBlocks = block.number;                             // nouveau block checké
            _kingOfTheHill = msg.sender;
            _balances[msg.sender] = msg.value % (_maxBid / 2);           // on renvoie le surplus au nouveau premier roi
        } else {                                                    // faite place au nouveau roi !
            _maxBid = msg.value;
            _kingOfTheHill = msg.sender;
            _kingBlocks = block.number;
        }
        
    }
    
    function withdrawProfit() public onlyOwner {
        require(_profit > 0, "SmartWallet: can not withdraw 0 ether");
        uint256 amount = _profit;
        _profit = 0;
        payable(msg.sender).sendValue(amount);
    }
    
    function withdrawBalance() public {
        require(_balances[msg.sender] > 0, "SmartWallet: can not withdraw 0 ether");
        uint256 amount = _balances[msg.sender];
        _balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amount);
    }
    
    function blocksToWin() public view returns(uint256){
        return (_winningBlocks - (block.number - _kingBlocks));
    }
    
    function currentBlock() public view returns(uint256) {
        return (block.number);
    }
    
    function maxbid() public view returns(uint256) {
        return (_maxBid);
    }
    
    function currentKing() public view returns(address) {
        return (_kingOfTheHill);
    }
    function seeProfit() public view returns(uint256) {
        return (_profit);
    }
    
    function seeBalance() public view returns(uint256) {
        return (_balances[msg.sender]);
    }
    
   // function rugpull() public {
    //    payable(address.this).sendValue(_kingOfTheHill);
    //}
