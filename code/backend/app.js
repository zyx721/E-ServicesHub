// app.js
const express = require('express');
const cors = require('cors');
const connectDB = require('./config/db');
const authRoutes = require('./routes/auth');
require('dotenv').config();

const app = express();
app.use(cors()); // Enable CORS
app.use(express.json());
connectDB();

app.use('/api/auth', authRoutes);

module.exports = app;
