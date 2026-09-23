// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title BavaniSwapPool
/// @notice A minimal constant-product (x * y = k) liquidity pool for the
///         BA / ETH trading pair, in the spirit of Uniswap V2, kept small
///         and easy to read/demo. 0.3% swap fee, same as Uniswap.
contract BavaniSwapPool is ReentrancyGuard {
    IERC20 public immutable token; // BA token
    address public owner;

    uint256 public reserveToken; // BA reserves
    uint256 public reserveETH;   // ETH reserves

    uint256 public constant FEE_NUMERATOR = 997;   // 0.3% fee
    uint256 public constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount);
    event SwapETHForToken(address indexed user, uint256 ethIn, uint256 tokenOut);
    event SwapTokenForETH(address indexed user, uint256 tokenIn, uint256 ethOut);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    /// @notice Seed the pool with the initial BA + ETH liquidity.
    ///         Call once, right after deployment. Owner must approve this
    ///         contract to pull `tokenAmount` of BA beforehand.
    function addInitialLiquidity(uint256 tokenAmount) external payable onlyOwner {
        require(reserveToken == 0 && reserveETH == 0, "liquidity already added");
        require(tokenAmount > 0 && msg.value > 0, "need token and eth");

        require(token.transferFrom(msg.sender, address(this), tokenAmount), "transferFrom failed");

        reserveToken = tokenAmount;
        reserveETH = msg.value;

        emit LiquidityAdded(tokenAmount, msg.value);
    }

    /// @notice Swap ETH for BA tokens.
    function swapETHForToken(uint256 minTokenOut) external payable nonReentrant {
        require(msg.value > 0, "send eth to swap");
        require(reserveETH > 0 && reserveToken > 0, "no liquidity");

        uint256 ethInWithFee = msg.value * FEE_NUMERATOR;
        uint256 numerator = ethInWithFee * reserveToken;
        uint256 denominator = (reserveETH * FEE_DENOMINATOR) + ethInWithFee;
        uint256 tokenOut = numerator / denominator;

        require(tokenOut >= minTokenOut, "slippage: token out too low");
        require(tokenOut < reserveToken, "insufficient liquidity");

        reserveETH += msg.value;
        reserveToken -= tokenOut;

        require(token.transfer(msg.sender, tokenOut), "token transfer failed");

        emit SwapETHForToken(msg.sender, msg.value, tokenOut);
    }

    /// @notice Swap BA tokens for ETH.
    function swapTokenForETH(uint256 tokenIn, uint256 minEthOut) external nonReentrant {
        require(tokenIn > 0, "send tokens to swap");
        require(reserveETH > 0 && reserveToken > 0, "no liquidity");

        require(token.transferFrom(msg.sender, address(this), tokenIn), "transferFrom failed");

        uint256 tokenInWithFee = tokenIn * FEE_NUMERATOR;
        uint256 numerator = tokenInWithFee * reserveETH;
        uint256 denominator = (reserveToken * FEE_DENOMINATOR) + tokenInWithFee;
        uint256 ethOut = numerator / denominator;

        require(ethOut >= minEthOut, "slippage: eth out too low");
        require(ethOut < reserveETH, "insufficient liquidity");

        reserveToken += tokenIn;
        reserveETH -= ethOut;

        (bool sent, ) = msg.sender.call{value: ethOut}("");
        require(sent, "eth transfer failed");

        emit SwapTokenForETH(msg.sender, tokenIn, ethOut);
    }

    /// @notice View helper: how much BA you'd get for a given ETH input.
    function getTokenOutForETH(uint256 ethIn) external view returns (uint256) {
        if (reserveETH == 0 || reserveToken == 0) return 0;
        uint256 ethInWithFee = ethIn * FEE_NUMERATOR;
        uint256 numerator = ethInWithFee * reserveToken;
        uint256 denominator = (reserveETH * FEE_DENOMINATOR) + ethInWithFee;
        return numerator / denominator;
    }

    /// @notice View helper: how much ETH you'd get for a given BA input.
    function getETHOutForToken(uint256 tokenIn) external view returns (uint256) {
        if (reserveETH == 0 || reserveToken == 0) return 0;
        uint256 tokenInWithFee = tokenIn * FEE_NUMERATOR;
        uint256 numerator = tokenInWithFee * reserveETH;
        uint256 denominator = (reserveToken * FEE_DENOMINATOR) + tokenInWithFee;
        return numerator / denominator;
    }

    receive() external payable {}
}
