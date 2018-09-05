pragma solidity ^0.4.24;

contract BancorProxyI {
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
