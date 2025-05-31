const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('pls work');
});

app.get('/api/zkproof/getProof', (req, res) => {
    const { txid, key, address } = req.query;

    console.log(txid, key, address);
  res.send('pls work');
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

