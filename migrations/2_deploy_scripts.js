const UserWallet = artifacts.require("./UserWallet.sol");
const Main = artifacts.require("./Main.sol");

module.exports = async function (deployer, network, accounts) {
    if (network === 'live') {
        await deployer.deploy(Main, "0xa3a89db39f4Cbfb8753259456332Ce8373Ff5bAd", {from: accounts[0]});
        await deployer.deploy(UserWallet, [accounts[0], accounts[0], accounts[0]], {from: accounts[0]});
    }
};
