pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';

contract Main is Claimable {

    function transferToken(
        address[3] addresses,
        uint256 amount,
        address watcher
    )
    public
    returns
    (
        bool
    )
    {
        ERC20 token = ERC20(addresses[0]);
        token.transferFrom(addresses[1], address(this), amount);
        return true;
    }

}
