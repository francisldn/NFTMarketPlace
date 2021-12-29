//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //address of marketplace for NFTs to interface
    address contractAddress;

    constructor(address marketplaceAddress) ERC721('Marvel', 'MARVEL') {
        contractAddress = marketplaceAddress;
    }

    // use memory to reduce gas usage
    function mintToken (string memory tokenURI) public returns(uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        // mint takes 2 argument - recipient and tokenId
        _mint(msg.sender, newItemId);
        // takes tokenId and URI 
        _setTokenURI(newItemId, tokenURI);
        // give the marketplace the approval to transact between users
        setApprovalForAll(contractAddress, true);
        // mint the token and set it for sale- return the id to do so
        return newItemId;
    }
}
