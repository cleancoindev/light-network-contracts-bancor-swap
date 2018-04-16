const ABI = require('ethereumjs-abi');
const BN = require('bn.js');
const util = require('ethereumjs-util');
const Main = artifacts.require('./Main.sol');
const UserWallet = artifacts.require('./UserWallet.sol');
const Token = artifacts.require('./Token.sol');

const Utils = artifacts.require('Utils.sol');
const Owned = artifacts.require('Owned.sol');
const Managed = artifacts.require('Managed.sol');
const TokenHolder = artifacts.require('TokenHolder.sol');
const ERC20Token = artifacts.require('ERC20Token.sol');
const EtherToken = artifacts.require('EtherToken.sol');
const SmartToken = artifacts.require('SmartToken.sol');
const SmartTokenController = artifacts.require('SmartTokenController.sol');
const BancorFormula = artifacts.require('BancorFormula.sol');
const BancorGasPriceLimit = artifacts.require('BancorGasPriceLimit.sol');
const BancorQuickConverter = artifacts.require('BancorQuickConverter.sol');
const BancorConverterExtensions = artifacts.require('BancorConverterExtensions.sol');
const BancorConverter = artifacts.require('BancorConverter.sol');
const CrowdsaleController = artifacts.require('CrowdsaleController.sol');

const TestERC20Token = artifacts.require('TestERC20Token.sol');
const utils = require('./helpers/Utils');


contract('Light', async function ([owner, userOne, userTwo, userThree]) {

    let main, wallet;
    let token;
    let connectorToken;
    let connectorToken2;
    let converter;
    let quickConverter;

    const gasPrice = 22000000000;

    beforeEach(async () => {
        token = await SmartToken.new('Token1', 'TKN1', 2);
        let formula = await BancorFormula.new();
        let gasPriceLimit = await BancorGasPriceLimit.new(gasPrice);
        quickConverter = await BancorQuickConverter.new();
        let converterExtensions = await BancorConverterExtensions.new(formula.address, gasPriceLimit.address, quickConverter.address);
        connectorToken = await TestERC20Token.new('ERC Token 1', 'ERC1', 100000);
        connectorToken2 = await TestERC20Token.new('ERC Token 2', 'ERC2', 200000);
        converter = await BancorConverter.new(token.address, converterExtensions.address, 0, connectorToken.address, 250000);
        await converter.addConnector(connectorToken2.address, 150000, false);

        await token.issue(owner, 20000);
        await connectorToken.transfer(converter.address, 5000);
        await connectorToken2.transfer(converter.address, 8000);

        await token.transferOwnership(converter.address);
        await converter.acceptTokenOwnership();


        main = await Main.new(converter.address);
        wallet = await UserWallet.new([userOne, userTwo, userThree]);
    });

    // it('Should convert between ERC1 and ERC2 through TKN1', async () => {
    //     await connectorToken.transfer(userOne, 10);
    //     await connectorToken.approve(converter.address, 5, {from: userOne});
    //     await converter.convert(connectorToken.address, connectorToken2.address, 5, 1, {from: userOne, gasPrice: 1});
    // });

    it('Delegated token transfer', async () => {

        await connectorToken.transfer(wallet.address, 10, {from: owner});
        const delegationHash = `0x${ABI.soliditySHA3(['address', 'address', 'address', 'address', 'uint', 'uint'],
            [
                new BN(connectorToken.address.replace('0x', ''), 16),
                new BN(connectorToken2.address.replace('0x', ''), 16),
                new BN(main.address.replace('0x', ''), 16),
                new BN(userTwo.replace('0x', ''), 16),
                5,
                0
            ])
            .toString('hex')}`;
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
         */

        await wallet.delegate(
            [userOneV, userTwoV],
            [userOneR, userTwoR, userOneS, userTwoS],
            [userOne, userTwo, connectorToken.address, connectorToken2.address, main.address, userTwo],
            [0, 0, 5],
            {gasPrice: 1}
        );
    });
});
