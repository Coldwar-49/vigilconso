const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

app.post('/send-email', async (req, res) => {
  const { to, subject, text, html } = req.body;
  if (!to || !subject) return res.status(400).json({ message: 'Champs requis manquants.' });
  try {
    const info = await transporter.sendMail({ from: process.env.FROM_EMAIL, to, subject, text, html });
    return res.status(200).json({ message: 'Email envoyé', id: info.messageId });
  } catch (error) {
    console.error('Erreur:', error.message);
    return res.status(500).json({ message: 'Erreur envoi email' });
  }
});

app.post('/newsletter', async (req, res) => {
  const { email } = req.body;
  if (!email || !isValidEmail(email)) return res.status(400).json({ message: 'Email invalide.' });
  try {
    await transporter.sendMail({
      from: `VigilConso <${process.env.FROM_EMAIL}>`,
      to: email,
      subject: 'Bienvenue sur VigilConso !',
      html: `<div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:24px;border:1px solid #e0e0e0;border-radius:12px;"><h2 style="color:#1976D2;">Inscription confirmee !</h2><p>Votre inscription a la newsletter VigilConso est confirmee. Vous recevrez les dernieres alertes de rappels directement dans votre boite mail.</p></div>`,
    });
    await transporter.sendMail({
      from: `VigilConso <${process.env.FROM_EMAIL}>`,
      to: process.env.FROM_EMAIL,
      subject: `Nouvelle inscription newsletter : ${email}`,
      text: `Nouvel abonne : ${email}\nDate : ${new Date().toLocaleString('fr-FR')}`,
    });
    return res.status(200).json({ message: 'Inscription reussie !' });
  } catch (error) {
    console.error('Erreur newsletter:', error.message);
    return res.status(500).json({ message: 'Erreur inscription. Reessayez.' });
  }
});

app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }));

const port = parseInt(process.env.PORT || '3000');
app.listen(port, () => console.log(`VigilConso API running on http://localhost:${port}`));
