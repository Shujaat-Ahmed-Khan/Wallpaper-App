// Official Firebase v10 Modular SDK via Google CDN
import { initializeApp, getApps } from 'https://www.gstatic.com/firebasejs/10.9.0/firebase-app.js';
import {
  getFirestore,
  collection,
  query,
  where,
  getDocs,
  doc,
  setDoc,
  deleteDoc,
  updateDoc,
  writeBatch,
  serverTimestamp,
  addDoc
} from 'https://www.gstatic.com/firebasejs/10.9.0/firebase-firestore.js';
import {
  getStorage,
  ref,
  uploadBytesResumable,
  getDownloadURL
} from 'https://www.gstatic.com/firebasejs/10.9.0/firebase-storage.js';

const firebaseConfig = {
  apiKey: "AIzaSyDemoAdminKeyForNeonGlass2026",
  authDomain: "neonglass-wallpaper.firebaseapp.com",
  projectId: "neonglass-wallpaper",
  storageBucket: "neonglass-wallpaper.appspot.com",
  messagingSenderId: "1029384756",
  appId: "1:1029384756:web:abcd1234ef5678"
};

const app = !getApps().length ? initializeApp(firebaseConfig) : getApps()[0];
export const db = getFirestore(app);
export const storage = getStorage(app);

// Re-export Firestore & Storage helpers for consistent modular usage across components
export {
  collection,
  query,
  where,
  getDocs,
  doc,
  setDoc,
  deleteDoc,
  updateDoc,
  writeBatch,
  serverTimestamp,
  addDoc,
  ref,
  uploadBytesResumable,
  getDownloadURL
};

export default app;
