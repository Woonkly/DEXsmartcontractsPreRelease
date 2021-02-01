// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


interface IWStaked{

    function StakeExist(address account) external returns (bool) ;
    function addToStake(address account, uint256 addAmount) external returns(uint256);
    function newStake(address account,uint256 amount ) external returns (uint256);
    function getStake(address account) external returns( uint256 ,uint256,uint256) ;
    function removeStake(address account) external;
    function renewStake(address account, uint256 newAmount) external returns(uint256);
    function getStakeCount() external returns(uint256) ;
    function getLastIndexStakes() external returns (uint256) ;
    function getStakeByIndex(uint256 index) external  returns(address, uint256 ,uint256,uint256,uint8);
    function removeAllStake() external returns(bool);
    function balanceOf(address account)  external returns(uint256) ;
    function changeReward(address account,uint256 amount,bool isCoin,uint8 set) external returns(bool);
    function substractFromStake(address account, uint256 subAmount) external returns(uint256);
    function getReward(address account )external returns(uint256,uint256);
    
}