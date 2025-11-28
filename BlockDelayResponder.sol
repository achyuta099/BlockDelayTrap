// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract BlockDelayResponder {
    event DelayDetected(address indexed target, uint256 prevBlock, uint256 currBlock, uint256 delay);

    function handleAnomaly(bytes calldata payload) external {
        (address target, uint256 prevBlock, uint256 currBlock, uint256 delay) =
            abi.decode(payload, (address, uint256, uint256, uint256));
        emit DelayDetected(target, prevBlock, currBlock, delay);
    }
}
