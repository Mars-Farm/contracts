//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../owner/AdminRole.sol";


contract EquipNFT is ERC721Burnable, AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 public constant durableMax = 100;
    mapping(address => EnumerableSet.UintSet) ownerNFTs;
    mapping(uint256 => uint8) public nftsDurExpend;      

    uint256 public nftNumber = 10000;      
     
     

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == to) { return; }
        ownerNFTs[from].remove(tokenId);
        ownerNFTs[to].add(tokenId);
    }

    function getOwnerNFTList(address _acc)
        public view
        returns (uint256[] memory _nftList)
    {
        _nftList = new uint256[](ownerNFTs[_acc].length());
        for(uint256 i=0;i<_nftList.length;i++){
            _nftList[i] = ownerNFTs[_acc].at(i);
        }
    }

    function getOwnerNFTRangeInfo(address _acc, uint256 _startNo, uint256 _endNo)
        public view
        returns (uint256[2][] memory _nftList)
    {
        if (_startNo >= ownerNFTs[_acc].length()){
            _endNo = _startNo;
        } else if (_endNo > ownerNFTs[_acc].length()) {
            _endNo = ownerNFTs[_acc].length();
        }
        _nftList = new uint256[2][](_endNo - _startNo);
        for(uint256 i=0;i<_nftList.length;i++){
            uint256 _nftNo = ownerNFTs[_acc].at(i+_startNo);
            _nftList[i] = [_nftNo, durableMax - nftsDurExpend[_nftNo]];
        }
    }

    function getOwnerNFTRange(address _acc, uint256 _startNo, uint256 _endNo)
        public view
        returns (uint256[] memory _nftList)
    {
        if (_startNo >= ownerNFTs[_acc].length()){
            _endNo = _startNo;
        } else if (_endNo > ownerNFTs[_acc].length()) {
            _endNo = ownerNFTs[_acc].length();
        }
        _nftList = new uint256[](_endNo - _startNo);
        for(uint256 i=0;i<_nftList.length;i++){
            _nftList[i] = ownerNFTs[_acc].at(i + _startNo);
        }
    }

    function ownerNFTsContains(address _acc, uint256 _nftNo)
        public view onlyAdmin
        returns (bool)
    {
        return ownerNFTs[_acc].contains(_nftNo);
    }

    function ownerNFTsAt(address _acc, uint256 _index)
        public view onlyAdmin
        returns (uint256)
    {
        return ownerNFTs[_acc].at(_index);
    }

    function ownerNFTsLength(address _acc)
        public view onlyAdmin
        returns (uint256)
    {
        return ownerNFTs[_acc].length();
    }

    function isExists(uint256 _nftNo)
        public view
        returns (bool)
    {
        return _exists(_nftNo);
    }

    function getNFTInfo(uint256 _nftNo)
        public view
        returns (uint8 _nftDur, address _acc)
    {
        _nftDur = durableMax - nftsDurExpend[_nftNo];
        _acc = ownerOf(_nftNo);
    }

    function getNFTProps(uint256 _nftNo)
        public pure
        returns (uint256 _idx, uint256 _time, uint16 _nftType)
    {    
        _nftType = uint16(_nftNo & (~(~0<<16)));
        _time = uint256((_nftNo >> 128) & (~(~0<<64)));
        _idx = uint256((_nftNo >> 192) & (~(~0<<64)));
    }

     
    function getNFTDurable(uint256 _nftNo)
        public view
        returns (uint8)
    {
        return durableMax - nftsDurExpend[_nftNo];
    }

    function ownerOfList(uint256[] memory _nftList)
        public view
        returns(address[] memory _addrsList)
    {
        _addrsList = new address[](_nftList.length);
        for(uint256 i=0;i<_nftList.length;i++){
            _addrsList[i] = ownerOf(_nftList[i]);
        }
    }

    function _getNFTNo(uint256 _num, uint16 _nftType)
        private view
        returns (uint256)
    {    
        return uint256((_num << 192) + (block.timestamp << 128) + _nftType);
    }

    function mintNFT(address _to, uint16 _nftType)
        public onlyAdmin
        returns (uint256)
    {
        nftNumber++;
        uint256 nftNo = _getNFTNo(nftNumber, _nftType);
        _safeMint(_to, nftNo);
        return nftNo;
    }

    function recoverDurable(uint256 _nftNo)
        public onlyAdmin
    {
        nftsDurExpend[_nftNo] = 0;
    }

    function setNFTNumber(uint256 _no)
        public onlyAdmin
    {
        nftNumber = _no;
    }

    function addNFTDurable(uint256 _nftNo, uint8 _value)
        public onlyAdmin
    {
        require(nftsDurExpend[_nftNo] >= _value, "Durable is too large");
        nftsDurExpend[_nftNo] -= _value;
    }

    function subNFTDurable(uint256 _nftNo, uint8 _value)
        public onlyAdmin
    {
        require(nftsDurExpend[_nftNo] + _value <= durableMax, "Durable is too small");
        nftsDurExpend[_nftNo] += _value;
        if (nftsDurExpend[_nftNo] + _value > durableMax) {
            nftsDurExpend[_nftNo] = durableMax;
        } else {
            nftsDurExpend[_nftNo] += _value;
        }
    }

}
