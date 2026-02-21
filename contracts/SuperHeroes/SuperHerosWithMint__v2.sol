// Original license: SPDX_License_Identifier: MIT
pragma solidity >=0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/onft/ONFT721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BasicAccessControl} from "../shared/BasicAccessControl.sol";
import {Freezable} from "../shared/Freezable.sol";

contract Blockchain_Superheroes__v2 is ONFT721, Freezable, BasicAccessControl {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
    event Highfive(uint256 _tokenId, address _owner);
    event Deposit(uint256 _tokenId, uint256 _amount, address _owner);
    event WithdrawDeposit(uint256 _tokenId, uint256 _amount, address _owner);


    uint256 constant START_TOKEN = 1_116_000_000_001; // replace with chain id of the network
    uint256 _maxCap = 1_116_000_002_500;

    uint256 public updateableTimes = 2;
    uint256 public updatedTimes = 0;
    bool public nativeDepositAllowed = true;
    bool public erc20DepositAllowed = true;

    // create mapping for mainting eth deposits
    mapping(uint256 => mapping(address => uint256)) public tokenDeposits;

    mapping(uint256 => uint256) public tokenHighFiversCount;
    mapping(uint256 => address[]) public tokenHighFivers;
    // mapping for maintaining that how many times a user has worshipped a token
    mapping(address => mapping(uint256 => uint256)) public userHighFiversCount;

    //variable to store tokenDeposit value
    mapping(address => uint256) public totalTokenDeposit;
    mapping(address => bool) public tokensAllowed;

    receive() external payable {}

    string public _baseTokenURI = "https://api.bcsh.xyz/metadata/";

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _minGasToTransfer,
        address _lzEndpoint
    ) ONFT721(_name, _symbol, _minGasToTransfer, _lzEndpoint) {}

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

    function mintNextToken(
        address _owner,
        uint256 _tokenId
    ) external onlyModerators returns (bool) {
        return mint(_owner, _tokenId);
    }

    function mint(
        address _owner,
        uint256 _tokenId
    ) internal onlyModerators returns (bool) {
        require(_owner != address(0), "ERC721: mint to the zero address");
        require(
            _tokenId >= START_TOKEN && _tokenId <= _maxCap,
            "Token ID is out of range"
        );

        _safeMint(_owner, _tokenId);

        return true;
    }

    // function to handle deposits of eth for token ids . Only owner of token can deposit eth
    function depositFundERC20(
        IERC20 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(erc20DepositAllowed == true, "ERC20 token mint not allowed");

        require(
            tokensAllowed[address(_token)] == true,
            "This currency not accepted"
        );
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        tokenDeposits[_tokenId][address(_token)] += _amount;
        totalTokenDeposit[address(_token)] += _amount;

        require(
            _token.balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );

        _token.transferFrom(address(msg.sender), address(this), _amount);
        emit Deposit(_tokenId, _amount, msg.sender);
    }

    // function to handle deposits of eth for token ids . Only owner of token can deposit eth
    function depositFund(uint256 _tokenId) external payable {
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

    // function to withdraw erc-20 token from token deposits
    function withdrawTokenDepositERC20(
        IERC20 _token,
        uint256 _tokenId,
        uint256 _amount
    ) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(
            tokenDeposits[_tokenId][address(_token)] >= _amount &&
                _token.balanceOf(address(this)) >=
                tokenDeposits[_tokenId][address(_token)] &&
                _token.balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );

        tokenDeposits[_tokenId][address(_token)] -= _amount;
        totalTokenDeposit[address(_token)] -= _amount;

        bool success = IERC20(_token).transfer(msg.sender, _amount);
        require(success == true, "failed transfer");
        emit WithdrawDeposit(_tokenId, _amount, msg.sender);
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

    // function to withdraw native token from token deposits
    function withdrawTokenDeposit(uint256 _tokenId, uint256 _amount) external {
        require(
            ownerOf(_tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(
            tokenDeposits[_tokenId][address(0)] >= _amount,
            "Insufficient balance"
        );

        tokenDeposits[_tokenId][address(0)] -= _amount;
        totalTokenDeposit[address(0)] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit WithdrawDeposit(_tokenId, _amount, msg.sender);
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

    function toggleNativeDepositAllowed() external onlyModerators {
        nativeDepositAllowed = !nativeDepositAllowed;
    }

    function toggleERC20DepositAllowed() external onlyModerators {
        erc20DepositAllowed = !erc20DepositAllowed;
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
        require(ownerOf(_tokenId) != address(0), "Token not minted");

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

    function getDepositesERC20(
        uint256[] memory _tokens,
        IERC20[] memory _erc20Addresses
    ) external view returns (uint256[] memory) {
        require(
            (_tokens.length == _erc20Addresses.length),
            "Invalid value provided"
        );
        uint256[] memory depositesERC20 = new uint256[](_tokens.length);
        for (uint256 index = 0; index < _tokens.length; index++) {
            depositesERC20[index] = tokenDeposits[_tokens[index]][
                address(_erc20Addresses[index])
            ];
        }
        return depositesERC20;
    }

    function setUpdateableTime(uint256 _updateableTimes) external onlyOwner {
        updateableTimes = _updateableTimes;
    }
}
