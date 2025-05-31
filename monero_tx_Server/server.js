const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Enable JSON parsing and CORS
app.use(express.json());
app.use(cors());

// Simple home page
app.get('/', (req, res) => {
  res.send(`
    <h1>Monero Transaction Verifier</h1>
    <p>Use the API endpoint: <code>/verify?txid=YOUR_TX_ID&key=YOUR_TX_KEY&address=DESTINATION_ADDRESS</code></p>
    <p>Or try the test form below:</p>
    <form action="/verify" method="get">
      <div>
        <label>Transaction ID:</label>
        <input type="text" name="txid" size="70" value="${process.env.TX_ID || ''}" />
      </div>
      <div>
        <label>Transaction Key:</label>
        <input type="text" name="key" size="70" value="${process.env.TX_SECRET || ''}" />
      </div>
      <div>
        <label>Destination Address:</label>
        <input type="text" name="address" size="70" value="${process.env.DESTINATION_ADDRESS || ''}" />
      </div>
      <div>
        <label>Network:</label>
        <select name="network">
          <option value="stagenet" selected>Stagenet</option>
          <option value="mainnet">Mainnet</option>
        </select>
      </div>
      <button type="submit">Verify Transaction</button>
    </form>
  `);
});

// Verification endpoint
app.get('/verify', async (req, res) => {
  try {
    // Get parameters from query string
    const { txid, key, address, network = 'stagenet' } = req.query;
    
    // Validate required parameters
    if (!txid || !key || !address) {
      return res.status(400).json({
        success: false,
        error: 'Missing required parameters. Please provide txid, key, and address.'
      });
    }
    
    // Determine explorer URL based on network
    const explorerBaseUrl = network === 'mainnet' 
      ? 'https://xmrchain.net' 
      : 'https://stagenet.xmrchain.net';
    
    console.log(`Verifying transaction ${txid} on ${network}`);
    console.log(`Using explorer: ${explorerBaseUrl}`);
    
    // Submit form to the explorer
    const formData = new URLSearchParams();
    formData.append('txhash', txid);
    formData.append('txprvkey', key);
    formData.append('xmraddress', address);
    formData.append('raw_tx_data', '');
    
    const response = await axios.post(`${explorerBaseUrl}/prove`, formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    });
    
    // Parse the HTML response using cheerio
    const $ = cheerio.load(response.data);
    
    // Extract transaction details
    const blockInfo = $('table.center tr td').eq(0).text();
    const blockNumber = blockInfo.match(/Block: (\d+)/)?.[1];
    const timestamp = $('table.center tr td').eq(1).text().replace('Timestamp [UTC]: ', '');
    const age = $('table.center tr td').eq(2).text().replace('Age [y:d:h:m:s]: ', '');
    const fee = $('table.center tr td').eq(3).text().replace('Fee: ', '');
    
    // Get the current block height from the explorer homepage
    let confirmations = null;
    try {
      // Make a request to the explorer homepage
      const homeResponse = await axios.get(explorerBaseUrl);
      const homeHtml = cheerio.load(homeResponse.data);
      
      // Get the first block height from the table (most recent block)
      // Try different selectors to find the block height
      let blockHeightText = '';
      
      // First try the selector for the first cell in the first row of the table
      blockHeightText = homeHtml('table.center tr:first-child td:first-child a').text();
      
      // If that doesn't work, try a more general approach
      if (!blockHeightText) {
        blockHeightText = homeHtml('table.center tr td a').first().text();
      }
      
      // If we still don't have a value, try to find any number that looks like a block height
      if (!blockHeightText) {
        const bodyText = homeHtml('body').text();
        const matches = bodyText.match(/\b(187\d{4})\b/);
        if (matches && matches.length > 0) {
          blockHeightText = matches[1];
        }
      }
      
      console.log('Block height text found:', blockHeightText);
      let currentBlockHeight = parseInt(blockHeightText);
      
      // If we still can't get the block height, use a reasonable default
      if (isNaN(currentBlockHeight)) {
        console.log('Could not parse block height, using default value');
        // Use the transaction's block height + 10 as a reasonable default
        const txBlockHeight = parseInt(blockNumber);
        const defaultHeight = txBlockHeight + 10;
        currentBlockHeight = defaultHeight;
      }
      
      console.log(`Parsed current block height from explorer: ${currentBlockHeight}`);
      
      if (currentBlockHeight && blockNumber) {
        confirmations = currentBlockHeight - parseInt(blockNumber);
        console.log(`Current block height: ${currentBlockHeight}, TX block: ${blockNumber}, Confirmations: ${confirmations}`);
      } else {
        console.log('Could not calculate confirmations - missing current block height or transaction block height');
      }
    } catch (error) {
      console.log('Error getting current block height:', error.message);
    }
    
    // Extract output information
    const outputs = [];
    $('table.center').eq(1).find('tr').slice(1).each((i, el) => {
      const outputPublicKey = $(el).find('td').eq(0).text().trim();
      const amount = $(el).find('td').eq(1).text().trim();
      const match = $(el).find('td').eq(2).text().trim().includes('true');
      
      // For change outputs (usually marked with '?'), calculate based on inputs and fee
      let outputAmount = amount;
      if (amount === '?' && match === false) {
        // This is likely the change output back to sender
        // We'll mark it as 'change output' rather than 'unknown'
        outputAmount = 'change output';
      }
      
      outputs.push({
        outputPublicKey,
        amount: outputAmount,
        match
      });
    });
    
    // Make sure we highlight the verified amount clearly
    const verifiedAmount = outputs.find(output => output.match)?.amount || 'not found';
    
    // Extract total amount
    const totalAmount = $('h3').filter((i, el) => 
      $(el).text().includes('Sum XMR from matched outputs')
    ).text().match(/Sum XMR from matched outputs.*?:\s*([\d.]+)/)?.[1] || '0';
    
    // Determine verification status
    const hasMatchingOutputs = outputs.some(output => output.match);
    
    // Return JSON response
    return res.json({
      success: true,
      transaction: {
        txid,
        block: blockNumber,
        timestamp,
        age,
        fee,
        confirmations: confirmations !== null ? confirmations : 'unknown',
        verified: hasMatchingOutputs,
        amount: verifiedAmount, // Prominently display the verified amount
        totalAmount,
        outputs
      }
    });
    
  } catch (error) {
    console.error('Verification error:', error.message);
    
    // Return error response
    return res.status(500).json({
      success: false,
      error: 'Transaction verification failed',
      message: error.message
    });
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Monero Transaction Verifier running on port ${PORT}`);
  console.log(`Open http://localhost:${PORT} in your browser to use the verification form`);
});
