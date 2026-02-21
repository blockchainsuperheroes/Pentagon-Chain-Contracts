// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {BasicAccessControl} from "../shared/BasicAccessControl.sol";
import {Freezable} from "../shared/Freezable.sol";

contract BCSH_Hero_Receipt is
    ERC721,
    ReentrancyGuard,
    Freezable,
    BasicAccessControl
{
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event Receipt(address owner, uint256 token, uint256 createdAt);

    uint256 constant START_TOKEN = 3_344_000_000_000;
    uint256 public currentToken = START_TOKEN;
    uint256 public _maxCap = 3_344_000_010_000;

    bool public isTransferable = false;

    uint256 public nftPrice = 0.004 ether;

    fallback() external payable {}

    receive() external payable {}

    string public _baseTokenURI = "https://api.bcsh.xyz/metadata/";

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BatchMetadataUpdate(1, _maxCap);
    }

    function setMaxCap(uint256 _newCap) external onlyOwner {
        require(_newCap > _maxCap, "New cap must be greater than current cap");
        _maxCap = _newCap;
    }

    function setNFTPrice(uint256 _nftPrice) public onlyOwner {
        nftPrice = _nftPrice;
    }

    /**
     * Method to be called by transak
     */
    function mint(
        address _owner,
        uint256 _tokenId
    ) external payable onlyModerators isActive nonReentrant returns (bool) {
        require(msg.value == nftPrice, "Insufficient price provided");

        uint256 tokenId = currentToken + 1;
        require(
            _tokenId == tokenId,
            "Cannot mint more or less than next token"
        );
        require(_owner != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");
        require(
            tokenId >= START_TOKEN && tokenId <= _maxCap,
            "Token ID is out of range"
        );
        _safeMint(_owner, tokenId);
        currentToken = tokenId;

        emit Receipt(_owner, _tokenId, block.timestamp);
        return true;
    }

    /**
     * Failsafe function if token id not minted and an empty id left in between
     */
    function safeMint(
        address _owner,
        uint256 _tokenId
    ) external onlyOwner isActive returns (bool) {
        require(_tokenId < currentToken, "Cannot mint more than current token");
        require(_owner != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");
        require(
            _tokenId >= START_TOKEN && _tokenId <= _maxCap,
            "Token ID is out of range"
        );

        _safeMint(_owner, _tokenId);

        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 batchSize
    ) internal virtual override {
        require(
            moderators[_msgSender()] || isTransferable,
            "Cannot transfer to the provided address"
        );
        require(!isFrozen(from), "ERC20Freezable: from account is frozen");
        require(!isFrozen(to), "ERC20Freezable: to account is frozen");
        super._beforeTokenTransfer(from, to, amount, batchSize);
    }

    function freeze(address _account) public onlyOwner {
        freezes[_account] = true;
        emit Frozen(_account);
    }

    function unfreeze(address _account) public onlyOwner {
        freezes[_account] = false;
        emit Unfrozen(_account);
    }

    function toggleIsTransferable() public onlyOwner {
        isTransferable = !isTransferable;
    }

    // function to withdraw all token from contract of contract
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // function to withdraw all erc-20 token from contract of contract
    function withdrawAllERC20(IERC20 _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
