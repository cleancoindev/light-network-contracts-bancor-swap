const UserWallet = artifacts.require("./UserWallet.sol");
const Main = artifacts.require("./Main.sol");
const Utils = artifacts.require('./Utils.sol');
const Owned = artifacts.require('./Owned.sol');
const Managed = artifacts.require('./Managed.sol');
const TokenHolder = artifacts.require('./TokenHolder.sol');
const ERC20Token = artifacts.require('./ERC20Token.sol');
const EtherToken = artifacts.require('./EtherToken.sol');
const SmartToken = artifacts.require('./SmartToken.sol');
const SmartTokenController = artifacts.require('./SmartTokenController.sol');
const BancorFormula = artifacts.require('./BancorFormula.sol');
const BancorGasPriceLimit = artifacts.require('./BancorGasPriceLimit.sol');
const BancorQuickConverter = artifacts.require('./BancorQuickConverter.sol');
const BancorConverterExtensions = artifacts.require('./BancorConverterExtensions.sol');
const BancorConverter = artifacts.require('./BancorConverter.sol');
const CrowdsaleController = artifacts.require('./CrowdsaleController.sol');


module.exports = async function (deployer, network, accounts) {
    if (network === 'test')
        return;
    await deployer.deploy(Utils);
    await deployer.deploy(Owned);
    await deployer.deploy(Managed);
    await deployer.deploy(TokenHolder);
    await deployer.deploy(ERC20Token, 'DummyToken', 'DUM', 0);
    await deployer.deploy(EtherToken);
    await deployer.deploy(SmartToken, 'Token1', 'TKN1', 2);
    await deployer.deploy(SmartTokenController, SmartToken.address);
    await deployer.deploy(BancorFormula);
    await deployer.deploy(BancorGasPriceLimit, '22000000000');
    await deployer.deploy(BancorQuickConverter);
    await deployer.deploy(BancorConverterExtensions, '0x125463', '0x145463', '0x125763');
    await deployer.deploy(BancorConverter, SmartToken.address, '0x124', 0, '0x0', 0);
    await deployer.deploy(Main, BancorConverter.address, {from: accounts[0]});
    await deployer.deploy(UserWallet, [accounts[0], accounts[1], accounts[2]], {from: accounts[0]});
};
