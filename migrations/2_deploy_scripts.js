const UserWallet = artifacts.require("./UserWallet.sol");
const Main = artifacts.require("./Main.sol");

module.exports = function(deployer, network, accounts) {
  if(network === 'development')
    return;
  deployer.deploy(Main, {from: accounts[0]});
  deployer.deploy(UserWallet, [accounts[0], accounts[1], accounts[2]], {from: accounts[0]});
};
