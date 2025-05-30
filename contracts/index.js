const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

async function main() {
    const response = await fetch('https://localmonero.co/blocks/tx/250908a82e2ec72f20aab8072ab045c2bc1da531588a1a5b977052f3487d86a0?xmraddress=82Yy6ygohJZdungHrXovdDjdpAu31iGPsXTTZRnPYadgJ9735P8eBweHK5djgovYQhEqssjRaNZ4hhi1e3MyaS28T1X471g&txprvkey=60166f73264a77544b7aa287d45d82b91bba023358ffd00c227489dbc48d5809');

    const text = await response.text();

    const regex = /The address shown below has received the following amount in this transaction:\s*([\d.]+)\s*XMR/i;

    const match = text.match(regex);

    if (match && match[1]) {
        console.log("Extracted XMR amount:", match[1]);
    } else {
        console.log("Amount not found.");
    }
}


// GET endpoint to extract XMR amount from dynamic link
app.get('/xmr-amount', async (req, res) => {
    try {
        // Get the URL from query parameter
        const { url } = req.query;
        
        // Validate URL parameter
        if (!url) {
            return res.status(400).json({
                error: 'URL parameter is required',
                usage: 'GET /xmr-amount?url=YOUR_LOCALMONERO_URL'
            });
        }

        // Validate that it's a LocalMonero URL (basic security check)
        if (!url.includes('localmonero.co')) {
            return res.status(400).json({
                error: 'Invalid URL. Only LocalMonero URLs are supported.'
            });
        }

        // Fetch the page content
        const response = await fetch(url);
        
        if (!response.ok) {
            return res.status(response.status).json({
                error: Failed to fetch URL: ${response.status} ${response.statusText}
            });
        }

        const text = await response.text();
        
    const regex = /The address shown below has received the following amount in this transaction:\s*([\d.]+)\s*XMR/i;

    const match = text.match(regex);

    if (match && match[1]) {
        console.log("Extracted XMR amount:", match[1]);
        return res.json();
    } else {
        console.log("Amount not found.");
        return null;
    }

    } catch (error) {
        console.error('Error processing request:', error);
        res.status(500).json({
            error: 'Internal server error',
            message: error.message
        });
    }
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start the server
app.listen(PORT, () => {
    console.log(Server is running on port ${PORT});
    console.log(Usage: GET http://localhost:${PORT}/xmr-amount?url=YOUR_LOCALMONERO_URL);
});

module.exports = app;