// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BasicAccessControl} from "../shared/BasicAccessControl.sol";
import {Freezable} from "../shared/Freezable.sol";

contract Blockchain_Supervillains is ONFT721, Freezable, BasicAccessControl {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event Highfive(uint256 _tokenId, address _owner);
    event Deposit(uint256 _tokenId, uint256 _amount, address _owner);
    event WithdrawDeposit(uint256 _tokenId, uint256 _amount, address _owner);
    event SunkenPower(uint256 _tokenId, uint256 _amount, address _owner);

    address public burnAddress = address(this);
    uint256 constant START_TOKEN = 1_482_601_649_000_000_000;
    uint256 public currentToken = START_TOKEN;
    uint256 _maxCap = 1_482_601_649_000_000_999;

    bool public isTransferable = false;

    // create mapping for mainting gas deposits
    mapping(uint256 => uint256) public tokenDeposits;

    // create mapping for mainting gas burns
    mapping(uint256 => uint256) public tokenBurns;

    mapping(uint256 => uint256) public tokenHighFiversCount;
    mapping(uint256 => address[]) public tokenHighFivers;
    // mapping for maintaining that how many times a user has worshipped a token
    mapping(address => mapping(uint256 => uint256)) public userHighFiversCount;

    IERC20 public erc20Token;

    //variable to store tokenDeposit value
    uint256 public totalTokenDeposit;

    receive() external payable {}

    string public _baseTokenURI = "https://api.bcsh.xyz/metadata/musklprime/";

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _minGasToTransfer,
        address _lzEndpoint
    ) ONFT721(_name, _symbol, _minGasToTransfer, _lzEndpoint) {
        erc20Token = IERC20(0x7F73B66d4e6e67bCdeaF277b9962addcDabBFC4d);
    }

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

    function setERC20Token(IERC20 _erc20Token) external onlyOwner {
        erc20Token = _erc20Token;
    }

    function mintNextToken(
        address _owner
    ) external onlyModerators returns (bool) {
        return mint(_owner);
    }

    function mint(address _owner) internal returns (bool) {
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

    // function to handle deposits of eth for token ids . Only owner of token can deposit eth
    function depositFund(uint256 _tokenId, uint256 _amount) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        tokenDeposits[_tokenId] += _amount;
        totalTokenDeposit += _amount;
        erc20Token.transferFrom(address(msg.sender), address(this), _amount);

        emit Deposit(_tokenId, _amount, msg.sender);
    }

    function sunkenPower(uint256 _tokenId, uint256 _amount) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(
            burnAddress != address(0),
            "Burn Address cannot be null address"
        );
        tokenBurns[_tokenId] += _amount;
        erc20Token.transferFrom(address(msg.sender), burnAddress, _amount);
        emit SunkenPower(_tokenId, _amount, msg.sender);
    }

    function toggleIsTransferable() public onlyOwner {
        isTransferable = !isTransferable;
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

    function withdrawTokenDeposit(uint256 _tokenId, uint256 _amount) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(tokenDeposits[_tokenId] >= _amount, "Insufficient balance");
        tokenDeposits[_tokenId] -= _amount;
        totalTokenDeposit -= _amount;

        erc20Token.transfer(msg.sender, _amount);
        emit WithdrawDeposit(_tokenId, _amount, msg.sender);
    }

    function updateBurnAddress(address _burnAddress) external onlyOwner {
        require(
            address(this).balance > totalTokenDeposit,
            "No deposite from contract owner"
        );
        burnAddress = _burnAddress;
    }

    // function to withdraw all token from contract of contract
    function withdrawAll() external onlyOwner {
        require(
            address(this).balance > totalTokenDeposit,
            "No deposite from contract owner"
        );
        payable(msg.sender).transfer(address(this).balance - totalTokenDeposit);
    }

    function ownerWithdrawERC20(IERC20 _token) external onlyOwner {
        require(
            _token.balanceOf(address(this)) > totalTokenDeposit,
            "No withdrawl for owner"
        );
        bool success = IERC20(_token).transfer(
            msg.sender,
            _token.balanceOf(address(this)) - totalTokenDeposit
        );
        require(success == true, "failed transfer");
    }

    // function to HighFive a token
    function highFiveToken(uint256 _tokenId) external {
        require(_exists(_tokenId), "Token does not exist");
        tokenHighFiversCount[_tokenId] += 1;
        tokenHighFivers[_tokenId].push(msg.sender);
        userHighFiversCount[msg.sender][_tokenId] += 1;
        emit Highfive(_tokenId, msg.sender);
    }
}
