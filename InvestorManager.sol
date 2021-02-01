// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./../contracts/math/SafeMath.sol";



contract InvestorManager {

 using SafeMath for uint256;

    struct Investor {
    address account;
    uint256 liquidity;
    uint8 flag; //0 no exist  1 exist 2 deleted
    
  }

  // las index of 
  uint256 internal _lastIndexInvestors;
  // store new  by internal  id (_lastIndexInvestors)
  mapping(uint256 => Investor) internal _Investors;    
  // store address  -> internal  id (_lastIndexInvestors)
  mapping(address => uint256) internal _IDInvestorsIndex;    
 uint256 internal _InvestorCount;

 

constructor () internal {
    
      _lastIndexInvestors = 0;
       _InvestorCount = 0;

    }    



    function getInvestorCount() public view returns (uint256) {
        return _InvestorCount;
    }


    function InvestorExist(address account) public view returns (bool) {
        return _InvestorExist( _IDInvestorsIndex[account]);
    }

    function InvestorIndexExist(uint256 index) public view returns (bool) {
        
        if(_InvestorCount==0) return false;
        
        if(index <  (_lastIndexInvestors + 1) ) return true;
        
        return false;
    }


    function _InvestorExist(uint256 InvestorID)internal view returns (bool) {
        
        //0 no exist  1 exist 2 deleted
        if(_Investors[InvestorID].flag == 1 ){ 
            return true;
        }
        return false;         
    }


      modifier onlyNewInvestor(address account) {
        require(!this.InvestorExist(account), "This Investor account exist");
        _;
      }
      
      
      modifier onlyInvestorExist(address account) {
        require(this.InvestorExist(account), "This Investor account not exist");
        _;
      }
      
      modifier onlyInvestorIndexExist(uint256 index) {
        require(this.InvestorIndexExist(index), "This Investor index not exist");
        _;
      }
  
  
  
  
  event addNewInvestor(address account,uint256 liquidity);
    
     
 function newInvestor(address account,uint256 liquidity ) internal onlyNewInvestor(account) returns (uint256){
    _lastIndexInvestors=_lastIndexInvestors.add(1);
    _InvestorCount=  _InvestorCount.add(1);
    
    _Investors[_lastIndexInvestors].account = account;
    _Investors[_lastIndexInvestors].liquidity = liquidity;
    _Investors[_lastIndexInvestors].flag = 1;
    
    _IDInvestorsIndex[account] = _lastIndexInvestors;
    
    emit addNewInvestor(account,liquidity);
    return _lastIndexInvestors;
}    


function adminInvestor(address account,uint256 liquidity) internal returns(bool){
    if(!InvestorExist(account)){
        newInvestor(account, liquidity );
    }else{
        setInvestorAddLiquidity( account, liquidity);
    }
}



event removeInvestor(address account);

function disableInvestor(address account) internal onlyInvestorExist(account) {
    _Investors[ _IDInvestorsIndex[account] ].flag = 2;
    _InvestorCount=  _InvestorCount.sub(1);
    emit removeInvestor( account);
}



 function getInvestor(address account) public view  onlyInvestorExist(account) returns( uint256 , address) {
     
        Investor memory p= _Investors[ _IDInvestorsIndex[account] ];
         
        return (p.liquidity, p.account);
    }

function getInvestorLiquidity(address account) public view returns(uint256){
    if(!InvestorExist(account)) return 0;
    Investor memory p= _Investors[ _IDInvestorsIndex[account] ];
    return p.liquidity;
}


function getInvestorByIndex(uint256 index) public view onlyInvestorIndexExist(index)  returns( uint256 , address) {
     
        Investor memory p= _Investors[ index ];
         
        return (p.liquidity, p.account);
    }



function getAllInvestor() public view returns(uint256[] memory,uint256[] memory, address[] memory) {
  
    uint256[] memory indexs=new uint256[](_InvestorCount);
    uint256[] memory pLiqs=new uint256[](_InvestorCount);
    address[] memory pACCs=new address[](_InvestorCount);
    
    uint256 ind=0;
    
    for (uint32 i = 0; i < (_lastIndexInvestors +1) ; i++) {
        Investor memory p= _Investors[ i ];
        if(p.flag == 1 ){
            indexs[ind]=i;
            pLiqs[ind]=p.liquidity;
            pACCs[ind]=p.account;
            ind++;
        }
    }

    return (indexs, pLiqs,pACCs);

}

function removeAllInvestor() internal returns(bool){
    for (uint32 i = 0; i < (_lastIndexInvestors +1) ; i++) {
        _IDInvestorsIndex[_Investors[ i ].account] = 0;
        
        _Investors[ i ].flag=0;
        _Investors[ i ].account=address(0);
        _Investors[ i ].liquidity=0;
        
        
    }
    _lastIndexInvestors = 0;
    _InvestorCount = 0;
    return true;
}
  
 
 function setInvestorAddLiquidity(address account, uint256 liquidity) internal onlyInvestorExist(account) {
     _Investors[ _IDInvestorsIndex[account] ].liquidity=_Investors[ _IDInvestorsIndex[account] ].liquidity.add(liquidity);
  }


 function setInvestorSubLiquidity(address account, uint256 liquidity) internal onlyInvestorExist(account) {
     _Investors[ _IDInvestorsIndex[account] ].liquidity=_Investors[ _IDInvestorsIndex[account] ].liquidity.sub(liquidity);


  }
    
    
    
}