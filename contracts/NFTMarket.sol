//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/** 
 * @title NFT Marketplace to list, buy and sell NFTs
 */
contract NFTMarket is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    // keep track of tokens total number - tokenId
    Counters.Counter private _tokenIds;
    // keept track of tokens that have been sold
    Counters.Counter private _tokenSold;

    uint256 private listingFee = 0.001 ether;

    constructor() {}

    // create a struct consisting of token details
    struct MarketToken {
        uint256 itemId;  //item id in the marketplace
        address nftContract; //contract address
        uint256 tokenId; // tokenId in an ERC721 contract
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //tokenId mapped to MarketToken struct
    mapping(uint256 => MarketToken) private idToMarketToken;

    // event emitted when a token is listed
    event MarketTokenListed(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /**
     * @notice function to set listing price; only contract owner is authorized;
     * @param _listingFee uint256 
     */
    function setListingFee(uint256 _listingFee) external onlyOwner {
        listingFee = _listingFee;
    }

    /**
     * @notice to get listing price for the marketplace
     */
    function getListingFee() external view returns (uint256) {
        return listingFee;
    }

    /** 
    * @notice function to provide for listing of NFT in the marketplace, seller will pay a listingFee in Eth
    * @dev ReentrancyGuard to prevent the risk of reentrancy
    * @param nftContract address of ERC721 contract
    * @param tokenId uint256 - tokenId of the item that is to be listed
    * @param price uint256 - price of the item
    */
    function listMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
    public payable nonReentrant {
        require(price>0, "INVALID_PRICE");
        require(msg.value == listingFee, "INCORRECT_PAYMENT_FOR_LISTING_FEE");
        _tokenIds.increment();

        uint256 itemId = _tokenIds.current();

        // update details of the token Struct
        idToMarketToken[itemId] = MarketToken(
            itemId, 
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        // transfer token from the tokenholder to this contract
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketTokenListed(
            itemId, 
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    /**
     * @notice function to provide for selling of NFTs and update token details
     * @param nftContract address
     * @param itemId uint256
     */
    function createMarketSale(
        address nftContract,
        uint256 itemId
        )
        public payable nonReentrant {
            uint256 price = idToMarketToken[itemId].price;
            uint256 tokenId = idToMarketToken[itemId].tokenId;
            // buyer pays the price of NFT to this contract
            require(msg.value == price, "INCORRECT_PAYMENT_AMOUNT");
            //transfer payment of NFT price to seller from this contract
            (bool success,) = idToMarketToken[itemId].seller.call{value: msg.value}("");
            require(success, "PAYMENT_FOR_NFT_FAILED");
            
            // transfer NFT from the marketplace contract to the buyer
            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketToken[itemId].owner= payable(msg.sender);
            idToMarketToken[itemId].sold= true;
            _tokenSold.increment();
        }

    
    /** 
     * @notice function to fetch unsold NFTs - identified through owner == address(0)
     * @return MarketToken - array of unsold items
     */ 
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
    
    /**
     * @notice function to fetch NFTs purchased by a tokenholder
     * @return MarketToken - array of purchased items
     */ 
    function fetchMyNFT() public view returns (MarketToken[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        //a second counter for items sold
        uint256 ownedItemCount = 0;
        uint256 currentIndex = 0;
        // Loop through the MarketTokens and identify the number of NFTs owned by the tokenholder (ownedItemCount)
        for(uint256 i = 0; i< totalItemCount; i++) {
            if(idToMarketToken[i+1].owner == msg.sender) {
                ownedItemCount +=1;
            }
        }
        // use ownedItemCount to initialize an array of purchased items
        MarketToken[] memory items = new MarketToken[](ownedItemCount);
        for (uint256 i =0; i < ownedItemCount; i++) {
            if(idToMarketToken[i+1].owner == msg.sender) {
                uint256 currentId = idToMarketToken[i+1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                // store the purchased items in items array
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /**
     * @notice function to fetch all NFTs listed (both sold and unsold) by a tokenholder
     * @return MarketToken - array of listed items
     */
    function fetchListedNFT() public view returns(MarketToken[] memory) {
        //similar to the previous - but would be .seller
        uint256 totalItemCount = _tokenIds.current();
        //a second counter for items listed by the seller
        uint256 listedItemCount = 0;
        uint256 currentIndex = 0;
        // Loop through the MarketTokens and identify the number of NFTs listed/minted by the user (listedItemCount)
        for(uint256 i = 0; i< totalItemCount; i++) {
            if(idToMarketToken[i+1].seller == msg.sender) {
                listedItemCount +=1;
            }
        }
        // use the listedItemCount to initialize an array of minted/listed tokens
        MarketToken[] memory items = new MarketToken[](listedItemCount);
        for (uint256 i =0; i < listedItemCount; i++) {
            if(idToMarketToken[i+1].seller == msg.sender) {
                uint256 currentId = idToMarketToken[i+1].itemId;
                MarketToken storage currentItem = idToMarketToken[currentId];
                // store the listed items in an array
                items[currentIndex] = currentItem;
                currentIndex += 1;
            } 
        }
        return items;
    }



}
