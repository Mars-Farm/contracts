//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../owner/BaseOp.sol";


interface IData {
    function nftsFromDict(uint256 _nftNo) external view returns (address _nftFrom);
    function getNFTAndAccUseInfo(uint256 _nftNo) external view returns (address, uint32, uint32);
    function accLandInfo(address _acc) external view returns (uint32, uint32);
    function getAccUseLandIdList(address _acc) external view returns (uint256[] memory _nftList);
    function accLandListLength(address _acc) external view returns (uint256);

    function addUseLand(address _acc, uint256 _nftNo, uint32 _posNum) external returns (uint32);
    function cancelUseLand(address _acc, uint256 _nftNo, uint32 _posNum) external returns (uint32);
    function addPosNumOccupy(address _acc, uint32 _posNum) external;
    function reducePosNumOccupy(address _acc, uint32 _posNum) external;
}

interface ILandNFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract LandManage is BaseOp, ERC721Holder {
    using SafeERC20 for IBurnERC20;

    IData public dataObj;
    ILandNFTCard public landCard;
    uint32 public landPosStatic;     

    event UseLandEvent(address indexed user, uint256 nftNo, uint32 posNum);
    event CancelLandEvent(address indexed user, uint256 nftNo, uint32 posNum);

    constructor(
        IData dataObj_,
        ILandNFTCard landCard_
    ){
        dataObj = dataObj_;
        landCard = landCard_;

        landPosStatic = 8;
    }

    function getAccLandInfo(address _acc)
        public view
        returns (uint32, uint32)
    {
        return dataObj.accLandInfo(_acc);
    }

    function getAccUseLandList(address _acc)
        public view
        returns (uint256[] memory _nftsList)
    {
        _nftsList = dataObj.getAccUseLandIdList(_acc);
    }

    function getAccUseLandsLength(address _acc)
        public view
        returns (uint256)
    {
        return dataObj.accLandListLength(_acc);
    }

     
    function useLand(uint256 _nftNo)
        public isOpen
    {
         
        require(landCard.ownerOf(_nftNo) == msg.sender, "Param error");

         
        landCard.safeTransferFrom(msg.sender, address(this), _nftNo);
         
        uint32 posTotal = dataObj.addUseLand(msg.sender, _nftNo, landPosStatic);

        emit UseLandEvent(msg.sender, _nftNo, posTotal);
    }

     
    function recycleLand(uint256 _nftNo)
        public isOpen
    {
        (address _nftFrom, uint32 _numOccupy, uint32 _numTotal) = dataObj.getNFTAndAccUseInfo(_nftNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_numOccupy + landPosStatic <= _numTotal, "Land pos is in use");

         
        landCard.safeTransferFrom(address(this), msg.sender, _nftNo);
        uint32 posTotal = dataObj.cancelUseLand(msg.sender, _nftNo, landPosStatic);

        emit CancelLandEvent(msg.sender, _nftNo, posTotal);
    }

    function occupyLand(address _acc, uint32 _posNum)
        public onlyAdmin
    {
        (uint32 _numOccupy, uint32 _numTotal) = dataObj.accLandInfo(_acc);
        require(_numOccupy + _posNum <= _numTotal, "Occupy too many");

        dataObj.addPosNumOccupy(_acc, _posNum);
    }

    function reduceOccupyLand(address _acc, uint32 _posNum)
        public onlyAdmin
    {
        dataObj.reducePosNumOccupy(_acc, _posNum);
    }

     
    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("landCard")) {
            landCard = ILandNFTCard(_addr);
        }
    }

    function setLandPosStatic(uint32 _value)
        public onlyAdmin
    {
        landPosStatic = _value;
    }

}
