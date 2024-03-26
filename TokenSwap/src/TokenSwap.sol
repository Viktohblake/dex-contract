// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console2} from "forge-std/Test.sol";

contract TokenSwap {
    address ETHUSDAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address LINKUSDAddress = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    address DIAUSD = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;
    AggregatorV3Interface internal dataFeed;

    // contract address
    address DAI = 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6;
    address LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    mapping(address => uint256) public LINKDeposit;

    mapping(address => uint256) public DIADeposit;

    int public pairResult;

    int public testingGetDerivedPrice;

    event TokenSwapForETH(address from, address to, uint256 value);

    function getChainlinkDataFeedLatestAnswer(
        address _pairAddress
    ) public returns (int) {
        dataFeed = AggregatorV3Interface(_pairAddress);

        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        pairResult = answer;
        return answer;
    }

    function AddLiquidity(uint256 _amountDia, uint256 _amountLink) external {
        require(
            IERC20(DAI).transferFrom(msg.sender, address(this), _amountDia),
            "Deposit Faild for TokenA"
        );
        require(
            IERC20(LINK).transferFrom(msg.sender, address(this), _amountLink),
            "Deposit Failed for TokenB"
        );
        LINKDeposit[LINK] = LINKDeposit[LINK] + _amountLink;
        DIADeposit[DAI] = DIADeposit[DAI] + _amountDia;
    }

    // function ViewApproval() external view returns (uint256) {
    //     return IERC20(TokenA).allowance(msg.sender, address(this));
    // }

    // function SwapToken(uint256 _toAmount) external {
    //     require(swap(_toAmount), "Unable to Swap Token");
    // }

    // function swap(uint256 _value) internal returns (bool) {
    //     require(msg.sender != address(0x0), "Wrong EOA");

    //     ATokenDeposit[msg.sender] = ATokenDeposit[msg.sender] - _value;

    //     BTokenDeposit[msg.sender] = BTokenDeposit[msg.sender] + _value;
    //     //(success, _to.call{value:_value}(""));
    //     //_to.transfer(_value);
    //     // Event
    //     return true;
    // }

    function swapTokenForETH(address _base, uint256 _amountIn) external {
        // int256 tokenPrice = getDerivedPrice(_base, ETHUSDAddress, 8);

        // uint256 amountOut = uint256(result) * _amount;

        // uint256 amountOutDivid = amountOut / 100;
        // console2.log("Raw result from Chainlink :", result);
        // console2.log("Amount after calculation with swap amount", amountOut);
        // console2.log("Current Dia Liquidity: ", DIADeposit);
        // console2.log("Checking Amount After Calculation", amountOutDivid);

        // DIADeposit = DIADeposit - amountOutDivid;

        AggregatorV3Interface tokenPriceFeed = AggregatorV3Interface(_base);
        (, int tokenPrice, , , ) = tokenPriceFeed.latestRoundData();

        uint256 ethAmount = (_amountIn * uint(tokenPrice)) /
            (10 ** tokenPriceFeed.decimals());

        emit TokenSwapForETH(address(this), msg.sender, ethAmount);

        DIADeposit[_base] = DIADeposit[_base] - ethAmount;

        // payable(msg.sender).transfer(ethAmount);
    }

    function swapTokenForToken(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin
    ) external {
        AggregatorV3Interface tokenInPriceFeed = AggregatorV3Interface(tokenIn);
        AggregatorV3Interface tokenOutPriceFeed = AggregatorV3Interface(
            tokenOut
        );
        // Get the latest price data for both tokens
        (, int token1Price, , , ) = tokenInPriceFeed.latestRoundData();
        (, int token2Price, , , ) = tokenOutPriceFeed.latestRoundData();

        // Calculate the exchange rate between the tokens
        uint exchangeRate = (uint(token1Price) *
            10 ** tokenOutPriceFeed.decimals()) / uint(token2Price);

        // Calculate the amount of tokenOut to send
        uint amountOut = (amountIn * exchangeRate) /
            (10 ** tokenInPriceFeed.decimals());

        console2.log(
            "Balance of token sdender",
            IERC20(tokenIn).balanceOf(msg.sender)
        );

        // Transfer tokens from the caller to this contract
        DIADeposit[tokenIn] = DIADeposit[tokenIn] + amountIn;
        LINKDeposit[tokenOut] = LINKDeposit[tokenOut] - amountOut;

        // Transfer tokensOut to the caller
        require(
            IERC20(tokenOut).transfer(msg.sender, amountOut),
            "Transfer failed"
        );

        // Optional: Ensure minimum amount of tokenOut received
        require(amountOut >= amountOutMin, "Insufficient output amount");
    }

    fallback() external payable {}

    receive() external payable {}
}