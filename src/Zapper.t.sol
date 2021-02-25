pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Zapper.sol";

contract ZapperTest is DSTest {
    Zapper zapper;

    function setUp() public {
        zapper = new Zapper();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
