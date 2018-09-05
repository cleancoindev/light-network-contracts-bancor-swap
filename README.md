# Light Network

## Overview

Light Network is a multi-signature wallet available on both android and IOS (built in react-native ) that allows you to store tokens, swap them, and send them without the need to hold ethereum in the wallet.
In essence, you can "hodl" some tokens in a smart contract and then digitally sign messages to delegate the execution of the smart contract to another party (ERC 865).

When the contract is executed, it will optionally perform a swap for you using Bancor.

The main point is that you can swap tokens without holding ethereum.

## Testing

Run `npm install && npm start`

## Technical Overview
### UserWallet.sol
A 2 of 3 multi-signature wallet that holds ERC20 tokens.

The delegate function can be called by any party, so long two signers have authorized the action taking place via a digital signature.


```solidity 

/**
    r, s, and v correspond to the user's digital signatures
    addresses = {signerOne, signerTwo, destination, receiver}
    misc = {nonceOne, nonceTwo, amount}
    path = bancor quickConvert path
*/

function delegate
(
    uint8[2] v,
    bytes32[4] rs,
    address[4] addresses,
    uint256[3] misc,
    address[3] path
 )
```
UserWallet calls BancorProxy through IBancorProxy's interface.

### BancorProxy.sol

A proxy interface for uses Bancor's quickConvert functionality

```solidity
/**
    path: The quick convert path that the Bancor protocol follows to convert a token
    receiverAddress: Who will receive the tokens after they have been swapped
    executor: The user who will take a cut of the tokens after (or before) they have been swapped. TODO
    amount: The amount being swapped
*/

function transferToken(
    address[3] path,
    address receiverAddress,
    address executor,
    uint256 amount
)

```


```solidity
//convert the path to the correct parameter type
IERC20Token[] memory pathConverted = new IERC20Token[](path.length);

for (uint i = 0; i < path.length; i++) {
   pathConverted[i] = IERC20Token(path[i]);
}

//transfer the balances to this contract so that it can be converted
require(IERC20Token(path[0]).transferFrom(msg.sender, address(this), amount), "transferFrom msg.sender failed");
require(IERC20Token(path[0]).approve(address(bancor), amount), "approve to bancor failed");

//convert along the path specified
uint256 amountReceived = bancor.quickConvert(pathConverted, amount, 1);

//TODO: Pay executor a small fee for paying the user's gas costs

//send the converted amount to the desired receiver's address
require(IERC20Token(path[path.length - 1]).transfer(receiverAddress, amountReceived),
   "transfer back to receiverAddress failed"
);
```

### IBancorProxy.sol

An interface for BancorProxy

### Tests
#### UserWallet.js

In this test, we first setup a bancor converter between three tokens (two erc20s and a smart token).

```javascript
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
```

We then setup a multisignature wallet with three signers - users one, two, and three.
```javascript
wallet = await UserWallet.new([userOne, userTwo, userThree]);
```

After that, two out of the three signers perform a digital signature authorizing 5 tokens to be swapped and sent to userTwo.

Then a third party (in this case userZero) calls the wallet's delegate functionality:
```javascript
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

```
