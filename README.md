# NFT Marketplace
## About
This DApp is an NFT marketplace which allows users to mint, list, buy and sell NFTs. Users can fill in a simple form containing the metadata of the NFT such as name, description, price and uploading the image file. 

There are 2 contracts: 
* NFT - allows user to mint his/her own token
* NFTMarketplace - allows user to list, buy and sell tokens

## Dependencies
To run the DApp in a local environment, the following dependencies are required:
* Node v14.15.0
  * download Node: https://nodejs.org/en/download/
* Hardhat
  * ``npx hardhat``
  * ``npm install --save-dev @nomiclabs/hardhat-waffle ethereum-waffle chai @nomiclabs/hardhat-ethers ethers``
* Openzeppelin contracts and libraries: ``npm i @openzeppelin/contracts``
* Front end 
  * React - NextJS: ``npx create-next-app YOUR_APP``
* Web3modal/Ethers
  * Ethers: ``npm i --save ethers``
  * Web3modal: ``npm i --save web3modal`` 
* Utils
  * .env file: ``npm i dotenv``

## Frontend
#### Web interface
* Go to: https://nft-marketplace-lac.vercel.app/
#### Localhost
* Run ``npm run dev`` and the app will run on ``http://localhost:3000``

