pragma solidity ^0.4.21;

contract MainInterface {
    function transferToken(
        address[3] addresses,
        uint256 amount,
        address watcher
    ) returns (bool);
}
