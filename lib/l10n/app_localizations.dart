import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @tituloApp.
  ///
  /// In es, this message translates to:
  /// **'Mi Vecino'**
  String get tituloApp;

  /// No description provided for @bienvenida.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Mi Vecino'**
  String get bienvenida;

  /// No description provided for @direccion.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get direccion;

  /// No description provided for @idioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get idioma;

  /// No description provided for @acercaDe.
  ///
  /// In es, this message translates to:
  /// **'Acerca de la App'**
  String get acercaDe;

  /// No description provided for @buenosDias.
  ///
  /// In es, this message translates to:
  /// **'¡Buenos días, vecino!'**
  String get buenosDias;

  /// No description provided for @buenasTardes.
  ///
  /// In es, this message translates to:
  /// **'¡Buenas tardes, vecino!'**
  String get buenasTardes;

  /// No description provided for @buenasNoches.
  ///
  /// In es, this message translates to:
  /// **'¡Buenas noches, vecino!'**
  String get buenasNoches;

  /// No description provided for @correo.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get correo;

  /// No description provided for @correoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Ingrese un correo válido'**
  String get correoInvalido;

  /// No description provided for @contrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get contrasena;

  /// No description provided for @contrasenaCorta.
  ///
  /// In es, this message translates to:
  /// **'Contraseña muy corta'**
  String get contrasenaCorta;

  /// No description provided for @iniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get iniciarSesion;

  /// No description provided for @noCuentaRegistrate.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? Regístrate'**
  String get noCuentaRegistrate;

  /// No description provided for @usuarioNoEncontrado.
  ///
  /// In es, this message translates to:
  /// **'Usuario no encontrado'**
  String get usuarioNoEncontrado;

  /// No description provided for @contrasenaIncorrecta.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta'**
  String get contrasenaIncorrecta;

  /// No description provided for @errorGenerico.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión'**
  String get errorGenerico;

  /// No description provided for @sugerencias.
  ///
  /// In es, this message translates to:
  /// **'Sugerencias'**
  String get sugerencias;

  /// No description provided for @nombre.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nombre;

  /// No description provided for @apellido.
  ///
  /// In es, this message translates to:
  /// **'Apellido'**
  String get apellido;

  /// No description provided for @registrarse.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registrarse;

  /// No description provided for @registroExitoso.
  ///
  /// In es, this message translates to:
  /// **'Registro exitoso'**
  String get registroExitoso;

  /// No description provided for @registroError.
  ///
  /// In es, this message translates to:
  /// **'Error al registrar usuario'**
  String get registroError;

  /// No description provided for @yaTieneCuentaInicieSesion.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get yaTieneCuentaInicieSesion;

  /// No description provided for @limiteAlcanzado.
  ///
  /// In es, this message translates to:
  /// **'Límite alcanzado'**
  String get limiteAlcanzado;

  /// No description provided for @maximoDosPorDireccion.
  ///
  /// In es, this message translates to:
  /// **'Solo se permiten dos registros por dirección'**
  String get maximoDosPorDireccion;

  /// No description provided for @usuarioRegistrado.
  ///
  /// In es, this message translates to:
  /// **'Usuario registrado correctamente'**
  String get usuarioRegistrado;

  /// No description provided for @correoYaRegistrado.
  ///
  /// In es, this message translates to:
  /// **'El correo ya está registrado'**
  String get correoYaRegistrado;

  /// No description provided for @contrasenaDebil.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil'**
  String get contrasenaDebil;

  /// No description provided for @atencion.
  ///
  /// In es, this message translates to:
  /// **'Atención'**
  String get atencion;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorInesperado.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado'**
  String get errorInesperado;

  /// No description provided for @registroVecinos.
  ///
  /// In es, this message translates to:
  /// **'Registro de Vecinos'**
  String get registroVecinos;

  /// No description provided for @ingresaNombre.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get ingresaNombre;

  /// No description provided for @apellidos.
  ///
  /// In es, this message translates to:
  /// **'Apellidos'**
  String get apellidos;

  /// No description provided for @ingresaApellidos.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tus apellidos'**
  String get ingresaApellidos;

  /// No description provided for @ingresaDireccion.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu dirección'**
  String get ingresaDireccion;

  /// No description provided for @nombreComunidad.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Comunidad'**
  String get nombreComunidad;

  /// No description provided for @ingresaNombreComunidad.
  ///
  /// In es, this message translates to:
  /// **'Ingresa el nombre de la comunidad'**
  String get ingresaNombreComunidad;

  /// No description provided for @confirmarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contraseña'**
  String get confirmarContrasena;

  /// No description provided for @contrasenasNoCoinciden.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get contrasenasNoCoinciden;

  /// No description provided for @yaTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta? Inicia sesión'**
  String get yaTienesCuenta;

  /// No description provided for @seguroCerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cerrar sesión?'**
  String get seguroCerrarSesion;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @salir.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get salir;

  /// No description provided for @ajustes.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get ajustes;

  /// No description provided for @estadoApp.
  ///
  /// In es, this message translates to:
  /// **'Estado de la App'**
  String get estadoApp;

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get cerrarSesion;

  /// No description provided for @hola.
  ///
  /// In es, this message translates to:
  /// **'Hola'**
  String get hola;

  /// No description provided for @comunidad.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get comunidad;

  /// No description provided for @queCompartir.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te gustaría compartir?'**
  String get queCompartir;

  /// No description provided for @agregaPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Agrega una publicación'**
  String get agregaPublicacion;

  /// No description provided for @muroPublicaciones.
  ///
  /// In es, this message translates to:
  /// **'Muro de Publicaciones'**
  String get muroPublicaciones;

  /// No description provided for @sinPublicaciones.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay publicaciones'**
  String get sinPublicaciones;

  /// No description provided for @desconocido.
  ///
  /// In es, this message translates to:
  /// **'Desconocido'**
  String get desconocido;

  /// No description provided for @estadoConectado.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get estadoConectado;

  /// No description provided for @descripcionApp.
  ///
  /// In es, this message translates to:
  /// **'Una aplicación comunitaria pensada para mejorar la comunicación y colaboración entre vecinos.'**
  String get descripcionApp;

  /// No description provided for @version.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get version;

  /// No description provided for @derechosReservados.
  ///
  /// In es, this message translates to:
  /// **'Todos los derechos reservados.'**
  String get derechosReservados;

  /// No description provided for @textoSugerencia.
  ///
  /// In es, this message translates to:
  /// **'¿Tienes una sugerencia o idea para mejorar la app?'**
  String get textoSugerencia;

  /// No description provided for @hintSugerencia.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu sugerencia aquí...'**
  String get hintSugerencia;

  /// No description provided for @enviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get enviar;

  /// No description provided for @sugerenciaEnviada.
  ///
  /// In es, this message translates to:
  /// **'✅ Sugerencia enviada'**
  String get sugerenciaEnviada;

  /// No description provided for @errorSugerencia.
  ///
  /// In es, this message translates to:
  /// **'❌ Hubo un error. Intenta más tarde'**
  String get errorSugerencia;

  /// No description provided for @crearPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Crear Publicación'**
  String get crearPublicacion;

  /// No description provided for @publicar.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get publicar;

  /// No description provided for @placeholderMensaje.
  ///
  /// In es, this message translates to:
  /// **'¿Qué estás pensando?'**
  String get placeholderMensaje;

  /// No description provided for @agregarArchivo.
  ///
  /// In es, this message translates to:
  /// **'Agregar imagen o archivo'**
  String get agregarArchivo;

  /// No description provided for @archivo.
  ///
  /// In es, this message translates to:
  /// **'Archivo'**
  String get archivo;

  /// No description provided for @mensajeVacio.
  ///
  /// In es, this message translates to:
  /// **'Por favor escribe un mensaje'**
  String get mensajeVacio;

  /// No description provided for @usuarioNoAutenticado.
  ///
  /// In es, this message translates to:
  /// **'Usuario no autenticado'**
  String get usuarioNoAutenticado;

  /// No description provided for @publicacionExitosa.
  ///
  /// In es, this message translates to:
  /// **'¡Publicación enviada con éxito!'**
  String get publicacionExitosa;

  /// No description provided for @errorPublicar.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error al publicar'**
  String get errorPublicar;

  /// No description provided for @versionApp.
  ///
  /// In es, this message translates to:
  /// **'Versión de la App'**
  String get versionApp;

  /// No description provided for @estadoConexion.
  ///
  /// In es, this message translates to:
  /// **'Estado de Conexión'**
  String get estadoConexion;

  /// No description provided for @estadoDesconectado.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión'**
  String get estadoDesconectado;

  /// No description provided for @usuarioLogueado.
  ///
  /// In es, this message translates to:
  /// **'Usuario logueado'**
  String get usuarioLogueado;

  /// No description provided for @correoUsuario.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get correoUsuario;

  /// No description provided for @conectado.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get conectado;

  /// No description provided for @desconectado.
  ///
  /// In es, this message translates to:
  /// **'Desconectado'**
  String get desconectado;

  /// No description provided for @correoElectronico.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get correoElectronico;

  /// No description provided for @cambiosGuardados.
  ///
  /// In es, this message translates to:
  /// **'Cambios guardados correctamente.'**
  String get cambiosGuardados;

  /// No description provided for @activarNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'Activar notificaciones cuando alguien publique'**
  String get activarNotificaciones;

  /// No description provided for @guardarCambios.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get guardarCambios;

  /// No description provided for @alarmaVecinal.
  ///
  /// In es, this message translates to:
  /// **'Alarma Vecinal'**
  String get alarmaVecinal;

  /// No description provided for @activarAlarmaVecinal.
  ///
  /// In es, this message translates to:
  /// **'ACTIVAR ALARMA VECINAL'**
  String get activarAlarmaVecinal;

  /// No description provided for @telefonosEmergencia.
  ///
  /// In es, this message translates to:
  /// **'Teléfonos de Emergencia'**
  String get telefonosEmergencia;

  /// No description provided for @carabineros.
  ///
  /// In es, this message translates to:
  /// **'Carabineros de Chile'**
  String get carabineros;

  /// No description provided for @bomberos.
  ///
  /// In es, this message translates to:
  /// **'Bomberos'**
  String get bomberos;

  /// No description provided for @samu.
  ///
  /// In es, this message translates to:
  /// **'SAMU'**
  String get samu;

  /// No description provided for @llamar.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get llamar;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
