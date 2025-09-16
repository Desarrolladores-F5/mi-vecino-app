const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "us-central1" });

/**
 * Normaliza igual que en Flutter helper:
 * - a minúsculas
 * - espacios -> "_"
 * - elimina caracteres no permitidos
 * - prefijo "comunidad_"
 */
function toTopic(communityName) {
  const s = String(communityName || "")
    .trim()
    .toLowerCase()
    .replaceAll(" ", "_")
    .replace(/[^a-z0-9_\-\.~%]/g, "");
  return `comunidad_${s}`;
}

/**
 * 🔔 Se ejecuta al crear un documento en panic_alerts
 * Espera campos: comunidad, nombre, direccion, latitud, longitud, userId (opcional)
 */
exports.notificarPanicAlert = onDocumentCreated("panic_alerts/{alertId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const d = snap.data() || {};
  const comunidadRaw = d.comunidad || "";
  const nombre       = d.nombre || "Un vecino";
  const direccion    = d.direccion || "una dirección no especificada";
  const lat          = d.latitud;
  const lng          = d.longitud;
  const emisorId     = d.userId || "";

  const topic = toTopic(comunidadRaw);

  // Si no viene mapUrl, lo construimos desde lat/long si existen
  let mapUrl = d.mapUrl;
  if (!mapUrl && lat != null && lng != null) {
    mapUrl = `https://www.google.com/maps?q=${lat},${lng}`;
  }

  const data = {
    tipo: "panic",
    comunidad: comunidadRaw,     // texto “humano” para logs
    emisorId: String(emisorId),
  };
  if (lat != null)  data.latitud  = String(lat);
  if (lng != null)  data.longitud = String(lng);
  if (mapUrl)       data.mapUrl   = String(mapUrl);

  const message = {
    topic,
    notification: {
      title: "🚨 Alerta de Pánico",
      body: `${nombre} ha activado el botón de pánico en ${direccion}.`,
    },
    data, // <- importante para cold start + abrir Maps
    android: {
      priority: "high",
      notification: {
        channelId: "mi_vecino_channel",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        sound: "default",
      },
    },
  };

  try {
    const id = await admin.messaging().send(message);
    console.log("FCM message ID:", id, "topic:", topic, "data:", data);
  } catch (err) {
    console.error("Error enviando notificación:", err);
  }
});

/** 🚨 NUEVA: alarma → alarmas_activas/{comunidadId} */
exports.onAlarmWrite = onDocumentWritten("alarmas_activas/{comunidadId}", async (event) => {
  const before = event.data?.before?.data() || null;
  const after  = event.data?.after?.data()  || null;
  if (!after) return;

  if (before && before.activa === after.activa) return; // no cambió estado

  function toTopic(communityName) {
    return "comunidad_" + String(communityName || "")
      .trim().toLowerCase()
      .replace(/[^a-z0-9]+/g, "_")
      .replace(/_+/g, "_")
      .replace(/^_|_$/g, "");
  }

  const comunidadId = event.params.comunidadId;           // ej: "Jardines de Paso Hondo 2"
  const activa      = after.activa === true;
  const durationSec = Number.isInteger(after.durationSec) ? after.durationSec : 5;
  const activadaPor = String(after.activada_por_direccion || after.activada_por || "");

  const topic = toTopic(comunidadId);

  if (activa) {
    const message = {
      topic,
      notification: {
        title: "🚨 Alarma vecinal",
        body: activadaPor
          ? `Alarma activada desde: ${activadaPor}`
          : "Se activó una alarma en tu comunidad",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "alarma_vecinal",                // 👈 debe existir el canal en la app
          sound: "alarma_vecinal_chat_ready",         // 👈 archivo en res/raw (sin .mp3)
          ticker: "Alarma vecinal",
        },
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: {
            alert: {
              title: "🚨 Alarma vecinal",
              body: activadaPor
                ? `Alarma activada desde: ${activadaPor}`
                : "Se activó una alarma en tu comunidad",
            },
            // Para sonido custom en iOS, agregar .caf al bundle y setear: sound: "alarma_vecinal_chat_ready.caf"
          },
        },
      },
      data: {
        type: "alarm",
        comunidadId,
        activada_por: activadaPor,
        durationSec: String(durationSec),
      },
    };

    try {
      const id = await admin.messaging().send(message);
      console.log("FCM alarm ID:", id, "topic:", topic, "data:", { comunidadId, activadaPor, durationSec });
    } catch (err) {
      console.error("Error enviando notificación de alarma:", err);
    }
  
  }
  
});