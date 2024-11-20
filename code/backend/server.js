const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors'); // Add CORS if needed
const bcrypt = require('bcrypt');
const { admin, db } = require('./config/firebaseAdmin'); // Firebase Admin SDK
require('dotenv').config(); // Use dotenv for environment variables

const app = express();
const port = 3000;

// Middleware to parse JSON requests
app.use(bodyParser.json());
app.use(cors());

// Helper function: Validate email format
const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

/**
 * Signup route
 * Creates a Firebase Auth user and stores additional details in Firestore
 */
app.post('/signup', async (req, res) => {
  const { name, email, password, phone } = req.body;

  // Validate input fields
  if (!name || !email || !password || !phone) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }

  try {
    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create Firebase Auth user
    const userRecord = await admin.auth().createUser({ email, password });

    // Save additional details in Firestore
    await db.collection('users').doc(userRecord.uid).set({
      name,
      email,
      phone,
      password: hashedPassword,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(201).json({
      success: true,
      message: 'User signed up successfully',
      userId: userRecord.uid,
    });
  } catch (error) {
    console.error('Signup error:', error.message);

    // Specific Firebase error handling
    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({ error: 'Email is already in use' });
    }
    return res.status(500).json({ error: 'Failed to sign up', details: error.message });
  }
});

/**
 * Login route
 */
app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }

  try {
    // Retrieve user by email
    const user = await admin.auth().getUserByEmail(email);

    // Fetch user details from Firestore
    const userDoc = await db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      return res.status(404).json({ error: 'User not found' });
    }

    const userData = userDoc.data();

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, userData.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate a custom token
    const customToken = await admin.auth().createCustomToken(user.uid);

    return res.status(200).json({
      success: true,
      token: customToken,
      message: 'Login successful',
    });
  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(500).json({ error: 'Login failed', details: error.message });
  }
});

/**
 * Check connection route
 */
app.get('/check-connection', async (req, res) => {
  try {
    const users = await admin.auth().listUsers(100);
    return res.status(200).json({
      message: 'Firebase connection successful',
      userCount: users.users.length,
      users: users.users.map((user) => user.email),
    });
  } catch (error) {
    console.error('Connection check error:', error.message);
    return res.status(500).json({
      error: 'Failed to connect to Firebase',
      details: error.message,
    });
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
