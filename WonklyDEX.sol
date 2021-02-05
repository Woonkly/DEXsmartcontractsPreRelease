// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/math/SafeMath.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/token/ERC20/ERC20.sol";
import "https://github.com/Woonkly/OpenZeppelinBaseContracts/contracts/utils/ReentrancyGuard.sol";

import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/Pausabled.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/StakeManager.sol";
import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/IwoonklyPOS.sol";

import "https://github.com/Woonkly/DEXsmartcontractsPreRelease/IWStaked.sol";



contract WonklyDEX  is Owners,Pausabled,ReentrancyGuard {

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
    
  IWStaked    internal  _stakes;
  address internal  _stakeable;
    

  constructor(address token_addr,uint32 fee,address operations, address beneficiary,address stake)
    public {
    token = IERC20(token_addr);
    _woonclyBEP20=token_addr;
    _fee=fee;
    _paused=true;
    _beneficiary=beneficiary;
    _operations=operations;
    _baseFee=10000;
    _coin_reserve=0;
    _woonckyPOS=address(0);
    
    _stakeable=stake;
    _stakes= IWStaked(stake);
    
  }
  
  

    modifier IhaveEnoughTokens(uint256 token_amount) {
        require( token_amount <= getMyTokensBalance() ,"I do not have enough tokens " );
        _;
    }
  
  
    modifier IhaveEnoughCoins(uint256 coins) {
        require( coins <= getMyCoinBalance() ,"I do not have enough coins " );
        _;
    }
    
   
    modifier hasApprovedTokens(address sender, uint256 token_amount) {
    require(  token.allowance(sender,address(this)) >= token_amount , "Does not have approved tokens!"); //sender != address(0) &&
    _;
  }


    modifier HasLiquidity() {
         require(totalLiquidity>0,"DEX:NOT init - Cero  liquidity");
        _;
      }



    function getCoinReserve() public view returns(uint256){
        return  _coin_reserve;
    }


    function getFee() public view returns(uint32){
        return _fee;    
    }
    
    event FeeChanged(uint32 oldFee, uint32 newFee);

    function setFee(uint32 newFee) public onlyIsInOwners returns(bool){
        require( (newFee>0 && newFee<=1000000),'DX:!');
        uint32 old=_fee;
        _fee=newFee;
        emit FeeChanged(old,_fee);
        return true;
    }




    function getBaseFee() public view returns(uint32){
        return _baseFee;    
    }
    
    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);

    function setBaseFee(uint32 newbFee) public onlyIsInOwners returns(bool){
        require( (newbFee>0 && newbFee<=1000000),'DX:!');
        uint32 old=_baseFee;
        _baseFee=newbFee;
        emit FeeChanged(old,_baseFee);
        return true;
    }



    
    function getOperations() public view returns(address){
        return _operations;    
    }
    
    event OperationsChanged(address oldOp, address newOp);

    function setOperations(address newOp) public onlyIsInOwners returns(bool){
        require(newOp != address(0), "DX:0addr");
        address old=_operations;
        _operations=newOp;
        emit OperationsChanged(old,_operations);
        return true;
    }
    

    function getWoonklyPOS() public view returns(address){
        return _woonckyPOS;    
    }
    
    event WoonklyPOSChanged(address oldaddr, address newaddr);

    function setWoonklyPOS(address newAddr) public onlyIsInOwners returns(bool){
        //require(newAddr != address(0), "DX:0addr");
        address old=_woonckyPOS;
        _woonckyPOS=newAddr;
        emit WoonklyPOSChanged(old,_woonckyPOS);
        return true;
    }

    
    

    function getBeneficiary() public view returns(address){
        return _beneficiary;    
    }
    
    event BeneficiaryChanged(address oldBn, address newBn);

    function setBeneficiary(address newBn) public onlyIsInOwners returns(bool){
        require(newBn != address(0), "DX:0addr");
        address old=_beneficiary;
        _beneficiary = newBn;
        emit BeneficiaryChanged(old,_beneficiary);
        return true;
    }




    function getStakeAddr() public view returns(address){
        return _stakeable;
    }
    
    
    event StakeAddrChanged(address old,address news);
    function setStakeAddr(address news) public onlyIsInOwners returns(bool){
        address old=_stakeable;
        _stakeable=news;
        _stakes= IWStaked(news);
        emit StakeAddrChanged(old,news);
        return true;
    }







    
    event CoinReceived(uint256 coins);
      receive() external payable {
            // React to receiving ether
            if(!isPaused()) {
                coinToToken();
            }
            emit CoinReceived(msg.value);
        }
        

    fallback()  external payable { emit CoinReceived(msg.value); }
  
    function getMyCoinBalance() public view returns(uint256){
        /*
            address payable self = address(this);
            uint256 bal =  self.balance;    
            return bal;
        */
        return  address(this).balance;
    }
    
    function getMyTokensBalance() public view returns(uint256){
        return token.balanceOf(address(this));
    }

    function getSCtokenAddress() public view returns(address){
        return address(token);
    }
    


    function _addStake(address account, uint256 amount)   internal returns(bool){

        if(!_stakes.StakeExist(account)){
            //NEW
                        
            _stakes.newStake(account, amount );
            
            
        }else{
            //has funds
            
            _stakes.addToStake(account, amount);
            
        }
        
        return true;
        
    }


  
    event PoolCreated(uint256 totalLiquidity,address investor,uint256 token_amount);
    
    function createPool(uint256 token_amount) public payable hasApprovedTokens(_msgSender(), token_amount)  returns (uint256) {
          require(! _stakes.StakeExist(_msgSender()),"DX:!");    
          require(totalLiquidity==0,"DEX:init - already has liquidity");
          require(msg.value > 0 ,"Ivalid wei value (0) !");
          totalLiquidity = address(this).balance;
           _coin_reserve = totalLiquidity;
           
          _addStake(_msgSender(), totalLiquidity); 

          require(token.transferFrom(_msgSender(), address(this), token_amount));
          _paused=false;
          emit PoolCreated( totalLiquidity,_msgSender(),token_amount);
          return totalLiquidity;
    }
    
    
    
    
    
