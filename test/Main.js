const ABI = require('ethereumjs-abi');
const BN = require('bn.js');
const util = require('ethereumjs-util');
const Main = artifacts.require('./Main.sol');
const UserWallet = artifacts.require('./UserWallet.sol');
const Token = artifacts.require('./Token.sol');

contract('Atomic', async function ([owner, userOne, userTwo, userThree]) {

    let tokenA, main, wallet;

    beforeEach(async () => {
        main = await Main.new();
        tokenA = await Token.new();
        wallet = await UserWallet.new([userOne, userTwo, userThree]);
    });

    it('Delegated token transfer', async () => {
        //users receive tokens
        await tokenA.transfer(wallet.address, 10, {from: owner});
        //

        const delegationHash = `0x${ABI.soliditySHA3(['address', 'address', 'uint', 'uint'],
            [new BN(tokenA.address.replace('0x', ''), 16), new BN(main.address.replace('0x', ''), 16), 10, 0]).toString('hex')}`;
        const userOneSig = await web3.eth.sign(userOne, delegationHash);
        const userOneRaw = util.fromRpcSig(userOneSig);

        const userTwoHash = `0x${ABI.soliditySHA3(['bytes32', 'uint'],
            [delegationHash, 0]).toString('hex')}`;
        const userTwoSig = await web3.eth.sign(userTwo, userTwoHash);
        const userTwoRaw = util.fromRpcSig(userTwoSig);

        const userOneR = `0x${userOneRaw.r.toString('hex')}`, userOneS = `0x${userOneRaw.s.toString('hex')}`,
            userOneV = userOneRaw.v;
        const userTwoR = `0x${userTwoRaw.r.toString('hex')}`, userTwoS = `0x${userTwoRaw.s.toString('hex')}`,
            userTwoV = userTwoRaw.v;

        /*

            uint8[2] v,
            bytes32[4] rs,
            address[5] addresses,
            uint256[3] misc

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
            signerTwoS: rs[3],

        });
         */

        await wallet.delegate(
            [userOneV, userTwoV],
            [userOneR, userTwoR, userOneS, userTwoS],
            [userOne, userTwo, tokenA.address, userTwo, main.address],
            [0, 0, 10]
        );
    });
});
