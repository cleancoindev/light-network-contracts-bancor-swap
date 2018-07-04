pragma solidity ^0.4.21;

contract MainInterface {
    function transferToken(
        address[3] path,
        address receiverAddress,
        address executor,
        uint256 amount
    )
    public
    returns
    (
        bool
    );
}
