// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title BavaniToken (BA)
/// @notice Simple ERC20 token with a hard-capped max supply of 1,000,000 tokens.
///         The entire max supply is minted to the deployer at deployment time,
///         which is exactly what we need: 50% goes into the liquidity pool,
///         and 50% stays in the deployer's wallet.
contract BavaniToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    constructor() ERC20("Bavani", "BA") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
    }
}
