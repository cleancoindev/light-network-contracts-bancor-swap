pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
import './interfaces/IERC20Token.sol';
import './MainInterface.sol';

/**
    A multi-sig wallet that allows for tokens to be swapped using Bancor
    Additionally, token swaps can be delegated to an external third party
    This allows the contract to only hold tokens and for gas costs to be paid with tokens
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
        bytes32 signerTwoR;
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

    /**
        Delegators can call this function to initiate a token swap or a token transfer
        v: Digital signature param
        rs: Digital signature param
        addresses: Destination address, receiver, signers
        misc: Nonces and amount
        path: Quick convert path followed by the Bancor Protocol
    */

    function delegate
    (
        uint8[2] v,
        bytes32[4] rs,
        address[4] addresses,
        uint256[3] misc,
        address[3] path
    )
    public
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
            signerTwoR: rs[1],
            signerOneS: rs[2],
            signerTwoS: rs[3]
        });

        bytes32 delegatedHashOne = keccak256(
            path[0],
            path[1],
            path[2],
            delegation.destinationAddress,
            delegation.receiverAddress,
            delegation.amount,
            delegation.signerOneNonce
        );

        //ensure delegation has not happened yet
        require(!delegations[delegatedHashOne], "signer one: order filled");
        delegations[delegatedHashOne] = true;

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(prefix, delegatedHashOne);
        require(ecrecover(prefixedHash, delegation.signerOneV, delegation.signerOneR, delegation.signerOneS) ==
            address(delegation.signerOne), "Failed to verify userOne signature");

        bytes32 delegatedHashTwo = keccak256(
            delegatedHashOne,
            delegation.signerTwoNonce
        );

        //ensure delegation has not happened yet
        require(!delegations[delegatedHashTwo], "signer two: order filled");
        delegations[delegatedHashTwo] = true;

        bytes32 prefixedHashTwo = keccak256(prefix, delegatedHashTwo);
        require(ecrecover(prefixedHashTwo, delegation.signerTwoV, delegation.signerTwoR, delegation.signerTwoS) ==
            address(delegation.signerTwo), "Failed to verify userTwo signature");

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
