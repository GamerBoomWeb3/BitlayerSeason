// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DailyBadgeSBT is ERC721, ReentrancyGuard, Ownable {
    string public constant TOKEN_URI = "ipfs://QmXYGyVmT85dQN8RwGYGVcw5gTnZPFps5N4kQJCRD1QHmC";
    bool public mintingEnabled;
    uint256 public totalSupply;

    // Events
    event MintingDisabled();
    event MintingEnabled();
    event Minted(address to, uint256 tokenId);
    event DailyCheckProof(address indexed user, string message);

    constructor() ERC721("DailyBadgeSBT", "DBT") Ownable(msg.sender) {}

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _baseURI();
    }

    function _baseURI() internal pure override returns (string memory) {
        return TOKEN_URI;
    }

    function enableMinting() public onlyOwner {
        mintingEnabled = true;
        emit MintingEnabled();
    }

    function disableMinting() public onlyOwner {
        mintingEnabled = false;
        emit MintingDisabled();
    }

    function mint() public nonReentrant {
        require(mintingEnabled, "Minting is not enabled");

        totalSupply++;
        uint256 newTokenId = totalSupply;
        _safeMint(msg.sender, newTokenId);

        emit Minted(msg.sender, newTokenId);
    }

    // Withdraw function to allow owner to withdraw funds
    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success,) = owner().call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("Transfer not allowed");
    }

    // Daily check proof
    function signDailyCheckProof() public {
        emit DailyCheckProof(msg.sender, "Daily check-in on Bitlayer");
    }
}
