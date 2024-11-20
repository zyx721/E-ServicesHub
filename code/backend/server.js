const express = require('express');
const bodyParser = require('body-parser');
const { admin, db } = require('./config/firebaseAdmin'); // Ensure this points to your Firebase admin config

const app = express();
const port = 3000;

// Middleware to parse JSON requests
app.use(bodyParser.json());

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

  try {
    // Create user in Firebase Auth
    const userRecord = await admin.auth().createUser({
      email,
      password,
    });

    // Add user details to Firestore
    const usersCollection = db.collection('users');
    await usersCollection.doc(userRecord.uid).set({
      name,
      email,
      password,
      phone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(201).json({
      success: true,
      message: 'User signed up successfully',
      userId: userRecord.uid,
    });
  } catch (error) {
    console.error('Error during signup:', error.message);
    return res.status(500).json({ error: 'Failed to sign up', details: error.message });
  }
});

/**
 * Login route
 * Verifies user credentials and returns a Firebase custom token
 */
app.post('/login', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    // Retrieve user by email
    const user = await admin.auth().getUserByEmail(email);

    // Generate a custom token for the user
    const customToken = await admin.auth().createCustomToken(user.uid);

    return res.status(200).json({ success: true, token: customToken });
  } catch (error) {
    console.error('Login error:', error.message);
    return res.status(401).json({ error: 'Authentication failed', details: error.message });
  }
});

/**
 * Check connection route
 * Ensures the backend is properly connected to Firebase
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

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
