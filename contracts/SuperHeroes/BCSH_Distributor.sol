// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IBlockchain_Superheroes} from "../interfaces/IBlockchain_Superheroes.sol";
import {BasicAccessControl} from "../shared/BasicAccessControl.sol";

contract BCSH_Distributor is BasicAccessControl {
    event Mint(address _owner, uint256 token);

    address public blockchainSuperheroes;

    constructor(address _blockchainSuperheroes) {
        blockchainSuperheroes = _blockchainSuperheroes;
    }

    uint256 public mintingCount = 143_000_000_000;
    uint256 public mintingCap = 143_000_002_500; //  end token id

    uint256 public tokenPrice = 100 * (10 ** 18);

    bool public _mintingPaused = false;

    function setContract(address _blockchainSuperheroes) external onlyOwner {
        blockchainSuperheroes = _blockchainSuperheroes;
    }

    function getBalance(address _owner) public view returns (uint256) {
        IBlockchain_Superheroes blockchainSuperherosContract = IBlockchain_Superheroes(
                blockchainSuperheroes
            );
        return blockchainSuperherosContract.balanceOf(_owner);
    }

    function mintTo(address _owner) public onlyModerators returns (bool) {
        IBlockchain_Superheroes blockchainSuperherosContract = IBlockchain_Superheroes(
                blockchainSuperheroes
            );

        mintingCount++;

        require(!_mintingPaused, "Minting paused");
        require(mintingCount <= mintingCap, "Minting cap reached");

        blockchainSuperherosContract.mintNextToken(_owner, mintingCount);
        emit Mint(_owner, mintingCount);
        return true;
    }

    function mint() public payable returns (bool) {
        IBlockchain_Superheroes blockchainSuperherosContract = IBlockchain_Superheroes(
                blockchainSuperheroes
            );

        mintingCount++;

        require(!_mintingPaused, "Minting paused");
        require(msg.value == tokenPrice, "token price not met");
        require(mintingCount <= mintingCap, "Minting cap reached");

        blockchainSuperherosContract.mintNextToken(msg.sender, mintingCount);
        emit Mint(msg.sender, mintingCount);
        return true;
    }

    fallback() external payable {}

    receive() external payable {}

    function togglePause(bool _pause) public onlyOwner {
        require(_mintingPaused != _pause, "Already in desired pause state");
        _mintingPaused = _pause;
    }

    function updatePrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function setMintingCap(uint256 _mintingCap) external onlyOwner {
        mintingCap = _mintingCap;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
