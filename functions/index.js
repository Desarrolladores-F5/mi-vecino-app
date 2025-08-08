const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "us-central1" });

// 🔔 Se ejecuta al crear un documento en panic_alerts
exports.notificarPanicAlert = onDocumentCreated("panic_alerts/{alertId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const d = snap.data();
  const comunidadRaw = d.comunidad || "";
  const nombre       = d.nombre || "Un vecino";
  const direccion    = d.direccion || "una dirección no especificada";
  const lat          = d.latitud;
  const lng          = d.longitud;
  const emisorId     = d.userId || "";

  // ✅ Normaliza el nombre de la comunidad para usarlo como topic
  const comunidadTopic = comunidadRaw.toLowerCase().replace(/[^a-z0-9_-]/g, "_");

  try {
    await admin.messaging().send({
      topic: comunidadTopic,
      notification: {
        title: "🚨 Alerta de Pánico",
        body: `${nombre} ha activado el botón de pánico en ${direccion}.`,
      },
      data: {
        tipo: "panic",
        comunidad: comunidadRaw,
        emisorId,
        latitud: String(lat ?? ""),
        longitud: String(lng ?? ""),
        // 👇 clave para abrir Google Maps en el receptor
        mapUrl: (lat != null && lng != null) ? `https://www.google.com/maps?q=${lat},${lng}` : "",
      },
      android: {
        priority: "high",
        notification: { sound: "default" },
      },
    });

    console.log(`Notificación enviada al topic: ${comunidadTopic}`);
  } catch (err) {
    console.error("Error enviando notificación:", err);
  }
});