struct Stake {
    address account;
    uint256 bnb;
    uint256 bal;
    uint256 woop;
    uint8 flag; //0 no exist  1 exist 2 deleted
    
  }
    
    

    
    
    
    event PoolClosed(uint256 eth_reserve,uint256 token_reserve, uint256 liquidity,address destination);    
    
    
    function closePool() public onlyIsInOwners HasLiquidity returns(bool){
        uint256 fund=0;

        Stake memory p;

        uint256 last=_stakes.getLastIndexStakes();

        for (uint256 i = 0; i < (last +1) ; i++) {
            
            (p.account,p.bal ,p.bnb,p.woop ,p.flag)=_stakes.getStakeByIndex(i);

            if(p.flag == 1 ){
                
                (fund,,)=_stakes.getStake(p.account);
                
                address(uint160(p.account)).transfer(p.bnb);
                token.transfer(p.account, p.woop);
                
                _withdrawFunds(p.account, fund);
                
                _stakes.removeStake( p.account);

            }
        }
            
/*        
        for (uint32 i = 0; i < (_lastIndexStakes +1) ; i++) {
            Stake memory p= _Stakes[ i ];
            if(p.flag == 1 ){
                
                (fund,,)=getStake(p.account);
                
                address(uint160(p.account)).transfer(p.bnb);
                token.transfer(p.account, p.woop);
                
                _withdrawFunds(p.account, fund);
                
                removeStake( p.account);

            }
        }
*/        
        
        uint256 token_reserve = token.balanceOf(address(this));
        _coin_reserve = address(this).balance;
        

        require(token.transfer(_operations, token_reserve) ,"Error token.transfer tokens ");
        address payable ow = address(uint160(_operations));
        ow.transfer(_coin_reserve);
        uint256 liq=totalLiquidity;
        totalLiquidity=0;
        _coin_reserve=0;
        _stakes.removeAllStake();
        setPause(true);
        emit PoolClosed( _coin_reserve, token_reserve, liq,ow);    
        return true;
    }
    


    function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view  returns (uint256) {
          uint256 input_amount_with_fee = input_amount.mul( uint256(_fee));
          uint256 numerator = input_amount_with_fee.mul(output_reserve);
          uint256 denominator = input_reserve.mul(_baseFee).add(input_amount_with_fee);
          return numerator / denominator;
    }


    function planePrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
          uint256 input_amount_with_fee0 = input_amount.mul( uint256(_baseFee));
          uint256 numerator = input_amount_with_fee0.mul(output_reserve);
          uint256 denominator = input_reserve.mul(_baseFee).add(input_amount_with_fee0);
          return numerator / denominator;
    }



    function calcDeal(uint256 amount) public pure returns(uint256,uint256,uint256)  {
        
        uint256 p4=amount.mul(444)/1000;
        uint256 p1=amount-(p4+p4);
        
        return(p4,p4,p1);
        
    }
    
    
    function isOverLimit(uint256 amount,bool isCoin) public view returns(bool){
        if( getPercImpact( amount, isCoin)>10 ){
          return true;  
        } 
        return false;
    }
    
    
    function getPercImpact(uint256 amount,bool isCoin) public view returns(uint8){
        
        uint256 reserve=0;

        if(isCoin){
            reserve=_coin_reserve;
        }else{
            reserve=token.balanceOf(address(this));
        }
        
        uint256 p=amount.mul(100)/reserve;
        
        if(p<=100){
            return uint8(p);
        }else{
            return uint8(100);
        }
    }


    function getMaxAmountSwap() public view returns(uint256,uint256){
        
         return( _coin_reserve.mul(10)/100 , token.balanceOf(address(this)).mul(10)/100  );
        
    }
    

    function currentTokensToCoin(uint256 token_amount)public view returns(uint256){
          uint256 token_reserve = token.balanceOf(address(this));
          return price(token_amount, token_reserve, _coin_reserve); 
    }
    

    function currentCoinToTokens(uint256 coin_amount) public view returns(uint256){
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


    function WithdrawReward(uint256 amount, bool isCoin) Active  public returns(bool){
        require( _stakes.StakeExist(_msgSender()),"DX:!");    
        _withdrawReward( _msgSender(),  amount, isCoin);

        return true;
    }



    function _withdrawReward(address account, uint256 amount , bool isCoin) Active internal returns(bool){
        
        if(!_stakes.StakeExist(account)){
            return false;
        }
        
        uint256 bnb=0;
        uint256 woop=0;
        
        (bnb, woop) =_stakes.getReward(account );
        
        uint256 remainder = 0;
        
        if(isCoin){
            require(amount <= bnb,"DX:1");    

            require( amount <= getMyCoinBalance() ,"DX:-c" );        
            
            address(uint160(account)).transfer(amount);

            remainder = bnb.sub(amount);

        }else{  //token
            
            require(amount <= woop,"DX:amew");    

            require( amount <= getMyTokensBalance() ,"DX:-tk" );        
        
            require(token.transfer(account, amount) ,"DX:4");

            remainder = woop.sub(amount);
        }
        
        
        if(remainder==0){
            _stakes.changeReward(account,0, isCoin,1);    
        }else{
            _stakes.changeReward(account,remainder, isCoin,1);    
        }
        
        
    }




    function getCalcRewardAmount(address account,  uint256 amount) public view returns(uint256,uint256){
        
        if(!_stakes.StakeExist(account)) return (0,0);

        uint256 liq=0;

        (liq,,) = _stakes.getStake(account);
        
        if(liq==0) return (0,0);
        
        uint256 part=liq * amount / totalLiquidity;
        
        if(part==0) return (0,0);
        
        uint256 remainder=amount - part;
        
        return (part,remainder);    

    }

    event InsuficientRewardFund(address account,bool isCoin);
    event NewLeftover(address account, uint256 leftover,bool isCoin);


    function _processReward_2( uint256 amount,bool isCoin) internal returns(uint256){
        
        processRewardInfo memory slot;
        
        Stake memory p;

        uint256 last=_stakes.getLastIndexStakes();

        for (uint256 i = 0; i < (last +1) ; i++) {
            
            (p.account,p.bal ,p.bnb,p.woop ,p.flag)=_stakes.getStakeByIndex(i);
            if(p.flag == 1 ){

                (slot.woopsRewards, slot.remainder) = getCalcRewardAmount(p.account, amount );
                if(slot.woopsRewards>0){
                    _stakes.changeReward(p.account,slot.woopsRewards, isCoin,2);    
                    slot.dealed=slot.dealed.add(slot.woopsRewards);

                }else{
                    emit InsuficientRewardFund( p.account,isCoin);
                }

            }
        }//for
        
        return slot.dealed;
    }




    function _triggerReward(uint256 amount, bool isCoin) internal returns(bool){
        
        if(_woonckyPOS==address(0)){
            return false;
        }
        
        if(isCoin){
            /*
            address payable wp=address(uint160(_woonckyPOS));
            wp.transfer(amount);
            return true;
            */
            address payable ac=address(uint160(_woonckyPOS));
            (bool success,  ) =ac.call{gas: 150000,value: amount}("");
            return success;
            
        }else{
            IwoonklyPOS wsc=IwoonklyPOS(_woonckyPOS);
            token.approve(_woonckyPOS, amount);
            return wsc.processReward(_woonclyBEP20, amount);
        }
    }
    
    

    event PurchasedTokens(address purchaser,uint256 coins, uint256 tokens_bought);
    event FeeTokens(uint256 bnPart,uint256 liqPart,uint256 opPart,address beneficiary , address operations);
    
    function coinToToken() public payable Active HasLiquidity  returns (uint256) {
        
          require(!isOverLimit(msg.value,true),'DX:c');
        
          uint256 token_reserve = token.balanceOf(address(this));
          
          uint256 tokens_bought = price(msg.value, _coin_reserve , token_reserve);
          
          uint256 tokens_bought0fee = planePrice(msg.value, _coin_reserve , token_reserve); 

          _coin_reserve=_coin_reserve.add(msg.value);
          
          require( tokens_bought <= getMyTokensBalance() ,"DX:a" );
          require(token.transfer(_msgSender(), tokens_bought) ,"DX:b");
          
          emit PurchasedTokens(_msgSender(),  msg.value,  tokens_bought);

          uint256 tokens_fee=tokens_bought0fee - tokens_bought;
          
          uint256 tokens_bnPart;
          uint256 tokens_opPart;
          uint256 tokens_liqPart;
          
          ( tokens_bnPart, tokens_liqPart, tokens_opPart )=calcDeal(tokens_fee);
          
          if(_woonckyPOS==address(0)){
              
              require(token.transfer(_beneficiary, tokens_bnPart) ,"DX:1");
              
          }else{
              
            _triggerReward(tokens_bnPart, false);    
          }
          

          require(token.transfer(_operations, tokens_opPart) ,"DX:3");

            processRewardInfo memory slot;
            slot.dealed=_processReward_2( tokens_liqPart, false);
            uint256 leftover=tokens_liqPart.sub(slot.dealed);
            if(leftover > 0){
                require(token.transfer(_operations, leftover) ,"DX:4");
                emit NewLeftover( _operations, leftover,false);
            }

          emit FeeTokens(tokens_bnPart,tokens_liqPart,tokens_opPart,_beneficiary, _operations);
          
          
          
          return tokens_bought;
    }
    
    

    event TokensSold(address vendor,uint256 eth_bought,uint256 token_amount);
    event FeeCoins(uint256 bnPart,uint256 liqPart,uint256 opPart,address beneficiary , address operations);
    
    function tokenToCoin(uint256 token_amount) Active HasLiquidity hasApprovedTokens(_msgSender(), token_amount)  public returns (uint256) {
        
        require(!isOverLimit(token_amount,false),'DX:c');    
        
          uint256 token_reserve = token.balanceOf(address(this));

          uint256 eth_bought = price(token_amount, token_reserve, _coin_reserve ); 
          
          uint256 eth_bought0fee = planePrice(token_amount, token_reserve,  _coin_reserve); 

          require( eth_bought <= getMyCoinBalance() ,"DX:!" );
          
          _msgSender().transfer(eth_bought);

        _coin_reserve =address(this).balance;    

          require(token.transferFrom(_msgSender(), address(this), token_amount));
          
          emit TokensSold(_msgSender(),eth_bought, token_amount);

          uint256 eth_fee=eth_bought0fee - eth_bought;
          uint256 eth_bnPart;
          uint256 eth_opPart;
          uint256 eth_liqPart;
          

          ( eth_bnPart, eth_liqPart, eth_opPart )=calcDeal(eth_fee);
          
            address(uint160(_operations)).transfer(eth_opPart);
            

          if(_woonckyPOS==address(0)){
              
              address(uint160(_beneficiary)).transfer(eth_bnPart);
              
          }else{
              
            _triggerReward(eth_bnPart, true);    
            
          }



            processRewardInfo memory slot;
            slot.dealed=_processReward_2( eth_liqPart, true);
            uint256 leftover=eth_liqPart.sub(slot.dealed);
            if(leftover > 0){
                address(uint160(_operations)).transfer(leftover);
                emit NewLeftover( _operations, leftover,true);
            }

          _coin_reserve =address(this).balance;

          emit FeeCoins(eth_bnPart, eth_liqPart, eth_opPart, _beneficiary ,  _operations);
          
          return eth_bought;
    }
    

    function calcTokenToAddLiq(uint256 coinDeposit) public view returns(uint256){
          return (coinDeposit.mul(token.balanceOf(address(this))) / _coin_reserve ).add(1); 
    }

    


    event LiquidityChanged(uint256 oldLiq, uint256 newLiq);
    
    function AddLiquidity() public payable Active returns (uint256) {
        
        uint256 eth_reserve = _coin_reserve;
        
        uint256 token_amount = calcTokenToAddLiq(msg.value);
        
          require( _msgSender() != address(0) && token.allowance(_msgSender(),address(this)) >= token_amount   , "DX:1"); 
          
          uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;

          _coin_reserve=_coin_reserve.add(msg.value);    

          _addStake(_msgSender(), liquidity_minted);
          
          uint256 oldLiq=totalLiquidity;
          totalLiquidity = totalLiquidity.add(liquidity_minted);
          require(token.transferFrom(_msgSender(), address(this), token_amount));

          emit LiquidityChanged(oldLiq, totalLiquidity);
          return liquidity_minted;
    }



    function getValuesLiqWithdraw(address investor, uint256 liq) public view returns(uint256, uint256){
        
        if(!_stakes.StakeExist(investor)){
            return (0,0);
        }
        
       uint256 inv;
       
        (inv,,)=_stakes.getStake(investor);
        
        if(liq>inv){
            return (0,0);
        }
        
        uint256 eth_amount = liq.mul(_coin_reserve) / totalLiquidity;
        uint256 token_amount = liq.mul(token.balanceOf(address(this))) / totalLiquidity;
        return(eth_amount,token_amount);
        
    }




    function getMaxValuesLiqWithdraw(address investor) public view  returns(uint256,uint256, uint256){
        if(!_stakes.StakeExist(investor)){
            return (0,0,0);
        }
        
        uint256 token_reserve = token.balanceOf(address(this));

       uint256 inv;
       
        (inv,,)=_stakes.getStake(investor);
        
        uint256 eth_amount = inv.mul(_coin_reserve) / totalLiquidity;
        uint256 token_amount = inv.mul(token_reserve) / totalLiquidity;
        return(inv,eth_amount,token_amount);
        
    }
    
    
    event LiquidityWithdraw(address investor,uint256 coins, uint256 token_amount,uint256 newliquidity);
    
    function _withdrawFunds( address account, uint256 liquid)  internal returns(uint256,uint256){
        
        require( _stakes.StakeExist(account),"DX:!");    
        
       uint256 inv_liq;
       
        (inv_liq,,)=_stakes.getStake(account);

        
        require( liquid <= inv_liq ,"DX:3" );
        
          uint256 token_reserve = token.balanceOf(address(this));
          
          uint256 eth_amount = liquid.mul(_coin_reserve) / totalLiquidity;  
          uint256 token_amount = liquid.mul(token_reserve) / totalLiquidity;
          
          
          require( eth_amount <= getMyCoinBalance() ,"DX:1" );
          require( token_amount <= getMyTokensBalance() ,"DX:2" );

         
        _stakes.substractFromStake(account, liquid);         
          
          uint256 oldLiq=totalLiquidity;

          totalLiquidity = totalLiquidity.sub(liquid);
          
          address(uint160(account)).transfer(eth_amount);

          _coin_reserve = address(this).balance;
          
          require(token.transfer(account, token_amount));
          emit LiquidityWithdraw(account, eth_amount, token_amount, totalLiquidity );
          emit LiquidityChanged(oldLiq, totalLiquidity);
          return (eth_amount, token_amount);
    }
    
    
    function WithdrawLiquidity(uint256 liquid) public Active HasLiquidity  returns (uint256, uint256) {
        
        require( _stakes.StakeExist(_msgSender()),"DX:!");    
        
        return _withdrawFunds( _msgSender(), liquid);
        
       
    }



}
