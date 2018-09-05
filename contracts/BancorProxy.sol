pragma solidity ^0.4.24;

import "zeppelin-solidity/contracts/ownership/Claimable.sol";
import "./interfaces/IERC20Token.sol";

contract Bancor {
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
    public
    payable
    returns (uint256);

}

/**
    Interfaces with Bancor's quick convert functionality to quickly swap tokens according to a predefined path
*/

contract BancorProxy is Claimable {

    Bancor public bancor;

    constructor(address _bancor) public {
        bancor = Bancor(_bancor);
    }

    /**
        path: The quick convert path that the Bancor protocol follows to convert a token
        receiverAddress: Who will receive the tokens after they have been swapped
        executor: The user who will take a cut of the tokens after (or before) they have been swapped. TODO
        amount: The amount being swapped
    */

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
    )
    {

        //convert the path to the correct parameter type
        IERC20Token[] memory pathConverted = new IERC20Token[](path.length);

        for (uint i = 0; i < path.length; i++) {
            pathConverted[i] = IERC20Token(path[i]);
        }

        //transfer the balances to this contract so that it can be converted
        require(IERC20Token(path[0]).transferFrom(msg.sender, address(this), amount), "transferFrom msg.sender failed");
        require(IERC20Token(path[0]).approve(address(bancor), amount), "approve to bancor failed");

        //convert along the path specified
        uint256 amountReceived = bancor.quickConvert(pathConverted, amount, 1);

        //TODO: Pay executor a small fee for paying the user's gas costs

        //send the converted amount to the desired receiver's address
        require(IERC20Token(path[path.length - 1]).transfer(receiverAddress, amountReceived),
            "transfer back to receiverAddress failed"
        );
        return true;
    }

}
