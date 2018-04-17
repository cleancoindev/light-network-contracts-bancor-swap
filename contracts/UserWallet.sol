pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
import './interfaces/IERC20Token.sol';
import './MainInterface.sol';

/*
    Allows for tokens to be transferred
*/

contract UserWallet is Claimable {

    address[] public signers;
    mapping(bytes32 => bool) delegations;

    struct Delegation {
        address signerOne;
        address signerTwo;
        address destinationAddress;
        address receiverAddress;

        address[] path;

        uint8 signerOneV;
        uint8 signerTwoV;
        uint256 signerOneNonce;
        uint256 signerTwoNonce;
        uint256 amount;

        bytes32 signerOneR;
        bytes32 sigerTwoR;
        bytes32 signerOneS;
        bytes32 signerTwoS;
    }

    function UserWallet
    (
        address[] _signers
    )
    {
        require(_signers.length == 3); //2 of 3 multi-signature required
        signers = _signers;
    }

    //TODO: function to withdraw a token

    function delegate
    (
        uint8[2] v,
        bytes32[4] rs,
        address[4] addresses,
        uint256[3] misc,
        address[] path
    )
    external
    {
        Delegation memory delegation = Delegation({
            signerOne: addresses[0],
            signerTwo: addresses[1],
            destinationAddress: addresses[2], //address that will execute the trade
            receiverAddress: addresses[3], //address that will receive the resulting tokens

            path: path,

            signerOneV: v[0],
            signerTwoV: v[1],
            signerOneNonce: misc[0],
            signerTwoNonce: misc[1],
            amount: misc[2],

            signerOneR: rs[0],
            sigerTwoR: rs[1],
            signerOneS: rs[2],
            signerTwoS: rs[3]
        });

        bytes32 delegatedHash = keccak256(
            delegation.path,
            delegation.destinationAddress,
            delegation.receiverAddress,
            delegation.amount,
            delegation.signerOneNonce
        );

        //ensure delegation has not happened yet
        require(!delegations[delegatedHash]);
        delegations[delegatedHash] = true;

        //TODO signature checks
        //TODO events


        //approve sending the token
        IERC20Token(delegation.path[0]).approve(delegation.destinationAddress, delegation.amount);
        MainInterface main = MainInterface(delegation.destinationAddress);
        main.transferToken(
            delegation.path,
            delegation.receiverAddress,
            msg.sender,
            delegation.amount
        );
    }

}
