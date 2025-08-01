const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");

// Inicializa Firebase Admin
admin.initializeApp();

// Opciones globales
setGlobalOptions({ region: "us-central1" });

// Función Cloud Function para notificaciones de pánico
exports.notificarPanicAlert = onDocumentCreated("panic_alerts/{alertId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data();
  const comunidad = data.comunidad    // Normaliza el nombre del topic para que sea válido en FCM
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, '_'); // reemplaza espacios y caracteres inválidos por "_"
  const nombre = data.nombre;
  const lat = data.latitud;
  const lng = data.longitud;

  try {
    // Enviar notificación a todos los suscritos al topic de la comunidad
    await admin.messaging().send({
      topic: comunidad,
      notification: {
        title: "🚨 Alerta de Pánico",
        body: `${nombre} ha activado el botón de pánico.`,
      },
      data: {
        tipo: "panic",
        latitud: lat.toString(),
        longitud: lng.toString(),
        comunidad: comunidad,
      },
    });

    console.log(`Notificación enviada al topic: ${comunidad}`);
  } catch (error) {
    console.error("Error enviando notificación:", error);
  }
});