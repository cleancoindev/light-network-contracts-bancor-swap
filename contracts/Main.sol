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
        address receiver,
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

        IERC20Token[] storage pathConverted;
        for(uint i = 0; i < path.length; i++) {
            pathConverted.push(IERC20Token(path[i]));
        }

        pathConverted[0].transferFrom(msg.sender, address(this), amount);
        pathConverted[0].approve(address(bancor), amount);
        uint amountReceived = bancor.quickConvert(pathConverted, amount, 1);
        pathConverted[pathConverted.length].transfer(receiver, amountReceived);
        return true;
    }

}
