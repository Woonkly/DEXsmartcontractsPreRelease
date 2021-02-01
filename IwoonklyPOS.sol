// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;


interface IwoonklyPOS{

    function processReward(address sc, uint256 amount) external returns(bool);
}