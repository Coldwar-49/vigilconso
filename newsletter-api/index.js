const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const cron = require('node-cron');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// ── Configuration ──────────────────────────────────────────────────
const SUBSCRIBERS_FILE = path.join(__dirname, 'subscribers.json');
const APP_URL = process.env.APP_URL || 'http://localhost:8080';
const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

// ── Gestion des abonnés (fichier JSON local) ───────────────────────
function loadSubscribers() {
  try {
    if (!fs.existsSync(SUBSCRIBERS_FILE)) return [];
    return JSON.parse(fs.readFileSync(SUBSCRIBERS_FILE, 'utf8'));
  } catch {
    return [];
  }
}

function saveSubscribers(list) {
  fs.writeFileSync(SUBSCRIBERS_FILE, JSON.stringify(list, null, 2));
}

// ── Transport SMTP ─────────────────────────────────────────────────
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// ── Template HTML commun ───────────────────────────────────────────
function wrapEmail(title, content) {
  return `<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin:0;padding:0;background:#f5f5f5;font-family:Arial,sans-serif;">
  <div style="max-width:600px;margin:24px auto;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.1);">

    <!-- Header rouge VigilConso -->
    <div style="background:#CC1421;padding:28px 24px;text-align:center;">
      <h1 style="color:#ffffff;margin:0;font-size:26px;letter-spacing:1px;">⚠️ VigilConso</h1>
      <p style="color:#ffcdd2;margin:6px 0 0;font-size:14px;">Alertes rappels de produits</p>
    </div>

    <!-- Contenu -->
    <div style="padding:28px 24px;">
      <h2 style="color:#CC1421;margin-top:0;">${title}</h2>
      ${content}
    </div>

    <!-- Bouton principal -->
    <div style="padding:0 24px 24px;text-align:center;">
      <a href="${APP_URL}"
         style="display:inline-block;background:#CC1421;color:#ffffff;text-decoration:none;
                padding:14px 32px;border-radius:28px;font-weight:bold;font-size:15px;">
        Ouvrir VigilConso
      </a>
    </div>

    <!-- Footer -->
    <div style="background:#f9f9f9;padding:16px 24px;text-align:center;border-top:1px solid #eeeeee;">
      <p style="color:#aaa;font-size:12px;margin:0;">
        Vous recevez cet email car vous êtes abonné(e) aux alertes VigilConso.<br>
        <a href="${APP_URL}" style="color:#CC1421;">Visiter l'application</a>
      </p>
    </div>

  </div>
</body>
</html>`;
}

// ── Route : inscription newsletter ────────────────────────────────
app.post('/newsletter', async (req, res) => {
  const { email } = req.body;
  if (!email || !isValidEmail(email)) {
    return res.status(400).json({ message: 'Email invalide.' });
  }

  // Enregistrer l'abonné (sans doublon)
  const subscribers = loadSubscribers();
  if (!subscribers.includes(email)) {
    subscribers.push(email);
    saveSubscribers(subscribers);
  }

  try {
    // Email de bienvenue → abonné
    await transporter.sendMail({
      from: `VigilConso <${process.env.FROM_EMAIL}>`,
      to: email,
      subject: 'Bienvenue sur VigilConso ! 🛡️',
      html: wrapEmail(
        'Inscription confirmée !',
        `<p style="color:#555;line-height:1.7;">
          Merci de rejoindre <strong>VigilConso</strong> !<br>
          Vous recevrez désormais un <strong>résumé hebdomadaire</strong> des derniers
          rappels de produits <strong>chaque lundi matin</strong>.
        </p>
        <p style="color:#555;line-height:1.7;">
          Pour consulter les alertes <em>en temps réel</em> et scanner des produits,
          ouvrez l'application directement depuis le bouton ci-dessous.
        </p>
        <div style="background:#fff8f8;border-left:4px solid #CC1421;padding:12px 16px;margin:20px 0;border-radius:4px;">
          <p style="margin:0;color:#CC1421;font-size:13px;">
            💡 <strong>Conseil :</strong> Ajoutez VigilConso en favori pour accéder rapidement
            aux dernières alertes sans attendre le résumé hebdomadaire.
          </p>
        </div>`
      ),
    });

    // Notification admin
    await transporter.sendMail({
      from: `VigilConso <${process.env.FROM_EMAIL}>`,
      to: process.env.FROM_EMAIL,
      subject: `Nouvelle inscription newsletter : ${email}`,
      text: `Nouvel abonné : ${email}\nDate : ${new Date().toLocaleString('fr-FR')}\nTotal abonnés : ${subscribers.length}`,
    });

    return res.status(200).json({ message: 'Inscription réussie !' });
  } catch (error) {
    console.error('Erreur newsletter:', error.message);
    return res.status(500).json({ message: 'Erreur inscription. Réessayez.' });
  }
});

