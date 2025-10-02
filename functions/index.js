const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2/options");
const admin = require("firebase-admin");
// NUEVO: logger y nodemailer + secrets
const logger = require("firebase-functions/logger");
const nodemailer = require("nodemailer");
const { defineSecret } = require("firebase-functions/params");

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

// 🔔 cuando alguien crea una nueva publicación
exports.onNuevaPublicacion = onDocumentCreated("publicaciones/{pubId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const d = snap.data() || {};
  const comunidadRaw = d.nombre_comunidad || d.comunidad || "";
  const autor        = d.autor || "Un vecino";
  const mensaje      = (d.mensaje || "").toString();
  const pubId        = event.params.pubId;

  if (!comunidadRaw) return;

  // pequeño preview (no más de 100 chars)
  const preview = mensaje.length > 100 ? `${mensaje.slice(0, 100)}…` : mensaje;

  const topic = toTopic(comunidadRaw);

  const data = {
    tipo: "post",
    postId: String(pubId),
    comunidad: comunidadRaw,
  };

  const message = {
    topic,
    notification: {
      title: "📰 Nueva publicación",
      body: `${autor}: ${preview || "publicó algo nuevo en el muro"}`,
    },
    data,
    android: {
      priority: "high",
      notification: {
        channelId: "mi_vecino_channel",     // ya creado en main.dart
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        sound: "default",
      },
    },
  };

  try {
    const id = await admin.messaging().send(message);
    console.log("FCM post ->", id, "topic:", topic, "pubId:", pubId);
  } catch (err) {
    console.error("Error enviando notificación de post:", err);
  }
});

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
    emisorId: String(emisorId || ""),
    titulo: "🚨 Alerta de Pánico",
    cuerpo: `${nombre} ha activado el botón de pánico en ${direccion}.`,
  };
  if (lat != null)  data.latitud  = String(lat);
  if (lng != null)  data.longitud = String(lng);
  if (mapUrl)       data.mapUrl   = String(mapUrl);

  const message = {
    topic,
    notification: {
      title: data.titulo,
      body: data.cuerpo,
    },
    data, // <- importante para cold start + abrir Maps
    android: {
      priority: "high",
      notification: {
        channelId: "mi_vecino_panic_channel",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        //sound: "default",
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

// =========================
// NUEVO: Envío de correo al crear sugerencia
// =========================

// Secrets (CLI: functions:secrets:set ...)
const SMTP_USER = defineSecret("SMTP_USER"); // upf5digital@gmail.com
const SMTP_PASS = defineSecret("SMTP_PASS"); // App Password (16 chars)
const SMTP_HOST = defineSecret("SMTP_HOST"); // smtp.gmail.com
const SMTP_PORT = defineSecret("SMTP_PORT"); // 465 (SSL) o 587 (STARTTLS)

exports.enviarCorreoSugerencia = onDocumentCreated(
  {
    document: "sugerencias/{docId}",
    region: "us-central1",
    secrets: [SMTP_USER, SMTP_PASS, SMTP_HOST, SMTP_PORT],
    retry: true, // reintentos si falla por red/SMTP
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const d = snap.data() || {};
    const uid     = d.uid || "-";
    const email   = (d.email || "-").toString();
    const mensaje = (d.mensaje || "").toString();

    // Fecha legible
    const fecha = (() => {
      try {
        if (d?.fecha?.toDate) return d.fecha.toDate().toISOString();
        if (d?.fecha?.seconds) return new Date(d.fecha.seconds * 1000).toISOString();
        return new Date().toISOString();
      } catch {
        return new Date().toISOString();
      }
    })();

    // Transporter SMTP (Gmail)
    const host = SMTP_HOST.value() || "smtp.gmail.com";
    const port = Number(SMTP_PORT.value() || 465);
    const secure = port === 465;

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: {
        user: SMTP_USER.value(), // upf5digital@gmail.com
        pass: SMTP_PASS.value(), // App Password 16
      },
    });

    // Email
    const from = `"Mi Vecino" <${SMTP_USER.value()}>`;
    const to   = "contacto@upf5.com"; // destinatario final (tu casilla de recepción)
    const replyTo = /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) ? email : undefined;

    const subject = "Nueva sugerencia – Mi Vecino";
    const text = [
      `UID: ${uid}`,
      `Email: ${email}`,
      `Fecha: ${fecha}`,
      "",
      "Mensaje:",
      mensaje,
    ].join("\n");

    const html = `
      <div style="font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;">
        <h2>Mi Vecino – Nueva sugerencia</h2>
        <p><b>UID:</b> ${uid}</p>
        <p><b>Email:</b> ${email}</p>
        <p><b>Fecha:</b> ${fecha}</p>
        <hr/>
        <p><b>Mensaje:</b></p>
        <pre style="white-space:pre-wrap;font-family:inherit">${mensaje
          .replace(/</g,"&lt;").replace(/>/g,"&gt;")}</pre>
      </div>
    `;

    try {
      await transporter.sendMail({ from, to, replyTo, subject, text, html });
      logger.info("✅ Sugerencia enviada a contacto@upf5.com");
    } catch (err) {
      logger.error("❌ Error enviando correo de sugerencia", err);
      throw err; // permite retry automático
    }
  }
);
