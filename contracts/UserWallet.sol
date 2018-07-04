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
        address[3] path
    )
    external
    {
        Delegation memory delegation = Delegation({
            signerOne: addresses[0],
            signerTwo: addresses[1],
            destinationAddress: addresses[2], //address that will execute the trade
            receiverAddress: addresses[3], //address that will receive the resulting tokens

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
            path[0],
            path[1],
            path[2],
            delegation.destinationAddress,
            delegation.receiverAddress,
            delegation.amount,
            delegation.signerOneNonce
        );

        //ensure delegation has not happened yet
        require(!delegations[delegatedHash], "order has already been filled");
        delegations[delegatedHash] = true;

        //TODO signature checks
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, delegatedHash);
        require(ecrecover(prefixedHash, delegation.signerOneV, delegation.signerOneR, delegation.signerOneS) ==
            address(delegation.signerOne), "Failed to verify userOne signature");
        //TODO events


        //approve sending the token
        require(IERC20Token(path[0]).approve(delegation.destinationAddress, delegation.amount),
            "failed to approve path[0] token to destination address");
        MainInterface main = MainInterface(delegation.destinationAddress);
        require(main.transferToken(
            path,
            delegation.receiverAddress,
            msg.sender,
            delegation.amount),
        "failed to delegate token transfer to destinationAddress");
    }

}
