importScripts("https://www.gstatic.com/firebasejs/7.20.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/7.20.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyCdShq8i_462FswskxbbXPdhZ_px740P2M",
  authDomain: "carrot-foodelivery.firebaseapp.com",
  projectId: "carrot-foodelivery",
  storageBucket: "carrot-foodelivery.firebasestorage.app",
  messagingSenderId: "629553534814",
  appId: "1:629553534814:android:5dfc7ed901be63eaa9a1cf",
  databaseURL: "https://carrot-foodelivery-default-rtdb.firebaseio.com",
});

const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});