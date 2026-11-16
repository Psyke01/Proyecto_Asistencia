import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera un código institucional único garantizando que no se repita en Firestore
  static Future<String> generarCodigoUnico(String rol) async {
    final String prefijo = rol == 'Docente' ? 'DOC' : 'EST';
    final int anio = DateTime.now().year;

    while (true) {
      // Genera un número aleatorio de 4 dígitos (entre 1000 y 9999)
      final int numero = Random().nextInt(9000) + 1000;
      final String codigoGenerado = '$prefijo-$anio$numero';

      // Valida en Firestore que no exista otro usuario con ese mismo código
      final query = await _db
          .collection('usuarios')
          .where('codigoMatricula', isEqualTo: codigoGenerado)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return codigoGenerado;
      }
    }
  }

  /// Registro de usuario en Firebase Auth y Firestore con generación automática de código
  static Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String facultad,
    String? codigoMatricula,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );

      final String uid = credential.user!.uid;

      // Si no se proporcionó código, el sistema lo genera automáticamente
      final String codigoFinal = (codigoMatricula != null && codigoMatricula.trim().isNotEmpty)
          ? codigoMatricula.trim().toUpperCase()
          : await generarCodigoUnico(rol);

      Usuario nuevoUsuario = Usuario(
        uid: uid,
        nombre: nombre,
        correo: correo,
        rol: rol,
        codigoMatricula: codigoFinal,
        facultad: facultad,
      );

      try {
        await _db.collection('usuarios').doc(uid).set(nuevoUsuario.toMap());
      } catch (dbError) {
        debugPrint('Error al guardar usuario en Firestore: $dbError');
        return {
          'exito': false,
          'error': 'Cuenta creada en autenticación, pero hubo un error en Firestore: $dbError',
        };
      }

      return {
        'exito': true,
        'codigoAsignado': codigoFinal,
      };
    } on FirebaseAuthException catch (e) {
      String mensaje = e.message ?? 'Error al registrar la cuenta.';
      if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        mensaje = 'Este correo ya está registrado.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo no es válido.';
      }
      return {'exito': false, 'error': mensaje};
    } catch (e) {
      debugPrint('Error inesperado en registrarUsuario: $e');
      return {
        'exito': false,
        'error': 'Ocurrió un error inesperado al conectar con Firebase: $e',
      };
    }
  }

  /// Genera un código de asignatura único y representativo (ej: PRG-304, SIS-201)
  static String generarCodigoAsignatura(String nombreAsignatura) {
    final palabras = nombreAsignatura
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();

    String prefijo = 'ASG';
    if (palabras.length >= 2) {
      final p1 = palabras[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      final p2 = palabras[1].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (p1.length >= 2 && p2.isNotEmpty) {
        prefijo = '${p1.substring(0, 2)}${p2.substring(0, 1)}'.toUpperCase();
      } else if (p1.length >= 3) {
        prefijo = p1.substring(0, 3).toUpperCase();
      }
    } else if (palabras.isNotEmpty) {
      final p = palabras[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
      if (p.length >= 3) {
        prefijo = p.substring(0, 3).toUpperCase();
      }
    }

    final int numero = Random().nextInt(900) + 100; // Número de 3 dígitos (ej: 304, 201)
    return '$prefijo-$numero';
  }

  /// Busca estudiantes en Firestore por código institucional O por nombre
  static Future<List<Usuario>> buscarEstudiantes(String termino) async {
    final queryLimpio = termino.trim().toLowerCase();
    if (queryLimpio.isEmpty) return [];

    try {
      // 1. Primero intentamos buscar por código institucional exacto
      final codigoUpper = termino.trim().toUpperCase();
      var queryCodigo = await _db
          .collection('usuarios')
          .where('codigoMatricula', isEqualTo: codigoUpper)
          .where('rol', isEqualTo: 'Estudiante')
          .limit(5)
          .get();

      if (queryCodigo.docs.isEmpty && !codigoUpper.startsWith('EST-')) {
        queryCodigo = await _db
            .collection('usuarios')
            .where('codigoMatricula', isEqualTo: 'EST-$codigoUpper')
            .where('rol', isEqualTo: 'Estudiante')
            .limit(5)
            .get();
      }

      if (queryCodigo.docs.isNotEmpty) {
        return queryCodigo.docs.map((d) => Usuario.fromMap(d.data())).toList();
      }

      // 2. Si no es por código, buscamos por nombre (filtrando los estudiantes)
      final todosEstudiantes = await _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'Estudiante')
          .limit(50)
          .get();

      final resultados = todosEstudiantes.docs
          .map((d) => Usuario.fromMap(d.data()))
          .where((est) =>
              est.nombre.toLowerCase().contains(queryLimpio) ||
              est.codigoMatricula.toLowerCase().contains(queryLimpio))
          .take(5)
          .toList();

      return resultados;
    } catch (e) {
      debugPrint('Error al buscar estudiantes: $e');
      return [];
    }
  }

  /// Inicio de Sesión
  static Future<Usuario?> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );

    final String uid = credential.user!.uid;
    DocumentSnapshot doc = await _db.collection('usuarios').doc(uid).get();

    if (doc.exists) {
      return Usuario.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      // Auto-reparar si el usuario existe en Auth pero quedó sin documento en Firestore
      Usuario usuarioRecuperado = Usuario(
        uid: uid,
        nombre: credential.user!.displayName ?? correo.split('@')[0],
        correo: correo,
        rol: 'Estudiante',
        codigoMatricula: '',
        facultad: '',
      );
      await _db.collection('usuarios').doc(uid).set(usuarioRecuperado.toMap());
      return usuarioRecuperado;
    }
  }

  /// Verifica el formato del correo y la existencia de la cuenta en Firebase
  static Future<String?> verificarYRecuperarContrasena(String correo) async {
    final bool correoValido = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+')
        .hasMatch(correo);

    if (!correoValido) {
      return 'Por favor ingresa un correo electrónico válido (ejemplo@universidad.edu).';
    }

    try {
      await _auth.sendPasswordResetEmail(email: correo);
      return null; // Éxito
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No existe ninguna cuenta registrada con este correo institucional.';
      } else if (e.code == 'invalid-email') {
        return 'El formato del correo no es válido.';
      }
      return e.message ?? 'Error al procesar la solicitud de recuperación.';
    } catch (e) {
      return 'Ocurrió un error al verificar el correo en la base de datos.';
    }
  }

  /// Cerrar Sesión
  static Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}
