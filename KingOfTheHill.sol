// SPDX-License-Identifier: GPL-3.0
//finney = 001000000000000000
//test   = 002000000000000000
//test   = 000900000000000000

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol" ;

/** @title King of the hill */
contract KingOfTheHill {
   
    using Address for address payable;
    
    /** @Dev States variables
      * @param _owner : the creator of the contract (he wil receive all the tax from each game)
      * @param _profit : the total amount of ether made because od the tax.
      * @param _tax : the tax that will be given to the owner for each game.
      * @param _winningsBlocks : the required numbers of blocks resolved, to win the game.
      * @param _kingBlocks : the block where the last king has took position.
      * @param _maxBid : the actual bid made by the current king.
      * @param _kingOfTheHill : the current king 👑.
      * @param _potTotal : the total amount in the pot.
      */
    mapping(address => uint256) private _balances;
    
    // variable states concernant que le owner
    address private _owner;
    uint256 private _profit;
    
    //variable states initialisé au lors du constructor
    uint private _tax;
    uint256 private _winningBlocks;
    uint private _kingBlocks;
    uint256 private _maxBid;
    address private _kingOfTheHill;
    uint256 private _potTotal;
    
    
    constructor(uint tax_, uint winningBlocks_) payable {
        require(msg.value >= 1e15, "KingOfTheHill: you must to put at least 1 finney to deploy the contract");
        require(tax_ <= 10, "KingOfTheHill: tax cannot exceed 10 percent");
        _owner = msg.sender;
        _tax = tax_;
        _winningBlocks = winningBlocks_;
        _maxBid = msg.value;
        _potTotal += msg.value;
    }
    
    event NewKing(address indexed newKing, uint256 amount)

    /** @dev This is the main function each player must send the double amount of the current king
             to pretend to the crown ! then if nobody bid higher during x number of blocks resolved
             he will win.
      */       
             
    function iAmTheKing() public payable {
        require(msg.value >= (_maxBid * 2), "KingOfTheHill: you must put twice higher than the current king to be king");
        require(msg.sender != _kingOfTheHill, "KingOfTheHill: you are already the boss ;)");
        
        if(block.number - _kingBlocks > _winningBlocks && _kingBlocks != 0) {            // le roi a GAGNE 
            _profit += (_potTotal * _tax) / 100;                                            // on compte les profits total réalisé
            payable(_owner).sendValue((_potTotal * _tax) / 100);                            // le createur récupere ses profits
            payable(_kingOfTheHill).sendValue(_potTotal * 80 / 100);                        // le roi aussi
            _maxBid = (_potTotal * (100 - (80 + _tax)) / 100) * 2;                          // recommence la partie avec le reste de l'ancienne partie + le nouveau king qui a * 2 le pot Totall
            _potTotal = (address(this).balance - msg.value) + _maxBid;                          // on met le reste dans le pot pour la nouvelle partie
            _balances[msg.sender] = msg.value - _maxBid;                              // on renvoie le surplus au nouveau premier roi
        } else {                                                                            // faite place au nouveau roi !
            _maxBid = msg.value;
            _potTotal += _maxBid;
        }
        _kingBlocks = block.number;
        _kingOfTheHill = msg.sender;
    }
    
    function askForReward() public {
        require(block.number - _kingBlocks > _winningBlocks, "KingOfTheHill: you have not won yet ! check 'blocksToWin' to see how many blocks you have to wait again");
        require(msg.sender == _kingOfTheHill, "KingOfTheHill: You must be the king to use this function");
        
        _profit += (_potTotal * _tax) / 100;                       
        payable(_owner).sendValue((_potTotal * _tax) / 100);       
        payable(_kingOfTheHill).sendValue(_potTotal * 80 / 100);   
        _maxBid = (_potTotal * (100 - (80 + _tax)) / 100);    
        _potTotal = (address(this).balance);
        _kingBlocks = 0;
    }
    
    function withdrawBalance() public {
        require(_balances[msg.sender] > 0, "SmartWallet: can not withdraw 0 ether");
        uint256 amount = _balances[msg.sender];
        _balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amount);
    }
    
    function kingHasWon() public view returns(bool){
        return block.number - _kingBlocks > _winningBlocks ? true : false;
    }
    
    function maxbid() public view returns(uint256) {
        return (_maxBid);
    }
    
    function currentKing() public view returns(address) {
        return (_kingOfTheHill);
    }
    
    function seeProfits() public view returns(uint256) {
        return (_profit);
    }
    
    function seeBalance() public view returns(uint256) {
        return (_balances[msg.sender]);
    }
    
    function seePot() public view returns(uint256) {
        return (_potTotal);
    }
    
}
