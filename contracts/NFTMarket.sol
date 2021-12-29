//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
// security against transactions for multiple requests
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import 'hardhat/console.sol';

contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;

    // keep track of tokens total number - tokenId
    Counters.Counter private _tokenIds;
    // keept track of tokens that have been sold
    Counters.Counter private _tokenSold;

    address payable owner;

    uint256 listingPrice = 0.045 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    // create a struct which can act like an object
    struct MarketToken {
        uint256 itemId;
        address nftContract; //contract address
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //tokenId mapped to MarketToken struct
    mapping(uint256 => MarketToken) private idToMarketToken;

    // events
    // itemId - index of token in the market place, tokenId - index of token from the original 721 contract
    event MarketTokenMinted(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /* @notice create a market item to put it up for sale
    *  
    */
    function listMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
    public payable nonReentrant {
        require(price>0, "Price must be at least one wei");
        require(msg.value == listingPrice, "Price must be equal to listing price");
        _tokenIds.increment();

        uint256 itemId = _tokenIds.current();
        
        //putting up item for sale
        idToMarketToken[itemId] = MarketToken(
            itemId, 
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        //transfer token to the buyer
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketTokenMinted(
            itemId, 
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    // function to conduct transactions and market sale
    function createMarketSale(
        address nftContract,
        uint256 itemId
        )
        public payable nonReentrant {
            uint256 price = idToMarketToken[itemId].price;
            uint256 tokenId = idToMarketToken[itemId].tokenId;
            require(msg.value == price, "Please submit the asking price in order to continue");
            idToMarketToken[itemId].seller.transfer(msg.value);
            // once sold, nft will transfer the token to the buyer
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketToken[itemId].owner= payable(msg.sender);
            idToMarketToken[itemId].sold= true;
            _tokenSold.increment();
            payable(owner).transfer(listingPrice);
        }

    
    // function to fetchMarketItems - unsold NFTs where address(0) is the owner
    // return the array of unsold items
    function fetchUnsoldNFT() public view returns(MarketToken[] memory) {
        uint256 itemCount = _tokenIds.current();
        // tokenSold keeps track of the number of items sold (using Counters)
        uint256 unsoldItemCount = _tokenIds.current() - _tokenSold.current();
        uint256 currentIndex = 0;

        MarketToken[] memory items = new MarketToken[](unsoldItemCount);
        // Loop through the MarketTokens and identify unsold items
        for(uint256 i = 0; i < itemCount ; i++) {
            if(idToMarketToken[i+1].owner == address(0)) {
                uint256 currentId = i+1;
                // create MarketToken to keep track of unsold items and return unsold items array
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
    
    // fetch NFTs that have been purchased by the user and return array of owned NFTs by the user
    function fetchMyNFT() public view returns (MarketToken[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        //a second counter for items sold
        uint256 ownedItemCount = 0;
        uint256 currentIndex = 0;
        // Loop through the MarketTokens and identify the number of NFTs owned by the user (itemCount)
        for(uint256 i = 0; i< totalItemCount; i++) {
            if(idToMarketToken[i+1].owner == msg.sender) {
                ownedItemCount +=1;
            }
        }
        // use the itemCount to initialise an array of sold item 
        MarketToken[] memory items = new MarketToken[](ownedItemCount);
        for (uint256 i =0; i < ownedItemCount; i++) {
            if(idToMarketToken[i+1].owner == msg.sender) {
                uint256 currentId = idToMarketToken[i+1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                // store the sold items in a new items array
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // function for return an array of listed/minted NFT by the seller
    function fetchListedNFT() public view returns(MarketToken[] memory) {
        //similar to the previous - but would be .seller
        uint256 totalItemCount = _tokenIds.current();
        //a second counter for items listed by the seller
        uint256 listedItemCount = 0;
        uint256 currentIndex = 0;
        // Loop through the MarketTokens and identify the number of NFTs listed/minted by the user (itemCount)
        for(uint256 i = 0; i< totalItemCount; i++) {
            if(idToMarketToken[i+1].seller == msg.sender) {
                listedItemCount +=1;
            }
        }
        // use the itemCount to initialise an array of minted NFT by the seller 
        MarketToken[] memory items = new MarketToken[](listedItemCount);
        for (uint256 i =0; i < listedItemCount; i++) {
            if(idToMarketToken[i+1].seller == msg.sender) {
                uint256 currentId = idToMarketToken[i+1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                // store the listed items in a new items array
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } 
        }
        return items;
    }



}
