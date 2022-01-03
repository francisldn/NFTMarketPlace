import React,{useState} from 'react';
import Web3Modal from 'web3modal'
import {ethers} from 'ethers';

const Wallet = ({onClick, connect, user}) => {
    
    return (
        <div>
            <button onClick={() => onClick()}
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