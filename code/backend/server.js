const express = require('express');
const cors = require('cors'); // Added CORS
const bodyParser = require('body-parser');
const signupRouter = require('./controllers/signup');
const loginRouter = require('./controllers/login');
const verifyGoogleRouter = require('./controllers/verifyGoogle');
const forgotPassword = require('./controllers/forgotPassword');

const app = express();
const port = 3000;


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


// Middleware to parse JSON requests
app.use(cors());
app.use(bodyParser.json());

// Routes
app.use(signupRouter);
app.use(loginRouter);
app.use(verifyGoogleRouter);
app.use(forgotPassword);


// // Start server
app.listen(port, () => {
  console.log(`Server running on http://localhost:${port}`);
});

