//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../owner/BaseOp.sol";

interface IData {
    function getProduceNFTInfo(uint256 _nftNo) external view returns (uint32, uint32, uint32, address);
    function getAccProduceEquipInfoList(address _acc) external view returns (uint256[] memory _nftList, uint256[2][] memory _infoList);
    function accEquipListLength(address _acc) external view returns (uint256);

    function addProduceNFT(address _acc, uint256 _nftNo, uint32 _sTime, uint32 _eTime) external;
    function renewProduceInfo(uint256 _nftNo, uint32 _sTime, uint32 _eTime) external;
    function drawProduceInfo(uint256 _nftNo, uint32 _dTime) external;
    function exitProduceNFT(address _acc, uint256 _nftNo) external;

}

interface IEquipNFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);
    function getNFTInfo(uint256 _nftNo) external view returns (uint8 _nftDur, address _acc);
    function getNFTDurable(uint256 _nftNo) external view returns (uint8);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function subNFTDurable(uint256 _nftNo, uint8 _value) external;
}

interface ILandManage {
    function getAccLandInfo(address _acc) external view returns (uint32, uint32);

    function occupyLand(address _acc, uint32 _posNum) external;
    function reduceOccupyLand(address _acc, uint32 _posNum) external;
}

interface ITokenPrice {
    function getPrice(address _tokenAddr) external view returns (uint256);
}

