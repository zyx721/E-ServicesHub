const express = require('express');
const bodyParser = require('body-parser');
const { admin, db } = require('./config/firebaseAdmin');  // Ensure correct import


const app = express();
const port = 3000;

app.use(bodyParser.json());

app.post('/signup', async (req, res) => {
  const { name, email, password, phone } = req.body;

  // Validate required fields
  if (!name || !email || !password || !phone) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  
  try {
    // Firestore add operation
    const usersCollection = db.collection('users'); // name Collection
    const newUserRef = await usersCollection.add({
      name,
      email,
      password,
      phone,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({
      success: true,
      userId: newUserRef.id,
      message: 'User created successfully',
    });
  } catch (error) {
    console.error('Error adding user to Firestore:', error);
    res.status(500).json({ error: 'Failed to create user', details: error.message });
  }
});

app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});
