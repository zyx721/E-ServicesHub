// firebaseAdmin.js
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-adminsdk-key.json'); // Update the path

// Initialize the Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Ensure that 'db' is properly initialized as Firestore instance
const db = admin.firestore();

// Export db for use in other files
module.exports = { admin, db }; 