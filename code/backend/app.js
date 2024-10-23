const express = require('express');
const cors = require('cors');  // Import CORS

const app = express();
const port = 3000;

// Use CORS middleware
app.use(cors());

app.get('/api/data', (req, res) => {
    res.json({
        success: true,
        message: 'Connected to Node.js from Flutter Web'
    });
});

app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});