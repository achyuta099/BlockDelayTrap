// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITrap.sol";

contract BlockDelayTrap is ITrap {
    uint256 public constant BLOCK_DELAY_THRESHOLD = 50;
    uint8   public constant MIN_SAMPLES = 2;

    address public constant TARGET = YOUR_WALLET_ADDRESS;

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.number, block.timestamp);
    }

    function shouldRespond(bytes[] calldata data)
        external
        pure
        override
        returns (bool, bytes memory)
    {
        if (data.length < MIN_SAMPLES) return (false, "");

        (uint256 blkNow, ) = abi.decode(data[0], (uint256, uint256));
        (uint256 blkPrev, ) = abi.decode(data[1], (uint256, uint256));

        if (blkNow <= blkPrev) return (false, "");

        uint256 delay = blkNow - blkPrev;
        if (delay <= BLOCK_DELAY_THRESHOLD) return (false, "");

        bytes memory payload = abi.encode(TARGET, blkPrev, blkNow, delay);
        return (true, payload);
    }
}
