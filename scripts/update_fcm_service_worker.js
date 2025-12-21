/**
 * Script pour mettre à jour automatiquement firebase-messaging-sw.js
 * avec la configuration Firebase depuis firebase_options.dart
 * 
 * Usage: node scripts/update_fcm_service_worker.js
 */

const fs = require('fs');
const path = require('path');

// Lire firebase_options.dart
const firebaseOptionsPath = path.join(__dirname, '../lib/core/firebase/firebase_options.dart');
const serviceWorkerPath = path.join(__dirname, '../web/firebase-messaging-sw.js');

try {
  const firebaseOptionsContent = fs.readFileSync(firebaseOptionsPath, 'utf8');
  
  // Extraire les valeurs de configuration web
  const apiKeyMatch = firebaseOptionsContent.match(/apiKey:\s*['"]([^'"]+)['"]/);
  const authDomainMatch = firebaseOptionsContent.match(/authDomain:\s*['"]([^'"]+)['"]/);
  const projectIdMatch = firebaseOptionsContent.match(/projectId:\s*['"]([^'"]+)['"]/);
  const storageBucketMatch = firebaseOptionsContent.match(/storageBucket:\s*['"]([^'"]+)['"]/);
  const messagingSenderIdMatch = firebaseOptionsContent.match(/messagingSenderId:\s*['"]([^'"]+)['"]/);
  const appIdMatch = firebaseOptionsContent.match(/appId:\s*['"]([^'"]+)['"]/);

  if (!apiKeyMatch || !authDomainMatch || !projectIdMatch || !storageBucketMatch || !messagingSenderIdMatch || !appIdMatch) {
    console.error('❌ Impossible de trouver toutes les valeurs de configuration Firebase');
    process.exit(1);
  }

  const config = {
    apiKey: apiKeyMatch[1],
    authDomain: authDomainMatch[1],
    projectId: projectIdMatch[1],
    storageBucket: storageBucketMatch[1],
    messagingSenderId: messagingSenderIdMatch[1],
    appId: appIdMatch[1],
  };

  // Lire le service worker
  let serviceWorkerContent = fs.readFileSync(serviceWorkerPath, 'utf8');

  // Remplacer la configuration
  const configRegex = /const firebaseConfig = \{[\s\S]*?\};/;
  const newConfig = `const firebaseConfig = {
  apiKey: "${config.apiKey}",
  authDomain: "${config.authDomain}",
  projectId: "${config.projectId}",
  storageBucket: "${config.storageBucket}",
  messagingSenderId: "${config.messagingSenderId}",
  appId: "${config.appId}"
};`;

  serviceWorkerContent = serviceWorkerContent.replace(configRegex, newConfig);

  // Écrire le fichier mis à jour
  fs.writeFileSync(serviceWorkerPath, serviceWorkerContent, 'utf8');

  console.log('✅ Service worker mis à jour avec succès !');
  console.log('📝 Configuration Firebase appliquée:');
  console.log(`   - Project ID: ${config.projectId}`);
  console.log(`   - App ID: ${config.appId}`);
} catch (error) {
  console.error('❌ Erreur lors de la mise à jour du service worker:', error.message);
  console.log('\n💡 Alternative: Mettez à jour manuellement web/firebase-messaging-sw.js');
  console.log('   avec les valeurs de Firebase Console > Project Settings > Your apps > Web app');
  process.exit(1);
}


