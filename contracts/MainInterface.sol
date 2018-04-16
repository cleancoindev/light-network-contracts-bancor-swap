pragma solidity ^0.4.21;

contract MainInterface {
    function transferToken(
        address[5] addresses,
        uint256 amount
    ) returns (bool);
}
