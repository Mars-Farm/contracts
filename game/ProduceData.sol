//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../owner/AdminRole.sol";


contract ProduceData is AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private accNFTList;      
    mapping(uint256 => ProduceInfo) public nftProduceInfo;      

    struct ProduceInfo{
        uint32 sTime;        
        uint32 eTime;        
        uint32 dTime;        
        address nftFrom;
    }

     
    function getAccProduceNFTInfoList(address _acc)
        public view
        returns (uint256[] memory _nftList, uint32[3][] memory _infoList)
    {
        _nftList = new uint256[](accNFTList[_acc].length());
        _infoList = new uint32[3][](accNFTList[_acc].length());
        for (uint256 i=0; i< accNFTList[_acc].length(); i++){
            _nftList[i] = accNFTList[_acc].at(i);
            _infoList[i] = [nftProduceInfo[_nftList[i]].sTime, nftProduceInfo[_nftList[i]].eTime,
                            nftProduceInfo[_nftList[i]].dTime];
        }
    }

    function getAccProduceNFTIdList(address _acc)
        public view
        returns (uint256[] memory _nftList)
    {
        _nftList = new uint256[](accNFTList[_acc].length());
        for (uint256 i=0; i< accNFTList[_acc].length(); i++){
            _nftList[i] = accNFTList[_acc].at(i);
        }
    }

    function getProduceNFTInfo(uint256 _nftNo)
        public view
        returns (uint32, uint32, uint32, address)
    {
        return (nftProduceInfo[_nftNo].sTime, nftProduceInfo[_nftNo].eTime, nftProduceInfo[_nftNo].dTime, nftProduceInfo[_nftNo].nftFrom);
    }

    function accNFTContains(address _acc, uint256 _nftNo)
        public view
        returns (bool)
    {
        return accNFTList[_acc].contains(_nftNo);
    }

    function accNFTAt(address _acc, uint256 _index)
        public view
        returns (uint256)
    {
        return accNFTList[_acc].at(_index);
    }

    function accNFTListLength(address _acc)
        public view
        returns (uint256)
    {
        return accNFTList[_acc].length();
    }

     
    function addProduceNFT(address _acc, uint256 _nftNo, uint32 _sTime, uint32 _eTime)
        public onlyAdmin
    {
        accNFTList[_acc].add(_nftNo);
        nftProduceInfo[_nftNo] = ProduceInfo({
            sTime: _sTime,
            eTime: _eTime,
            dTime: 0,
            nftFrom: _acc
        });
    }

    function renewProduceInfo(uint256 _nftNo, uint32 _sTime, uint32 _eTime)
        public onlyAdmin
    {
        nftProduceInfo[_nftNo].sTime = _sTime;
        nftProduceInfo[_nftNo].eTime = _eTime;
        nftProduceInfo[_nftNo].dTime = 0;
    }

    function drawProduceInfo(uint256 _nftNo, uint32 _dTime)
        public onlyAdmin
    {
        nftProduceInfo[_nftNo].dTime = _dTime;
    }

    function exitProduceNFT(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accNFTList[_acc].remove(_nftNo);
        delete nftProduceInfo[_nftNo];
    }

    function addAccNFT(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accNFTList[_acc].add(_nftNo);
    }

    function removeAccNFT(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accNFTList[_acc].remove(_nftNo);
    }

    function setProduceNFTInfo(address _acc, uint256 _nftNo, uint32 _sTime, uint32 _eTime, uint32 _dTime)
        public onlyAdmin
    {
        nftProduceInfo[_nftNo] = ProduceInfo({
            sTime: _sTime,
            eTime: _eTime,
            dTime: _dTime,
            nftFrom: _acc
        });
    }

}
