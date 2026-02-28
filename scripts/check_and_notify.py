"""
Script automatique : détecte les nouvelles alertes RappelConso
et envoie une notification push OneSignal à tous les abonnés.

Lancé toutes les 6h par GitHub Actions.
"""

import os
import json
import requests
from datetime import datetime

# ── Config ──────────────────────────────────────────────────────────────────
ONESIGNAL_APP_ID  = "eb3fd80e-1a70-468f-ab2e-e1d2eb9592ab"
ONESIGNAL_API_KEY = os.environ.get("ONESIGNAL_API_KEY", "")  # Secret GitHub

RAPPEL_API_URL = (
    "https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets"
    "/rappelconso-v2-gtin-espaces/records?limit=10&order_by=date_publication%20desc"
)

LAST_DATE_FILE = "scripts/last_alert_date.txt"

# ── Helpers ──────────────────────────────────────────────────────────────────

def fetch_latest_alerts():
    try:
        r = requests.get(RAPPEL_API_URL, timeout=15)
        r.raise_for_status()
        return r.json().get("results", [])
    except Exception as e:
        print(f"[ERREUR] Impossible de récupérer les alertes : {e}")
        return []


def get_last_sent_date():
    try:
        with open(LAST_DATE_FILE, "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        return ""


def save_last_sent_date(date_str):
    with open(LAST_DATE_FILE, "w") as f:
        f.write(date_str)


def send_push_notification(new_count, latest_title):
    if not ONESIGNAL_API_KEY:
        print("[ERREUR] ONESIGNAL_API_KEY non défini dans les secrets GitHub.")
        return False

    plural = "s" if new_count > 1 else ""
    message = f"{new_count} nouveau{plural} rappel{plural} de produit{plural} publié{plural} !"
    subtitle = latest_title[:60] if latest_title else ""

    payload = {
        "app_id": ONESIGNAL_APP_ID,
        "included_segments": ["All"],
        "headings":  {"fr": "VigilConso 🔔", "en": "VigilConso 🔔"},
        "contents":  {"fr": message, "en": message},
        "subtitle":  {"fr": subtitle, "en": subtitle},
        "android_accent_color": "FFCC1421",
        "small_icon": "ic_notification",
    }

    r = requests.post(
        "https://onesignal.com/api/v1/notifications",
        headers={
            "Authorization": f"Basic {ONESIGNAL_API_KEY}",
            "Content-Type": "application/json",
        },
        json=payload,
        timeout=15,
    )
    print(f"[OneSignal] {r.status_code} → {r.text}")
    return r.status_code == 200


# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    print(f"[{datetime.utcnow().isoformat()}] Vérification des nouvelles alertes...")

    alerts = fetch_latest_alerts()
    if not alerts:
        print("Aucune alerte récupérée, abandon.")
        return

    latest_date  = alerts[0].get("date_publication", "")
    latest_title = alerts[0].get("libelle") or alerts[0].get("libelle_produit", "Produit rappelé")
    last_sent    = get_last_sent_date()

    print(f"  Dernière alerte API  : {latest_date}")
    print(f"  Dernière notif envoyée: {last_sent}")

    if not latest_date or latest_date == last_sent:
        print("Aucune nouvelle alerte. Rien à envoyer.")
        return

    # Compter uniquement les alertes plus récentes que la dernière notif
    new_alerts = [a for a in alerts if a.get("date_publication", "") > last_sent] if last_sent else alerts
    new_count  = len(new_alerts)

    print(f"  {new_count} nouvelle(s) alerte(s) détectée(s) → envoi push...")
    success = send_push_notification(new_count, latest_title)

    if success:
        save_last_sent_date(latest_date)
        print("Notification envoyée et date mise à jour.")
    else:
        print("[ERREUR] Échec de l'envoi, date non mise à jour.")


if __name__ == "__main__":
    main()
