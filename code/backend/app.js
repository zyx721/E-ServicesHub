// var for express
const express = require('express');
// create express app
const app = express();
// desired port 
const port = 3000;

// path for api endpoint ( with frontend (flitter) )
app.get('/api/data', (req, res)=>{
    res.json({
        success: true,
        message: 'connected to Node.js from flutter'
    });
    // res.send('hello world');
})

// test to connect to the port 
app.listen(port,()=>{
    console.log(`successfully connected to ${port}`)
});