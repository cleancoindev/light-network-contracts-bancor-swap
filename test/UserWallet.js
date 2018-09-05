const ABI = require('ethereumjs-abi');
const BN = require('bn.js');
const util = require('ethereumjs-util');
const BancorProxy = artifacts.require('./BancorProxy.sol');
const UserWallet = artifacts.require('./UserWallet.sol');

const SmartToken = artifacts.require('SmartToken.sol');
const BancorFormula = artifacts.require('BancorFormula.sol');
const BancorGasPriceLimit = artifacts.require('BancorGasPriceLimit.sol');
const BancorQuickConverter = artifacts.require('BancorQuickConverter.sol');
const BancorConverterExtensions = artifacts.require('BancorConverterExtensions.sol');
const BancorConverter = artifacts.require('BancorConverter.sol');

const TestERC20Token = artifacts.require('TestERC20Token.sol');

contract('Light', async function ([owner, userOne, userTwo, userThree]) {

    let bancorProxy, wallet;
    let token;
    let connectorToken;
    let connectorToken2;
    let converter;
    let quickConverter;

    const gasPrice = 22000000000;

    /**
     * Setup Bancor quick converter between two ERC20 and a smart token
     */

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
        await token.transferOwnership(converter.address);
        await converter.acceptTokenOwnership();

        await connectorToken.transfer(converter.address, 5000);
        await connectorToken2.transfer(converter.address, 15000);

        bancorProxy = await BancorProxy.new(converter.address);
        wallet = await UserWallet.new([userOne, userTwo, userThree]);
    });

    /**
     * Swap between ERC1 and ERC2 using Bancor
     * Additionally, after swapping has occurred send ERC2 to User2 (from User1)
     */

    it('Delegated token transfer', async () => {

        await connectorToken.transfer(wallet.address, 10, {from: owner});

        /**
         * User one performs a digital signature on the path, destination, receiver, amount, and nonce
         */

        const delegationHash = `0x${ABI.soliditySHA3([
                'address', 'address', 'address', 'address', 'address', 'uint', 'uint'
            ],
            [
                new BN(connectorToken.address.replace('0x', ''), 16),
                new BN(token.address.replace('0x', ''), 16),
                new BN(connectorToken2.address.replace('0x', ''), 16),
                new BN(bancorProxy.address.replace('0x', ''), 16),
                new BN(userTwo.replace('0x', ''), 16),
                5,
                0
            ])
            .toString('hex')}`;
        const userOneSig = await web3.eth.sign(delegationHash, userOne);
        const userOneRaw = util.fromRpcSig(userOneSig);

        /**
         * User two performs a digital signature on the hash and their nonce
         */

        const userTwoHash = `0x${ABI.soliditySHA3(['bytes32', 'uint'],
            [new Buffer(delegationHash.replace('0x', ''), "hex"), 0]).toString('hex')}`;
        const userTwoSig = await web3.eth.sign(userTwoHash, userTwo);
        const userTwoRaw = util.fromRpcSig(userTwoSig);

        const userOneR = `0x${userOneRaw.r.toString('hex')}`, userOneS = `0x${userOneRaw.s.toString('hex')}`,
            userOneV = userOneRaw.v;
        const userTwoR = `0x${userTwoRaw.r.toString('hex')}`, userTwoS = `0x${userTwoRaw.s.toString('hex')}`,
            userTwoV = userTwoRaw.v;

        /**
         * Anyone can call delegate so long as they pass in both signatures and the original data that was hashed
         * This allows for a UserWallet to hold only tokens and for gas costs to be delegated to a third party
         */

        await wallet.delegate(
            [userOneV, userTwoV],
            [userOneR, userTwoR, userOneS, userTwoS],
            [userOne, userTwo, bancorProxy.address, userTwo],
            [0, 0, 5],
            [connectorToken.address, token.address, connectorToken2.address],
            {gasPrice: 1}
        );

    });
});