// ── Route : envoi email générique ─────────────────────────────────
app.post('/send-email', async (req, res) => {
  const { to, subject, text, html } = req.body;
  if (!to || !subject) {
    return res.status(400).json({ message: 'Champs requis manquants.' });
  }
  try {
    const info = await transporter.sendMail({
      from: process.env.FROM_EMAIL,
      to,
      subject,
      text,
      html,
    });
    return res.status(200).json({ message: 'Email envoyé', id: info.messageId });
  } catch (error) {
    console.error('Erreur:', error.message);
    return res.status(500).json({ message: 'Erreur envoi email' });
  }
});

// ── Digest hebdomadaire ────────────────────────────────────────────
async function sendWeeklyDigest() {
  const subscribers = loadSubscribers();
  if (subscribers.length === 0) {
    console.log('Digest : aucun abonné, envoi annulé.');
    return;
  }

  try {
    // Récupérer les 10 derniers rappels depuis l'API gouvernementale
    const year = new Date().getFullYear();
    const apiUrl = `https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso0/records?limit=10&where=date_publication>="${year}-01-01"&order_by=date_publication%20DESC`;
    const response = await fetch(apiUrl);
    const data = await response.json();
    const rappels = data.results || [];

    if (rappels.length === 0) {
      console.log('Digest : aucun rappel récent trouvé.');
      return;
    }

    // Construire les cartes HTML des rappels
    const rappelsHtml = rappels.map((r) => {
      const nom = r.noms_des_modeles_ou_references || r.libelle_produit || 'Produit inconnu';
      const marque = r.nom_de_la_marque_du_produit || '';
      const categorie = r.categorie_de_produit || '';
      const date = r.date_publication
        ? new Date(r.date_publication).toLocaleDateString('fr-FR', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
          })
        : '';
      const lienFiche = r.lien_vers_la_liste_des_produits || APP_URL;

      return `
        <div style="border:1px solid #e8e8e8;border-radius:10px;padding:16px;margin-bottom:14px;">
          ${categorie
            ? `<span style="background:#ffebee;color:#CC1421;font-size:11px;
                            padding:3px 10px;border-radius:12px;font-weight:bold;">
                ${categorie.toUpperCase()}
               </span>`
            : ''}
          <p style="margin:10px 0 4px;font-weight:bold;color:#222;font-size:15px;">${nom}</p>
          ${marque ? `<p style="margin:0 0 4px;color:#666;font-size:13px;">${marque}</p>` : ''}
          ${date ? `<p style="margin:0 0 12px;color:#999;font-size:12px;">📅 ${date}</p>` : ''}
          <div>
            <a href="${lienFiche}"
               style="color:#CC1421;font-size:13px;text-decoration:none;margin-right:16px;">
              Fiche officielle →
            </a>
            <a href="${APP_URL}"
               style="background:#CC1421;color:#ffffff;font-size:12px;text-decoration:none;
                      padding:6px 16px;border-radius:16px;font-weight:bold;">
              Voir dans l'app
            </a>
          </div>
        </div>`;
    }).join('');

    const weekStr = new Date().toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    });

    // Envoyer à chaque abonné
    let sent = 0;
    for (const email of subscribers) {
      try {
        await transporter.sendMail({
          from: `VigilConso <${process.env.FROM_EMAIL}>`,
          to: email,
          subject: `VigilConso — Résumé hebdomadaire du ${weekStr}`,
          html: wrapEmail(
            `Résumé de la semaine — ${weekStr}`,
            `<p style="color:#555;margin-bottom:20px;">
              Voici les <strong>${rappels.length} derniers rappels</strong>
              signalés. Cliquez sur <em>"Voir dans l'app"</em> pour accéder
              à tous les détails et scanner vos produits.
            </p>
            ${rappelsHtml}`
          ),
        });
        sent++;
      } catch (e) {
        console.error(`Erreur envoi digest à ${email}:`, e.message);
      }
    }

    console.log(`Digest hebdomadaire envoyé à ${sent}/${subscribers.length} abonné(s)`);
  } catch (err) {
    console.error('Erreur digest hebdomadaire:', err.message);
  }
}

// Planification : tous les lundis à 9h00 (fuseau Paris)
cron.schedule('0 9 * * 1', sendWeeklyDigest, { timezone: 'Europe/Paris' });

// ── Health check ───────────────────────────────────────────────────
app.get('/health', (req, res) =>
  res.status(200).json({
    status: 'ok',
    subscribers: loadSubscribers().length,
    nextDigest: 'Tous les lundis à 9h00 (Europe/Paris)',
  })
);

// ── Démarrage ──────────────────────────────────────────────────────
const port = parseInt(process.env.PORT || '3000');
app.listen(port, () =>
  console.log(`VigilConso API running on http://localhost:${port}`)
);
