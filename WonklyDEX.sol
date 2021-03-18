// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/utils/ReentrancyGuard.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/StakeManager.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/IwoonklyPOS.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/IWStaked.sol";
import "https://github.com/Woonkly/MartinHSolUtils/PausabledLMH.sol";

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

contract WonklyDEX is Owners, PausabledLMH, ReentrancyGuard {
    using SafeMath for uint256;
    IERC20 token;

    uint256 public totalLiquidity;
    uint32 internal _fee;
    uint32 internal _baseFee;
    address internal _operations;
    address internal _beneficiary;
    uint256 internal _coin_reserve;
    address internal _woonckyPOS;
    address internal _woonclyBEP20;
    IWStaked internal _stakes;
    address internal _stakeable;
    IWStaked internal _stakesSH;
    address internal _stakeableSH;
    address internal _woopSharedFunds;
    uint256 internal _gasRequired;

    constructor(
        address token_addr,
        uint32 fee,
        address operations,
        address beneficiary,
        address stake,
        address stakeSH,
        address woopSharedFunds
    ) public {
        token = IERC20(token_addr);
        _woonclyBEP20 = token_addr;
        _fee = fee;
        _paused = true;
        _beneficiary = beneficiary;
        _operations = operations;
        _baseFee = 10000;
        _coin_reserve = 0;
        _woonckyPOS = address(0);
        _stakeable = stake;
        _stakes = IWStaked(stake);
        _stakeableSH = stakeSH;
        _stakesSH = IWStaked(stakeSH);
        _woopSharedFunds = woopSharedFunds;
        _gasRequired = 150000;
    }

    function getCoinReserve() public view returns (uint256) {
        return _coin_reserve;
    }

    function getFee() public view returns (uint32) {
        return _fee;
    }

    event FeeChanged(uint32 oldFee, uint32 newFee);

    function setFee(uint32 newFee) external onlyIsInOwners returns (bool) {
        require((newFee > 0 && newFee <= 1000000), "DX:!");
        uint32 old = _fee;
        _fee = newFee;
        emit FeeChanged(old, _fee);
        return true;
    }

    function getBaseFee() public view returns (uint32) {
        return _baseFee;
    }

    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);

    function setBaseFee(uint32 newbFee) external onlyIsInOwners returns (bool) {
        require((newbFee > 0 && newbFee <= 1000000), "DX:!");
        uint32 old = _baseFee;
        _baseFee = newbFee;
        emit FeeChanged(old, _baseFee);
        return true;
    }

    function getGasRequired() public view returns (uint256) {
        return _gasRequired;
    }

    event GasRequiredChanged(uint256 oldg, uint256 newg);

    function setGasRequired(uint256 newg)
        external
        onlyIsInOwners
        returns (bool)
    {
        uint256 old = _gasRequired;
        _gasRequired = newg;
        emit GasRequiredChanged(old, _gasRequired);
        return true;
    }

    function getOperations() public view returns (address) {
        return _operations;
    }

    event OperationsChanged(address oldOp, address newOp);

    function setOperations(address newOp)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newOp != address(0), "DX:0addr");
        address old = _operations;
        _operations = newOp;
        emit OperationsChanged(old, _operations);
        return true;
    }

    function getWoonklyPOS() public view returns (address) {
        return _woonckyPOS;
    }

    event WoonklyPOSChanged(address oldaddr, address newaddr);

    function setWoonklyPOS(address newAddr)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newAddr != address(0), "!0");
        address old = _woonckyPOS;
        _woonckyPOS = newAddr;
        emit WoonklyPOSChanged(old, _woonckyPOS);
        return true;
    }

    function getBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    event BeneficiaryChanged(address oldBn, address newBn);

    function setBeneficiary(address newBn)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(newBn != address(0), "DX:0addr");
        address old = _beneficiary;
        _beneficiary = newBn;
        emit BeneficiaryChanged(old, _beneficiary);
        return true;
    }

    function getStakeAddr() public view returns (address) {
        return _stakeable;
    }

    event StakeAddrChanged(address old, address news);

    function setStakeAddr(address news) external onlyIsInOwners returns (bool) {
        require(news != address(0), "!0");
        address old = _stakeable;
        _stakeable = news;
        _stakes = IWStaked(news);
        emit StakeAddrChanged(old, news);
        return true;
    }

    function getStakeAddrSH() public view returns (address) {
        return _stakeableSH;
    }

    event StakeSHAddrChanged(address old, address news);

    function setStakeSHAddr(address news)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(news != address(0), "!0");
        address old = _stakeableSH;
        _stakeableSH = news;
        _stakesSH = IWStaked(news);
        emit StakeSHAddrChanged(old, news);
        return true;
    }

    function getWoopSHFunds() public view returns (address) {
        return _woopSharedFunds;
    }

    event WoopSHFundsChanged(address old, address news);

    function setWoopSHFunds(address news)
        external
        onlyIsInOwners
        returns (bool)
    {
        require(news != address(0), "!0");
        address old = _woopSharedFunds;
        _woopSharedFunds = news;

        emit WoopSHFundsChanged(old, news);
        return true;
    }

    event CoinReceived(uint256 coins);

    receive() external payable {
        if (!isPaused()) {
            coinToToken();
        }
        emit CoinReceived(msg.value);
    }

    function addCoin() external payable returns (bool) {
        _coin_reserve = address(this).balance;
        return true;
    }

    fallback() external payable {
        emit CoinReceived(msg.value);
    }

    function getMyCoinBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyTokensBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getSCtokenAddress() public view returns (address) {
        return address(token);
    }

    function _addStake(
        address account,
        uint256 amount,
        bool isSH
    ) internal returns (bool) {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(account)) {
            //NEW
            stk.newStake(account, amount);
        } else {
            //has funds
            stk.addToStake(account, amount);
        }

        return true;
    }

    event PoolCreated(
        uint256 totalLiquidity,
        address investor,
        uint256 token_amount
    );

    function createPool(uint256 token_amount)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(
            token.allowance(_msgSender(), address(this)) >= token_amount,
            "!aptk"
        );

        require(!_stakes.StakeExist(_msgSender()), "DX:!");
        require(totalLiquidity == 0, "DEX:i");
        require(msg.value > 0, "DX:I");
        totalLiquidity = address(this).balance;
        _coin_reserve = totalLiquidity;

        _addStake(_msgSender(), totalLiquidity, false);

        require(token.transferFrom(_msgSender(), address(this), token_amount));
        _paused = false;
        emit PoolCreated(totalLiquidity, _msgSender(), token_amount);
        return totalLiquidity;
    }

    function migratePool(uint256 token_amount, uint256 newLiq)
        external
        payable
        onlyIsInOwners
        nonReentrant
        returns (uint256)
    {
        require(isPaused(), "p");

        require(
            token.allowance(_msgSender(), address(this)) >= token_amount,
            "!aptk"
        );

        require(totalLiquidity == 0, "DEX:i");

        require(msg.value > 0, "DX:I");

        totalLiquidity = newLiq;
        _coin_reserve = address(this).balance;

        require(token.transferFrom(_msgSender(), address(this), token_amount));
        _paused = false;
        emit PoolCreated(_coin_reserve, _msgSender(), token_amount);
        return totalLiquidity;
    }

    struct Stake {
        address account;
        uint256 bnb;
        uint256 bal;
        uint256 woop;
        uint8 flag;
    }

    event PoolClosed(
        uint256 eth_reserve,
        uint256 token_reserve,
        uint256 liquidity,
        address destination
    );

    function closePool() public onlyIsInOwners nonReentrant returns (bool) {
        require(totalLiquidity > 0, "DX:0");

        uint256 token_reserve = token.balanceOf(address(this));

        require(token.transfer(_operations, token_reserve), "DX:1");
        address payable ow = address(uint160(_operations));

        _coin_reserve = address(this).balance;
        ow.transfer(_coin_reserve);

        uint256 liq = totalLiquidity;
        totalLiquidity = 0;
        _coin_reserve = 0;
        setPause(true);
        emit PoolClosed(_coin_reserve, token_reserve, liq, ow);
        return true;
    }

    function price(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        uint256 input_amount_with_fee = input_amount.mul(uint256(_fee));
        uint256 numerator = input_amount_with_fee.mul(output_reserve);
        uint256 denominator =
            input_reserve.mul(_baseFee).add(input_amount_with_fee);
        return numerator / denominator;
    }

    function planePrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256) {
        uint256 input_amount_with_fee0 = input_amount.mul(uint256(_baseFee));
        uint256 numerator = input_amount_with_fee0.mul(output_reserve);
        uint256 denominator =
            input_reserve.mul(_baseFee).add(input_amount_with_fee0);
        return numerator / denominator;
    }

    function calcDeal(uint256 amount)
        public
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 p4 = amount.mul(444) / 1000;
        uint256 p1 = amount - (p4 + p4);

        return (p4, p4, p1);
    }

    function isOverLimit(uint256 amount, bool isCoin)
        public
        view
        returns (bool)
    {
        if (getPercImpact(amount, isCoin) > 10) {
            return true;
        }
        return false;
    }

    function getPercImpact(uint256 amount, bool isCoin)
        public
        view
        returns (uint8)
    {
        uint256 reserve = 0;

        if (isCoin) {
            reserve = _coin_reserve;
        } else {
            reserve = token.balanceOf(address(this));
        }

        uint256 p = amount.mul(100) / reserve;

        if (p <= 100) {
            return uint8(p);
        } else {
            return uint8(100);
        }
    }

    function getMaxAmountSwap() public view returns (uint256, uint256) {
        return (
            _coin_reserve.mul(10) / 100,
            token.balanceOf(address(this)).mul(10) / 100
        );
    }

    function currentTokensToCoin(uint256 token_amount)
        public
        view
        returns (uint256)
    {
        uint256 token_reserve = token.balanceOf(address(this));
        return price(token_amount, token_reserve, _coin_reserve);
    }

    function currentCoinToTokens(uint256 coin_amount)
        public
        view
        returns (uint256)
    {
        uint256 token_reserve = token.balanceOf(address(this));
        return price(coin_amount, _coin_reserve, token_reserve);
    }

    struct processRewardInfo {
        uint256 remainder;
        uint256 woopsRewards;
        uint256 dealed;
        address me;
        bool resp;
    }

    function WithdrawReward(
        uint256 amount,
        bool isCoin,
        bool isSH
    ) external nonReentrant returns (bool) {
        IWStaked stk = getSTK(isSH);

        require(!isPaused(), "p");

        require(stk.StakeExist(_msgSender()), "DX:!");

        _withdrawReward(_msgSender(), amount, isCoin, isSH);

        return true;
    }

    function getSTK(bool isSH) internal view returns (IWStaked) {
        if (isSH) {
            return _stakesSH;
        }

        return _stakes;
    }

    function _withdrawReward(
        address account,
        uint256 amount,
        bool isCoin,
        bool isSH
    ) internal returns (bool) {
        require(!isPaused(), "p");

        IWStaked stk = getSTK(isSH);

        require(stk.StakeExist(account), "!E");

        /*
        if(!stk.StakeExist(account)){
            return false;
        }
        */

        uint256 bnb = 0;
        uint256 woop = 0;

        (bnb, woop) = stk.getReward(account);

        uint256 remainder = 0;

        if (isCoin) {
            require(amount <= bnb, "DX:1");

            require(amount <= getMyCoinBalance(), "DX:-c");

            address(uint160(account)).transfer(amount);

            //_coin_reserve = address(this).balance;

            remainder = bnb.sub(amount);
        } else {
            //token

            require(amount <= woop, "DX:amew");

            require(amount <= getMyTokensBalance(), "DX:-tk");

            require(token.transfer(account, amount), "DX:5");

            remainder = woop.sub(amount);
        }

        _coin_reserve = address(this).balance;

        /* 
        if(remainder==0){
            stk.changeReward(account,0, isCoin,1);    
        }else{
            stk.changeReward(account,remainder, isCoin,1);    
        }
        */

        stk.changeReward(account, remainder, isCoin, 1);
    }

    function getCalcRewardAmount(
        address account,
        uint256 amount,
        bool isSH
    ) public view returns (uint256, uint256) {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(account)) return (0, 0);

        uint256 liq = 0;

        (liq, , ) = stk.getStake(account);

        if (liq == 0) return (0, 0);

        uint256 part = (liq * amount) / totalLiquidity;

        if (part == 0) return (0, 0);

        uint256 remainder = amount - part;

        return (part, remainder);
    }

    event InsuficientRewardFund(address account, bool isCoin, bool isSH);
    event NewLeftover(address account, uint256 leftover, bool isCoin);

    function _DealLiquidity(
        uint256 amount,
        bool isCoin,
        bool isSH
    ) internal returns (uint256) {
        processRewardInfo memory slot;
        slot.dealed = 0;

        Stake memory p;

        IWStaked stk = getSTK(isSH);

        uint256 last = stk.getLastIndexStakes();

        for (uint256 i = 0; i < (last + 1); i++) {
            (p.account, p.bal, p.bnb, p.woop, p.flag) = stk.getStakeByIndex(i);
            if (p.flag == 1) {
                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(
                    p.account,
                    amount,
                    isSH
                );
                if (slot.woopsRewards > 0) {
                    stk.changeReward(p.account, slot.woopsRewards, isCoin, 2);
                    slot.dealed = slot.dealed.add(slot.woopsRewards);
                } else {
                    emit InsuficientRewardFund(p.account, isCoin, isSH);
                }
            }
        } //for

        return slot.dealed;
    }

    function _triggerReward(uint256 amount, bool isCoin)
        internal
        returns (bool)
    {
        if (_woonckyPOS == address(0)) {
            return false;
        }

        if (isCoin) {
            address payable ac = address(uint160(_woonckyPOS));
            (bool success, ) = ac.call{gas: _gasRequired, value: amount}("");
            return success;
        } else {
            IwoonklyPOS wsc = IwoonklyPOS(_woonckyPOS);
            token.approve(_woonckyPOS, amount);
            return wsc.processReward(_woonclyBEP20, amount);
        }
    }

    event PurchasedTokens(
        address purchaser,
        uint256 coins,
        uint256 tokens_bought
    );
    event FeeTokens(
        uint256 bnPart,
        uint256 liqPart,
        uint256 opPart,
        address beneficiary,
        address operations
    );

    function coinToToken() public payable nonReentrant returns (uint256) {
        require(!isPaused(), "p");

        require(totalLiquidity > 0, "DX:0");

        require(!isOverLimit(msg.value, true), "DX:c");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 tokens_bought = price(msg.value, _coin_reserve, token_reserve);

        uint256 tokens_bought0fee =
            planePrice(msg.value, _coin_reserve, token_reserve);

        //_coin_reserve=_coin_reserve.add(msg.value);

        _coin_reserve = address(this).balance;

        require(tokens_bought <= getMyTokensBalance(), "DX:a");
        require(token.transfer(_msgSender(), tokens_bought), "DX:b");

        emit PurchasedTokens(_msgSender(), msg.value, tokens_bought);

        uint256 tokens_fee = tokens_bought0fee - tokens_bought;

        uint256 tokens_bnPart;
        uint256 tokens_opPart;
        uint256 tokens_liqPart;

        (tokens_bnPart, tokens_liqPart, tokens_opPart) = calcDeal(tokens_fee);

        if (_woonckyPOS == address(0)) {
            require(token.transfer(_beneficiary, tokens_bnPart), "DX:1");
        } else {
            _triggerReward(tokens_bnPart, false);
        }

        require(token.transfer(_operations, tokens_opPart), "DX:3");

        processRewardInfo memory slot;

        slot.dealed = _DealLiquidity(tokens_liqPart, false, false);

        slot.dealed += _DealLiquidity(tokens_liqPart, false, true);

        emit FeeTokens(
            tokens_bnPart,
            tokens_liqPart,
            tokens_opPart,
            _beneficiary,
            _operations
        );

        if (slot.dealed > tokens_liqPart) {
            return tokens_bought;
        }

        uint256 leftover = tokens_liqPart.sub(slot.dealed);

        if (leftover > 0) {
            require(token.transfer(_operations, leftover), "DX:4");
            emit NewLeftover(_operations, leftover, false);
        }

        return tokens_bought;
    }

    event TokensSold(address vendor, uint256 eth_bought, uint256 token_amount);
    event FeeCoins(
        uint256 bnPart,
        uint256 liqPart,
        uint256 opPart,
        address beneficiary,
        address operations
    );

    function tokenToCoin(uint256 token_amount)
        external
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "p");

        require(
            token.allowance(_msgSender(), address(this)) >= token_amount,
            "!aptk"
        );

        require(totalLiquidity > 0, "DX:0");

        require(!isOverLimit(token_amount, false), "DX:c");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 eth_bought = price(token_amount, token_reserve, _coin_reserve);

        uint256 eth_bought0fee =
            planePrice(token_amount, token_reserve, _coin_reserve);

        require(eth_bought <= getMyCoinBalance(), "DX:!");

        _msgSender().transfer(eth_bought);

        _coin_reserve = address(this).balance;

        require(token.transferFrom(_msgSender(), address(this), token_amount));

        emit TokensSold(_msgSender(), eth_bought, token_amount);

        uint256 eth_fee = eth_bought0fee - eth_bought;
        uint256 eth_bnPart;
        uint256 eth_opPart;
        uint256 eth_liqPart;

        (eth_bnPart, eth_liqPart, eth_opPart) = calcDeal(eth_fee);

        address(uint160(_operations)).transfer(eth_opPart);

        if (_woonckyPOS == address(0)) {
            address(uint160(_beneficiary)).transfer(eth_bnPart);
        } else {
            _triggerReward(eth_bnPart, true);
        }

        processRewardInfo memory slot;

        slot.dealed = _DealLiquidity(eth_liqPart, true, false);

        slot.dealed += _DealLiquidity(eth_liqPart, true, true);

        emit FeeCoins(
            eth_bnPart,
            eth_liqPart,
            eth_opPart,
            _beneficiary,
            _operations
        );

        if (slot.dealed > eth_liqPart) {
            return eth_bought;
        }

        uint256 leftover = eth_liqPart.sub(slot.dealed);

        if (leftover > 0) {
            address(uint160(_operations)).transfer(leftover);
            emit NewLeftover(_operations, leftover, true);
        }

        _coin_reserve = address(this).balance;

        return eth_bought;
    }

    function calcTokenToAddLiq(uint256 coinDeposit)
        public
        view
        returns (uint256)
    {
        return
            (coinDeposit.mul(token.balanceOf(address(this))) / _coin_reserve)
                .add(1);
    }

    event LiquidityChanged(uint256 oldLiq, uint256 newLiq, bool isSH);

    function AddLiquidity(bool isSH)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        require(!isPaused(), "p");

        uint256 eth_reserve = _coin_reserve;

        uint256 token_amount = calcTokenToAddLiq(msg.value);

        address origin = _msgSender();

        if (isSH) {
            origin = _woopSharedFunds;
        }

        require(
            origin != address(0) &&
                token.allowance(origin, address(this)) >= token_amount,
            "DX:1"
        );

        uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;

        _coin_reserve = address(this).balance;

        _addStake(_msgSender(), liquidity_minted, isSH);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.add(liquidity_minted);

        require(token.transferFrom(origin, address(this), token_amount));

        emit LiquidityChanged(oldLiq, totalLiquidity, isSH);

        return liquidity_minted;
    }

    function getValuesLiqWithdraw(
        address investor,
        uint256 liq,
        bool isSH
    ) public view returns (uint256, uint256) {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(investor)) {
            return (0, 0);
        }

        uint256 inv;

        (inv, , ) = stk.getStake(investor);

        if (liq > inv) {
            return (0, 0);
        }

        uint256 eth_amount = liq.mul(_coin_reserve) / totalLiquidity;
        uint256 token_amount =
            liq.mul(token.balanceOf(address(this))) / totalLiquidity;
        return (eth_amount, token_amount);
    }

    function getMaxValuesLiqWithdraw(address investor, bool isSH)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        IWStaked stk = getSTK(isSH);

        if (!stk.StakeExist(investor)) {
            return (0, 0, 0);
        }

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 inv;

        (inv, , ) = stk.getStake(investor);

        uint256 eth_amount = inv.mul(_coin_reserve) / totalLiquidity;
        uint256 token_amount = inv.mul(token_reserve) / totalLiquidity;
        return (inv, eth_amount, token_amount);
    }

    event LiquidityWithdraw(
        address investor,
        uint256 coins,
        uint256 token_amount,
        uint256 newliquidity,
        bool isSH
    );

    function _withdrawFunds(
        address account,
        uint256 liquid,
        bool isSH
    ) internal returns (uint256, uint256) {
        IWStaked stk = getSTK(isSH);

        require(stk.StakeExist(account), "DX:!");

        uint256 inv_liq;

        (inv_liq, , ) = stk.getStake(account);

        require(liquid <= inv_liq, "DX:3");

        uint256 token_reserve = token.balanceOf(address(this));

        uint256 eth_amount = liquid.mul(_coin_reserve) / totalLiquidity;

        uint256 token_amount = liquid.mul(token_reserve) / totalLiquidity;

        require(eth_amount <= getMyCoinBalance(), "DX:1");

        require(token_amount <= getMyTokensBalance(), "DX:2");

        stk.substractFromStake(account, liquid);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.sub(liquid);

        address(uint160(account)).transfer(eth_amount);

        _coin_reserve = address(this).balance;

        if (isSH) {
            require(token.transfer(_woopSharedFunds, token_amount));
        } else {
            require(token.transfer(account, token_amount));
        }

        emit LiquidityWithdraw(
            account,
            eth_amount,
            token_amount,
            totalLiquidity,
            isSH
        );
        emit LiquidityChanged(oldLiq, totalLiquidity, isSH);
        return (eth_amount, token_amount);
    }

    function WithdrawLiquidity(uint256 liquid, bool isSH)
        external
        nonReentrant
        returns (uint256, uint256)
    {
        require(!isPaused(), "p");

        require(totalLiquidity > 0, "DX:0");

        //    IWStaked stk=getSTK(isSH);

        //  require( stk.StakeExist(_msgSender()),"DX:!");

        return _withdrawFunds(_msgSender(), liquid, isSH);
    }
}
