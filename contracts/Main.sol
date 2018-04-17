pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
import './interfaces/IERC20Token.sol';

contract Bancor {
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
    public
    payable
    returns (uint256);

}

contract Main is Claimable {

    Bancor bancor;

    function Main(address _bancor) {
        bancor = Bancor(_bancor);
    }

    function transferToken(
        address[] path,
        address receiverAddress,
        address executor,
        uint256 amount
    )
    public
    returns
    (
        bool
    )
    {
        //TODO: require
        //TODO: events

        IERC20Token[] memory pathConverted = new IERC20Token[](path.length);

        for (uint i = 0; i < path.length; i++) {
            pathConverted[i] = IERC20Token(path[i]);
        }

        IERC20Token(path[0]).transferFrom(msg.sender, address(this), amount);
        IERC20Token(path[0]).approve(address(bancor), amount);
        uint256 amountReceived = bancor.quickConvert(pathConverted, amount, 1);
        IERC20Token(path[path.length - 1]).transfer(receiverAddress, amountReceived);
        return true;
    }

}
