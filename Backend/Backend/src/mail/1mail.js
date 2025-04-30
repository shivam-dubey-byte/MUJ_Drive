const express = require('express');
const nodemailer = require('nodemailer');
const app = express();
const port = 3000;

// Middleware to parse JSON
app.use(express.json());

// Brevo SMTP configuration
const transporter = nodemailer.createTransport({
  host: 'smtp-relay.brevo.com', // Brevo SMTP server
  port: 587, // Port for TLS
  secure: false, // true for 465 (SSL), false for other ports
  auth: {
    user: '850fee001@smtp-brevo.com', // Your Brevo SMTP login
    pass: 'nUzmwcTGpCSv60O7', // Replace with your Brevo SMTP password
  },
});

// Route to send email
app.post('/send-email', async (req, res) => {
  const { to, subject, text } = req.body;

  try {
    // Send email
    const info = await transporter.sendMail({
      from: 'KnowledgeSun <dubeyshivam1911@gmail.com>', // Sender address
      to, // Recipient address
      subject, // Email subject
      text, // Plain text body
      // html: "<b>Hello world?</b>", // HTML body (optional)
    });

    console.log('Message sent: %s', info.messageId);
    res.status(200).json({ message: 'Email sent successfully!', info });
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({ error: 'Failed to send email' });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});