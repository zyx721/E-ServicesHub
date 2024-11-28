const express = require('express');
const { admin, db } = require('../config/firebaseAdmin'); // Firebase Admin SDK
const bcrypt = require('bcrypt');
const router = express.Router();


/**
 * Login route
 */
router.post('/login', async (req, res) => {
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

  module.exports = router;