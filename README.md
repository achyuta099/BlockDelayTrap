# BlockDelayTrap
The trap will react if too many blocks have passed between two consecutive selections (for example, > 50). This is useful if the operator wants to catch anomalies in the network (e.g., confirmation delays or suspicious pauses in activity). This information helps to see failures or manipulations at the network/RPC level.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITrap.sol";

contract BlockDelayTrap is ITrap {
    uint256 public constant BLOCK_DELAY_THRESHOLD = 50;
    uint8   public constant MIN_SAMPLES = 2;

    address public constant TARGET = 0x4f97469df5A96E6b75E562e0792efcAc599D4B9e;

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
```

BlockDelayResponder
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BlockDelayResponder {
    event DelayDetected(address indexed target, uint256 prevBlock, uint256 currBlock, uint256 delay);

    function handleAnomaly(bytes calldata payload) external {
        (address target, uint256 prevBlock, uint256 currBlock, uint256 delay) =
            abi.decode(payload, (address, uint256, uint256, uint256));
        emit DelayDetected(target, prevBlock, currBlock, delay);
    }
}
Deployer: 0x4f97469df5A96E6b75E562e0792efcAc599D4B9e
Deployed to: 0x598823fF8BAD99bfF02882757af41e39fFA08d81
Transaction hash: 0x3acf4cfe6ff9845aee7e976532ed049833abd7100ebfbefa550d4b1f60747578
```

ITrap
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrap {
    function collect() external view returns (bytes memory);

    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}
```

Deploy:
```
forge create src/BlockDelayResponder.sol:BlockDelayResponder   --rpc-url https://ethereum-hoodi-rpc.publicnode.com   --broadcast   --private-key
```


Verifying BlockDelayTrap in the Hoodi test network may take some time, as delays between blocks occur irregularly. 
To demonstrate the full Drosera workflow, a simplified version of TestAlwaysTrap has been added, in which shouldRespond(...) always returns true and generates a payload in the format (TARGET, prevBlock, currBlock, delay). 
This allows Drosera to complete the entire process — aggregating signatures, sending a submit transaction, calling response_contract.handleAnomaly(bytes), and recording the event from the responder in the blockchain. Thus, the correctness of the integration is confirmed on real blocks without artificial manipulation of the network.

TestAlwaysTrap
```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ITrap.sol";

contract TestAlwaysTrap is ITrap {
    address public constant TARGET = 0x4f97469df5A96E6b75E562e0792efcAc599D4B9e;

    constructor() {}

    function collect() external view override returns (bytes memory) {
        return abi.encode(block.number, block.timestamp);
    }

    function shouldRespond(bytes[] calldata /*data*/) external pure override returns (bool, bytes memory) {
        bytes memory payload = abi.encode(TARGET, uint256(100), uint256(200), uint256(100));
        return (true, payload);
    }
}
```
