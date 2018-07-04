# Light Network

## Overview

Light Network a wallet available on both android and IOS (built in react-native ) that allows you to store tokens, swap them, and send them without the need to hold ethereum in the wallet.
In essence, you can "hodl" some tokens in a smart contract and then digitally sign messages to delegate the execution of the smart contract to another party (ERC 865).

When the contract is executed, it will optionally perform a swap for you using Bancor.

The main point is that you can swap tokens without holding ethereum.

## Testing

Run `npm install && npm test` with ganache on port 7545 (configurable in truffle.js)
