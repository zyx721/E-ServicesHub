// controllers/authController.js
const admin = require("../config/firebaseConfig");

exports.signup = async (req, res) => {
  const { email, password } = req.body;
  try {
    const userRecord = await admin.auth().createUser({ email, password });
    res.status(201).json({ message: "User signed up successfully", userRecord });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.login = async (req, res) => {
  const { email } = req.body;
  try {
    const user = await admin.auth().getUserByEmail(email);
    const customToken = await admin.auth().createCustomToken(user.uid);
    res.status(200).json({ token: customToken });
  } catch (error) {
    res.status(400).json({ error: "Authentication failed" });
  }
};
