const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors'); // Add CORS if needed
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
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
 * Forget Password route
 * Generates a password reset email using Firebase Auth
 */
app.post('/forget-password', async (req, res) => {
  const { email } = req.body;

  // Validate email field
  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  // Check if the email format is valid
  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'Invalid email format' });
  }

  try {
    // Generate a password reset link using Firebase Admin SDK
    const resetLink = await admin.auth().generatePasswordResetLink(email);

    // Send the reset link to the user's email using Nodemailer
    await sendPasswordResetEmail(email, resetLink);

    // Return success response
    return res.status(200).json({
      success: true,
      message: 'Password reset email sent successfully',
    });
  } catch (error) {
    console.error('Forget Password error:', error.message);

    // Specific Firebase error handling
    if (error.code === 'auth/user-not-found') {
      return res.status(404).json({ error: 'No user found for the provided email' });
    }

    // General error handling for other issues
    return res.status(500).json({
      error: 'Failed to send password reset email',
      details: error.message,
    });
  }
});


// Function to send the password reset link via email
const sendPasswordResetEmail = async (email, resetLink) => {
  // Create a Nodemailer transporter object
  const transporter = nodemailer.createTransport({
    service: 'gmail', // Change this if using another email service
    auth: {
      user: 'hanini.firebase@gmail.com', // Replace with your email
      pass: 'bxah jsut ugqb ezae',  // Replace with your email password (or app password if 2FA enabled)
    },
  });

  const mailOptions = {
    from: 'hanini.firebase@gmail.com', // Replace with your email
    to: email,
    subject: 'Password Reset Request',
    text: `Click the link below to reset your password:\n\n${resetLink}`,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Password reset email sent to: ${email}`);
  } catch (error) {
    console.error('Error sending password reset email:', error);
    throw new Error('Failed to send reset email');
  }
};

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
    // const saltRounds = 10;
    // const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create Firebase Auth user
    const userRecord = await admin.auth().createUser({ email, password });

    // Save additional details in Firestore
    await db.collection('users').doc(userRecord.uid).set({
      name,
      email,
      phone,
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

/**
 * Login route
 */
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
