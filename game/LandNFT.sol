//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../owner/AdminRole.sol";


contract LandNFT is ERC721Burnable, AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 public constant durableMax = 100;
    mapping(address => EnumerableSet.UintSet) ownerNFTs;

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

    function getNFTProps(uint256 _nftNo)
        public pure
        returns (uint256 _idx, uint256 _time)
    {    
        _time = uint256(_nftNo & (~(~0<<64)));
        _idx = uint256((_nftNo >> 64) & (~(~0<<64)));
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

    function _getNFTNo(uint256 _num)
        private view
        returns (uint256)
    {    
        return uint256((_num << 64) + block.timestamp);
    }

    function mintNFT(address _to)
        public onlyAdmin
        returns (uint256)
    {
        nftNumber++;
        uint256 nftNo = _getNFTNo(nftNumber);
        _safeMint(_to, nftNo);
        return nftNo;
    }

    function setNFTNumber(uint256 _no)
        public onlyAdmin
    {
        nftNumber = _no;
    }

}
