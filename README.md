# king-of-the-hill
![KOTH](./koth.png)

**url contract deployment** : https://rinkeby.etherscan.io/address/0x49d2bf95fbc1d381d1960bf768abec2c09ae08fc

**network** : rinkeby

## Rules ##

In this game only one will prevail to the top !!!! (like fornite). To get up there players must
fill up the chess the double amount of the current amount in the chess and which represent the reward.

To be able to steal the chess you have to stand until 8 blocks has been resolved in the blockchain test
rinkeby. 

Once a player has won the reward will be divided into 3 part :
1. 5% for the owner of the contract.
2. 80% for the king.
3. 15% as a seed for the next game.

if a bid is made after *8 blocks* has been resolved a new game is launch with the seed and a bid twice
higher from the player the rest of his money will be given back in his balance.

Otherwise the winner will also be able to claim his reward then the contract will have to wait a valiant
warrior to take the chess that contain the seed.

## The game ##

```js
// SPDX-License-Identifier: GPL-3.0
//finney = 001000000000000000
//test   = 002000000000000000
//test   = 000900000000000000

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol" ;

/** @title King of the hill */
contract KingOfTheHill {

    using Address for address payable;
    
    mapping(address => uint256) private _balances;
    
    // variable states concernant que le owner
    address private _owner;
    uint256 private _profit;
    
    // variable states initialisé au lors du constructor
    uint private _tax; //                   : the tax that will be given to the owner for each game.
    uint256 private _winningBlocks; //      : the required numbers of blocks resolved, to win the game.
    uint private _kingBlocks; //            : the block where the last king has took position.
    address private _kingOfTheHill; //      : the current king 👑.
    uint256 private _chess; //              : the total amount in the pot.
    
    // here will set all our variables to start the game with the function "iAmTheKing"
    constructor(uint tax_, uint winningBlocks_) payable {
        require(msg.value >= 1e15, "KingOfTheHill: you must to put at least 1 finney to deploy the contract");
        require(tax_ <= 10, "KingOfTheHill: tax cannot exceed 10 percent");
        _owner = msg.sender;
        _tax = tax_;
        _winningBlocks = winningBlocks_;
        _chess += msg.value;
    }
    
    event NewKing(address indexed newKing, uint256 amount);
    event HasWon(address indexed king, uint256 amount);
    event Withdrew(address indexed sender, uint256 amount);

    /**
     * @dev I am the king :
     *      This is the main function each player must send the double amount of the current king
     *      to pretend to the crown ! then if nobody bid higher during x number of blocks resolved
     *      he will win.
     *      
     *      We face 2 conditions :
     * 
     *      KING HAS WON !
     * 
     *      1.We first count the profits made then send it to the owner of the contract(_owner).
     *      2.We send 80% of the pot to the winner (_kingOfTheHill).
     *      3.We reinitialise a new game starting with a bid twice higher than the seed from the previous game.
     *      4.We set the new pot with the seed + the fresh bid of the first king.
     *      5.We transfer the extra to the balance of the new king.
     * 
     * 
     *      NEW KING !
     * 
     *      1.We reset all the king's status [_maxbid, _potTotal, _kingBlocks, _kingOfTheHill]
    */       
             
    function iAmTheKing() public payable {
        require(msg.value >= (_chess * 2), "KingOfTheHill: you must put twice higher than the current king to be king");
        require(msg.sender != _kingOfTheHill, "KingOfTheHill: you are already the boss ;)");
        
        if(block.number - _kingBlocks > _winningBlocks && _kingBlocks != 0) {            // le roi a GAGNE 
            _profit += (_chess * _tax) / 100;                                            // on compte les profits total réalisé
            payable(_owner).sendValue((_chess * _tax) / 100);                            // le createur récupere ses profits
            payable(_kingOfTheHill).sendValue(_chess * 80 / 100);
            emit HasWon(_kingOfTheHill, _chess * 80 / 100);                              // le roi aussi
            _chess = ((address(this).balance - msg.value) * 3);                          // on met le reste dans le pot pour la nouvelle partie
            _balances[msg.sender] = msg.value - (_chess / 3 * 2);                        // on renvoie le surplus au nouveau premier roi
            
        } else {                                                                         // faite place au nouveau roi !
            _chess += msg.value;
        }
        _kingBlocks = block.number;
        _kingOfTheHill = msg.sender;
        emit NewKing(msg.sender, msg.value);
    }
    
    /**
     * @dev Ask for Reward :
     *      Same as "i am the king",
     *      by claiming reward here the new game won't start until a bidder put ether in the function "i am the king".
     *      We put _kingBlocks to 0 to not trigger the condition in i am the king.
     */
    function claimReward() public {
        require(block.number - _kingBlocks > _winningBlocks, "KingOfTheHill: you have not won yet ! check 'blocksToWin' to see how many blocks you have to wait again");
        require(msg.sender == _kingOfTheHill, "KingOfTheHill: You must be the king to use this function");
        
        _profit += (_chess * _tax) / 100;                       
        payable(_owner).sendValue((_chess * _tax) / 100);       
        payable(_kingOfTheHill).sendValue(_chess * 80 / 100);
        emit HasWon(_kingOfTheHill, _chess * 80 / 100); 
        _chess = (address(this).balance);
        _kingBlocks = 0;
    }
    
    /**
     * @dev withdraw balance :
     *      withdraw the extra ether.
     */
    function withdrawBalance() public {
        require(_balances[msg.sender] > 0, "SmartWallet: can not withdraw 0 ether");
        uint256 amount = _balances[msg.sender];
        _balances[msg.sender] = 0;
        payable(msg.sender).sendValue(amount);
        emit Withdrew(msg.sender, amount);
    }
    
    /**
     * @dev calls kingHasWon 
     * @return : return true or false depending if the king Has won the game
     */
    function kingHasWon() public view returns(bool){
        return block.number - _kingBlocks > _winningBlocks ? true : false;
    }
    
    /**
     * @dev calls currentKing 
     * @return : return the address of the current king
     */
    function currentKing() public view returns(address) {
        return (_kingOfTheHill);
    }
    
    /**
     * @dev calls seeProfits 
     * @return : return the total profits made from the 1st game
     */
    function seeProfits() public view returns(uint256) {
        return (_profit);
    }
    
    /**
     * @dev calls seeBalance
     * @return : return the balance of the sender
     */
    function seeBalance() public view returns(uint256) {
        return (_balances[msg.sender]);
    }
    
    /**
     * @dev calls kingHasWon 
     * @return : return the total amount of the pot
     */
    function seePot() public view returns(uint256) {
        return (_chess);
    }   
}
