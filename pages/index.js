import {ethers} from 'ethers';
import {useEffect, useState} from 'react';
import axios from 'axios';
import Web3Modal from 'web3modal'
import {nftaddress, nftmarketaddress} from '../config.js'
import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import NFTMarket from '../artifacts/contracts/NFTMarket.sol/NFTMarket.json'
import {ErrorBoundary} from 'react-error-boundary';

export default function Home(props) {
  const [nft, setNFT]= useState([])
  const [loadingState, setLoadingState] = useState('not-loaded')

  useEffect(async () => {
    if(typeof props.user !== 'undefined') {await loadNFTdata()}
    console.log(props.user)
  },[props])

  // function to display minted but unsold NFTs
  async function loadNFTdata() {
    // to load provider, tokenContract, marketContract, data for marketItems
    const web3Modal = new Web3Modal();
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)
    // get Chain Id
    const chainId = await provider.getNetwork().then(network => network.chainId);
    if( chainId !== 4) {
      window.alert("Please connect to the Rinkeby network");
      return;
    }
    const tokenContract = new ethers.Contract(nftaddress, NFT.abi, provider)
    const marketContract = new ethers.Contract(nftmarketaddress, NFTMarket.abi, provider)
    const data = await marketContract.fetchUnsoldNFT()
    // get token data of listed tokens
    const items = await Promise.all(data.map(async i => {
      // tokenUri is a json format containing metadata - image, description, characteristics
      const tokenUri = await tokenContract.tokenURI(i.tokenId)
      let item;
      try{
        const meta = await axios.get(tokenUri)
        let price = ethers.utils.formatUnits(i.price.toString(), 'ether')
        item = {
          price, 
          tokenId: i.tokenId.toNumber(),
          seller: i.seller,
          owner: i.owner,
          image: meta.data.image,
          name: meta.data.name,
          description: meta.data.description
          }
          return item;
        } catch(err) {
          item = ''
          console.log('IPFS request failed', err)
        }
      }))
    console.log(items)
    setNFT(items)
    setLoadingState('loaded')
    
  }
  
  //function for user to buy nft
  async function buyNFT(nft) {
    const web3Modal = new Web3Modal()
    const connection = await web3Modal.connect()
    const provider = new ethers.providers.Web3Provider(connection)
    const signer = provider.getSigner()
    const contract = new ethers.Contract(nftmarketaddress, NFTMarket.abi, signer)

    const price = ethers.utils.parseUnits(nft.price.toString(), 'ether')
    const transaction= await contract.createMarketSale(nftaddress, nft.tokenId, {
      value: price
    })
    await transaction.wait()
    loadNFTdata()
  
  }


  if(loadingState === 'loaded' && !nft.length) {
    return (
    <h1 className='px-20 py-7 text-4x1'>No NFTs in the Marketplace</h1>)
    }

  return (
    <ErrorBoundary>
    <div className='flex justify-center'>
       <div className='px-4' style={{maxWidth: '160px'}}></div>
       <div className= 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4'>
         {
           nft.map((nft,i) => (
            <div key ={i} className='border shadow rounded-x1 overflow-hidden'>
              <img src={nft.image}/>
              <div className='p-4'>
                <p style={{height: '64px'}} className='text-3x1 font-semibold'>
                  {nft.name}
                </p>
                <div style={{height:'72px', overflow: 'hidden'}}>
                  <p className='text-gray-400'>{nft.description}</p>
                </div>
              </div>
                <div className='p-4 bg-black'>
                  <p className='text-3x-1 mb-4 font-bold text-white'>{nft.price} ETH</p>
                  <button className='w-full bg-purple-500 text-white font-bold py-3 px-12 rounded' 
                  onClick={() => buyNFT(nft)}>
                    buy
                  </button>
              </div>
            </div>
           ))
         }
       </div>
    </div>
    </ErrorBoundary>
  )
}
