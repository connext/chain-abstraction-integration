# Chain Abstraction Integration

Contracts for Chain Abstraction integration

# Setting up environment

### 1. Node.js environment - Prerequisite

You can `skip` this step if you are using node.js version `>=16.0`
command to check your node.js version

```
node -v
```

- `Installing Node.js`: https://hardhat.org/tutorial/setting-up-the-environment#installing-node.js
- `Upgrading your Node.js installation`: https://hardhat.org/tutorial/setting-up-the-environment#upgrading-your-node.js-installation

### 2. Foundry - Prerequisite

Command to check if foundry is already installed in your system - 

```
forge --version
```

- `Installing foundry`: https://book.getfoundry.sh/getting-started/installation

### 3. Install Dependencies - Prerequisite


- Adding all the dependency - 
```
yarn
```
- To install the modpacks - 
```
forge install
```
- To build -
```
forge build
```

### Running the tests - 

Try following command to run the contarct tests - 
```
yarn run test
```
or 
```
forge test --via-ir
```

# Reference

- https://hardhat.org/tutorial/setting-up-the-environment
