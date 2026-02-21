// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {BasicAccessControl} from "../shared/BasicAccessControl.sol";
import {Freezable} from "../shared/Freezable.sol";

contract Blockchain_Superheroes_V2 is
    ERC721,
    ReentrancyGuard,
    Freezable,
    BasicAccessControl
{
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event Highfive(uint256 _tokenId, address _owner);
    event SunkunPower(uint256 _tokenId, uint256 _amount, address _owner);
    event Deposit(uint256 _tokenId, uint256 _amount, address _owner);
    event WithdrawDeposit(uint256 _tokenId, uint256 _amount, address _owner);

    address public burnAddress = address(this);
    uint256 constant START_TOKEN = 3_344_000_000_000;
    uint256 public currentToken = START_TOKEN;
    uint256 public _maxCap = 3_344_000_010_000;

    bool public isTransferable = false;

    uint256 public updateableTimes = 2;
    uint256 public updatedTimes = 0;
    bool public nativeDepositAllowed = true;
    bool public erc20DepositAllowed = true;
    uint256 public nftPrice = 1 ether;

    // create mapping for mainting gas deposits
    mapping(uint256 => mapping(address => uint256)) public tokenDeposits;

    // create mapping for mainting gas burns
    mapping(uint256 => uint256) public tokenBurns;

    mapping(uint256 => uint256) public tokenHighFiversCount;
    mapping(uint256 => address[]) public tokenHighFivers;
    // mapping for maintaining that how many times a user has worshipped a token
    mapping(address => mapping(uint256 => uint256)) public userHighFiversCount;

    //variable to store tokenDeposit value
    mapping(address => uint256) public totalTokenDeposit;
    mapping(address => bool) public tokensAllowed;

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

    function mintNextToken(
        address _owner
    ) external onlyModerators isActive returns (bool) {
        return mint(_owner);
    }

    function mint(address _owner) internal onlyModerators returns (bool) {
        uint256 _tokenId = currentToken + 1;
        require(_owner != address(0), "ERC721: mint to the zero address");
        require(!_exists(_tokenId), "ERC721: token already minted");
        require(
            _tokenId >= START_TOKEN && _tokenId <= _maxCap,
            "Token ID is out of range"
        );

        _safeMint(_owner, _tokenId);
        currentToken = _tokenId;

        return true;
    }

    // function to handle deposits of ERC-20 token attached to NFTs
    function depositFundERC20(
        IERC20 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external isActive {
        address tokenAddress = address(_token);
        require(erc20DepositAllowed == true, "ERC20 token mint not allowed");

        require(
            tokensAllowed[tokenAddress] == true,
            "This currency not accepted"
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        tokenDeposits[_tokenId][tokenAddress] += _amount;
        totalTokenDeposit[tokenAddress] += _amount;

        require(
            _token.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );

        _token.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(_tokenId, _amount, msg.sender);
    }

    // function to handle deposits of native token attached to NFTs
    function depositFund(uint256 _tokenId) external payable isActive {
        require(nativeDepositAllowed == true, "ERC20 token mint not allowed");

        require(
            tokensAllowed[address(0)] == true,
            "This currency not accepted"
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        tokenDeposits[_tokenId][address(0)] += msg.value;
        totalTokenDeposit[address(0)] += msg.value;
        emit Deposit(_tokenId, msg.value, msg.sender);
    }

    function sunkenPower(uint256 _tokenId) external payable {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        (bool success, ) = burnAddress.call{value: msg.value}("");
        require(success, "Failed to burn ETH");

        tokenBurns[_tokenId] += msg.value;
        emit SunkunPower(_tokenId, msg.value, msg.sender);
    }

    function toggleIsTransferable() public onlyOwner {
        isTransferable = !isTransferable;
    }

    function setTokensAllowed(
        address _token,
        bool _allowed
    ) external onlyModerators {
        updatedTimes++;
        require(
            updatedTimes <= updateableTimes,
            "Cannot update tokens more than updateable times"
        );
        tokensAllowed[_token] = _allowed;
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

    // function to withdraw eth from token deposits
    function withdrawTokenDeposit(
        IERC20 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );

        address tokenAddress = address(_token);

        require(
            tokenDeposits[_tokenId][tokenAddress] >= _amount,
            "Insufficient recorded balance"
        );

        bool success = false;

        if (tokenAddress == address(0)) {
            require(
                address(this).balance >= _amount,
                "Insufficient native token balance"
            );

            tokenDeposits[_tokenId][address(0)] -= _amount;
            totalTokenDeposit[address(0)] -= _amount;

            (success, ) = msg.sender.call{value: _amount}("");
        } else {
            require(
                _token.balanceOf(address(this)) >= _amount,
                "Insufficient ERC20 balance"
            );

            tokenDeposits[_tokenId][tokenAddress] -= _amount;
            totalTokenDeposit[tokenAddress] -= _amount;

            success = _token.transfer(msg.sender, _amount);
        }

        require(success, "Transfer failed");
        emit WithdrawDeposit(_tokenId, _amount, msg.sender);
    }

    function toggleNativeDepositAllowed() external onlyModerators {
        nativeDepositAllowed = !nativeDepositAllowed;
    }

    function toggleERC20DepositAllowed() external onlyModerators {
        erc20DepositAllowed = !erc20DepositAllowed;
    }

    function updateBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }

    // function to withdraw all token from contract of contract
    function withdrawAll() external onlyOwner {
        require(
            address(this).balance > totalTokenDeposit[address(0)],
            "No withdrawl for owner"
        );
        payable(msg.sender).transfer(
            address(this).balance - totalTokenDeposit[address(0)]
        );
    }

    // function to withdraw all erc-20 token from contract of contract
    function withdrawAllERC20(IERC20 _token) external onlyOwner {
        require(
            _token.balanceOf(address(this)) >
                totalTokenDeposit[address(_token)],
            "No withdrawl for owner"
        );
        payable(msg.sender).transfer(
            _token.balanceOf(address(this)) - totalTokenDeposit[address(_token)]
        );
    }

    // function to HighFive a token
    function highFiveToken(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        tokenHighFiversCount[_tokenId] += 1;
        tokenHighFivers[_tokenId].push(msg.sender);
        userHighFiversCount[msg.sender][_tokenId] += 1;
        emit Highfive(_tokenId, msg.sender);
    }

    function getHighFives(
        uint256[] memory _tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory highFives = new uint256[](_tokens.length);
        for (uint256 index = 0; index < _tokens.length; index++) {
            highFives[index] = tokenHighFiversCount[_tokens[index]];
        }
        return highFives;
    }

    function getDeposites(
        uint256[] memory _tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory deposites = new uint256[](_tokens.length);
        for (uint256 index = 0; index < _tokens.length; index++) {
            deposites[index] = tokenDeposits[_tokens[index]][address(0)];
        }
        return deposites;
    }

    function getDepositesERC20(
        uint256[] memory _tokens,
        IERC20 _erc20Address
    ) external view returns (uint256[] memory) {
        uint256[] memory depositesERC20 = new uint256[](_tokens.length);
        for (uint256 index = 0; index < _tokens.length; index++) {
            depositesERC20[index] = tokenDeposits[_tokens[index]][
                address(_erc20Address)
            ];
        }
        return depositesERC20;
    }

    function setUpdateableTime(uint256 _updateableTimes) external onlyOwner {
        updateableTimes = _updateableTimes;
    }
}
