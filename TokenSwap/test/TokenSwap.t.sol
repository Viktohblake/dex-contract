// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {TokenSwap} from "../src/TokenSwap.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CounterTest is Test {
    TokenSwap public tokenSwap;

    address ETHUSDAddress = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address LINKUSDAddress = 0xc59E3633BAAC79493d908e63626716e204A45EdF;
    address DIAUSD = 0x14866185B1962B63C3Ea9E03Bc1da838bab34C19;

    // Contract
    address DIA = 0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6;
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
        vm.startPrank(0x61E5E1ea8fF9Dc840e0A549c752FA7BDe9224e99);

        uint256 _linkAmount = 10e18;
        IERC20(LINK).transfer(
            0xd0aD7222c212c1869334a680e928d9baE85Dd1d0,
            _linkAmount
        );
        assertEq(
            IERC20(LINK).balanceOf(0xd0aD7222c212c1869334a680e928d9baE85Dd1d0),
            _linkAmount
        );
        vm.stopPrank();

        vm.startPrank(0xd0aD7222c212c1869334a680e928d9baE85Dd1d0);
        uint256 _amount = 10e18;
        IERC20(DIA).approve(address(tokenSwap), _amount);

        IERC20(LINK).approve(address(tokenSwap), _linkAmount);
        tokenSwap.AddLiquidity(_amount, _linkAmount);
        uint256 diaBalance = tokenSwap.DIADeposit(DIA);
        uint256 linkBalance = tokenSwap.LINKDeposit(LINK);

        assertEq(diaBalance, _amount);
        assertEq(linkBalance, _linkAmount);
    }

    function testSwapForETH() public {
        testAddLiquidity();
        uint256 _amount = 10e18;
        uint256 _depositAmount = 1e18;
        uint256 diaDepositBeforeSwap = tokenSwap.DIADeposit(DIA);
        tokenSwap.swapTokenForETH(DIAUSD, _depositAmount);
        uint256 diaDepositAfterSwap = tokenSwap.DIADeposit(DIA);

        assertEq(diaDepositBeforeSwap, _amount);
        assertNotEq(diaDepositAfterSwap, _amount);
    }

    function testSwapTokenForToken() public {
        testAddLiquidity();

        uint256 _depositAmount = 1e18;
        uint256 _linkDepositAmount = 1e18;
        uint256 linksDepositBeforeSwap = tokenSwap.LINKDeposit(LINK);
        tokenSwap.swapTokenForToken(
            DIA,
            LINKUSDAddress,
            _depositAmount,
            _linkDepositAmount
        );
        uint256 linkDepositAfterSwap = tokenSwap.LINKDeposit(LINK);

        assertEq(linksDepositBeforeSwap, _linkDepositAmount);
        assertNotEq(linkDepositAfterSwap, _linkDepositAmount);
    }

}