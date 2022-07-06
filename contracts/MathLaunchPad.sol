// SPDX-License-Identifier: MIT
// MathLaunchPad Contracts v1.0.0
// Creator: Hging

pragma solidity ^0.8.4;

import './ERC721A.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract MathLaunchPad is ERC721A, ERC2981, AccessControl {
    bytes32 public merkleRoot;
    uint256 public maxSupply;
    uint256 public mintPrice;
    uint256 public maxCountPerAddress;
    uint256 public _privateMintCount;
    string public baseURI;
    bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
    MintTime public privateMintTime;
    MintTime public publicMintTime;
    TimeZone public timeZone;

    struct MintTime {
        uint64 startAt;
        uint64 endAt;
    }

    struct TimeZone {
        uint8 offset;
        string text;
    }

    mapping(address => bool) internal claimList;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint8 _maxCountPerAddress,
        string memory _uri,
        uint96 royaltyFraction,
        TimeZone memory _timezone
    ) ERC721A(name, symbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        maxCountPerAddress = _maxCountPerAddress;
        baseURI = _uri;
        timeZone = _timezone;
        _setDefaultRoyalty(_msgSender(), royaltyFraction);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), 'error: 20000 - only owner can call this function');
        _;
    }

    function  _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function changeMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function changeMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
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

    function changePublicMintTime(MintTime memory _mintTime) public onlyOwner {
        publicMintTime = _mintTime;
    }


    function moveMemberShip(address _newOwner) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _grantRole(DEFAULT_ADMIN_ROLE, _newOwner);
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function privateMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(block.timestamp > privateMintTime.startAt && block.timestamp < privateMintTime.endAt, "error: 10000 time is not allowed");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        require(mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        address claimAddress = _msgSender();
        require(!claimList[claimAddress], 'error:10003 already claimed');
        require(
            MerkleProof.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(claimAddress, quantity))),
            'error:10004 not in the whitelist'
        );
        _safeMint(claimAddress, quantity);
        claimList[claimAddress] = true;
        _privateMintCount = _privateMintCount + quantity;
    }

    function publicMint(uint256 quantity) external payable {
        require(block.timestamp > publicMintTime.startAt && block.timestamp < publicMintTime.endAt, "error: 10000 time is not allowed");
        require(quantity <= maxCountPerAddress, "error: 10004 max per address exceeded");
        uint256 supply = totalSupply();
        require(supply + quantity <= maxSupply, "error: 10001 supply exceeded");
        require(mintPrice * quantity <= msg.value, "error: 10002 price insufficient");
        address claimAddress = _msgSender();
        require(!claimList[claimAddress], 'error:10003 already claimed');
        _safeMint(claimAddress, quantity);
        claimList[claimAddress] = true;
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

    // This allows the devs to receive kind donations
    function withdraw(uint amt) external onlyOwner {
        (bool sent, ) = payable(_msgSender()).call{value: amt}("");
        require(sent, "GG: Failed to withdraw Ether");
    }
}
