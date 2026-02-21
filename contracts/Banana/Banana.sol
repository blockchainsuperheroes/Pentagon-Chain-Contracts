// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "../shared/BasicAccessControl.sol";
import "../shared/Freezable.sol";

contract BANANA is ERC20("BANANA", "BANANA"), Freezable, BasicAccessControl {
    mapping(address => bool) public transferable;

    bool public isTransferable = false;

    function mint(address _to, uint256 _amount) external onlyModerators {
        require(!isContract(_to), "Cannot mint to the contract");
        _mint(_to, _amount);
    }

    function bulkMint(
        address[] memory _to,
        uint256[] memory _amount
    ) external onlyModerators {
        for (uint256 index = 0; index < _to.length; index++) {
            require(!isContract(_to[index]), "Cannot mint to the contract");
            _mint(_to[index], _amount[index]);
        }
    }

    function toggleIsTransferable() public onlyOwner {
        isTransferable = !isTransferable;
    }

    function addTransferable(address _transferable) external onlyOwner {
        transferable[_transferable] = true;
    }

    function removeTransferable(address _transferable) external onlyOwner {
        transferable[_transferable] = false;
    }

    function spendBananas(address _to, uint256 _amount) external {
        require(
            _to == address(this) ||
                moderators[_msgSender()] ||
                transferable[_to],
            "Cannot transfer to the provided address"
        );
        require(
            !isFrozen(_msgSender()),
            "ERC20Freezable: from account is frozen"
        );
        require(!isFrozen(_to), "ERC20Freezable: to account is frozen");
        super.transfer(_to, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(
            moderators[_msgSender()] || isTransferable,
            "Cannot transfer to the provided address"
        );

        require(!isFrozen(from), "ERC20Freezable: from account is frozen");
        require(!isFrozen(to), "ERC20Freezable: to account is frozen");
    }

    function freeze(address _account) public onlyModerators {
        freezes[_account] = true;
        emit Frozen(_account);
    }

    function unfreeze(address _account) public onlyModerators {
        freezes[_account] = false;
        emit Unfrozen(_account);
    }

    function isContract(address _addr) private view returns (bool hasCode) {
        uint256 length;
        assembly {
            length := extcodesize(_addr)
        }
        return length > 0;
    }
}
