const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("Should mint and trade NFTs", async function () {
    const Market = await ethers.getContractFactory('NFTMarket')
    const market = await Market.deploy()
    await market.deployed()
    const marketAddress= market.address
    
    const NFT = await ethers.getContractFactory('NFT')
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address

    let listingPrice= await market.getListingPrice()
    listingPrice = listingPrice.toString()

    const auctionPrice = ethers.utils.parseUnits('100', 'ether')

    // mint new NFT from NFT contract
    await nft.mintToken('https-t1')
    await nft.mintToken('https-t2')

    // list newly minted NFTs 
    await market.listMarketItem(nftContractAddress,1, auctionPrice, {value: listingPrice});
    await market.listMarketItem(nftContractAddress, 2, auctionPrice, {value: listingPrice});

    // get an array of addresses for testing
    const [_, buyerAddress] = await ethers.getSigners();

    // create a market sale with address, id and price
    await market.connect(buyerAddress).createMarketSale(nftContractAddress, 1, {
      value: auctionPrice
    })
  
    let unsoldItems = await market.fetchUnsoldNFT()

    unsoldItems = await Promise.all(unsoldItems.map(async i => {
      const tokenUri = await nft.tokenURI(i.tokenId)
      let item = {
        price: ethers.utils.formatUnits(i.price.toString(),"ether") + " ether",
        tokenId: i.tokenId.toString(),
        seller: i.seller,
        owner: i.owner,
        tokenUri
      }
      return item;
    }))

    console.log('UnsoldItems', unsoldItems)
  });

});
