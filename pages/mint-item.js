import {ethers} from 'ethers';
import {useEffect, useState} from 'react';
import {create as ipfsHttpClient} from 'ipfs-http-client'
import Web3Modal from 'web3modal'
import {nftaddress, nftmarketaddress} from '../config.js'
import NFT from '../artifacts/contracts/NFT.sol/NFT.json'
import NFTMarket from '../artifacts/contracts/NFTMarket.sol/NFTMarket.json'
import {useRouter} from 'next/router'

// get this from infura IPFS site
const client = ipfsHttpClient('https://ipfs.infura.io:5001/api/v0')

export default function MintItem() {
    const [fileUrl, setFileUrl] = useState(null)
    const [formInput, updateFormInput] = useState({price:'',name:'', description:''})
    const router = useRouter()

    // grab image data from ipfs 
    async function onChange(e) {
        const file= e.target.files[0]
        try {
        const added = await client.add(
            file, {
                progress: (prog) => console.log(`received: ${prog}`)
            }
        )
        const url = `https://ipfs.infura.io/ipfs/${added.path}`
        setFileUrl(url)
        } catch (err) {
            console.log('Error uploading file', err)
        }
    }   
    
    // function to list an item that has been minted
    async function createMarket() {
        const {name, description, price} = formInput
        if(!name || !description || !price || !fileUrl) return

        const data = JSON.stringify({
            name, description, image: fileUrl
        })
        
        try {
            const added = await client.add(data)
            const url = `https://ipfs.infura.io/ipfs/${added.path}`
            createSale(url)
            } catch (err) {
                console.log('Error uploading file', err)
            }
    }

    //create the item through the form, mint token and list it on the marketplace
    async function createSale(url) {
        const web3Modal = new Web3Modal()
        const connection = await web3Modal.connect();
        const provider = new ethers.providers.Web3Provider(connection)
        const signer = provider.getSigner()
        
        let contract = new ethers.Contract(nftaddress, NFT.abi, signer)
        // call mintToken function
        let transaction = await contract.mintToken(url)
        // resolves to transactionReceipt
        let tx = await transaction.wait()
        console.log(tx)
        let event = tx.events[0]
        //get tokenId
        let tokenId= event.args[2]
        tokenId = tokenId.toNumber()
        const price = ethers.utils.parseUnits(formInput.price, 'ether')

        //list the item for sale on the marketplace
        contract = new ethers.Contract(nftmarketaddress, NFTMarket.abi, signer);
        let listingPrice = await contract.getListingPrice();
        listingPrice = listingPrice.toString();

        // list item
        transaction = await contract.listMarketItem(nftaddress, tokenId, price, {value: listingPrice})
        await transaction.wait()
        router.push('./')
    }

    return (
        <div className='flex justify-center'>
            <div className='w-1/2 flex flex-col pb-12'>
                <input
                placeholder = 'Asset Name'
                className='mt-8 border rounded p-4'
                onChange={e => updateFormInput({...formInput, name: e.target.value})}
                />
                <textarea
                placeholder = 'Asset Description'
                className='mt-2 border rounded p-4'
                onChange={e => updateFormInput({...formInput, description: e.target.value})}
                />
                <input
                placeholder = 'Asset Price in Eth'
                className='mt-2 border rounded p-4'
                onChange={e => updateFormInput({...formInput, price: e.target.value})}
                />
                <input
                type = 'file'
                name='Asset'
                className = 'mt-2 border rounded p-2'
                onChange={onChange}
                /> {
                fileUrl && (
                    <img className='rounded mt-4' width='350px' src={fileUrl} />
                )}
                <button onClick={() => createMarket()}
                className='font-bold mt-4 bg-purple-500 text-white rounded p-4 shadow-lg'>
                    Mint NFT
                </button>
            </div>

        </div>
    )

}