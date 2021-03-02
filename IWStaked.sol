// SPDX-License-Identifier: MIT

/**
MIT License

Copyright (c) 2021 Woonkly OU

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED BY WOONKLY OU "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/
pragma solidity ^0.6.6;


interface IWStaked{

    function StakeExist(address account) external view returns (bool) ;
    function addToStake(address account, uint256 addAmount) external returns(uint256);
    function newStake(address account,uint256 amount ) external returns (uint256);
    function getStake(address account) external view returns( uint256 ,uint256,uint256) ;
    function removeStake(address account) external;
    function renewStake(address account, uint256 newAmount) external returns(uint256);
    function getStakeCount() external view returns(uint256) ;
    function getLastIndexStakes() external view returns (uint256) ;
    function getStakeByIndex(uint256 index) external  view returns(address, uint256 ,uint256,uint256,uint8);
    function removeAllStake() external returns(bool);
    function balanceOf(address account)  external view returns(uint256) ;
    function changeReward(address account,uint256 amount,bool isCoin,uint8 set) external returns(bool);
    function substractFromStake(address account, uint256 subAmount) external returns(uint256);
    function getReward(address account )external view returns(uint256,uint256);
    
}