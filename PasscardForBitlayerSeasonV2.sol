// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PasscardForBitlayerSeasonV2 is ERC721, ReentrancyGuard, Ownable {
    string public constant TOKEN_URI = "ipfs://QmPEzG2MfBFLeQ36gQgX5v2xtRB5wBHi6EX9wVxqCLoDT2";
    bool public mintingEnabled;
    uint256 public openMintPrice;
    uint256 public whitelistMintPrice;
    uint256 public totalSupply;
    bytes32 public rootForWhitelist; // root of merkle tree for whitelist
    bytes32 public rootForAirdrop; // root of merkle tree for airdrop

    // Mapping to keep track of whitelist mint and airdrop mint
    mapping(address => bool) public hasMinted;

    // Events
    event MintingEnabled();
    event MintingDisabled();

    constructor() ERC721("PasscardForBitlayerSeasonV2", "PST") Ownable(msg.sender) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _baseURI();
    }

    function _baseURI() internal pure override returns (string memory) {
        return TOKEN_URI;
    }

    function setMintPrice(uint256 _openMintPrice, uint256 _whitelistMintPrice) public onlyOwner {
        openMintPrice = _openMintPrice;
        whitelistMintPrice = _whitelistMintPrice;
    }

    function setRoots(bytes32 newWhitelistRoot, bytes32 newAirdropRoot) public onlyOwner {
        rootForWhitelist = newWhitelistRoot;
        rootForAirdrop = newAirdropRoot;
    }

    function enableMinting() public onlyOwner {
        mintingEnabled = true;
        emit MintingEnabled();
    }

    function disableMinting() public onlyOwner {
        mintingEnabled = false;
        emit MintingDisabled();
    }

    function openMint() public payable nonReentrant {
        require(mintingEnabled, "Minting is not enabled");
        require(msg.value >= openMintPrice, "Incorrect value");

        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }

    function whitelistMint(bytes32[] memory proof) public payable nonReentrant {
        require(mintingEnabled, "Minting is not enabled");
        require(!hasMinted[msg.sender], "Already minted");
        require(msg.value >= whitelistMintPrice, "Incorrect value");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootForWhitelist, leaf), "Invalid Merkle Proof");
        hasMinted[msg.sender] = true;
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }

    function airdrop(bytes32[] memory proof) public payable nonReentrant {
        require(mintingEnabled, "Minting is not enabled");
        require(!hasMinted[msg.sender], "Already minted");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, rootForAirdrop, leaf), "Invalid Merkle Proof");
        hasMinted[msg.sender] = true;
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }

    // Withdraw function to allow owner to withdraw funds
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success,) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    //Soulbound token
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Transfer not allowed");
    }
}
