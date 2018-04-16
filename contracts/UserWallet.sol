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
        address tokenAddress;
        address tokenBAddress;
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

    function delegate
    (
        uint8[2] v,
        bytes32[4] rs,
        address[6] addresses,
        uint256[3] misc
    )
    external
    {
        Delegation memory delegation = Delegation({
            signerOne: addresses[0],
            signerTwo: addresses[1],
            tokenAddress: addresses[2],
            tokenBAddress: addresses[3],
            destinationAddress: addresses[4],
            receiverAddress: addresses[5],



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
            delegation.tokenBAddress,
            delegation.destinationAddress,
            delegation.receiverAddress,
            delegation.amount,
            delegation.signerOneNonce
        );

        //ensure delegation has not happened yet
        require(!delegations[delegatedHash]);
        delegations[delegatedHash] = true;

        //ensure enough tokens are already in this contract
        IERC20Token token = IERC20Token(delegation.tokenAddress);
        require(token.balanceOf(address(this)) >= delegation.amount);

        //TODO signature checks
        //TODO events


        //approve sending the token
        token.approve(delegation.destinationAddress, delegation.amount);
        MainInterface main = MainInterface(delegation.destinationAddress);
        main.transferToken(
            [delegation.tokenAddress, delegation.tokenBAddress, address(this), msg.sender, delegation.receiverAddress],
            delegation.amount
        );
    }

}
