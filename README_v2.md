# mi_vecino

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Framework-blue" alt="Flutter">
  <img src="https://img.shields.io/badge/Firebase-Backend-orange" alt="Firebase">
  <img src="https://img.shields.io/badge/Status-Estable-green" alt="Estado">
  <img src="https://img.shields.io/github/last-commit/Desarrolladores-F5/mi-vecino-app" alt="Último Commit">
</p>

🏡 Mi Vecino – App Comunitaria
Versión: app_estable_muro_funcional_v2
Tecnologías: Flutter + Firebase (Auth, Firestore, Storage, Messaging)

📌 ¿Qué es Mi Vecino?
Mi Vecino es una aplicación comunitaria orientada a la cooperación y seguridad entre vecinos.
Permite a las personas conectarse por comunidad para compartir información, avisos y situaciones de emergencia en su sector.

## 📌  Actualización — Subida de publicaciones con imagen (15-08-2025)

### ✅ Resumen
Se corrigió y optimizó la funcionalidad de subir publicaciones con imagen al muro, asegurando que:
- El mensaje y la imagen se suben correctamente a Firebase Storage y Firestore.
- Se aplican **reglas seguras** en Firebase Storage para proteger las rutas:
  - `/fotos_perfil/{uid}.jpg` → Solo el usuario dueño puede subir/cambiar su foto de perfil.
  - `/publicaciones/{uid}/{archivo}` → Solo el usuario dueño puede subir publicaciones en su carpeta.
- Se manejan casos de error como:
  1. Archivo inexistente.
  2. Error de permisos.
  3. Exceso de tamaño o tipo de archivo inválido.

### 🔧 Cambios realizados
1. **Método robusto** en `crear_publicacion_screen.dart` para evitar fallos y mostrar mensajes claros en cada caso.
2. Ajuste de reglas en Firebase Storage con tamaño máximo:
   - Fotos de perfil: **3 MB**.
   - Imágenes/PDFs en publicaciones: **10 MB**.
3. Validación de `contentType` en Storage para permitir solo `image/*` o PDF (opcional).
4. Pruebas con distintos dispositivos y app cerrada.

### 📂 Rutas seguras en Storage
- `fotos_perfil/{uid}.jpg`
- `publicaciones/{uid}/{archivo}`

### 🚀 Resultado
- Subida de mensajes + imágenes funcionando correctamente en muro.
- Reglas de seguridad publicadas y probadas con éxito.
- Compatible con cold start y múltiples usuarios autenticados.

---


🚀 Novedades de esta versión
Muro comunitario funcional:

Las publicaciones ahora se muestran filtradas por comunidad usando nombre_comunidad.

Cada usuario ve solo las publicaciones relevantes para su sector.

Creación de publicaciones mejorada:

Publicaciones con texto e imágenes subidas a Firebase Storage.

Inclusión del campo nombre_comunidad en cada publicación.

Teléfonos de emergencia:

Nueva sección en el menú lateral con botones de llamada directa a:

Carabineros (133)

Bomberos (132)

SAMU (131)

Con diseño visual y colores diferenciados.

Notificaciones y alarma comunitaria:

Sistema de notificaciones basado en Firebase Cloud Messaging (FCM).

Alarma comunitaria filtrada por comunidad: solo suena en la comunidad activada.

Internacionalización completa:

Soporte de idiomas Español / Inglés.

📱 Funciones principales
Registro y login con Firebase Authentication.

Perfil de usuario con foto y datos de la comunidad.

Muro de publicaciones filtrado por comunidad.

Alarmas comunitarias en tiempo real.

Teléfonos de emergencia accesibles desde el menú lateral.

## 🚨 Alarma Vecinal — Implementación Cold Start + Google Maps

**Objetivo:**  
Permitir que los usuarios reciban y abran notificaciones de alarma, con la app cerrada o el usuario deslogueado, y que al tocar la notificación se abra **Google Maps** mostrando la ubicación exacta del emisor.

---

### 1️⃣ Suscripción Persistente por Comunidad
- Archivo: `lib/core/topic_subscription.dart`
- Guarda la comunidad en `SharedPreferences`.
- Suscribe automáticamente al topic al iniciar la app.
- Actualiza la suscripción al cambiar de comunidad.

**Uso en main.dart:**
```dart
await TopicSubscription.subscribeFromLocalPrefs();
