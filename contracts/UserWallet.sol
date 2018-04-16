pragma solidity ^0.4.21;

import 'zeppelin-solidity/contracts/ownership/Claimable.sol';
import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
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
        address tokenAddress;
        address receivingAddress;
        address destinationAddress;

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

    function delegate
    (
        uint8[2] v,
        bytes32[4] rs,
        address[5] addresses,
        uint256[3] misc
    )
    external
    {
        Delegation memory delegation = Delegation({
            signerOne: addresses[0],
            signerTwo: addresses[1],
            tokenAddress: addresses[2],
            receivingAddress: addresses[3],
            destinationAddress: addresses[4],


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
            delegation.tokenAddress,
            delegation.receivingAddress,
            delegation.destinationAddress,
            delegation.amount,
            delegation.signerOneNonce
        );

        //ensure delegation has not happened yet
        require(!delegations[delegatedHash]);
        delegations[delegatedHash] = true;

        //ensure enough tokens are already in this contract
        ERC20 token = ERC20(delegation.tokenAddress);
        require(token.balanceOf(address(this)) >= delegation.amount);

        //TODO signature checks


        //approve sending the token
        token.approve(delegation.destinationAddress, delegation.amount);
        MainInterface main = MainInterface(delegation.destinationAddress);
        require(main.transferToken(
            [delegation.tokenAddress, address(this), delegation.receivingAddress],
            delegation.amount,
            msg.sender
        ));
    }

}