contract EquipProduce is BaseOp, ERC721Holder {
    using SafeERC20 for IBurnERC20;

    IData public dataObj;
    IEquipNFTCard public equipCard;
    ILandManage public landMgObj;
    address public tokenPriceAddr;

    mapping(uint16 => uint256[3]) public produceCostStatic;    
    mapping(uint16 => uint256[3]) public produceRwdStatic;    
    mapping(uint16 => uint32) public landOccupyStatic;    
     
    mapping(string => address) public addrsMap;    
    mapping(string => uint256) public staticInfo;    

    event ProduceEvent(address indexed user, uint256 nftNo, uint32 endTime);
    event ContinueProduceEvent(address indexed user, uint256 nftNo, uint32 endTime, uint256 preRwd);
    event DrawRewardEvent(address indexed user, uint256 nftNo, uint256 preRwd);
    event ExitProduceEvent(address indexed user, uint256 nftNo, uint256 preRwd);

    constructor(
        IData dataObj_,
        IEquipNFTCard equipCard_,
        ILandManage landMgObj_
    ){
        dataObj = dataObj_;
        equipCard = equipCard_;
        landMgObj = landMgObj_;
    }

 
 
 
 
 
 
 
 
 
 
 
 
 
//
 
 
 
 
 
 
 
 
 
 
 

    function getAccProduceEquipsLength(address _acc)
        public view
        returns (uint256)
    {
        return dataObj.accEquipListLength(_acc);
    }

    function _getEquipNFTLv(uint256 _nftNo)
        private pure
        returns (uint8)
    {
        return uint8((_nftNo >> 16) & (~(~0<<8)));
    }

    function _getEquipNFTType(uint256 _nftNo)
        private pure
        returns (uint16)
    {
        return uint16(_nftNo & (~(~0<<16)));
    }

    function _getProduceTime()
        private view
        returns (uint32)
    {
        return 3600*4;
    }

    function getTokenPrice(address _tokenAddr)
        public view
        returns (uint256 _price)
    {
        _price = ITokenPrice(tokenPriceAddr).getPrice(_tokenAddr);
    }

    function getTokenWorth(address _tokenAddr)
        public view
        returns (uint256)
    {
        uint256 _price = ITokenPrice(tokenPriceAddr).getPrice(_tokenAddr);
        return 1e18 * 1e18 / _price;
    }

    function _drawReward(uint256 _nftNo)
        private
        returns (uint256)
    {
        uint256 _reward = _earned(_nftNo);
 
// 
 
        return _reward;
    }

     
    function toProduce(uint256 _nftNo)
        public isOpen
    {
         
        (uint8 _nftDur, address _nftAcc) = equipCard.getNFTInfo(_nftNo);
        require(_nftAcc == msg.sender, "Param error");
        require(_nftDur >= staticInfo['durableExpend'], "NFT durable is zero");
         
        (uint32 _numOccupy, uint32 _numTotal) = landMgObj.getAccLandInfo(_nftAcc);
        uint16 _equipType = _getEquipNFTType(_nftNo);

         
        require(_numOccupy + landOccupyStatic[_equipType] <= _numTotal, "Land too less");

         
        landMgObj.occupyLand(msg.sender, landOccupyStatic[_equipType]);
         
        equipCard.subNFTDurable(_nftNo, uint8(staticInfo['durableExpend']));

         
        uint32 produceTime = _getProduceTime();
        uint32 _endTime = uint32(block.timestamp + produceTime);
        dataObj.addProduceNFT(msg.sender, _nftNo, uint32(block.timestamp), _endTime);
         
        if (produceCostStatic[_equipType][0] > 0) {
            IBurnERC20(addrsMap["MM"]).burnFrom(msg.sender, produceCostStatic[_equipType][0]); }
        if (produceCostStatic[_equipType][1] > 0) {
            IBurnERC20(addrsMap["ME"]).burnFrom(msg.sender, produceCostStatic[_equipType][1]); }
        if (produceCostStatic[_equipType][2] > 0) {
            IBurnERC20(addrsMap["MF"]).burnFrom(msg.sender, produceCostStatic[_equipType][2]); }

         
        equipCard.safeTransferFrom(msg.sender, address(this), _nftNo);

        emit ProduceEvent(msg.sender, _nftNo, _endTime);
    }

     
    function continueProduce(uint256 _nftNo)
        public isOpen
    {
        (, uint32 _eTime, , address _nftFrom) = dataObj.getProduceNFTInfo(_nftNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_eTime <= block.timestamp, "It's running");

        uint8 _nftDur = equipCard.getNFTDurable(_nftNo);
        require(_nftDur >= staticInfo['durableExpend'], "NFT durable is zero");
         
        (uint32 _numOccupy, uint32 _numTotal) = landMgObj.getAccLandInfo(_nftFrom);
        uint16 _equipType = _getEquipNFTType(_nftNo);
         
        require(_numOccupy + landOccupyStatic[_equipType] <= _numTotal, "Land too less");


         
        uint256 _preRwd = _drawReward(_nftNo);
         
        landMgObj.occupyLand(msg.sender, landOccupyStatic[_equipType]);
         
        equipCard.subNFTDurable(_nftNo, uint8(staticInfo['durableExpend']));
         
        uint32 produceTime = _getProduceTime();
        uint32 _newEndT = uint32(block.timestamp + produceTime);
        dataObj.renewProduceInfo(_nftNo, uint32(block.timestamp), _newEndT);
         
        if (produceCostStatic[_equipType][0] > 0) {
            IBurnERC20(addrsMap["MM"]).burnFrom(msg.sender, produceCostStatic[_equipType][0]); }
        if (produceCostStatic[_equipType][1] > 0) {
            IBurnERC20(addrsMap["ME"]).burnFrom(msg.sender, produceCostStatic[_equipType][1]); }
        if (produceCostStatic[_equipType][2] > 0) {
            IBurnERC20(addrsMap["MF"]).burnFrom(msg.sender, produceCostStatic[_equipType][2]); }

        emit ContinueProduceEvent(msg.sender, _nftNo, _newEndT, _preRwd);
    }

     
    function drawReward(uint256 _nftNo)
        public isOpen
    {
        (, uint32 _eTime, , address _nftFrom) = dataObj.getProduceNFTInfo(_nftNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_eTime <= block.timestamp, "It's running");

        uint256 _preRwd = _drawReward(_nftNo);
        require (_preRwd > 0, "Reward zero");

        dataObj.drawProduceInfo(_nftNo, uint32(block.timestamp));

        emit DrawRewardEvent(msg.sender, _nftNo, _preRwd);
    }

     
    function exitProduceing(uint256 _nftNo)
        public isOpen
    {
        (, uint32 _eTime, , address _nftFrom) = dataObj.getProduceNFTInfo(_nftNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_eTime <= block.timestamp, "It's running");

         
        uint256 _preRwd = _drawReward(_nftNo);
         
        landMgObj.reduceOccupyLand(msg.sender, landOccupyStatic[_equipType]);
        dataObj.exitProduceNFT(msg.sender, _nftNo);
         
        equipCard.safeTransferFrom(address(this), msg.sender, _nftNo);

        emit ExitProduceEvent(msg.sender, _nftNo, _preRwd);
    }

     
    function _earned(uint256 _nftNo) internal view returns (uint256) {
 
 
 
         
 
        return 0;
    }

    function _getDurRwdReductRate(uint8 _durableV) private pure returns (uint8)
    {
         
        if (_durableV < 50){
            return 25;
        } else if (_durableV < 80){
            return 50;
        } else {
            return 100;
        }
    }

    function _getPriceRwdReductRate(address _rwdTAddr) private view returns (uint8)
    {
         
        uint256 _tWorth = getTokenWorth(_rwdTAddr);
 
        if (_tWorth < staticInfo["tokenPrice"]/2){
            return 25;
        } else if (_tWorth < staticInfo["tokenPrice"]*4/3){
            return 50;
        } else {
            return 100;
        }
    }

     
    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("equipCard")) {
            equipCard = IEquipNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("landMgObj")) {
            landMgObj = ILandManage(_addr);
        }
    }

    function setStaticInfo(string[] memory _keyList, uint256[] memory _valueList)
        public onlyAdmin
    {
        for (uint256 i=0;i<_keyList.length; i++){
            staticInfo[_keyList[i]] = _valueList[i];
        }
    }

    function setAddrMap(string[] memory _keyList, address[] memory _valueList)
        public onlyAdmin
    {
        for (uint256 i=0;i<_keyList.length; i++){
            addrsMap[_keyList[i]] = _valueList[i];
        }
    }

 
 
 
 
 
 
 
 
 
 
 
 
 

}
