const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");

// Inicializa Firebase Admin
admin.initializeApp();

// Configuración global de funciones
setGlobalOptions({ region: "us-central1" });

/**
 * Cloud Function:
 * Envía una notificación push cuando se crea un documento en panic_alerts.
 */
exports.notificarPanicAlert = onDocumentCreated("panic_alerts/{alertId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const data = snap.data();
  const comunidadRaw = data.comunidad || "";
  const nombre = data.nombre || "Un vecino";
  const direccion = data.direccion || "una dirección no especificada";
  const lat = data.latitud;
  const lng = data.longitud;
  const emisorId = data.userId; // para identificar al emisor

  // Normalizamos el nombre de la comunidad para usarlo como topic
  const comunidadTopic = comunidadRaw
    .toLowerCase()
    .replace(/[^a-z0-9_-]/g, "_");

  try {
    // Construimos el payload de la notificación
    const payload = {
      notification: {
        title: "🚨 Alerta de Pánico",
        body: `${nombre} ha activado el botón de pánico en ${direccion}.`,
      },
      data: {
        tipo: "panic",
        latitud: lat.toString(),
        longitud: lng.toString(),
        comunidad: comunidadRaw,
        emisorId: emisorId,
      },
    };

    // Enviar la notificación al topic (todos los usuarios de la comunidad)
    await admin.messaging().send({
      topic: comunidadTopic,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`Notificación enviada al topic: ${comunidadTopic}`);
  } catch (error) {
    console.error("Error enviando notificación:", error);
  }
});
