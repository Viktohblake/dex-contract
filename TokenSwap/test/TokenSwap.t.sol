// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenSwap} from "../src/TokenSwap.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwapTest is Test {
    TokenSwap public tokenSwap;

    address ETHUSDAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address LINKUSDAddress = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    address DAIUSD = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;

    // Contract
    address DAI = 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6;
    address LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    function setUp() public {
        tokenSwap = new TokenSwap();
    }

    function testChainLinkPriceFeed() public {
        int result = tokenSwap.getChainlinkDataFeedLatestAnswer(LINKUSDAddress);
        console2.log(result);
        assertGt(result, 1);
    }

    function testAddLiquidity() public {
        vm.startPrank(0xF36a4BA50C603204c3FC6d2dA8b78A7b69CBC67d);

        uint256 _linkAmount = 10e18;
        IERC20(LINK).transfer(
            0x85C6c9c42a7d249202e5fD7d0A8062395594fd6A,
            _linkAmount
        );
        assertEq(
            IERC20(LINK).balanceOf(0x85C6c9c42a7d249202e5fD7d0A8062395594fd6A),
            _linkAmount
        );
        vm.stopPrank();

        vm.startPrank(0x85C6c9c42a7d249202e5fD7d0A8062395594fd6A);
        uint256 _amount = 10e18;
        IERC20(DAI).approve(address(tokenSwap), _amount);

        IERC20(LINK).approve(address(tokenSwap), _linkAmount);
        tokenSwap.AddLiquidity(_amount, _linkAmount);
        uint256 DAIBalance = tokenSwap.DAIDeposit(DAI);
        uint256 linkBalance = tokenSwap.LINKDeposit(LINK);

        assertEq(DAIBalance, _amount);
        assertEq(linkBalance, _linkAmount);
    }

    function testSwapForETH() public {
        testAddLiquidity();
        uint256 _amount = 10e18;
        uint256 _depositAmount = 1e18;
        uint256 DAIDepositBeforeSwap = tokenSwap.DAIDeposit(DAI);
        tokenSwap.swapTokenForETH(DAIUSD, _depositAmount);
        uint256 DAIDepositAfterSwap = tokenSwap.DAIDeposit(DAI);

        assertEq(DAIDepositBeforeSwap, _amount);
        assertNotEq(DAIDepositAfterSwap, _amount);
    }

    function testSwapTokenForToken() public {
        testAddLiquidity();

        uint256 _depositAmount = 1e18;
        uint256 _linkDepositAmount = 1e18;
        uint256 linksDepositBeforeSwap = tokenSwap.LINKDeposit(LINK);
        tokenSwap.swapTokenForToken(
            DAI,
            LINKUSDAddress,
            _depositAmount,
            _linkDepositAmount
        );
        uint256 linkDepositAfterSwap = tokenSwap.LINKDeposit(LINK);

        assertEq(linksDepositBeforeSwap, _linkDepositAmount);
        assertNotEq(linkDepositAfterSwap, _linkDepositAmount);
    }

}