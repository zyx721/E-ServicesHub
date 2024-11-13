// npm install firebase-admin
const admin = require('firebase-admin');
const serviceAccount = require('./config/serviceAccountKey.json');  // Replace with your file path

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Initialize Firestore
const db = admin.firestore();

// Example: Save a document to Firestore
const saveToFirestore = async () => {
  try {
    const docRef = db.collection('users').doc('user_id');
    await docRef.set({
      name: 'John Doe',
      email: 'john.doe@example.com',
      age: 30,
    });
    console.log('Document written successfully');
  } catch (error) {
    console.error('Error writing document: ', error);
  }
};

saveToFirestore();
