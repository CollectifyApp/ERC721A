// SPDX-License-Identifier: MIT
// Collectify Launchapad Contracts v1.1.0
// Creator: Hging

pragma solidity ^0.8.4;

import './ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract ERC721TOKEN is ERC721A, ERC2981, AccessControl {
    MerkleRoot public merkleRoot;
    uint256 public maxSupply;
    MintPrice public mintPrice;
    uint256 public maxCountPerAddress;
    MintCount public mintCount;
    string public baseURI;
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
    MintTime public privateMintTime;
    MintTime public luckyMintTime;
    MintTime public publicMintTime;
    TimeZone public timeZone;
    address public tokenContract;
    address[] private _operatorFilterAddresses;

    struct MintTime {
        uint64 startAt;
        uint64 endAt;
    }

    struct TimeZone {
        int8 offset;
        string text;
    }

    struct MintState {
        bool privateMinted;
        bool luckyMinted;
        bool publicMinted;
    }

    struct MintTimeStruct {
        MintTime privateMintTime;
        MintTime luckyMintTime;
        MintTime publicMintTime;
    }

    struct MintPrice {
        uint256 privateMintPrice;
        uint256 luckyMintPrice;
        uint256 publicMintPrice;
    }

    struct MerkleRoot {
        bytes32 privateMerkleRoot;
        bytes32 luckyMerkleRoot;
    }

    struct MintCount {
        uint256 privateMintCount;
        uint256 luckyMintCount;
    }

    mapping(address => bool) internal privateClaimList;
    mapping(address => bool) internal luckyClaimList;
    mapping(address => bool) internal publicClaimList;

    constructor(
        string memory name,
        string memory symbol,
        MintPrice memory _mintPrice,
        uint256 _maxSupply,
        uint8 _maxCountPerAddress,
        string memory _uri,
        uint96 royaltyFraction,
        TimeZone memory _timezone,
        MintTimeStruct memory mintTime,
        address _tokenContract
    ) ERC721A(name, symbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxCountPerAddress = _maxCountPerAddress;
        baseURI = _uri;
        timeZone = _timezone;
        privateMintTime = mintTime.privateMintTime;
        luckyMintTime = mintTime.luckyMintTime;
        publicMintTime = mintTime.publicMintTime;
        tokenContract = _tokenContract;
        _setDefaultRoyalty(_msgSender(), royaltyFraction);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), 'error: 20000 - only owner can call this function');
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) {
        for (uint256 i = 0; i < _operatorFilterAddresses.length; i++) {
            require(
                operator != _operatorFilterAddresses[i],
                "ERC721: operator not allowed"
            );
        }
        _;
    }

    modifier onlyAllowedOperator(address from) {
        for (uint256 i = 0; i < _operatorFilterAddresses.length; i++) {
            require(
                from != _operatorFilterAddresses[i],
                "ERC721: operator not allowed"
            );
        }
        _;
    }

    function  _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isMinted(address owner) public view returns (MintState memory) {
        return(
            MintState(
                privateClaimList[owner],
                luckyClaimList[owner],
                publicClaimList[owner]
            )
        );
    }

    function changeBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function changePrivateMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot.privateMerkleRoot = _merkleRoot;
    }

    function changeLuckyMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot.luckyMerkleRoot = _merkleRoot;
    }

    function changePrivateMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice.privateMintPrice = _mintPrice;
    }

    function changeLuckyMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice.luckyMintPrice = _mintPrice;
    }

    function changePublicMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice.publicMintPrice = _mintPrice;
    }

    function changeMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function changemaxPerAddress(uint8 _maxPerAddress) public onlyOwner {
        maxCountPerAddress = _maxPerAddress;
    }

    function changeDefaultRoyalty(uint96 _royaltyFraction) public onlyOwner {
        _setDefaultRoyalty(_msgSender(), _royaltyFraction);
    }

    function changeRoyalty(uint256 _tokenId, uint96 _royaltyFraction) public onlyOwner {
        _setTokenRoyalty(_tokenId, _msgSender(), _royaltyFraction);
    }

    function changePrivateMintTime(MintTime memory _mintTime) public onlyOwner {
        privateMintTime = _mintTime;
    }

    function changeLuckyMintTime(MintTime memory _mintTime) public onlyOwner {
        luckyMintTime = _mintTime;
    }

    function changePublicMintTime(MintTime memory _mintTime) public onlyOwner {
        publicMintTime = _mintTime;
    }

    function changeMintTime(MintTime memory _publicMintTime, MintTime memory _luckyMintTime, MintTime memory _privateMintTime) public onlyOwner {
        privateMintTime = _privateMintTime;
        luckyMintTime = _luckyMintTime;
        publicMintTime = _publicMintTime;
    }

    function moveMemberShip(address _newOwner) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function changeOperatorFilterAddresses(address[] memory _addresses) public onlyOwner {
        _operatorFilterAddresses = _addresses;
    }

    function changeOperatorFilterAddressesAndMintTime(address[] memory _addresses, MintTime memory _publicMintTime, MintTime memory _privateMintTime, MintTime memory _luckyMintTime) public onlyOwner {
        _operatorFilterAddresses = _addresses;
        privateMintTime = _privateMintTime;
        luckyMintTime = _luckyMintTime;
        publicMintTime = _publicMintTime;
    }

    function operatorFilterAddresses() public view returns (address[] memory) {
        return _operatorFilterAddresses;
    }

    function privateMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof) public payable {
        _privateMint(quantity, whiteQuantity, merkleProof, _msgSender());
    }

    function privateMintFor(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof, address receiver) public payable {
        _privateMint(quantity, whiteQuantity, merkleProof, receiver);
    }

    function _privateMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof, address receiver) internal {
        require(block.timestamp >= privateMintTime.startAt && block.timestamp <= privateMintTime.endAt, "error: 10000 time is not allowed");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        address claimAddress = _msgSender();
        require(!privateClaimList[claimAddress], "error:10003 already claimed");
        require(quantity <= whiteQuantity, "error: 10004 quantity is not allowed");
        require(
            MerkleProof.verify(merkleProof, merkleRoot.privateMerkleRoot, keccak256(abi.encodePacked(claimAddress, whiteQuantity))),
            "error:10004 not in the whitelist"
        );

        if (tokenContract == address(0)) {
            require(mintPrice.privateMintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, claimAddress, address(this), mintPrice.privateMintPrice * quantity));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "error: 10002 price insufficient"
            );
        }
        privateClaimList[claimAddress] = true;
        mintCount.privateMintCount = mintCount.privateMintCount + quantity;
        _safeMint(receiver, quantity);
    }

    function luckyMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof) external payable {
        _luckyMint(quantity, whiteQuantity, merkleProof, _msgSender());
    }
    function luckyMintFor(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof, address receiver) external payable {
        _luckyMint(quantity, whiteQuantity, merkleProof, receiver);
    }

    function _luckyMint(uint256 quantity, uint256 whiteQuantity, bytes32[] calldata merkleProof, address receiver) internal {
        require(block.timestamp >= luckyMintTime.startAt && block.timestamp <= luckyMintTime.endAt, "error: 10000 time is not allowed");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        address claimAddress = _msgSender();
        require(!luckyClaimList[claimAddress], "error:10003 already claimed");
        require(quantity <= whiteQuantity, "error: 10004 quantity is not allowed");
        require(
            MerkleProof.verify(merkleProof, merkleRoot.luckyMerkleRoot, keccak256(abi.encodePacked(claimAddress, whiteQuantity))),
            "error:10004 not in the whitelist"
        );

        if (tokenContract == address(0)) {
            require(mintPrice.luckyMintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, claimAddress, address(this), mintPrice.luckyMintPrice * quantity));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "error: 10002 price insufficient"
            );
        }
        luckyClaimList[claimAddress] = true;
        mintCount.luckyMintCount = mintCount.luckyMintCount + quantity;
        _safeMint(receiver, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        _publicMint(quantity, _msgSender());
    }

    function publicMintFor(uint256 quantity, address receiver) external payable {
        _publicMint(quantity, receiver);
    }

    function _publicMint(uint256 quantity, address receiver) internal {
        require(block.timestamp >= publicMintTime.startAt && block.timestamp <= publicMintTime.endAt, "error: 10000 time is not allowed");
        require(quantity <= maxCountPerAddress, "error: 10004 max per address exceeded");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        address claimAddress = _msgSender();
        require(!publicClaimList[claimAddress], "error:10003 already claimed");
        if (tokenContract == address(0)) {
            require(mintPrice.publicMintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0x23b872dd, claimAddress, address(this), mintPrice.publicMintPrice * quantity));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "error: 10002 price insufficient"
            );
        }
        publicClaimList[claimAddress] = true;
        _safeMint(receiver, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // This allows the contract owner to withdraw the funds from the contract.
    function withdraw(uint amt) external onlyOwner {
        if (tokenContract == address(0)) {
            (bool sent, ) = payable(_msgSender()).call{value: amt}("");
            require(sent, "GG: Failed to withdraw Ether");
        } else {
            (bool success, bytes memory data) = tokenContract.call(abi.encodeWithSelector(0xa9059cbb, _msgSender(), amt));
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "GG: Failed to withdraw Ether"
            );
        }
    }
}
