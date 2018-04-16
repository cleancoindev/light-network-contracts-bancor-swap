pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
import './interfaces/IERC20Token.sol';

contract IBancorConverter {
    function convert(
        IERC20Token _fromToken,
        IERC20Token _toToken,
        uint256 _amount,
        uint256 _minReturn
    )
    public returns (uint256);
}

contract Main is Claimable {

    IBancorConverter bancor;
    function Main(address _bancor) {
        bancor = IBancorConverter(_bancor);
    }

    function transferToken(
        address[5] addresses,
        uint256 amount
    )
    public
    returns
    (
        bool
    )
    {
        //TODO: require
        IERC20Token token = IERC20Token(addresses[0]);
        token.transferFrom(addresses[2], address(this), amount);
        token.approve(address(bancor), amount);
        bancor.convert(token, IERC20Token(addresses[1]), amount, 1);
//        ERC20 receivingToken = ERC20(addresses[2]);
//        receivingToken.transfer(addresses[4], amount);
        return true;
    }

}
