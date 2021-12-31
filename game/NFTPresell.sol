//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../owner/BaseOp.sol";


interface IGNFTCard {
    function mintNFT(address _to) external returns (uint256);
}

contract NFTPresell is BaseOp {
    using SafeERC20 for IBurnERC20;

    uint32 public sellTotal;     
    uint32 public soldNum;       

    IGNFTCard public nftCard;
    IBurnERC20[2] public payTokens;
    mapping(address => uint256) public payPrice;

    event BuyNFTEvent(address indexed user, uint256[] nftList, uint256 cost);

    constructor(IGNFTCard nftCard_, address[] memory payTokens_, uint256[] memory payPrice_){
        nftCard = nftCard_;
        sellTotal = 1000;

        for(uint256 i=0;i<payTokens_.length;i++){
            payTokens[i] = IBurnERC20(payTokens_[i]);
            payPrice[payTokens_[i]] = payPrice_[i];
        }
    }

    function getPayInfo()
        public view
        returns (uint32 _sellTotal, uint32 _soldNum, address[] memory _payTkList, uint256[] memory _priceList)
    {
        _sellTotal = sellTotal;
        _soldNum = soldNum;
        _payTkList = new address[](payTokens.length);
        _priceList = new uint256[](_payTkList.length);
        for(uint256 i=0;i<_payTkList.length;i++){
            _payTkList[i] = address(payTokens[i]);
            _priceList[i] = payPrice[_payTkList[i]];
        }
    }

    function buyNFT(uint8 _payWay, uint16 _amount)
        public isOpen
    {    
         
        require(_amount > 0, "Param error");
        require(soldNum + _amount <= sellTotal, "Sold out");
        require(address(payTokens[_payWay]) != address(0), "Param error");

         
        uint256 _costAmount = payPrice[address(payTokens[_payWay])] * _amount;
        payTokens[_payWay].burnFrom(msg.sender, _costAmount);
         
        uint256[] memory _nftList = new uint256[](_amount);
        for(uint256 i=0;i<_amount;i++){
            _nftList[i] = nftCard.mintNFT(msg.sender);
        }

        soldNum += _amount;

        emit BuyNFTEvent(msg.sender, _nftList, _costAmount);
    }

     
    function setSellTotal(uint32 _value)
        public onlyAdmin
    {
        sellTotal = _value;
    }

    function setSoldNum(uint32 _value)
        public onlyAdmin
    {
        soldNum = _value;
    }

    function setPayPrice(address[] memory _payTkList, uint256[] memory _priceList)
        public onlyAdmin
    {
        for(uint256 i=0;i<_payTkList.length;i++){
            payPrice[_payTkList[i]] = _priceList[i];
        }
    }

    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("nftCard")) {
            nftCard = IGNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("payTokens0")) {
            payTokens[0] = IBurnERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("payTokens1")) {
            payTokens[1] = IBurnERC20(_addr);
        }
    }

}
