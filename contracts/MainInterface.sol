pragma solidity ^0.4.21;

contract MainInterface {
    function transferToken(
        address[] path,
        address receiver,
        address executor,
        uint256 amount
    )
    public
    returns
    (
        bool
    );
}
