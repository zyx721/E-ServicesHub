const express = require('express');
const { admin, db } = require('../config/firebaseAdmin'); // Firebase Admin SDK
const router = express.Router();
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client("733920147635-oo5ntbeokk91snik5hjkrojr9v0l715i.apps.googleusercontent.com");


/**
 * Signup With google route
 */
router.post('/verify-google-token', async (req, res) => {
  const { idToken } = req.body;

  if (!idToken) {
    return res.status(400).json({ error: 'ID token is required' });
  }

  try {
    // Verify Google ID Token
    const ticket = await client.verifyIdToken({
      idToken,
      audience: "733920147635-oo5ntbeokk91snik5hjkrojr9v0l715i.apps.googleusercontent.com", //your Web Client ID
    });
    
    const user = ticket.getPayload();
    const email = user['email'];
    const googleUid = user['sub'];

    // Create or update user in Firebase Authentication
    const userRecord = await admin.auth().getUserByEmail(email).catch(async (error) => {
  if (error.code === 'auth/user-not-found') {
    // User doesn't exist, create a new user
    return await admin.auth().createUser({
      email: email,
      providerData: 'google.com'
    });
  }
  throw error; // Other errors
});


// Save user to Firestore or proceed as necessary
const userRef = db.collection('users').doc(userRecord.uid);
await db.runTransaction(async (transaction) => {
  const userDoc = await transaction.get(userRef);
  if (!userDoc.exists) {
    transaction.set(userRef, {
      email: user.email,
      name: user.name,
      photoUrl: user.picture,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});

    // Return success response with the user's Firebase ID token
    const firebaseToken = await admin.auth().createCustomToken(userRecord.uid);

    return res.status(200).json({
      success: true,
      message: 'Google authentication successful',
      userId: userRecord.uid,
      token: firebaseToken,
    });
  } catch (error) {
    console.error('Error verifying Google token:', error.message);
    return res.status(500).json({ error: 'Failed to verify token', details: error.message });
  }
});

module.exports = router;