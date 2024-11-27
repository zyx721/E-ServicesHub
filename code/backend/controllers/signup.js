const express = require('express');
const { admin, db } = require('../config/firebaseAdmin'); // Firebase Admin SDK
const router = express.Router();
const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email); // Helper function: Validate email format


/**
 * Signup route
 * Creates a Firebase Auth user and stores additional details in Firestore
 */
router.post('/signup', async (req, res) => {
    const { name, email, password} = req.body;
  
    // Validate input fields
    if (!name || !email || !password ) {
      return res.status(400).json({ error: 'All fields are required' });
    }
  
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
  
    try {
      // Hash password
      // const saltRounds = 10;
      // const hashedPassword = await bcrypt.hash(password, saltRounds);
  
      // Create Firebase Auth user
      const userRecord = await admin.auth().createUser({ email, password });
  
      // Save additional details in Firestore
      await db.collection('users').doc(userRecord.uid).set({
        name,
        email,
        // password:hashedPassword ,
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

  module.exports = router;