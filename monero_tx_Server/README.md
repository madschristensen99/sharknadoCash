# Monero Transaction Verifier

A simple server that verifies Monero transactions without downloading the entire blockchain. It uses the Monero block explorer to verify transactions and returns the results in JSON format.

## Features

- Verify Monero transactions using transaction ID, transaction key, and destination address
- Works with both mainnet and stagenet transactions
- Returns detailed information including:
  - Transaction confirmation count
  - Verified amount
  - Transaction fee
  - Block height and timestamp
  - Output details

## Deployment Instructions for VPS

### Prerequisites

- Node.js (v14 or higher)
- npm

### Setup on VPS

1. Install dependencies:

```bash
npm install
```

2. Configure your environment variables:

Copy the example environment file:

```bash
cp .env.example .env
```

Edit the `.env` file with your server settings:

```bash
# Server configuration
PORT=3000

# Default network (mainnet or stagenet)
NETWORK=stagenet
```

3. Start the server:

```bash
node server.js
```

### Running as a Service (PM2)

For production use, it's recommended to use PM2 to keep the server running:

1. Install PM2 globally:

```bash
npm install -g pm2
```

2. Start the server with PM2:

```bash
pm2 start server.js --name monero-verifier
```

3. Configure PM2 to start on boot:

```bash
pm2 startup
pm2 save
```

## API Usage

### Verify a Transaction

```
GET /verify?txid=TRANSACTION_ID&key=TRANSACTION_KEY&address=DESTINATION_ADDRESS&network=stagenet
```

Parameters:
- `txid`: The transaction ID to verify
- `key`: The transaction key (tx_key)
- `address`: The destination address
- `network`: Either "mainnet" or "stagenet" (default is stagenet)

### Example Response

```json
{
  "success": true,
  "transaction": {
    "txid": "b96790e316edc38f5e280641229afdff19962d11037c6e3f62aea69596fc2d58",
    "block": "1872228",
    "timestamp": "2025-05-30 11:59:01",
    "age": "00:000:12:27:21",
    "fee": "0.000053060000",
    "confirmations": 463,
    "verified": true,
    "amount": "0.001000000000",
    "totalAmount": "0.001000000000",
    "outputs": [
      {
        "outputPublicKey": "00: 109f16e6bef466816af61cf93039b1932aec0ee7fa2b167b0cc4246a8ed20471",
        "amount": "0.001000000000",
        "match": true
      },
      {
        "outputPublicKey": "01: 319a39edf77801f083c286fc4ea7f931faf597ce009334574a6c3a6ffeb6f4c4",
        "amount": "change output",
        "match": false
      }
    ]
  }
}
```

## Maintenance

### Updating the Current Block Height

The server uses a hardcoded block height to calculate confirmations. For production use, you should update this value regularly.

Edit `server.js` and update the `currentBlockHeight` value:

```javascript
const currentBlockHeight = 1872691; // Update this value regularly
```

You could set up a cron job to update this value automatically by fetching the current block height from a reliable source.

## Security Considerations

- Set up HTTPS for secure communication
- Add rate limiting to prevent abuse
- Consider adding authentication for sensitive operations


## Notes

- The transaction key (TX_SECRET) is required to verify the exact amount sent to the destination address
- This tool works with stagenet and mainnet transactions
- No need to download the entire blockchain - verification happens through the block explorer
