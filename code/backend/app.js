const express = require("express");
const bodyParser = require("body-parser");
const admin = require("./config/firebaseConfig");

const app = express();
app.use(bodyParser.json());

// Sign-Up Route
app.post("/signup", async (req, res) => {
  const { email, password } = req.body;

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
    });
    res.status(201).json({ message: "User signed up successfully", userRecord });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Login Route
app.post("/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    // Verify email and password using Firebase
    const user = await admin.auth().getUserByEmail(email);
    const customToken = await admin.auth().createCustomToken(user.uid);

    // Send back a custom token that can be used by the client to authenticate
    res.status(200).json({ token: customToken });
  } catch (error) {
    res.status(400).json({ error: "Authentication failed" });
  }
});

app.get("/check-connection", async (req, res) => {
  try {
    const users = await admin.auth().listUsers(100); // List up to 100 users
    res.status(200).json({
      message: "Firebase connection successful",
      userCount: users.users.length,
      users: users.users.length > 0 ? users.users : "No users found",
    });
  } catch (error) {
    res.status(500).json({
      error: "Failed to connect to Firebase",
      details: error.message,
    });
  }
});

// Start server and check Firebase connection
const PORT = process.env.PORT || 3000;
app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  
  try {
    // Attempt to list users to verify Firebase connection
    const users = await admin.auth().listUsers(1); // List a single user to confirm connection
    console.log("Connected to Firebase successfully. User count:", users.users.length);
  } catch (error) {
    console.error("Failed to connect to Firebase:", error.message);
  }
});
