//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../owner/BaseOp.sol";


interface INFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);
    function nftsDurExpend(uint256 _nftNo) external view returns (uint8);

    function mintNFT(address _to, uint16 _nftType) external returns (uint256);
    function recoverDurable(uint256 _nftNo) external;
}


contract GNFTOption is BaseOp {
    using SafeERC20 for IBurnERC20;

    IBurnERC20 public payToken;
    INFTCard public nftCard;
    mapping(uint16 => mapping(address => uint256)) public nftRecoverPrice;      
    mapping(uint16 => uint256[3]) public buildPriceList;      
    mapping(uint16 => uint256) public nftBuildPay;      

     
    mapping(string => address) public addrsMap;    

    event CompoundNFTEvent(address indexed user, uint256 nftNo);
    event RecoverNFTDurEvent(address indexed user, uint256 nftNo, uint256 amount);

    constructor(
        IBurnERC20 _payToken,
        INFTCard _nftCard
    ){
        payToken = _payToken;
        nftCard = _nftCard;
    }

     
    function getNFTPriceList(uint16[] memory _typeList)
        public view
        returns (uint256[3][] memory _priceList)
    {
        _priceList = new uint256[3][](_typeList.length);
        for(uint256 i=0;i<_typeList.length;i++){
            _priceList[i] = buildPriceList[_typeList[i]];
        }
    }

    function getNFTBuildCost(uint16[] memory _typeList)
        public view
        returns (uint256[] memory _valueList)
    {
        _valueList = new uint256[](_typeList.length);
        for(uint256 i=0;i<_typeList.length;i++){
            _valueList[i] = nftBuildPay[_typeList[i]];
        }
    }

    function getNFTRecoverPrice(address _tkAddr, uint16[] memory _typeList)
        public view
        returns (uint256[] memory _valueList)
    {
        _valueList = new uint256[](_typeList.length);
        for(uint256 i=0;i<_typeList.length;i++){
            _valueList[i] = nftRecoverPrice[_typeList[i]][_tkAddr];
        }
    }

     
    function compoundNFT(uint16 _nftType)
        public isOpen
    {
        require(buildPriceList[_nftType][0] + buildPriceList[_nftType][1] + buildPriceList[_nftType][2] > 0, "Param error");

         
        if (nftBuildPay[_nftType] > 0){
            payToken.burnFrom(msg.sender, nftBuildPay[_nftType]);
        }

        if (buildPriceList[_nftType][0] > 0) {
            IBurnERC20(addrsMap["MM"]).burnFrom(msg.sender, buildPriceList[_nftType][0]); }
        if (buildPriceList[_nftType][1] > 0) {
            IBurnERC20(addrsMap["ME"]).burnFrom(msg.sender, buildPriceList[_nftType][1]); }
        if (buildPriceList[_nftType][2] > 0) {
            IBurnERC20(addrsMap["MF"]).burnFrom(msg.sender, buildPriceList[_nftType][2]); }

        uint256 _nftNo = nftCard.mintNFT(msg.sender, _nftType);

        emit CompoundNFTEvent(msg.sender, _nftNo);
    }

    function _getNFTType(uint256 _nftNo)
        private pure
        returns(uint16)
    {
        return uint16(_nftNo & (~(~0<<16)));
    }

    function recoverNFTDurable(uint256 _nftNo, address _tokenAddr)
        public isOpen
    {
        address _nftAcc = nftCard.ownerOf(_nftNo);
        require(_nftAcc == msg.sender, "NFT is not yours");

        uint16 _nftType = _getNFTType(_nftNo);
        require(nftRecoverPrice[_nftType][_tokenAddr] > 0, "Param error");

         
        uint8 _expend = nftCard.nftsDurExpend(_nftNo);
        require(_expend > 0, "It's complete");
        uint256 _amount = _expend * nftRecoverPrice[_nftType][_tokenAddr];
        IBurnERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
         
        nftCard.recoverDurable(_nftNo);

        emit RecoverNFTDurEvent(msg.sender, _nftNo, _amount);
    }

     
    function setBuildInfoList(
        uint16[] memory _typeList,
        uint256[3][] memory _priceList,
        uint256[] memory _nftBuildPayList
    ) public onlyAdmin {
        for (uint256 i = 0; i < _typeList.length; i++) {
            buildPriceList[_typeList[i]] = _priceList[i];
        }
        for (uint256 i = 0; i < _nftBuildPayList.length; i++) {
            nftBuildPay[_typeList[i]] = _nftBuildPayList[i];
        }
    }

    function setPayToken(address _addr)
        public onlyAdmin
    {
        payToken = IBurnERC20(_addr);
    }

    function setNFTRecoverPrice(
        address _tkAddr,
        uint16[] memory _typeList,
        uint256[] memory _recoverList
    ) public onlyAdmin {
        for (uint256 i = 0; i < _typeList.length; i++) {
            nftRecoverPrice[_typeList[i]][_tkAddr] = _recoverList[i];
        }
    }

    function setNFTCard(address _addr)
        public onlyAdmin
    {
        nftCard = INFTCard(_addr);
    }

    function setAddrMap(string[] memory _keyList, address[] memory _valueList)
        public onlyAdmin
    {
        for (uint256 i=0;i<_keyList.length; i++){
            addrsMap[_keyList[i]] = _valueList[i];
        }
    }

}
