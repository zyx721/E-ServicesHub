const express = require('express');
const nodemailer = require('nodemailer');
const router = express.Router();
const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email); // Helper function: Validate email format
const { admin, db } = require('../config/firebaseAdmin'); // Firebase Admin SDK


/**
 * Forget Password route
 * Generates a password reset email using Firebase Auth
 */
router.post('/forget-password', async (req, res) => {
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
  
  
  module.exports = router;