//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../owner/AdminRole.sol";


contract LManageData is AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private accLandList;      
    mapping(uint256 => address) public nftsFromDict;      
    mapping(address => LandInfo) public accLandInfo;      

    struct LandInfo{
        uint32 numOccupy;      
        uint32 numTotal;      
    }

     
    function getAccUseLandIdList(address _acc)
        public view
        returns (uint256[] memory _nftList)
    {
        _nftList = new uint256[](accLandList[_acc].length());
        for (uint256 i=0; i< accLandList[_acc].length(); i++){
            _nftList[i] = accLandList[_acc].at(i);
        }
    }

    function getNFTAndAccUseInfo(uint256 _nftNo)
        public view
        returns (address, uint32, uint32)
    {
        address _acc = nftsFromDict[_nftNo];
        return (_acc, accLandInfo[_acc].numOccupy, accLandInfo[_acc].numTotal);
    }

    function accLandContains(address _acc, uint256 _nftNo)
        public view
        returns (bool)
    {
        return accLandList[_acc].contains(_nftNo);
    }

    function accLandAt(address _acc, uint256 _index)
        public view
        returns (uint256)
    {
        return accLandList[_acc].at(_index);
    }

    function accLandListLength(address _acc)
        public view
        returns (uint256)
    {
        return accLandList[_acc].length();
    }

     
    function addUseLand(address _acc, uint256 _nftNo, uint32 _posNum)
        public onlyAdmin
        returns (uint32)
    {
        require(accLandList[_acc].add(_nftNo), "add error");
        nftsFromDict[_nftNo] = _acc;
        accLandInfo[_acc].numTotal += _posNum;
        return accLandInfo[_acc].numTotal;
    }

    function cancelUseLand(address _acc, uint256 _nftNo, uint32 _posNum)
        public onlyAdmin
        returns (uint32)
    {
        require(accLandList[_acc].remove(_nftNo), "remove error");
        delete nftsFromDict[_nftNo];
        require(accLandInfo[_acc].numTotal - accLandInfo[_acc].numOccupy >= _posNum, "Error");
        accLandInfo[_acc].numTotal -= _posNum;
        return accLandInfo[_acc].numTotal;
    }

    function addPosNumOccupy(address _acc, uint32 _posNum)
        public onlyAdmin
    {
        accLandInfo[_acc].numOccupy += _posNum;
    }

    function reducePosNumOccupy(address _acc, uint32 _posNum)
        public onlyAdmin
    {
        accLandInfo[_acc].numOccupy -= _posNum;
    }

    function addPosNumTotal(address _acc, uint32 _posNum)
        public onlyAdmin
    {
        accLandInfo[_acc].numTotal += _posNum;
    }

    function reducePosNumTotal(address _acc, uint32 _posNum)
        public onlyAdmin
    {
        require(accLandInfo[_acc].numTotal - accLandInfo[_acc].numOccupy >= _posNum, "Error");
        accLandInfo[_acc].numTotal -= _posNum;
    }

    function addAccLand(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accLandList[_acc].add(_nftNo);
    }

    function removeAccLand(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accLandList[_acc].remove(_nftNo);
    }

    function setNFTsFromDict(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        nftsFromDict[_nftNo] = _acc;
    }

    function setAccLandInfo(address _acc, uint32 _posNumOccupy, uint32 _posNumTotal)
        public onlyAdmin
    {
        accLandInfo[_acc] = LandInfo({
            numOccupy: _posNumOccupy,
            numTotal: _posNumTotal
        });
    }

}
