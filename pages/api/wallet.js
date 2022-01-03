import React,{useState} from 'react';
import Web3Modal from 'web3modal'
import {ethers} from 'ethers';

const Wallet = () => {
    const [user, setUser] = useState();
    const [chainName, setChainName] = useState();
    const [connect, setConnect] = useState('Connect Wallet');

    const onClick = async () => {
        // to load provider, tokenContract, marketContract, data for marketItems
        const web3Modal = new Web3Modal();
        const connection = await web3Modal.connect()
        const provider = new ethers.providers.Web3Provider(connection)
        const signer = provider.getSigner()
        const address = await signer.getAddress();
        console.log(address)
        setUser(address);
        // get Chain Id
        const chain = await provider.getNetwork().then(network => network.name);
        setChainName(chain);
        setConnect('Connected');

    }

    return (
        <div>
            <button onClick={onClick}
            className='font-bold bg-purple-500 text-white rounded p-2 shadow-lg absolute top-4 right-2'>
                {connect}
            </button>
                <div>
                {user? (<span className='absolute right-px p-3 w-1/5 text-white truncate'>
                            {user}
                        </span>) : 
                        ""
                }
                </div>
        </div>
    )
}

export default Wallet;