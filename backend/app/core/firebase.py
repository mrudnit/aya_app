import os
import firebase_admin
from firebase_admin import credentials, firestore
from dotenv import load_dotenv

load_dotenv()

_db = None


def init_firebase():
    global _db
    if not firebase_admin._apps:
        key_path = os.getenv("FIREBASE_KEY_PATH", "serviceAccountKey.json")
        if not os.path.exists(key_path):
            raise FileNotFoundError(
                f"serviceAccountKey.json not found at '{key_path}'.\n"
                "Download it from Firebase Console → Project Settings → "
                "Service accounts → Generate new private key."
            )
        cred = credentials.Certificate(key_path)
        firebase_admin.initialize_app(cred)
    _db = firestore.client()


def get_db():
    if _db is None:
        raise RuntimeError(
            "Firestore not initialised. "
            "Make sure init_firebase() is called at startup."
        )
    return _db
