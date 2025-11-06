class Horario {
  final DateTime horaInicio;
  final DateTime horaFin;

  Horario({required this.horaInicio, required this.horaFin});

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      horaInicio: DateTime.parse(json['hora_inicio']),
      horaFin: DateTime.parse(json['hora_fin']),
    );
  }
}

class Jugador {
  final String nombre;
  final int numero;
  final String posicion;
  final int edad;

  Jugador({
    required this.nombre,
    required this.numero,
    required this.posicion,
    required this.edad,
  });

  factory Jugador.fromJson(Map<String, dynamic> json) {
    return Jugador(
      nombre: json['nombre'],
      numero: json['numero'],
      posicion: json['posicion'],
      edad: json['edad'],
    );
  }
}

// En tu archivo: clases.dart

class Partido {
  final String id;
  final String arbitroId;
  final String localId;
  final String visitanteId;
  final String lugar;
  final Map<String, int>? resultado;
  final Horario horario;
  final List<String> notas;
  // --- CAMBIO AQUÍ ---
  // El tipo correcto para los eventos. Las llaves son strings ("0", "1", etc.)
  // y los valores son listas de elementos (strings).
  final Map<String, List<dynamic>>? eventos;

  Partido({
    required this.id,
    required this.arbitroId,
    required this.localId,
    required this.visitanteId,
    required this.lugar,
    required this.resultado,
    required this.horario,
    required this.notas,
    required this.eventos,
  });

  factory Partido.fromJson(Map<String, dynamic> json) {
    return Partido(
      id: json['_id'] ?? '',
      arbitroId: json['arbitro_id'],
      localId: json['local_id'],
      visitanteId: json['visitante_id'],
      lugar: json['lugar'],
      resultado:
          json['resultado'] != null ? Map<String, int>.from(json['resultado']) : null,
      horario: Horario.fromJson(json['horario']),
      notas: (json['notas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      // --- Y CAMBIO AQUÍ ---
      eventos:
          json['eventos'] != null
              ? Map<String, List<dynamic>>.from(json['eventos'])
              : null,
    );
  }
}

class Liga {
  final String id;
  final String nombre;
  final String reglasId;
  final List<Horario> temporada;
  final List<String> arbitros;
  final List<String> directores;
  final List<String> equipos;
  final List<String> partidos;
  final String? fase;
  bool esFavorita;

  Liga({
    required this.id,
    required this.nombre,
    required this.reglasId,
    required this.temporada,
    required this.arbitros,
    required this.directores,
    required this.equipos,
    required this.partidos,
    this.fase,
    this.esFavorita = false,
  });

  factory Liga.fromJson(Map<String, dynamic> json) {
    return Liga(
      id: json['_id'] ?? '',
      nombre: json['nombre'],
      reglasId: json['reglas_id'],
      temporada: (json['temporada'] as List).map((e) => Horario.fromJson(e)).toList(),
      arbitros: List<String>.from(json['arbitros'] ?? []),
      directores: List<String>.from(json['directores'] ?? []),
      equipos: List<String>.from(json['equipos'] ?? []),
      partidos: List<String>.from(json['partidos'] ?? []),
      fase: json['fase'],
    );
  }
}

class Reglas {
  final String id;
  final String deporte;
  final int duracionTotal;
  final int numPorEquipo;
  final Map<String, int> anotaciones;
  final Map<String, String> faltas;
  final List<String>? notas;
  final String tipoDuracion;

  Reglas({
    required this.id,
    required this.deporte,
    required this.duracionTotal,
    required this.numPorEquipo,
    required this.anotaciones,
    required this.faltas,
    this.notas,
    required this.tipoDuracion,
  });

  factory Reglas.fromJson(Map<String, dynamic> json) {
    return Reglas(
      id: json['_id'] ?? '',
      deporte: json['deporte'],
      duracionTotal: json['duracion_total'],
      numPorEquipo: json['num_por_equipo'],
      anotaciones: Map<String, int>.from(json['anotaciones']),
      faltas: Map<String, String>.from(json['faltas']),
      notas: (json['notas'] as List?)?.map((e) => e.toString()).toList(),
      tipoDuracion: json['tipo_duracion'],
    );
  }
}

class Equipo {
  final String id;
  final String nombre;
  final String? directorId;
  List<Jugador>? jugadores;
  final dynamic posicion;
  final int puntosLiga;
  final int partidosGanados;
  final int partidosPerdidos;
  final int partidosEmpatados;

  Equipo({
    required this.id,
    required this.nombre,
    this.directorId,
    this.jugadores,
    required this.posicion,
    required this.puntosLiga,
    required this.partidosGanados,
    required this.partidosPerdidos,
    required this.partidosEmpatados,
  });

  factory Equipo.fromJson(Map<String, dynamic> json) {
    return Equipo(
      id: json['_id'] ?? '',
      nombre: json['nombre'],
      directorId: json['director_id'],
      jugadores: (json['jugadores'] as List?)?.map((j) => Jugador.fromJson(j)).toList(),
      posicion: json['posicion'],
      puntosLiga: json['puntos_liga'],
      partidosGanados: json['partidos_ganados'],
      partidosPerdidos: json['partidos_perdidos'],
      partidosEmpatados: json['partidos_empatados'],
    );
  }
}

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String rol;
  final List<String> equipoFav;
  final List<String> ligasFav;

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.equipoFav = const [],
    this.ligasFav = const [],
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? '',
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'],
      equipoFav: List<String>.from(json['equipoFav'] ?? []),
      ligasFav: List<String>.from(json['ligasFav'] ?? []),
    );
  }
}

class Admin extends Usuario {
  final String telefono;
  final List<String> ligas;

  Admin({
    required super.id,
    required super.nombre,
    required super.correo,
    required super.rol,
    required this.telefono,
    this.ligas = const [],
  }) : super(equipoFav: const [], ligasFav: const []);

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'],
      telefono: json['telefono'],
      ligas: List<String>.from(json['ligas'] ?? []),
    );
  }
}

class Arbitro extends Usuario {
  final String telefono;
  final String certificacion;

  Arbitro({
    required super.id,
    required super.nombre,
    required super.correo,
    required super.rol,
    required this.telefono,
    required this.certificacion,
  }) : super(equipoFav: const [], ligasFav: const []);

  factory Arbitro.fromJson(Map<String, dynamic> json) {
    return Arbitro(
      id: json['id'] ?? '',
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'],
      telefono: json['telefono'],
      certificacion: json['certificacion'],
    );
  }
}

class Director extends Usuario {
  final String telefono;

  Director({
    required super.id,
    required super.nombre,
    required super.correo,
    required super.rol,
    required this.telefono,
  }) : super(equipoFav: const [], ligasFav: const []);

  factory Director.fromJson(Map<String, dynamic> json) {
    return Director(
      id: json['id'] ?? '',
      nombre: json['nombre'],
      correo: json['correo'],
      rol: json['rol'],
      telefono: json['telefono'],
    );
  }
}
