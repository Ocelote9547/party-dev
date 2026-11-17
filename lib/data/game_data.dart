// ignore_for_file: list_element_type_not_assignable, unnecessary_const
import 'dart:math';

class GameData {
  GameData._();

  static final _random = Random();

  static T randomFrom<T>(List<T> list) => list[_random.nextInt(list.length)];

  // ─── IMPOSTOR ────────────────────────────────────────────────

  static const impostorPairs = [
    _ImpostorPair(word: 'Playa', fake: 'Piscina', hint: 'Playa'),
    _ImpostorPair(word: 'Restaurante', fake: 'Cafetería', hint: 'Restaurante'),
    _ImpostorPair(
      word: 'Aeropuerto',
      fake: 'Estación de tren',
      hint: 'Aeropuerto',
    ),
    _ImpostorPair(word: 'Hospital', fake: 'Farmacia', hint: 'Hospital'),
    _ImpostorPair(word: 'Cine', fake: 'Teatro', hint: 'Cine'),
    _ImpostorPair(
      word: 'Supermercado',
      fake: 'Tienda de barrio',
      hint: 'Mercado',
    ),
    _ImpostorPair(
      word: 'Gimnasio',
      fake: 'Parque de calistenia',
      hint: 'Ejercicio',
    ),
    _ImpostorPair(word: 'Biblioteca', fake: 'Librería', hint: 'Lectura'),
    _ImpostorPair(word: 'Zoo', fake: 'Granja', hint: 'Animales'),
    _ImpostorPair(word: 'Discoteca', fake: 'Bar', hint: 'Música'),
    _ImpostorPair(word: 'Castillo', fake: 'Museo', hint: 'Antiguo'),
    _ImpostorPair(word: 'Avión', fake: 'Helicóptero', hint: 'Vuelo'),
    _ImpostorPair(word: 'Faro', fake: 'Torre de control', hint: 'Costa'),
    _ImpostorPair(word: 'Desierto', fake: 'Playa', hint: 'Arena'),
    _ImpostorPair(word: 'Volcán', fake: 'Montaña', hint: 'Lava'),
    _ImpostorPair(word: 'Sastrería', fake: 'Tienda de ropa', hint: 'Trajes'),
    _ImpostorPair(word: 'Relojería', fake: 'Joyería', hint: 'Tiempo'),
    _ImpostorPair(word: 'Panadería', fake: 'Pastelería', hint: 'Horno'),
    _ImpostorPair(word: 'Peluquería', fake: 'Spa', hint: 'Corte'),
    _ImpostorPair(word: 'Embajada', fake: 'Consulado', hint: 'País'),
    _ImpostorPair(word: 'Estadio', fake: 'Polideportivo', hint: 'Partido'),
    _ImpostorPair(
      word: 'Parque de atracciones',
      fake: 'Feria',
      hint: 'Diversión',
    ),
    _ImpostorPair(word: 'Oficina', fake: 'Despacho', hint: 'Trabajo'),
    _ImpostorPair(word: 'Cárcel', fake: 'Fortaleza', hint: 'Prisión'),
    _ImpostorPair(word: 'Acuario', fake: 'Zoo marino', hint: 'Agua'),
    _ImpostorPair(word: 'Jardín botánico', fake: 'Parque', hint: 'Plantas'),
    _ImpostorPair(word: 'Taberna', fake: 'Restaurante', hint: 'Vino'),
    _ImpostorPair(word: 'Carnicería', fake: 'Mercado', hint: 'Carne'),
    _ImpostorPair(word: 'Fontanería', fake: 'Taller', hint: 'Tubería'),
    _ImpostorPair(
      word: 'Carpintería',
      fake: 'Taller de artesanía',
      hint: 'Madera',
    ),
    _ImpostorPair(word: 'Mercado', fake: 'Supermercado', hint: 'Fresco'),
    _ImpostorPair(
      word: 'Farmacia',
      fake: 'Tienda de cosméticos',
      hint: 'Medicina',
    ),
    _ImpostorPair(word: 'Tren', fake: 'Autobús', hint: 'Raíles'),
    _ImpostorPair(word: 'Barco', fake: 'Velero', hint: 'Mar'),
    _ImpostorPair(word: 'Iglesia', fake: 'Capilla', hint: 'Oración'),
    _ImpostorPair(word: 'Museo', fake: 'Galería', hint: 'Arte'),
    _ImpostorPair(word: 'Hotel', fake: 'Hostal', hint: 'Habitación'),
    _ImpostorPair(word: 'Banco', fake: 'Cajero', hint: 'Dinero'),
    _ImpostorPair(word: 'Cocina', fake: 'Restaurante', hint: 'Cocinar'),
    _ImpostorPair(word: 'Garaje', fake: 'Taller', hint: 'Coche'),
    _ImpostorPair(word: 'Sótano', fake: 'Ático', hint: 'Oscuro'),
    _ImpostorPair(word: 'Azotea', fake: 'Terraza', hint: 'Altura'),
    _ImpostorPair(word: 'Escaleras', fake: 'Ascensor', hint: 'Subir'),
    _ImpostorPair(word: 'Puente', fake: 'Viaducto', hint: 'Río'),
    _ImpostorPair(word: 'Plaza', fake: 'Parque', hint: 'Centro'),
    _ImpostorPair(word: 'Fuente', fake: 'Chorrito', hint: 'Pública'),
    _ImpostorPair(word: 'Estatua', fake: 'Monumento', hint: 'Piedra'),
    _ImpostorPair(word: 'Ferretería', fake: 'Taller', hint: 'Herramientas'),
    _ImpostorPair(word: 'Mirador', fake: 'Terraza', hint: 'Vistas'),
    _ImpostorPair(word: 'Cueva', fake: 'Sótano', hint: 'Oscuridad'),
    _ImpostorPair(word: 'Lago', fake: 'Piscina', hint: 'Dulce'),
    _ImpostorPair(word: 'Bosque', fake: 'Parque', hint: 'Árboles'),
    _ImpostorPair(word: 'Montaña', fake: 'Colina', hint: 'Pico'),
    _ImpostorPair(word: 'Río', fake: 'Canal', hint: 'Corriente'),
    _ImpostorPair(word: 'Isla', fake: 'Península', hint: 'Rodeada'),
    _ImpostorPair(word: 'Nube', fake: 'Niebla', hint: 'Cielo'),
    _ImpostorPair(word: 'Trueno', fake: 'Relámpago', hint: 'Ruido'),
    _ImpostorPair(word: 'Viento', fake: 'Brisa', hint: 'Soplar'),
    _ImpostorPair(word: 'Lluvia', fake: 'Granizo', hint: 'Gotas'),
    _ImpostorPair(word: 'Nieve', fake: 'Escarcha', hint: 'Frío'),
    _ImpostorPair(word: 'Escuela', fake: 'Instituto', hint: 'Estudiar'),
    _ImpostorPair(word: 'Piscina', fake: 'Lago', hint: 'Cloro'),
    _ImpostorPair(word: 'Cementerio', fake: 'Iglesia', hint: 'Silencio'),
    _ImpostorPair(word: 'Sauna', fake: 'Hammam', hint: 'Sudor'),
    _ImpostorPair(word: 'Observatorio', fake: 'Planetario', hint: 'Estrellas'),
    _ImpostorPair(word: 'Academia de baile', fake: 'Gimnasio', hint: 'Pasos'),
    _ImpostorPair(word: 'Puesto de mercado', fake: 'Tienda', hint: 'Puesto'),
    _ImpostorPair(word: 'Templo budista', fake: 'Templo hindú', hint: 'Monjes'),
    _ImpostorPair(
      word: 'Central nuclear',
      fake: 'Central eléctrica',
      hint: 'Radiación',
    ),
    _ImpostorPair(word: 'Granja', fake: 'Huerto', hint: 'Cerdos'),
    _ImpostorPair(word: 'Casa embrujada', fake: 'Cueva', hint: 'Fantasma'),
    _ImpostorPair(word: 'Universidad', fake: 'Instituto', hint: 'Estudios'),
    _ImpostorPair(word: 'Teatro', fake: 'Cine', hint: 'Escenario'),
    _ImpostorPair(word: 'Piscina', fake: 'Playa', hint: 'Baño'),
    _ImpostorPair(word: 'Helicóptero', fake: 'Avión', hint: 'Hélice'),
    _ImpostorPair(word: 'Castillo', fake: 'Palacio', hint: 'Rey'),
    _ImpostorPair(word: 'Mercado', fake: 'Supermercado', hint: 'Puestos'),
    _ImpostorPair(word: 'Taller', fake: 'Garaje', hint: 'Reparar'),
    _ImpostorPair(word: 'Parque', fake: 'Jardín', hint: 'Verde'),
    _ImpostorPair(word: 'Estadio', fake: 'Campo', hint: 'Fútbol'),
    _ImpostorPair(word: 'Biblioteca', fake: 'Librería', hint: 'Libros'),
    _ImpostorPair(word: 'Puerto', fake: 'Aeropuerto', hint: 'Viaje'),
    _ImpostorPair(word: 'Catedral', fake: 'Iglesia', hint: 'Cruz'),
    _ImpostorPair(word: 'Hotel', fake: 'Hostal', hint: 'Turismo'),
    _ImpostorPair(word: 'Restaurante', fake: 'Bar', hint: 'Mesa'),
    _ImpostorPair(word: 'Gimnasio', fake: 'CrossFit', hint: 'Pesas'),
    _ImpostorPair(word: 'Safari', fake: 'Zoo', hint: 'León'),
    _ImpostorPair(word: 'Desierto', fake: 'Sahara', hint: 'Dunas'),
    _ImpostorPair(word: 'Volcán', fake: 'Montaña', hint: 'Fuego'),
    _ImpostorPair(word: 'Río', fake: 'Canal', hint: 'Agua'),
    _ImpostorPair(word: 'Isla', fake: 'Península', hint: 'Mar'),
    _ImpostorPair(word: 'Nieve', fake: 'Hielo', hint: 'Frío'),
    _ImpostorPair(word: 'Bosque', fake: 'Selva', hint: 'Troncos'),
    _ImpostorPair(word: 'Faro', fake: 'Torre', hint: 'Luz'),
    _ImpostorPair(word: 'Cueva', fake: 'Mina', hint: 'Oscura'),
    _ImpostorPair(word: 'Plaza mayor', fake: 'Mercado', hint: 'Piedra'),
    _ImpostorPair(word: 'Fábrica', fake: 'Taller', hint: 'Máquinas'),
    _ImpostorPair(word: 'Colegio', fake: 'Academia', hint: 'Clases'),
    _ImpostorPair(
      word: 'Hospital veterinario',
      fake: 'Hospital',
      hint: 'Animales',
    ),
    _ImpostorPair(word: 'Museo de cera', fake: 'Museo', hint: 'Figuras'),
    _ImpostorPair(word: 'Planetario', fake: 'Observatorio', hint: 'Planetas'),
  ];

  // ─── ADIVINA (por categorías) ─────────────────────────────────

  static const adivinaCategories = {
    'ANIMALES': [
      AdivinaWord(
        word: 'Elefante',
        clue: 'El terrestre más grande, tiene trompa.',
      ),
      AdivinaWord(
        word: 'Jirafa',
        clue: 'El más alto, tiene cuello largo y manchas.',
      ),
      AdivinaWord(
        word: 'Pingüino',
        clue: 'Pájaro que no vuela, vive en el hielo y viste de etiqueta.',
      ),
      AdivinaWord(
        word: 'Delfín',
        clue: 'Mamífero marino, muy inteligente y juguetón.',
      ),
      AdivinaWord(
        word: 'Canguro',
        clue: 'Tiene bolsa, salta alto y vive en Australia.',
      ),
      AdivinaWord(
        word: 'Pulpo',
        clue: 'Marino, tiene 8 brazos y cambia de color.',
      ),
      AdivinaWord(
        word: 'Águila',
        clue: 'Rapaz majestuosa, symbol de fuerza y vista aguda.',
      ),
      AdivinaWord(
        word: 'Serpiente',
        clue: 'Reptil sin patas, se arrastra y puede ser venenosa.',
      ),
      AdivinaWord(
        word: 'Ballena',
        clue: 'El animal más grande del mundo, vive en el océano.',
      ),
      AdivinaWord(
        word: 'León',
        clue: 'Rey de la selva, tiene melena y rugido fuerte.',
      ),
      AdivinaWord(
        word: 'Tortuga',
        clue: 'Lenta, lleva caparazón y puede vivir mucho tiempo.',
      ),
      AdivinaWord(
        word: 'Lobo',
        clue: 'Canino salvaje, aúlla a la luna y vive en manada.',
      ),
      AdivinaWord(
        word: 'Oso polar',
        clue: 'Blanco, vive en el Ártico y le gusta el pescado.',
      ),
      AdivinaWord(word: 'Cebra', clue: 'Caballo con rayas blancas y negras.'),
      AdivinaWord(
        word: 'Rinoceronte',
        clue: 'Grande, tiene cuerno en la nariz y piel gruesa.',
      ),
      AdivinaWord(
        word: 'Camello',
        clue: 'Robusto del desierto, carga mercancías y tiene jorobas.',
      ),
      AdivinaWord(
        word: 'Koala',
        clue: 'Bolsillo australiano, duerme en eucalipto y es fofo.',
      ),
      AdivinaWord(
        word: 'Tiburón',
        clue: 'Depredador del océano, tiene muchos dientes y aleta.',
      ),
      AdivinaWord(
        word: 'Mono',
        clue: 'Primate ágil, trepa árboles y come plátanos.',
      ),
      AdivinaWord(
        word: 'Zorro',
        clue: 'Raposo astuto, pelaje rojizo y cola esponjosa.',
      ),
      AdivinaWord(
        word: 'Hipopótamo',
        clue: 'Pesado africano, vive en ríos y tiene mandíbula grande.',
      ),
      AdivinaWord(
        word: 'Gato',
        clue: 'Felino doméstico, ronronea y es muy independiente.',
      ),
      AdivinaWord(
        word: 'Conejo',
        clue: 'Zancos cortos, orejas largas y salta.',
      ),
      AdivinaWord(
        word: 'Camaleón',
        clue: 'Reptil que cambia de color y tiene lengua larguísima.',
      ),
      AdivinaWord(
        word: 'Murciélago',
        clue: 'Sale de noche, vuela y se guía por ecos.',
      ),
      AdivinaWord(
        word: 'Pavo real',
        clue: 'Ave que abre su cola de colores como un abanico.',
      ),
      AdivinaWord(
        word: 'Nutria',
        clue: 'Le encanta el agua y flota de espaldas con su comida.',
      ),
      AdivinaWord(
        word: 'Ornitorrinco',
        clue: 'Pone huevos, tiene pico de pato y es australiano.',
      ),
      AdivinaWord(
        word: 'Lémur',
        clue: 'De Madagascar, tiene cola rayada y ojos grandes.',
      ),
      AdivinaWord(
        word: 'Flamenco',
        clue: 'Rosa, se para en una pata y duerme de pie.',
      ),
      AdivinaWord(
        word: 'Cangrejo',
        clue: 'Camina de lado, tiene pinzas y vive entre arena y rocas.',
      ),
      AdivinaWord(
        word: 'Gorila',
        clue: 'Primate gigante de espalda plateada y muy fuerte.',
      ),
      AdivinaWord(
        word: 'Panda',
        clue: 'Blanco y negro, come bambú y vive en China.',
      ),
      AdivinaWord(
        word: 'Leopardo',
        clue: 'Felino moteado que trepa árboles con su presa.',
      ),
      AdivinaWord(
        word: 'Guepardo',
        clue: 'El terrestre más rápido, manchas y lágrimas negras.',
      ),
      AdivinaWord(
        word: 'Búho',
        clue: 'Ave nocturna que gira la cabeza y ulula.',
      ),
      AdivinaWord(
        word: 'Colibrí',
        clue: 'Pajarito diminuto que bate alas rapidísimo y toma néctar.',
      ),
      AdivinaWord(
        word: 'Tucán',
        clue: 'Pico enorme y colorido de la selva tropical.',
      ),
      AdivinaWord(
        word: 'Cocodrilo',
        clue: 'Reptil gigante de mandíbulas enormes, vive en ríos.',
      ),
      AdivinaWord(
        word: 'Iguana',
        clue: 'Reptil verde que toma el sol y mueve papada.',
      ),
      AdivinaWord(
        word: 'Puma',
        clue: 'Felino americano sigiloso, también llamado león de montaña.',
      ),
      AdivinaWord(
        word: 'Jaguar',
        clue: 'Felino americano moteado, mordida muy potente.',
      ),
      AdivinaWord(
        word: 'Oso pardo',
        clue: 'Gran oso marrón que hiberna en cuevas.',
      ),
      AdivinaWord(
        word: 'Llama',
        clue: 'Camélido andino que escupe y lleva carga.',
      ),
      AdivinaWord(
        word: 'Avestruz',
        clue: 'Ave gigante que no vuela y pone huevos enormes.',
      ),
      AdivinaWord(
        word: 'Erizo',
        clue: 'Pequeño mamífero lleno de púas que se hace bola.',
      ),
      AdivinaWord(
        word: 'Ardilla',
        clue: 'Roedor de cola esponjosa que guarda nueces.',
      ),
      AdivinaWord(
        word: 'Mapache',
        clue: 'Antifaz negro, lava su comida y es nocturno.',
      ),
      AdivinaWord(
        word: 'Castor',
        clue: 'Roedor que construye diques con madera.',
      ),
      AdivinaWord(
        word: 'Suricata',
        clue: 'Pequeño de pie alerta que vigila en grupo.',
      ),
      AdivinaWord(
        word: 'Axolote',
        clue: 'Ajolote mexicano que nunca deja de ser larva.',
      ),
      AdivinaWord(
        word: 'Quokka',
        clue: 'Marsupial sonriente de Australia muy fotogénico.',
      ),
      AdivinaWord(
        word: 'Kiwi',
        clue: 'Ave nocturna de Nueva Zelanda sin alas visibles.',
      ),

      AdivinaWord(
        word: 'Ocelote',
        clue: 'Felino moteado pequeño, primo del jaguar. ',
      ),
      AdivinaWord(
        word: 'Alce',
        clue: 'Cérvido gigante con astas en forma de pala. ',
      ),
      AdivinaWord(
        word: 'Bisonte',
        clue: 'Bovino peludo que galopa en praderas norteñas. ',
      ),
      AdivinaWord(
        word: 'Hiena',
        clue: 'Ríe fuerte y caza en la sabana africana. ',
      ),
      AdivinaWord(
        word: 'Okapi',
        clue: 'Primo rayado de la jirafa que vive en selva del Congo. ',
      ),
      AdivinaWord(
        word: 'Tapir',
        clue: 'Hocico alargado y cuerpo robusto de selva tropical. ',
      ),
      AdivinaWord(
        word: 'Caracal',
        clue: 'Felino con orejas de pinceles y salto altísimo. ',
      ),
      AdivinaWord(
        word: 'Serval',
        clue: 'Moteado de patas larguísimas y orejas enormes. ',
      ),
      AdivinaWord(
        word: 'Gacela',
        clue: 'Antílope ligero que brinca elegante en sabana. ',
      ),
      AdivinaWord(
        word: 'Cóndor',
        clue: 'Ave andina gigante que planea en alturas. ',
      ),
      AdivinaWord(
        word: 'Guacamayo',
        clue: 'Loro grande y colorido de pico curvo. ',
      ),
      AdivinaWord(
        word: 'Cacatúa',
        clue: 'Cresta blanca y grito estridente de Oceanía. ',
      ),
      AdivinaWord(word: 'Pelícano', clue: 'Bolsa bajo el pico para pescar. '),
      AdivinaWord(
        word: 'Albatros',
        clue: 'Alas enormes que planea océanos sin batir. ',
      ),
      AdivinaWord(
        word: 'Foca',
        clue: 'Bigotes y chapotea con aletas en hielo. ',
      ),
      AdivinaWord(
        word: 'Morsa',
        clue: 'Colmillos largos y bigote en el Ártico. ',
      ),
      AdivinaWord(
        word: 'Orca',
        clue: 'Blanco y negro, cazadora inteligente del mar. ',
      ),
      AdivinaWord(
        word: 'Narval',
        clue: 'Unicornio marino con colmillo en espiral. ',
      ),
      AdivinaWord(word: 'Cobra', clue: 'Capucha desplegada y veneno rápido. '),
      AdivinaWord(
        word: 'Anaconda',
        clue: 'Constrictora gigante de ríos amazónicos. ',
      ),
      AdivinaWord(
        word: 'Tarántula',
        clue: 'Peluda de ocho patas y colmillos grandes. ',
      ),
      AdivinaWord(word: 'Escorpión', clue: 'Pinzas y cola con aguijón curvo. '),
      AdivinaWord(
        word: 'Chinchilla',
        clue: 'Gris suave andina de orejas redondas. ',
      ),
      AdivinaWord(word: 'Dromedario', clue: 'Una joroba y desierto arábigo. '),
      AdivinaWord(word: 'Manatí', clue: 'Vaca marina lenta y herbívora. '),
      AdivinaWord(word: 'Beluga', clue: 'Blanca cantarina del Ártico. '),
      AdivinaWord(
        word: 'Salamandra',
        clue: 'Anfibio moteado que regenera cola. ',
      ),
      AdivinaWord(word: 'Capibara', clue: 'Roedor gigante que nadar y es muy sociable.'),
      AdivinaWord(word: 'Tigre', clue: 'Rayas negras y naranjas, sigiloso cazador asiático.'),
      AdivinaWord(word: 'Oso hormiguero', clue: 'Hocico largo que lame hormigas con lengua pegajosa.'),
      AdivinaWord(word: 'Perezoso', clue: 'Lento colgado de rama y sonríe siempre.'),
      AdivinaWord(word: 'Wombat', clue: 'Marsupial rechoncho que hace cacas cúbicas.'),
      AdivinaWord(word: 'Ajolote', clue: 'Sonríe bajo agua y regenera extremidades.'),
      AdivinaWord(word: 'Mantis', clue: 'Insecto que reza y caza con patas delanteras.'),
      AdivinaWord(word: 'Luciernaga', clue: 'Cola que brilla de noche en verano.'),
      AdivinaWord(word: 'Medusa', clue: 'Campana gelatinosa que flota y pica.'),
      AdivinaWord(word: 'Coral cerebro', clue: 'Colonia marina con surcos como cerebro.'),
      AdivinaWord(word: 'Búfalo', clue: 'Bovino con cuernos curvos de sabana.'),
      AdivinaWord(word: 'Chimpancé', clue: 'Primate que usa herramientas y ríe.'),
      AdivinaWord(word: 'Gibón', clue: 'Brazos larguísimos que se balancea cantando.'),
      AdivinaWord(word: 'Pangolín', clue: 'Escamas que se hace bola ante peligro.'),
      AdivinaWord(word: 'Tucán toco', clue: 'Pico naranja enorme y hueco por dentro.'),
      AdivinaWord(word: 'Emú', clue: 'Ave australiana que corre y no vuela.'),
      AdivinaWord(word: 'Kiwi ave', clue: 'No confundir fruta, ave nocturna sin cola.'),
      AdivinaWord(word: 'Dingo', clue: 'Perro salvaje amarillento de Australia.'),
      AdivinaWord(word: 'Carpincho', clue: 'Otro nombre de capibara en sur, roedor de río.'),
      AdivinaWord(word: 'Urial', clue: 'Cabra salvaje de cuernos curvados asiática.'),
    ],
    'PROFESIONES': [
      AdivinaWord(
        word: 'Bombero',
        clue: 'Apaga incendios, lleva casco y manguera.',
      ),
      AdivinaWord(
        word: 'Astronauta',
        clue: 'Viaja al espacio, lleva traje especial.',
      ),
      AdivinaWord(
        word: 'Pirata',
        clue: 'Navega el mar, busca tesoros y lleva parche.',
      ),
      AdivinaWord(
        word: 'Mago',
        clue: 'Hace trucos, saca conejos del sombrero.',
      ),
      AdivinaWord(
        word: 'Chef',
        clue: 'Cocina en restaurantes, lleva gorro blanco.',
      ),
      AdivinaWord(
        word: 'Policía',
        clue: 'Protege a la gente, lleva uniforme y grilletes.',
      ),
      AdivinaWord(
        word: 'Doctor',
        clue: 'Cura enfermedades, lleva bata blanca y estetoscopio.',
      ),
      AdivinaWord(
        word: 'Piloto',
        clue: 'Vuela aviones, lleva gafas de sol y capucha.',
      ),
      AdivinaWord(
        word: 'Carpintero',
        clue: 'Trabaja la madera, hace muebles y puertas.',
      ),
      AdivinaWord(
        word: 'Fontanero',
        clue: 'Arregla tuberías, grifos y fugas de agua.',
      ),
      AdivinaWord(
        word: 'Barrendero',
        clue: 'Limpia las calles, usa escoba y carretilla.',
      ),
      AdivinaWord(
        word: 'Carnicero',
        clue: 'Corta y vende carne, trabaja en carnicería.',
      ),
      AdivinaWord(
        word: 'Bailarín',
        clue: 'Se mueve al ritmo, actúa en escenarios y estudios.',
      ),
      AdivinaWord(
        word: 'Pintor',
        clue: 'Usa pincel y lienzo, crea obras de arte.',
      ),
      AdivinaWord(
        word: 'Soldado',
        clue: 'Defiende la patria, lleva uniforme y arma.',
      ),
      AdivinaWord(
        word: 'Albañil',
        clue: 'Construye casas, apila ladrillos y mezcla cemento.',
      ),
      AdivinaWord(
        word: 'Electricista',
        clue: 'Arregla luces y cables, manipula corriente.',
      ),
      AdivinaWord(
        word: 'Veterinario',
        clue: 'Cura enfermedades, pero sus pacientes son animales.',
      ),
      AdivinaWord(
        word: 'Juez',
        clue: 'Dicta sentencias, lleva toga y trabaja en un tribunal.',
      ),
      AdivinaWord(
        word: 'Panadero',
        clue: 'Amasa y hornea, se levanta de madrugada.',
      ),
      AdivinaWord(
        word: 'Buceador',
        clue: 'Explora el fondo del mar con bombona y aletas.',
      ),
      AdivinaWord(
        word: 'Escalador',
        clue: 'Sube montañas o paredes con cuerdas y piolets.',
      ),
      AdivinaWord(
        word: 'Entrenador',
        clue: 'Prepara a atletas, pita y corrige ejercicios.',
      ),
      AdivinaWord(
        word: 'Cantante',
        clue: 'Actúa en un escenario, el público lo aplaude.',
      ),
      AdivinaWord(
        word: 'Sirviente',
        clue: 'Trabaja en una casa, sirve mesas y atiende a la familia.',
      ),
      AdivinaWord(
        word: 'Abogado',
        clue: 'Defiende en juicios y conoce las leyes.',
      ),
      AdivinaWord(word: 'Arquitecto', clue: 'Diseña edificios y hace planos.'),
      AdivinaWord(
        word: 'Ingeniero',
        clue: 'Calcula estructuras y resuelve problemas técnicos.',
      ),
      AdivinaWord(word: 'Profesor', clue: 'Enseña en clase y pone exámenes.'),
      AdivinaWord(
        word: 'Periodista',
        clue: 'Investiga noticias y escribe reportajes.',
      ),
      AdivinaWord(word: 'Fotógrafo', clue: 'Captura momentos con cámara.'),
      AdivinaWord(
        word: 'Enfermero',
        clue: 'Cuida pacientes y pone inyecciones.',
      ),
      AdivinaWord(word: 'Dentista', clue: 'Cuida dientes y hace empastes.'),
      AdivinaWord(word: 'Peluquero', clue: 'Corta y tiñe el cabello.'),
      AdivinaWord(word: 'Jardinero', clue: 'Cuida plantas y corta el césped.'),
      AdivinaWord(word: 'Granjero', clue: 'Cultiva campo y cría animales.'),
      AdivinaWord(word: 'Pescador', clue: 'Lanza redes y trae peces.'),
      AdivinaWord(
        word: 'Actor',
        clue: 'Interpreta personajes en cine o teatro.',
      ),
      AdivinaWord(
        word: 'Director de cine',
        clue: 'Dirige rodajes y dice ¡acción!',
      ),
      AdivinaWord(word: 'Escritor', clue: 'Crea historias y publica libros.'),
      AdivinaWord(
        word: 'Científico',
        clue: 'Hace experimentos y publica descubrimientos.',
      ),
      AdivinaWord(word: 'DJ', clue: 'Mezcla música y anima fiestas.'),
      AdivinaWord(word: 'Barbero', clue: 'Afeita barbas con navaja.'),
      AdivinaWord(word: 'Mecánico', clue: 'Arregla motores y cambia aceite.'),
      AdivinaWord(word: 'Agricultor', clue: 'Siembra cosechas y usa tractor.'),
      AdivinaWord(
        word: 'Arqueólogo',
        clue: 'Excava ruinas y encuentra fósiles antiguos.',
      ),
      AdivinaWord(word: 'Astrónomo', clue: 'Observa estrellas con telescopio.'),
      AdivinaWord(
        word: 'Cartero',
        clue: 'Reparte cartas puerta a puerta con bolsa al hombro.',
      ),
      AdivinaWord(
        word: 'Notario',
        clue: 'Da fe pública, firma escrituras y testamentos.',
      ),
      AdivinaWord(
        word: 'Traductor',
        clue: 'Convierte textos de un idioma a otro.',
      ),
      AdivinaWord(
        word: 'Psicólogo',
        clue: 'Escucha problemas y analiza la mente.',
      ),
      AdivinaWord(
        word: 'Sociólogo',
        clue: 'Estudia la sociedad y sus comportamientos colectivos.',
      ),
      AdivinaWord(
        word: 'Biólogo',
        clue: 'Estudia seres vivos en laboratorio y campo.',
      ),
      AdivinaWord(
        word: 'Químico',
        clue: 'Mezcla probetas y fórmulas en laboratorio.',
      ),
      AdivinaWord(
        word: 'Físico',
        clue: 'Calcula gravedad, energía y partículas.',
      ),
      AdivinaWord(
        word: 'Matemático',
        clue: 'Vive entre números, teoremas y ecuaciones.',
      ),
      AdivinaWord(word: 'Programador', clue: 'Escribe código y depura apps.'),
      AdivinaWord(
        word: 'Diseñador',
        clue: 'Crea logos, carteles y experiencias visuales.',
      ),
      AdivinaWord(
        word: 'Modista',
        clue: 'Cose vestidos a medida con alfileres.',
      ),
      AdivinaWord(
        word: 'Sastre',
        clue: 'Corte impecable de trajes masculinos a medida.',
      ),

      AdivinaWord(
        word: 'Socorrista',
        clue: 'Silbato en playa y rescata bañistas. ',
      ),
      AdivinaWord(
        word: 'Guardaespaldas',
        clue: 'Traje oscuro y protege a famoso. ',
      ),
      AdivinaWord(
        word: 'Cerrajero',
        clue: 'Ganzúa y bombín que abre puertas. ',
      ),
      AdivinaWord(word: 'Joyero', clue: 'Pule gemas y engarza oro en taller. '),
      AdivinaWord(word: 'Pastor', clue: 'Cayado y rebaño con perro guardián. '),
      AdivinaWord(
        word: 'Minero',
        clue: 'Casco con luz y extrae carbón bajo tierra. ',
      ),
      AdivinaWord(word: 'Topógrafo', clue: 'Mide terrenos con trípode láser. '),
      AdivinaWord(word: 'Locutor', clue: 'Voz en radio y presenta noticias. '),
      AdivinaWord(
        word: 'Croupier',
        clue: 'Reparte cartas y gira ruleta en casino. ',
      ),
      AdivinaWord(
        word: 'Sommelier',
        clue: 'Cata vinos y recomienda maridaje. ',
      ),
      AdivinaWord(
        word: 'Geólogo',
        clue: 'Martillo y estudia rocas terrestres. ',
      ),
      AdivinaWord(word: 'Filósofo', clue: 'Piensa existir y escribe teorías. '),
      AdivinaWord(
        word: 'Editor',
        clue: 'Corrige manuscritos y publica textos. ',
      ),
      AdivinaWord(
        word: 'Influencer',
        clue: 'Reels y canjes que recomienda productos. ',
      ),
      AdivinaWord(
        word: 'Taxista',
        clue: 'Taxímetro y recorre ciudad con pasajeros. ',
      ),
      AdivinaWord(word: 'Marinero', clue: 'Nudos y navega cubierta de barco. '),
      AdivinaWord(
        word: 'Azafata',
        clue: 'Demostración de chaleco en pasillo aéreo. ',
      ),
      AdivinaWord(word: 'Apicultor', clue: 'Humo y cosecha miel de colmenas. '),
      AdivinaWord(
        word: 'Paleontólogo',
        clue: 'Pincel y desentierra huesos gigantes. ',
      ),
      AdivinaWord(
        word: 'Meteorólogo',
        clue: 'Mapa de isobaras y predice lluvia. ',
      ),
      AdivinaWord(word: 'Leñador', clue: 'Hacha y troncos que corta en bosque.'),
      AdivinaWord(word: 'Relojero', clue: 'Lupa y engranajes que arregla tic tac.'),
      AdivinaWord(word: 'Sastre fino', clue: 'Tiza y cinta métrica para traje perfecto.'),
      AdivinaWord(word: 'Techador', clue: 'Sube a tejados y coloca tejas impermeables.'),
      AdivinaWord(word: 'Vidriero', clue: 'Corta y coloca cristales con ventosa.'),
      AdivinaWord(word: 'Herrero', clue: 'Yunque y martillo forja hierro al rojo.'),
      AdivinaWord(word: 'Alfarero', clue: 'Torno y barro que moldea vasijas.'),
      AdivinaWord(word: 'Pizzero', clue: 'Masa al aire y horno de leña.'),
      AdivinaWord(word: 'Cervecero', clue: 'Lúpulo y fermentación que embotella espuma.'),
      AdivinaWord(word: 'Barista', clue: 'Espuma latte y arte en taza.'),
      AdivinaWord(word: 'Catador', clue: 'Nariz y copa que puntúa aromas.'),
      AdivinaWord(word: 'Guía turístico', clue: 'Paraguas y megáfono que cuenta historia.'),
      AdivinaWord(word: 'Conserje', clue: 'Llaves y portería que abre a todos.'),
      AdivinaWord(word: 'Bibliotecario', clue: 'Silencio y tejuelo que ordena libros.'),
      AdivinaWord(word: 'Repartidor', clue: 'Mochila térmica y bici que entrega rápido.'),
      AdivinaWord(word: 'Tester', clue: 'Prueba apps y reporta fallos.'),
      AdivinaWord(word: 'Community manager', clue: 'Gestiona redes y responde comentarios.'),
      AdivinaWord(word: 'Copywriter', clue: 'Eslogan que vende con pocas palabras.'),
      AdivinaWord(word: 'Scrum master', clue: 'Facilita equipo ágil y quita bloqueos.'),
      AdivinaWord(word: 'Data scientist', clue: 'Python y datos que predice patrones.'),
    ],
    'COMIDA': [
      AdivinaWord(word: 'Pizza', clue: 'Italiana, redonda, con queso y masa.'),
      AdivinaWord(word: 'Sushi', clue: 'Japonés, lleva arroz y pescado crudo.'),
      AdivinaWord(
        word: 'Hamburguesa',
        clue: 'Carne en pan redondo, con lechuga y tomate.',
      ),
      AdivinaWord(
        word: 'Taco',
        clue: 'Mexicano, tortilla rellena de carne y salsa.',
      ),
      AdivinaWord(
        word: 'Croissant',
        clue: 'Francés, masa hojaldrada en forma de luna.',
      ),
      AdivinaWord(
        word: 'Spaghetti',
        clue: 'Pasta italiana larga, con salsa de tomate.',
      ),
      AdivinaWord(
        word: 'Tarta',
        clue: 'Dulce, lleva capas, crema y velas de cumpleaños.',
      ),
      AdivinaWord(word: 'Helado', clue: 'Frío, dulce, en cono o cucurucho.'),
      AdivinaWord(
        word: 'Burrito',
        clue: 'Mexicano, tortilla grande enrollada con relleno.',
      ),
      AdivinaWord(
        word: 'Paella',
        clue: 'Española, arroz con mariscos y azafrán.',
      ),
      AdivinaWord(
        word: 'Ceviche',
        clue: 'Sudamericano, pescado crudo marinado en limón.',
      ),
      AdivinaWord(
        word: 'Ramen',
        clue: 'Japonés, sopa de noodles con huevo y cerdo.',
      ),
      AdivinaWord(
        word: 'Empanada',
        clue: 'Masa rellena y frita o horneada, popular en Latinoamérica.',
      ),
      AdivinaWord(
        word: 'Arepa',
        clue: 'Venezolana o colombiana, maíz plano y dorado.',
      ),
      AdivinaWord(
        word: 'Tiramisú',
        clue: 'Postre italiano con café, cacao y mascarpone.',
      ),
      AdivinaWord(
        word: 'Churros',
        clue: 'Masa frita en forma de estrella, se mojan en chocolate.',
      ),
      AdivinaWord(
        word: 'Guacamole',
        clue: 'Salsa mexicana verde machacada con aguacate.',
      ),
      AdivinaWord(
        word: 'Nachos',
        clue: 'Triángulos de maíz con queso fundido para compartir.',
      ),
      AdivinaWord(
        word: 'Gazpacho',
        clue: 'Sopa andaluza fría de tomate, se toma en verano.',
      ),
      AdivinaWord(
        word: 'Moussaka',
        clue: 'Griego, berenjena con carne y bechamel.',
      ),
      AdivinaWord(
        word: 'Hummus',
        clue: 'Pasta de garbanzos y sésamo, se come con pan.',
      ),
      AdivinaWord(
        word: 'Macarrones',
        clue: 'Pasta corta con agujero, con tomate o queso.',
      ),
      AdivinaWord(
        word: 'Brownie',
        clue: 'Pastel de chocolate denso, a veces con nueces.',
      ),
      AdivinaWord(
        word: 'Lasaña',
        clue: 'Capas de pasta con carne y bechamel al horno.',
      ),
      AdivinaWord(word: 'Risotto', clue: 'Arroz italiano cremoso y caldo.'),
      AdivinaWord(
        word: 'Pad thai',
        clue: 'Noodles tailandeses con cacahuete y lima.',
      ),
      AdivinaWord(
        word: 'Curry',
        clue: 'Guiso especiado indio con salsa espesa.',
      ),
      AdivinaWord(
        word: 'Falafel',
        clue: 'Bolitas fritas de garbanzo y hierbas.',
      ),
      AdivinaWord(
        word: 'Shawarma',
        clue: 'Carne enrollada en pan de pita con salsa.',
      ),
      AdivinaWord(word: 'Kebab', clue: 'Brocheta de carne a la parrilla.'),
      AdivinaWord(
        word: 'Tortilla española',
        clue: 'Patata y huevo cuajado en sartén.',
      ),
      AdivinaWord(
        word: 'Fabada',
        clue: 'Judías blancas asturianas con chorizo.',
      ),
      AdivinaWord(
        word: 'Enchiladas',
        clue: 'Tortillas con salsa picante y queso.',
      ),
      AdivinaWord(
        word: 'Tamales',
        clue: 'Masa de maíz envuelta en hoja y al vapor.',
      ),
      AdivinaWord(
        word: 'Dim sum',
        clue: 'Bocaditos chinos al vapor en cestitas.',
      ),
      AdivinaWord(word: 'Gyros', clue: 'Carne vertical griega en pan pita.'),
      AdivinaWord(
        word: 'Carpaccio',
        clue: 'Finas láminas crudas con aceite y parmesano.',
      ),
      AdivinaWord(
        word: 'Ratatouille',
        clue: 'Verduras francesas al horno y hierbas.',
      ),
      AdivinaWord(
        word: 'Bruschetta',
        clue: 'Pan tostado con tomate y albahaca.',
      ),
      AdivinaWord(
        word: 'Quiche',
        clue: 'Tarta salada francesa con huevo y nata.',
      ),
      AdivinaWord(
        word: 'Canelones',
        clue: 'Tubos de pasta rellenos y gratinados.',
      ),
      AdivinaWord(word: 'Feijoada', clue: 'Guiso brasileño de alubias negras.'),
      AdivinaWord(word: 'Mochi', clue: 'Dulce japonés de arroz pegajoso.'),
      AdivinaWord(
        word: 'Baklava',
        clue: 'Postre de hojaldre con miel y nueces.',
      ),
      AdivinaWord(word: 'Poke', clue: 'Bol hawaiano de pescado crudo y arroz.'),
      AdivinaWord(
        word: 'Goulash',
        clue: 'Guiso húngaro de carne con pimentón.',
      ),
      AdivinaWord(
        word: 'Sashimi',
        clue: 'Láminas finas de pescado crudo japonés sin arroz.',
      ),
      AdivinaWord(
        word: 'Tempura',
        clue: 'Fritura japonesa ligera de verduras y marisco.',
      ),
      AdivinaWord(
        word: 'Udon',
        clue: 'Noodles gruesos japoneses en caldo caliente.',
      ),
      AdivinaWord(
        word: 'Bibimbap',
        clue: 'Bol coreano de arroz con verduras y huevo encima.',
      ),
      AdivinaWord(word: 'Kimchi', clue: 'Col fermentada picante coreana.'),
      AdivinaWord(
        word: 'Quesadilla',
        clue: 'Tortilla mexicana doblada con queso fundido.',
      ),
      AdivinaWord(
        word: 'Pozole',
        clue: 'Sopa mexicana de maíz cacahuazintle y carne.',
      ),
      AdivinaWord(
        word: 'Mole poblano',
        clue: 'Salsa mexicana oscura con chocolate y chiles.',
      ),
      AdivinaWord(
        word: 'Cochinita pibil',
        clue: 'Cerdo yucateco adobado en achiote y hoja de plátano.',
      ),
      AdivinaWord(
        word: 'Poutine',
        clue: 'Patatas canadienses con queso y salsa gravy.',
      ),
      AdivinaWord(
        word: 'Fish and chips',
        clue: 'Pescado rebozado británico con patatas fritas.',
      ),
      AdivinaWord(
        word: 'Clam chowder',
        clue: 'Sopa cremosa de almejas de Nueva Inglaterra.',
      ),
      AdivinaWord(
        word: 'Gumbo',
        clue: 'Guiso criollo de Luisiana con okra y marisco.',
      ),
      AdivinaWord(
        word: 'Jambalaya',
        clue: 'Arroz especiado de Nueva Orleans con carne y marisco.',
      ),

      AdivinaWord(
        word: 'Fondue',
        clue: 'Queso fundido que pinchas con pan largo. ',
      ),
      AdivinaWord(
        word: 'Gyoza',
        clue: 'Empanadilla japonesa al vapor y plancha. ',
      ),
      AdivinaWord(
        word: 'Pho',
        clue: 'Caldo vietnamita con fideos y hierbas frescas. ',
      ),
      AdivinaWord(
        word: 'Tartar',
        clue: 'Carne o pescado crudo picado con yema. ',
      ),
      AdivinaWord(
        word: 'Bao',
        clue: 'Panecillo esponjoso al vapor con relleno. ',
      ),
      AdivinaWord(
        word: 'Couscous',
        clue: 'Sémola norteafricana con verduras. ',
      ),
      AdivinaWord(
        word: 'Onigiri',
        clue: 'Triángulo de arroz envuelto en alga. ',
      ),
      AdivinaWord(
        word: 'Daifuku',
        clue: 'Bola de arroz dulce con relleno de anko. ',
      ),
      AdivinaWord(
        word: 'Croqueta',
        clue: 'Bechamel frita crujiente por fuera. ',
      ),
      AdivinaWord(
        word: 'Escargot',
        clue: 'Caracoles con ajo y mantequilla al horno. ',
      ),
      AdivinaWord(
        word: 'Biryani',
        clue: 'Arroz especiado indio con carne y yogur. ',
      ),
      AdivinaWord(
        word: 'Lahmacun',
        clue: 'Plano turco con carne picada y limón. ',
      ),
      AdivinaWord(
        word: 'Banh mi',
        clue: 'Bocadillo vietnamita crujiente con paté. ',
      ),
      AdivinaWord(
        word: 'Börek',
        clue: 'Hojaldre relleno turco de queso y espinacas. ',
      ),
      AdivinaWord(
        word: 'Chimichurri',
        clue: 'Salsa argentina verde para asados. ',
      ),
      AdivinaWord(
        word: 'Arepa de huevo',
        clue: 'Maíz frito colombiano con huevo dentro. ',
      ),
      AdivinaWord(
        word: 'Tacos al pastor',
        clue: 'Trompo de cerdo con piña y cilantro. ',
      ),
      AdivinaWord(
        word: 'Okonomiyaki',
        clue: 'Tortilla japonesa de col y mayonesa. ',
      ),
      AdivinaWord(
        word: 'Takoyaki',
        clue: 'Bolitas con pulpo y salsa dulce japonesa. ',
      ),
      AdivinaWord(
        word: 'Feuilleté',
        clue: 'Hojaldre francés con crema y fruta. ',
      ),
      AdivinaWord(word: 'Carbonara', clue: 'Pasta con huevo y guanciale sin nata.'),
      AdivinaWord(word: 'Ajo blanco', clue: 'Sopa fría de almendras y ajo malagueña.'),
      AdivinaWord(word: 'Salmorejo', clue: 'Crema cordobesa espesa con huevo y jamón.'),
      AdivinaWord(word: 'Escudella', clue: 'Olla catalana de invierno con galets.'),
      AdivinaWord(word: 'Cachopo', clue: 'Dos filetes con jamón y queso empanados asturiano.'),
      AdivinaWord(word: 'Pulpo a la gallega', clue: 'Patata, pimentón y pulpo tierno.'),
      AdivinaWord(word: 'Migas', clue: 'Pan frito con ajo y chorizo de pastor.'),
      AdivinaWord(word: 'Fideuá', clue: 'Fideos tostados con marisco valenciano.'),
      AdivinaWord(word: 'Arroz negro', clue: 'Tinta de calamar que tiñe grano.'),
      AdivinaWord(word: 'Bacalao al pil pil', clue: 'Salsa emulsionada de ajo y aceite.'),
      AdivinaWord(word: 'Calçots', clue: 'Cebolla dulce a la brasa con romesco.'),
      AdivinaWord(word: 'Esqueixada', clue: 'Bacalao desmigado con tomate y oliva.'),
      AdivinaWord(word: 'Pan tumaca', clue: 'Pan con tomate restregado catalán.'),
      AdivinaWord(word: 'Torrija', clue: 'Pan empapado en leche y frito de Semana Santa.'),
      AdivinaWord(word: 'Crema catalana', clue: 'Natilla quemada con azúcar crujiente.'),
      AdivinaWord(word: 'Pionono', clue: 'Bizcocho enrollado con crema granadino.'),
      AdivinaWord(word: 'Ensaimada', clue: 'Espiral mallorquina espolvoreada.'),
      AdivinaWord(word: 'Sobrasada', clue: 'Untable rojo mallorquín con pimentón.'),
      AdivinaWord(word: 'Morcilla', clue: 'Sangre y arroz embutida negra.'),
      AdivinaWord(word: 'Longaniza', clue: 'Embutido largo curado aragonés.'),
    ],
    'LUGARES': [
      AdivinaWord(
        word: 'Pirámide',
        clue: 'Egipcia, estructura triangular de piedra gigante.',
      ),
      AdivinaWord(
        word: 'Torre Eiffel',
        clue: 'París, torre de hierro, symbol de Francia.',
      ),
      AdivinaWord(
        word: 'Coliseo',
        clue: 'Roma, anfiteatro antiguo donde luchaban gladiadores.',
      ),
      AdivinaWord(
        word: 'Machu Picchu',
        clue: 'Perú, ciudadela en la montaña, incas.',
      ),
      AdivinaWord(
        word: 'Gran Muralla',
        clue: 'China, muralla gigante que se ve desde el espacio.',
      ),
      AdivinaWord(
        word: 'Taj Mahal',
        clue: 'India, palacio blanco de mármol, amor eterno.',
      ),
      AdivinaWord(
        word: 'Big Ben',
        clue: 'Londres, reloj gigante en una torre.',
      ),
      AdivinaWord(
        word: 'Statua de la Libertad',
        clue: 'NY, estatua gigante con antorcha y corona.',
      ),
      AdivinaWord(
        word: 'Sagrada Familia',
        clue: 'Barcelona, templo de Gaudí que nunca se termina.',
      ),
      AdivinaWord(
        word: 'Chichén Itzá',
        clue: 'México, pirámide maya con escalones.',
      ),
      AdivinaWord(
        word: 'Santorini',
        clue: 'Grecia, isla blanca y azul con casas encaladas.',
      ),
      AdivinaWord(
        word: 'Grand Canyon',
        clue: 'USA, cañón enorme tallado por el río Colorado.',
      ),
      AdivinaWord(
        word: 'Angkor Wat',
        clue: 'Camboya, templo budista monumental y antiguo.',
      ),
      AdivinaWord(
        word: 'Petra',
        clue: 'Jordania, ciudad tallada en roca roja.',
      ),
      AdivinaWord(
        word: 'Cataratas del Niágara',
        clue: 'Frontera USA-Canadá, agua gigante y niebla.',
      ),
      AdivinaWord(
        word: 'Kioto',
        clue: 'Japón, templos antiguos y jardines de bambú.',
      ),
      AdivinaWord(
        word: 'Torre de Pisa',
        clue: 'Italia, torre inclinada famosa por no caerse.',
      ),
      AdivinaWord(
        word: 'Ópera de Sídney',
        clue: 'Australia, edificio blanco con forma de velas junto al mar.',
      ),
      AdivinaWord(
        word: 'Muro de Berlín',
        clue: 'Alemania, dividía una ciudad hasta 1989.',
      ),
      AdivinaWord(
        word: 'Lago Baikal',
        clue: 'Rusia, el más profundo y con más agua dulce del mundo.',
      ),
      AdivinaWord(
        word: 'Salar de Uyuni',
        clue: 'Bolivia, espejo gigante de sal en el altiplano.',
      ),
      AdivinaWord(
        word: 'Aurora Boreal',
        clue: 'Luz de colores en el cielo de los polos.',
      ),
      AdivinaWord(
        word: 'Monte Everest',
        clue: 'El pico más alto del mundo, en el Himalaya.',
      ),
      AdivinaWord(
        word: 'Alhambra',
        clue: 'Palacio nazarí rojo en Granada con fuentes.',
      ),
      AdivinaWord(
        word: 'Mezquita de Córdoba',
        clue: 'Bosque de columnas y arcos rojos y blancos.',
      ),
      AdivinaWord(
        word: 'Cristo Redentor',
        clue: 'Estatua gigante con brazos abiertos en Río.',
      ),
      AdivinaWord(
        word: 'Burj Khalifa',
        clue: 'Rascacielos más alto del mundo en Dubái.',
      ),
      AdivinaWord(
        word: 'Capilla Sixtina',
        clue: 'Techo pintado por Miguel Ángel en el Vaticano.',
      ),
      AdivinaWord(
        word: 'Stonehenge',
        clue: 'Círculo de piedras gigantes y misteriosas en Inglaterra.',
      ),
      AdivinaWord(word: 'Monte Fuji', clue: 'Volcán nevado símbolo de Japón.'),
      AdivinaWord(
        word: 'Selva del Amazonas',
        clue: 'Bosque tropical más grande del planeta.',
      ),
      AdivinaWord(
        word: 'Islas Galápagos',
        clue: 'Islas ecuatorianas de tortugas gigantes y Darwin.',
      ),
      AdivinaWord(
        word: 'Cataratas de Iguazú',
        clue: 'Enormes caídas entre Brasil y Argentina.',
      ),
      AdivinaWord(
        word: 'Times Square',
        clue: 'Cruce neoyorquino lleno de pantallas luminosas.',
      ),
      AdivinaWord(
        word: 'Puente de Brooklyn',
        clue: 'Puente colgante icónico de Nueva York.',
      ),
      AdivinaWord(
        word: 'Acrópolis',
        clue: 'Colina de templos griegos sobre Atenas.',
      ),
      AdivinaWord(
        word: 'Palacio de Versalles',
        clue: 'Palacio francés de espejos y jardines inmensos.',
      ),
      AdivinaWord(
        word: 'Kremlin',
        clue: 'Fortaleza roja con cúpulas en Moscú.',
      ),
      AdivinaWord(
        word: 'Golden Gate',
        clue: 'Puente rojo colgante de San Francisco.',
      ),
      AdivinaWord(
        word: 'Desierto de Atacama',
        clue: 'El más árido del mundo en Chile.',
      ),
      AdivinaWord(
        word: 'Fiordos noruegos',
        clue: 'Valles inundados con acantilados y agua.',
      ),
      AdivinaWord(
        word: 'Serengeti',
        clue: 'Sabana africana de migraciones de ñus.',
      ),
      AdivinaWord(
        word: 'Antártida',
        clue: 'Continente blanco de hielo y pingüinos.',
      ),
      AdivinaWord(
        word: 'Sahara',
        clue: 'Desierto gigante de dunas doradas en África.',
      ),
      AdivinaWord(
        word: 'Patagonia',
        clue: 'Sur salvaje de glaciares y viento en Chile y Argentina.',
      ),
      AdivinaWord(
        word: 'Casa Batlló',
        clue: 'Fachada ondulada de Gaudí con balcones de máscara en Barcelona.',
      ),
      AdivinaWord(
        word: 'Park Güell',
        clue: 'Parque de Gaudí con lagarto de mosaico y vistas a la ciudad.',
      ),
      AdivinaWord(
        word: 'Mezquita Azul',
        clue: 'Seis minaretes y azulejos de Iznik en Estambul.',
      ),
      AdivinaWord(
        word: 'Basílica de San Pedro',
        clue: 'Cúpula de Miguel Ángel en el Vaticano.',
      ),
      AdivinaWord(
        word: 'Duomo de Florencia',
        clue: 'Cúpula roja de Brunelleschi que corona la ciudad.',
      ),
      AdivinaWord(
        word: 'Puente de Rialto',
        clue: 'Puente icónico sobre el Gran Canal veneciano.',
      ),
      AdivinaWord(
        word: 'Palacio de Buckingham',
        clue: 'Residencia real con cambio de guardia en Londres.',
      ),
      AdivinaWord(
        word: 'Torre de Londres',
        clue: 'Fortaleza con joyas de la corona y cuervos.',
      ),
      AdivinaWord(
        word: 'Neuschwanstein',
        clue: 'Castillo de cuento que inspiró Disney en Baviera.',
      ),
      AdivinaWord(
        word: 'Puerta de Brandeburgo',
        clue: 'Arco neoclásico símbolo de Berlín.',
      ),
      AdivinaWord(
        word: 'Plaza Roja',
        clue: 'Kremlin y San Basilio con cúpulas de colores en Moscú.',
      ),
      AdivinaWord(
        word: 'Meteora',
        clue: 'Monasterios colgantes sobre pilares rocosos en Grecia.',
      ),
      AdivinaWord(
        word: 'Teotihuacán',
        clue: 'Avenida de los Muertos y pirámides del Sol y la Luna en México.',
      ),
      AdivinaWord(
        word: 'Cenote Sagrado',
        clue: 'Pozo turquesa maya para rituales y baño.',
      ),
      AdivinaWord(
        word: 'Ruta 66',
        clue: 'Carretera mítica que cruza USA de Chicago a Santa Mónica.',
      ),

      AdivinaWord(
        word: 'Alcatraz',
        clue: 'Isla prisión en bahía de San Francisco. ',
      ),
      AdivinaWord(
        word: 'Zócalo',
        clue: 'Plaza mayor gigante de Ciudad de México. ',
      ),
      AdivinaWord(
        word: 'Mónaco',
        clue: 'Principado con casino y curva de Fórmula 1. ',
      ),
      AdivinaWord(
        word: 'Mont Saint-Michel',
        clue: 'Abadía en islote mareal francés. ',
      ),
      AdivinaWord(
        word: 'Tikal',
        clue: 'Pirámides mayas entre selva guatemalteca. ',
      ),
      AdivinaWord(
        word: 'Cappadocia',
        clue: 'Chimeneas de hadas y globos en Turquía. ',
      ),
      AdivinaWord(
        word: 'Hallstatt',
        clue: 'Pueblo lacustre austriaco de postal. ',
      ),
      AdivinaWord(
        word: 'Cinque Terre',
        clue: 'Cinco pueblos coloridos sobre acantilado italiano. ',
      ),
      AdivinaWord(
        word: 'Dubrovnik',
        clue: 'Murallas medievales sobre el Adriático croata. ',
      ),
      AdivinaWord(
        word: 'Bali',
        clue: 'Isla de templos y arrozales en Indonesia. ',
      ),
      AdivinaWord(
        word: 'Kyoto Arashiyama',
        clue: 'Bosque de bambú infinito y templo zen. ',
      ),
      AdivinaWord(
        word: 'Pamukkale',
        clue: 'Terrazas blancas de agua termal en Turquía. ',
      ),
      AdivinaWord(
        word: 'Antelope Canyon',
        clue: 'Grieta ondulada de luz en Arizona. ',
      ),
      AdivinaWord(
        word: 'Banff',
        clue: 'Lago turquesa y montañas rocosas canadienses. ',
      ),
      AdivinaWord(word: 'Lauterbrunnen', clue: 'Valle suizo con 72 cascadas. '),
      AdivinaWord(
        word: 'Santuario de Fushimi',
        clue: 'Miles de puertas torii rojas en Kioto. ',
      ),
      AdivinaWord(word: 'Palenque', clue: 'Ruinas mayas en selva chiapaneca. '),
      AdivinaWord(
        word: 'Cartagena de Indias',
        clue: 'Muralla caribeña y balcones coloniales. ',
      ),
      AdivinaWord(
        word: 'Valle de la Luna',
        clue: 'Formaciones blancas que parecen otro planeta en Chile. ',
      ),
      AdivinaWord(
        word: 'Cataratas Victoria',
        clue: 'Humo que truena entre Zambia y Zimbabue. ',
      ),
      AdivinaWord(
        word: 'Uluru',
        clue: 'Roca sagrada roja en desierto australiano. ',
      ),
      AdivinaWord(word: 'Petra nocturna', clue: 'Siq iluminado con velas en Jordania.'),
      AdivinaWord(word: 'Selva Lacandona', clue: 'Ceiba y ruinas mayas en Chiapas.'),
      AdivinaWord(word: 'Lencois Maranhenses', clue: 'Dunas blancas con lagunas turquesas en Brasil.'),
      AdivinaWord(word: 'Salar Uyuni nocturno', clue: 'Reflejo estrellado infinito en Bolivia.'),
      AdivinaWord(word: 'Torres del Paine', clue: 'Cuernos graníticos y viento patagónico.'),
      AdivinaWord(word: 'Fiordo Geiranger', clue: 'Cascada de las siete hermanas en Noruega.'),
      AdivinaWord(word: 'Isla Skye', clue: 'Cuernos de Storr con niebla escocesa.'),
      AdivinaWord(word: 'Valle de Ordesa', clue: 'Pared caliza y cascada en Pirineos.'),
      AdivinaWord(word: 'Ciudad Petra', clue: 'Tesoro tallado segunda variante fachada.'),
      AdivinaWord(word: 'Iceland Blue Lagoon', clue: 'Agua lechosa geotermal entre lava.'),
      AdivinaWord(word: 'Chefchaouen', clue: 'Pueblo azul tintado en Marruecos.'),
      AdivinaWord(word: 'Zhangjiajie', clue: 'Pilares verticales que inspiraron Avatar en China.'),
      AdivinaWord(word: 'Great Blue Hole', clue: 'Abismo azul circular en Belice.'),
      AdivinaWord(word: 'Wadi Rum', clue: 'Desierto rojo de Lawrence de Arabia.'),
      AdivinaWord(word: 'Siquijor', clue: 'Isla mística de curanderos en Filipinas.'),
      AdivinaWord(word: 'Palacio Pena', clue: 'Romántico colorido sobre Sintra.'),
      AdivinaWord(word: 'Castillo Himeji', clue: 'Garza blanca japonesa impecable.'),
      AdivinaWord(word: 'Templo Karnak', clue: 'Columnas gigantes en Luxor.'),
      AdivinaWord(word: 'Monte Cook', clue: 'Nevado alpino de Nueva Zelanda.'),
    ],
    'OBJETOS': [
      AdivinaWord(
        word: 'Guitarra',
        clue: 'Instrumento de cuerdas, se toca con las manos.',
      ),
      AdivinaWord(
        word: 'Cohete',
        clue: 'Viaja al espacio, tiene combustible y llama.',
      ),
      AdivinaWord(
        word: 'Ajedrez',
        clue: 'Juego de mesa, piezas blancas y negras, rey y reina.',
      ),
      AdivinaWord(
        word: 'Mariposa',
        clue: 'Insecto con alas coloridas, sale de oruga.',
      ),
      AdivinaWord(
        word: 'Reloj',
        clue: 'Mide el tiempo, tiene manecillas o es digital.',
      ),
      AdivinaWord(
        word: 'Paraguas',
        clue: 'Se usa con lluvia, se abre y cierra.',
      ),
      AdivinaWord(
        word: 'Brújula',
        clue: 'Siempre señala al norte, la usan los navegantes.',
      ),
      AdivinaWord(
        word: 'Cactus',
        clue: 'Planta con espinas, vive en el desierto.',
      ),
      AdivinaWord(
        word: 'Linterna',
        clue: 'Alumbra en la oscuridad, usa pilas.',
      ),
      AdivinaWord(
        word: 'Martillo',
        clue: 'Herramienta para clavar clavos, golpea.',
      ),
      AdivinaWord(
        word: 'Alcachofa',
        clue: 'Verdura con hojas, se come cocida.',
      ),
      AdivinaWord(
        word: 'Tamiz',
        clue: 'Tiene agujeros, se usa para separar harina.',
      ),
      AdivinaWord(
        word: 'Compás',
        clue: 'Dibuja círculos perfectos, tiene dos patas.',
      ),
      AdivinaWord(
        word: 'Cuadro',
        clue: 'Obra de arte en lienzo, cuelga en la pared.',
      ),
      AdivinaWord(
        word: 'Llave inglesa',
        clue: 'Herramienta ajustable, aprieta y suelta tornillos.',
      ),
      AdivinaWord(
        word: 'Telescopio',
        clue: 'Acerca estrellas y planetas, lo usan los astrónomos.',
      ),
      AdivinaWord(
        word: 'Tijeras',
        clue: 'Dos hojas con mango que cortan papel.',
      ),
      AdivinaWord(word: 'Imán', clue: 'Atrae metales, se pega a la nevera.'),
      AdivinaWord(
        word: 'Fusible',
        clue: 'Pequeño, se funde y salta en los enchufes.',
      ),
      AdivinaWord(word: 'Submarino', clue: 'Barco que navega bajo el agua.'),
      AdivinaWord(
        word: 'Estetoscopio',
        clue: 'El médico te escucha el corazón con él.',
      ),
      AdivinaWord(word: 'Bicicleta', clue: 'Dos ruedas y pedales, sin motor.'),
      AdivinaWord(
        word: 'Patinete',
        clue: 'Tabla con ruedas y manillar para empujar con el pie.',
      ),
      AdivinaWord(word: 'Balón', clue: 'Esfera que bota y se chuta.'),
      AdivinaWord(word: 'Altavoz', clue: 'Caja que amplifica sonido y música.'),
      AdivinaWord(word: 'Micrófono', clue: 'Capta tu voz y la amplifica.'),
      AdivinaWord(
        word: 'Auriculares',
        clue: 'Se ponen en orejas para escuchar música a solas.',
      ),
      AdivinaWord(word: 'Mochila', clue: 'Bolsa a la espalda con cremalleras.'),
      AdivinaWord(word: 'Maleta', clue: 'Caja con ruedas para viajar.'),
      AdivinaWord(word: 'Lámpara', clue: 'Da luz con bombilla y pantalla.'),
      AdivinaWord(word: 'Sofá', clue: 'Asiento largo y mullido para salón.'),
      AdivinaWord(word: 'Ventilador', clue: 'Aspas que giran y dan aire.'),
      AdivinaWord(
        word: 'Horno',
        clue: 'Caja caliente que hornea con resistencia.',
      ),
      AdivinaWord(
        word: 'Microondas',
        clue: 'Calienta comida rápido con ondas.',
      ),
      AdivinaWord(word: 'Nevera', clue: 'Mantiene comida fría con estantes.'),
      AdivinaWord(word: 'Cafetera', clue: 'Hace café con vapor y filtro.'),
      AdivinaWord(word: 'Aspiradora', clue: 'Succiona polvo haciendo ruido.'),
      AdivinaWord(word: 'Trampolín', clue: 'Lona elástica para saltar alto.'),
      AdivinaWord(word: 'Skate', clue: 'Tabla con cuatro ruedas para trucos.'),
      AdivinaWord(
        word: 'Diana',
        clue: 'Tablero redondo con números para lanzar dardos.',
      ),
      AdivinaWord(
        word: 'Puzzle',
        clue: 'Piezas que encajan para formar imagen.',
      ),
      AdivinaWord(word: 'Candado', clue: 'Cierra con llave o combinación.'),
      AdivinaWord(word: 'Báscula', clue: 'Mide peso al subirse encima.'),
      AdivinaWord(
        word: 'Abrelatas',
        clue: 'Gira y corta el borde metálico de latas.',
      ),
      AdivinaWord(
        word: 'Sacacorchos',
        clue: 'Espiral que extrae corchos de botellas.',
      ),
      AdivinaWord(
        word: 'Rallador',
        clue: 'Lámina con agujeros que desmenuza queso.',
      ),
      AdivinaWord(
        word: 'Espátula',
        clue: 'Paleta plana para voltear tortillas.',
      ),
      AdivinaWord(
        word: 'Colador',
        clue: 'Cuenco perforado para escurrir pasta.',
      ),
      AdivinaWord(
        word: 'Sartén',
        clue: 'Recipiente bajo antiadherente para freír.',
      ),
      AdivinaWord(
        word: 'Olla a presión',
        clue: 'Cocina rápido con vapor y válvula silbante.',
      ),
      AdivinaWord(
        word: 'Tostador',
        clue: 'Ranuras que doran pan con resistencia.',
      ),
      AdivinaWord(
        word: 'Exprimidor',
        clue: 'Cono que saca zumo de naranjas al girar.',
      ),
      AdivinaWord(
        word: 'Termo',
        clue: 'Mantiene líquidos calientes horas con doble pared.',
      ),
      AdivinaWord(
        word: 'Cantimplora',
        clue: 'Frasco metálico de excursionista para agua.',
      ),
      AdivinaWord(
        word: 'Binoculares',
        clue: 'Dos tubos que acercan paisajes lejanos.',
      ),
      AdivinaWord(
        word: 'Periscopio',
        clue: 'Tubo con espejos para mirar por encima del muro.',
      ),
      AdivinaWord(
        word: 'Microscopio',
        clue: 'Aumenta bacterias invisibles a la vista.',
      ),
      AdivinaWord(
        word: 'Proyector',
        clue: 'Lanza imagen grande sobre pared blanca.',
      ),
      AdivinaWord(
        word: 'Trípode',
        clue: 'Tres patas que sostienen cámara estable.',
      ),
      AdivinaWord(
        word: 'Drone cámara',
        clue: 'Cuatro hélices que filman desde el cielo.',
      ),

      AdivinaWord(
        word: 'Kalimba portátil',
        clue: 'Láminas metálicas que pulsas con pulgares. ',
      ),
      AdivinaWord(
        word: 'GoPro',
        clue: 'Cámara pequeña resistente para deportes extremos. ',
      ),
      AdivinaWord(
        word: 'Kindle',
        clue: 'Tinta electrónica para leer sin brillo. ',
      ),
      AdivinaWord(
        word: 'AirPods',
        clue: 'Auriculares blancos sin cable con estuche. ',
      ),
      AdivinaWord(
        word: 'Powerbank',
        clue: 'Ladrillo que recarga móvil sin enchufe. ',
      ),
      AdivinaWord(
        word: 'Router',
        clue: 'Caja con antenas que reparte internet. ',
      ),
      AdivinaWord(
        word: 'Cinta métrica',
        clue: 'Flexómetro que se recoge con muelle. ',
      ),
      AdivinaWord(
        word: 'Nivel de burbuja',
        clue: 'Tubo con gota que indica horizontal. ',
      ),
      AdivinaWord(
        word: 'Destornillador',
        clue: 'Mango y punta que gira tornillos. ',
      ),
      AdivinaWord(
        word: 'Taladro',
        clue: 'Gira broca y perfora pared con ruido. ',
      ),
      AdivinaWord(
        word: 'Sierra circular',
        clue: 'Disco dentado que corta madera rápido. ',
      ),
      AdivinaWord(
        word: 'Lijadora',
        clue: 'Vibra y alisa superficie de madera. ',
      ),
      AdivinaWord(
        word: 'Cutter',
        clue: 'Cuchilla retráctil para cortar cartón. ',
      ),
      AdivinaWord(word: 'Grapadora', clue: 'Clava grapas con golpe seco. '),
      AdivinaWord(
        word: 'Pegamento epoxi',
        clue: 'Dos tubos que mezclados endurecen fuerte. ',
      ),
      AdivinaWord(
        word: 'Báscula de cocina',
        clue: 'Plataforma que pesa gramos de harina. ',
      ),
      AdivinaWord(
        word: 'Molinillo de café',
        clue: 'Cuchillas que muelen granos aromáticos. ',
      ),
      AdivinaWord(
        word: 'Espumador de leche',
        clue: 'Varilla que hace espuma para capuchino. ',
      ),
      AdivinaWord(
        word: 'Rallador microplane',
        clue: 'Lámina fina que ralla cítricos en hilos. ',
      ),
      AdivinaWord(
        word: 'Mandolina de cocina',
        clue: 'Cuchilla que corta láminas finísimas. ',
      ),
      AdivinaWord(word: 'Termostato', clue: 'Rueda que regula temperatura ambiente.'),
      AdivinaWord(word: 'Higrómetro', clue: 'Mide humedad con aguja o digital.'),
      AdivinaWord(word: 'Anemómetro', clue: 'Cazoletas que giran con viento.'),
      AdivinaWord(word: 'Brújula lensática', clue: 'Militar con tapa y lente de aumento.'),
      AdivinaWord(word: 'Sismógrafo', clue: 'Aguja que dibuja temblores.'),
      AdivinaWord(word: 'Espectrómetro', clue: 'Descompone luz en arco iris medible.'),
      AdivinaWord(word: 'Centrífuga', clue: 'Gira tubos y separa mezclas.'),
      AdivinaWord(word: 'Autoclave', clue: 'Olla a presión que esteriliza con vapor.'),
      AdivinaWord(word: 'Impresora láser', clue: 'Tóner y cilindro que funde texto.'),
      AdivinaWord(word: 'Plotter', clue: 'Brazo que dibuja planos gigantes.'),
      AdivinaWord(word: 'Escáner 3D', clue: 'Láser que copia forma en nube de puntos.'),
      AdivinaWord(word: 'Pantalla e-ink', clue: 'Tinta que permanece sin energía.'),
      AdivinaWord(word: 'Estabilizador', clue: 'Gimbal que suaviza video en movimiento.'),
      AdivinaWord(word: 'Slider', clue: 'Raíl para cámara que se desliza suave.'),
      AdivinaWord(word: 'Chroma verde', clue: 'Tela que se vuelve fondo digital.'),
      AdivinaWord(word: 'Softbox', clue: 'Caja luminosa que difumina retrato.'),
      AdivinaWord(word: 'Ring light', clue: 'Aro que ilumina cara sin sombras.'),
      AdivinaWord(word: 'Claqueta digital', clue: 'Tabla con pantalla que sincroniza sonido.'),
      AdivinaWord(word: 'Boom micrófono', clue: 'Pértiga peluda que cuelga sobre actores.'),
      AdivinaWord(word: 'Grabadora campo', clue: 'Captura sonido ambiente con parabólica.'),
    ],
    'DEPORTES': [
      AdivinaWord(
        word: 'Fútbol',
        clue: 'Balón redondo, dos porterías, el deporte más popular.',
      ),
      AdivinaWord(
        word: 'Básquetbol',
        clue: 'Balón alto, canasta, se lanza con las manos.',
      ),
      AdivinaWord(word: 'Tenis', clue: 'Raqueta y pelota, se juega en cancha.'),
      AdivinaWord(
        word: 'Natación',
        clue: 'Se hace en piscina, se usan brazos y piernas.',
      ),
      AdivinaWord(
        word: 'Ciclismo',
        clue: 'Pedaleando, se va rápido en bicicleta.',
      ),
      AdivinaWord(
        word: 'Boxeo',
        clue: 'Guantes y ring, dos peleadores con puños.',
      ),
      AdivinaWord(word: 'Golf', clue: 'Palo y pelota, hoyo en el campo verde.'),
      AdivinaWord(word: 'Surf', clue: 'Tabla y ola, se balancea en el mar.'),
      AdivinaWord(
        word: 'Hockey',
        clue: 'Palo curvo y disco, se juega en hielo.',
      ),
      AdivinaWord(
        word: 'Esgrima',
        clue: 'Espada o florete, dos rivales con mascarilla.',
      ),
      AdivinaWord(
        word: 'Arquería',
        clue: 'Arco y flecha, se apunta al blanco.',
      ),
      AdivinaWord(
        word: 'Yoga',
        clue: 'Ejercicio mental, posturas y respiración.',
      ),
      AdivinaWord(
        word: 'Kárate',
        clue: 'Arte marcial, golpes con manos y pies.',
      ),
      AdivinaWord(
        word: 'Patinaje',
        clue: 'Deslizarse sobre hielo o ruedas, artístico.',
      ),
      AdivinaWord(
        word: 'Voley playa',
        clue: 'Arena, red y una pelota que no debe tocar el suelo.',
      ),
      AdivinaWord(
        word: 'Balonmano',
        clue: '7 contra 7, se lanza el balón a una portería pequeña.',
      ),
      AdivinaWord(
        word: 'Squash',
        clue: 'Pelota rebota contra las paredes de una sala.',
      ),
      AdivinaWord(
        word: 'Escalada',
        clue: 'Se asciende por una pared con pies y manos.',
      ),
      AdivinaWord(word: 'Atletismo', clue: 'Correr, saltar y lanzar en pista.'),
      AdivinaWord(word: 'Maratón', clue: 'Carrera larga de 42 kilómetros.'),
      AdivinaWord(word: 'Triatlón', clue: 'Nadar, pedalear y correr seguidos.'),
      AdivinaWord(word: 'Rugby', clue: 'Balón ovalado y placajes duros.'),
      AdivinaWord(word: 'Béisbol', clue: 'Bate, guante y home run.'),
      AdivinaWord(
        word: 'Críquet',
        clue: 'Bate plano y wickets en campo grande.',
      ),
      AdivinaWord(
        word: 'Bádminton',
        clue: 'Volante y raqueta ligera sobre red.',
      ),
      AdivinaWord(
        word: 'Pádel',
        clue: 'Pista con paredes de cristal y pala perforada.',
      ),
      AdivinaWord(word: 'Ping pong', clue: 'Mesa pequeña, raqueta y pelotita.'),
      AdivinaWord(word: 'Judo', clue: 'Kimono y llaves para derribar.'),
      AdivinaWord(word: 'Taekwondo', clue: 'Patadas altas y grito ¡kiap!'),
      AdivinaWord(word: 'Sumo', clue: 'Gigantes en círculo empujándose fuera.'),
      AdivinaWord(word: 'Gimnasia', clue: 'Pirueta y equilibrio en aparatos.'),
      AdivinaWord(
        word: 'Halterofilia',
        clue: 'Levantar barra con discos pesados.',
      ),
      AdivinaWord(
        word: 'CrossFit',
        clue: 'Circuito intenso de fuerza y cardio.',
      ),
      AdivinaWord(
        word: 'Parkour',
        clue: 'Saltar obstáculos urbanos con fluidez.',
      ),
      AdivinaWord(
        word: 'Snowboard',
        clue: 'Tabla ancha para deslizar en nieve.',
      ),
      AdivinaWord(
        word: 'Esquí',
        clue: 'Dos tablas largas para deslizar en nieve.',
      ),
      AdivinaWord(word: 'Motocross', clue: 'Moto saltando dunas y barro.'),
      AdivinaWord(word: 'Fórmula 1', clue: 'Monoposto rapidísimo en circuito.'),
      AdivinaWord(
        word: 'Rally',
        clue: 'Coches derrapando en tierra y asfalto.',
      ),
      AdivinaWord(word: 'Vela', clue: 'Barco con velas empujado por viento.'),
      AdivinaWord(
        word: 'Waterpolo',
        clue: 'Piscina, gorros y balón que se lanza con una mano.',
      ),
      AdivinaWord(
        word: 'Ultimate frisbee',
        clue: 'Disco volador que se pasa sin correr con él.',
      ),
      AdivinaWord(
        word: 'Lacrosse',
        clue: 'Red en palo para atrapar y lanzar bola.',
      ),
      AdivinaWord(
        word: 'Curling',
        clue: 'Piedra que se desliza y cepillos que barren hielo.',
      ),
      AdivinaWord(
        word: 'Bobsleigh',
        clue: 'Trineo de dos que baja canal helado a toda velocidad.',
      ),
      AdivinaWord(
        word: 'Skeleton',
        clue: 'Boca abajo en trineo por pista de hielo.',
      ),
      AdivinaWord(
        word: 'Salto de esquí',
        clue: 'Rampa gigante y vuelo largo sobre nieve.',
      ),
      AdivinaWord(
        word: 'Biathlon',
        clue: 'Esquís y rifle, se dispara tras esquiar.',
      ),
      AdivinaWord(
        word: 'Decathlon',
        clue: 'Diez pruebas de atletismo en dos días.',
      ),
      AdivinaWord(
        word: 'Pentathlon',
        clue: 'Cinco disciplinas clásicas combinadas.',
      ),
      AdivinaWord(
        word: 'Kendo',
        clue: 'Armadura y espada de bambú japonesa con gritos.',
      ),
      AdivinaWord(
        word: 'Muay Thai',
        clue: 'Codos, rodillas y patadas tailandesas.',
      ),
      AdivinaWord(
        word: 'Kickboxing',
        clue: 'Puños y patadas en ring con guantes.',
      ),
      AdivinaWord(
        word: 'Capoeira',
        clue: 'Danza-lucha brasileña con música y acrobacias.',
      ),
      AdivinaWord(
        word: 'Aikido',
        clue: 'Llaves suaves que usan la fuerza del rival.',
      ),
      AdivinaWord(
        word: 'Hapkido',
        clue: 'Coreano que mezcla patadas y luxaciones.',
      ),
      AdivinaWord(
        word: 'Sambo',
        clue: 'Lucha rusa con chaqueta parecida al judo.',
      ),
      AdivinaWord(
        word: 'Luge',
        clue: 'Trineo tumbado pies por delante en hielo.',
      ),
      AdivinaWord(
        word: 'Baloncesto 3x3',
        clue: 'Canasta callejera con tres por equipo en media pista.',
      ),
      AdivinaWord(
        word: 'Padbol',
        clue: 'Mezcla de fútbol y pádel en jaula de cristal.',
      ),

      AdivinaWord(
        word: 'Calistenia',
        clue: 'Dominadas y fondos usando solo tu cuerpo. ',
      ),
      AdivinaWord(
        word: 'Spinning',
        clue: 'Bici estática con música y sudor en sala. ',
      ),
      AdivinaWord(word: 'Zumba', clue: 'Baile fitness con ritmos latinos. '),
      AdivinaWord(
        word: 'Pilates',
        clue: 'Colchoneta y control del core respirando. ',
      ),
      AdivinaWord(
        word: 'Boxeo sombra',
        clue: 'Golpes al aire frente al espejo. ',
      ),
      AdivinaWord(
        word: 'MMA',
        clue: 'Jaula con golpes y sumisiones combinadas. ',
      ),
      AdivinaWord(
        word: 'Boulder',
        clue: 'Escalada sin cuerda sobre colchoneta. ',
      ),
      AdivinaWord(
        word: 'Slackline',
        clue: 'Cinta tensa para equilibrar sobre vacío. ',
      ),
      AdivinaWord(
        word: 'Orienteering',
        clue: 'Mapa y brújula corriendo por bosque. ',
      ),
      AdivinaWord(
        word: 'Raquetbol',
        clue: 'Paredes y raqueta corta en sala cerrada. ',
      ),
      AdivinaWord(
        word: 'Pickleball',
        clue: 'Pala y pelota perforada en pista pequeña. ',
      ),
      AdivinaWord(
        word: 'Tejo',
        clue: 'Disco metálico a diana de barro colombiana. ',
      ),
      AdivinaWord(
        word: 'Fútbol americano',
        clue: 'Ovalado, casco y touchdown. ',
      ),
      AdivinaWord(word: 'Netball', clue: 'Sin bote y canasta sin tablero. '),
      AdivinaWord(
        word: 'Floorball',
        clue: 'Palo ligero y pelota perforada indoor. ',
      ),
      AdivinaWord(word: 'Korfball', clue: 'Cesta mixta sin tablero y pases. '),
      AdivinaWord(
        word: 'Quidditch muggle',
        clue: 'Escoba entre piernas y pelotas corriendo. ',
      ),
      AdivinaWord(
        word: 'Shogi',
        clue: 'Ajedrez japonés con piezas que promocionan. ',
      ),
      AdivinaWord(
        word: 'Polo acuático',
        clue: 'Gorro y mano alzada en piscina. ',
      ),
      AdivinaWord(
        word: 'Tiro con arco a caballo',
        clue: 'Galope y flecha en diana japonesa. ',
      ),
      AdivinaWord(word: 'Netball elite', clue: 'Canasta sin tablero variante rápida.'),
      AdivinaWord(word: 'Ultimate mixto', clue: 'Disco sin árbitro y espíritu de juego.'),
      AdivinaWord(word: 'Bossaball', clue: 'Camas elásticas y voley con música.'),
      AdivinaWord(word: 'Sepak takraw', clue: 'Volea con pierna sobre red baja tailandesa.'),
      AdivinaWord(word: 'Kabaddi', clue: 'Cruzas línea aguantando respiración cantando.'),
      AdivinaWord(word: 'Jai alai', clue: 'Cesta curva que lanza pelota a 300 km/h.'),
      AdivinaWord(word: 'Pesca deportiva', clue: 'Caña y captura y suelta con medida.'),
      AdivinaWord(word: 'Esquí alpino', clue: 'Descenso con puertas y crono.'),
      AdivinaWord(word: 'Snowkite', clue: 'Cometa que tira de tabla sobre nieve.'),
      AdivinaWord(word: 'Kitesurf nieve', clue: 'Variante con esquís y vela.'),
      AdivinaWord(word: 'Surf remo', clue: 'Tabla grande y pala de pie.'),
      AdivinaWord(word: 'Wakesurf', clue: 'Ola artificial tras lancha sin cuerda.'),
      AdivinaWord(word: 'Wakeboard', clue: 'Tabla con fijaciones tras lancha.'),
      AdivinaWord(word: 'Esquí acuático', clue: 'Dos esquís tras lancha a gran velocidad.'),
      AdivinaWord(word: 'Barefoot ski', clue: 'Pies descalzos sobre agua a 60 km/h.'),
      AdivinaWord(word: 'Hockey subacuático', clue: 'Respiras con snorkel y empujas disco al fondo.'),
      AdivinaWord(word: 'Rugby subacuático', clue: 'Canasta en fondo de piscina y aletas.'),
      AdivinaWord(word: 'Apnea', clue: 'Sin botella aguantas metros bajo agua.'),
      AdivinaWord(word: 'Powerlifting', clue: 'Sentadilla, banca y peso muerto suma total.'),
      AdivinaWord(word: 'Strongman', clue: 'Arrastra camión y levanta piedra Atlas.'),
    ],
    'MÚSICA': [
      AdivinaWord(
        word: 'Piano',
        clue: 'Teclas blancas y negras, instrumento de teclado.',
      ),
      AdivinaWord(
        word: 'Violín',
        clue: 'Se toca con arco, cuerdas y cuerpo de madera.',
      ),
      AdivinaWord(
        word: 'Trompeta',
        clue: 'Instrumento de metal, se sopla con labios.',
      ),
      AdivinaWord(
        word: 'Batería',
        clue: 'Tambores y platillos, marca el ritmo.',
      ),
      AdivinaWord(
        word: 'Saxofón',
        clue: 'Curvo, de metal, instrumento de jazz.',
      ),
      AdivinaWord(
        word: 'Flauta',
        clue: 'Tubo delgado, se sopla por un extremo.',
      ),
      AdivinaWord(word: 'Acordes', clue: 'Varias notas juntas, crean armonía.'),
      AdivinaWord(
        word: 'Karaoke',
        clue: 'Micro y pantalla, cantas canciones famosas.',
      ),
      AdivinaWord(
        word: 'Vinilo',
        clue: 'Disco negro y redondo, suena con aguja.',
      ),
      AdivinaWord(
        word: 'Sinfonía',
        clue: 'Obra larga para orquesta, varios movimientos.',
      ),
      AdivinaWord(
        word: 'Tambor',
        clue: 'Redondo, piel tensada, golpe con baquetas.',
      ),
      AdivinaWord(word: 'Acordeón', clue: 'Se abre y cierra, teclas y fuelle.'),
      AdivinaWord(
        word: 'Arpa',
        clue: 'Instrumento enorme con muchas cuerdas verticales.',
      ),
      AdivinaWord(
        word: 'Guitarra eléctrica',
        clue: 'Cuerdas con amplificador y distorsión.',
      ),
      AdivinaWord(
        word: 'Bajo',
        clue: 'Cuatro cuerdas graves que marcan ritmo.',
      ),
      AdivinaWord(
        word: 'Ukelele',
        clue: 'Pequeñito de cuatro cuerdas y sonido alegre.',
      ),
      AdivinaWord(
        word: 'Clarinete',
        clue: 'Madera con boquilla y sonido dulce.',
      ),
      AdivinaWord(
        word: 'Oboe',
        clue: 'Madera con doble lengüeta y sonido nasal.',
      ),
      AdivinaWord(word: 'Tuba', clue: 'Metal enorme y grave que retumba.'),
      AdivinaWord(word: 'Chelo', clue: 'Cuerdas grande que se toca sentado.'),
      AdivinaWord(
        word: 'Contrabajo',
        clue: 'Gigante de cuerda frotada muy grave.',
      ),
      AdivinaWord(
        word: 'Maracas',
        clue: 'Sonajeros de mano que hacen chas-chas.',
      ),
      AdivinaWord(
        word: 'Bongó',
        clue: 'Dos tamboriles agarrados y percutidos.',
      ),
      AdivinaWord(
        word: 'Micrófono musical',
        clue: 'Amplifica voz en concierto.',
      ),
      AdivinaWord(
        word: 'Altavoz concierto',
        clue: 'Caja enorme que retumba graves.',
      ),
      AdivinaWord(word: 'Metrónomo', clue: 'Marca tempo con clics regulares.'),
      AdivinaWord(word: 'Partitura', clue: 'Papel con notas para músicos.'),
      AdivinaWord(word: 'Concierto', clue: 'Espectáculo musical en directo.'),
      AdivinaWord(
        word: 'Festival',
        clue: 'Varios conciertos y tiendas al aire libre.',
      ),
      AdivinaWord(word: 'Ópera', clue: 'Canto lírico con orquesta y disfraz.'),
      AdivinaWord(word: 'Coro', clue: 'Grupo que canta a varias voces.'),
      AdivinaWord(word: 'Solista', clue: 'Canta solo delante de todos.'),
      AdivinaWord(
        word: 'DJ de fiesta',
        clue: 'Pincha temas y mezcla en cabina.',
      ),
      AdivinaWord(
        word: 'Playlist',
        clue: 'Lista de canciones para reproducir.',
      ),
      AdivinaWord(
        word: 'Estribillo',
        clue: 'Parte pegadiza que se repite y todos cantan.',
      ),
      AdivinaWord(
        word: 'Armónica',
        clue: 'Pequeña de boca con lengüetas, soplas y aspiras.',
      ),
      AdivinaWord(
        word: 'Xilófono',
        clue: 'Láminas de madera que golpeas con mazas.',
      ),
      AdivinaWord(
        word: 'Sintetizador',
        clue: 'Teclado electrónico que crea sonidos futuristas.',
      ),
      AdivinaWord(word: 'Bandoneón', clue: 'Fuelle porteño esencial en tango.'),
      AdivinaWord(word: 'Kalimba', clue: 'Pequeño piano de pulgares africano.'),
      AdivinaWord(
        word: 'Theremin',
        clue: 'Se toca sin tocar, moviendo manos en el aire.',
      ),
      AdivinaWord(
        word: 'Banjo',
        clue: 'Cuerdas con parche redondo y sonido twang americano.',
      ),
      AdivinaWord(
        word: 'Mandolina',
        clue: 'Ocho cuerdas pequeñas con púa y sonido napolitano.',
      ),
      AdivinaWord(
        word: 'Sitar',
        clue: 'Muchas cuerdas indias que suenan hipnóticas con resonancia.',
      ),
      AdivinaWord(
        word: 'Shamisen',
        clue: 'Tres cuerdas japonesas con púa grande y caja cuadrada.',
      ),
      AdivinaWord(
        word: 'Didgeridoo',
        clue: 'Tubo largo aborigen que suena grave al soplar circular.',
      ),
      AdivinaWord(
        word: 'Cajón peruano',
        clue: 'Caja de madera donde te sientas y percutes.',
      ),
      AdivinaWord(
        word: 'Charango',
        clue: 'Cinco cuerdas andinas nacido del caparazón de armadillo.',
      ),
      AdivinaWord(word: 'Balalaika', clue: 'Triángulo ruso de tres cuerdas.'),
      AdivinaWord(
        word: 'Kora',
        clue: 'Arpa africana de 21 cuerdas con calabaza.',
      ),
      AdivinaWord(
        word: 'Mbira',
        clue: 'Piano de pulgares africano con láminas metálicas.',
      ),
      AdivinaWord(
        word: 'Hang drum',
        clue: 'Plato metálico con forma de ovni que suena místico.',
      ),
      AdivinaWord(
        word: 'Steelpan',
        clue: 'Bidón metálico caribeño afinado que suena a isla.',
      ),
      AdivinaWord(
        word: 'Gamelan',
        clue: 'Orquesta indonesia de gongs y metalófonos.',
      ),
      AdivinaWord(
        word: 'Bagpipe',
        clue: 'Fuelle escocés que suena al soplar bolsa y tubos.',
      ),
      AdivinaWord(
        word: 'Ocarina',
        clue: 'Huevo de cerámica con agujeros que silba dulce.',
      ),
      AdivinaWord(
        word: 'Kazoo',
        clue: 'Tubito que vibra con tu voz y suena gracioso.',
      ),
      AdivinaWord(
        word: 'Melódica',
        clue: 'Piano pequeño que soplas y tocas a la vez.',
      ),
      AdivinaWord(
        word: 'Laúd',
        clue: 'Cuerdas con forma de pera y mástil corto medieval.',
      ),
      AdivinaWord(
        word: 'Erhu',
        clue: 'Violín chino de dos cuerdas con sonido lloroso.',
      ),

      AdivinaWord(
        word: 'Corneta',
        clue: 'Metal pequeño sin válvulas que suena agudo. ',
      ),
      AdivinaWord(word: 'Trombón', clue: 'Vara deslizante de metal grave. '),
      AdivinaWord(
        word: 'Fagot',
        clue: 'Madera grave con tubo doblado y caña. ',
      ),
      AdivinaWord(
        word: 'Clavecín',
        clue: 'Teclado antiguo que puntea cuerdas. ',
      ),
      AdivinaWord(word: 'Órgano', clue: 'Tubos gigantes soplados en iglesia. '),
      AdivinaWord(
        word: 'Marimba',
        clue: 'Láminas de madera graves de Guatemala. ',
      ),
      AdivinaWord(
        word: 'Vibráfono',
        clue: 'Láminas metálicas con motor que vibra. ',
      ),
      AdivinaWord(
        word: 'Castañuelas',
        clue: 'Conchas que chasquean en manos flamencas. ',
      ),
      AdivinaWord(
        word: 'Bodhrán',
        clue: 'Tambor irlandés que golpeas con baqueta. ',
      ),
      AdivinaWord(
        word: 'Hurdy-gurdy',
        clue: 'Manivela y rueda que frota cuerdas. ',
      ),
      AdivinaWord(
        word: 'Nyckelharpa',
        clue: 'Arco y teclas suecas que rozan cuerdas. ',
      ),
      AdivinaWord(word: 'Shakuhachi', clue: 'Flauta bambú zen japonesa. '),
      AdivinaWord(
        word: 'Koto',
        clue: '13 cuerdas japonesas que punteas con púa. ',
      ),
      AdivinaWord(
        word: 'Taiko',
        clue: 'Tambor gigante japonés que golpeas fuerte. ',
      ),
      AdivinaWord(
        word: 'Djembe',
        clue: 'Copa africana de piel que percuten manos. ',
      ),
      AdivinaWord(
        word: 'Cajita de música',
        clue: 'Cilindro con púas que suena al girar manivela. ',
      ),
      AdivinaWord(
        word: 'Vocoder',
        clue: 'Voz robótica que modula sintetizador. ',
      ),
      AdivinaWord(
        word: 'Sampler',
        clue: 'Graba fragmento y lo dispara con pad. ',
      ),
      AdivinaWord(
        word: 'Autotune',
        clue: 'Corrige afinación con efecto robótico. ',
      ),
      AdivinaWord(
        word: 'Soundcheck',
        clue: 'Prueba de sonido antes del concierto. ',
      ),
      AdivinaWord(word: 'Celesta', clue: 'Teclado con placas metálicas que tintinea.'),
      AdivinaWord(word: 'Clavecin eléctrico', clue: 'Puntea con plectro amplificado.'),
      AdivinaWord(word: 'Ondas Martenot', clue: 'Antena y cinta que hace vibrato etéreo.'),
      AdivinaWord(word: 'Sarod', clue: 'Láud indio sin trastes metálico profundo.'),
      AdivinaWord(word: 'Surbahar', clue: 'Sitar grave que suena meditativo.'),
      AdivinaWord(word: 'Pipa china', clue: 'Cuatro cuerdas en pera que tremola.'),
      AdivinaWord(word: 'Guzheng', clue: 'Cítara china con 21 cuerdas y puentes móviles.'),
      AdivinaWord(word: 'Yangqin', clue: 'Dulcémele chino percutido con mazas de bambú.'),
      AdivinaWord(word: 'Sheng', clue: 'Órgano de boca chino con tubos verticales.'),
      AdivinaWord(word: 'Suona', clue: 'Oboe chino estridente para bodas.'),
      AdivinaWord(word: 'Duduk', clue: 'Flauta armenia doble caña y llanto nasal.'),
      AdivinaWord(word: 'Morin khuur', clue: 'Violín mongol con cabeza de caballo.'),
      AdivinaWord(word: 'Khoomei', clue: 'Canto difónico que saca dos voces.'),
      AdivinaWord(word: 'Beatbox', clue: 'Boca que imita batería y bajo.'),
      AdivinaWord(word: 'Loop station', clue: 'Pedal que graba y superpone voces.'),
      AdivinaWord(word: 'Ableton Push', clue: 'Pad luminoso para lanzar clips.'),
      AdivinaWord(word: 'Theremini', clue: 'Theremin moderno con corrección de nota.'),
      AdivinaWord(word: 'Seaboard', clue: 'Teclado blando que deslizas para vibrar.'),
      AdivinaWord(word: 'Handpan', clue: 'Ovni metálico que tocas con manos.'),
      AdivinaWord(word: 'Waterphone', clue: 'Varillas y agua que hace sonido de terror.'),
    ],
    'CINE/TV': [
      AdivinaWord(
        word: 'Superhéroe',
        clue: 'Capa y poderes, salva al mundo en películas.',
      ),
      AdivinaWord(
        word: 'Película',
        clue: 'Historia en pantalla, dura 90 minutos o más.',
      ),
      AdivinaWord(word: 'Estreno', clue: 'Primera vez que se ve en cine o TV.'),
      AdivinaWord(
        word: 'Comedia',
        clue: 'Género que provoca risas, finales felices.',
      ),
      AdivinaWord(
        word: 'Suspenso',
        clue: 'Te mantiene al borde, tensión y sorpresas.',
      ),
      AdivinaWord(
        word: 'Documental',
        clue: 'Cuenta hechos reales, enseña sobre un tema.',
      ),
      AdivinaWord(
        word: 'Teleprompter',
        clue: 'Pantalla que muestra el guion, lo lee el presentador.',
      ),
      AdivinaWord(word: 'Canal', clue: 'Emite programas, se ve en la tele.'),
      AdivinaWord(
        word: 'Extras',
        clue: 'Actores secundarios, aparecen de fondo en escenas.',
      ),
      AdivinaWord(
        word: 'Tráiler',
        clue: 'Vista previa de una película, dura pocos minutos.',
      ),
      AdivinaWord(
        word: 'Doblaje',
        clue: 'Voces en otro idioma, cambia la original.',
      ),
      AdivinaWord(
        word: 'Fotograma',
        clue: 'Una imagen de la película, la unidad más pequeña del cine.',
      ),
      AdivinaWord(
        word: 'Óscar',
        clue: 'Estatuilla dorada, el premio más famoso del cine.',
      ),
      AdivinaWord(word: 'Director', clue: 'Grita ¡acción! y dirige actores.'),
      AdivinaWord(
        word: 'Guionista',
        clue: 'Escribe diálogos y escenas del guion.',
      ),
      AdivinaWord(word: 'Productor', clue: 'Financia y organiza el rodaje.'),
      AdivinaWord(word: 'Casting', clue: 'Selección de actores para papeles.'),
      AdivinaWord(
        word: 'Vestuario',
        clue: 'Ropa de época o fantasía para rodaje.',
      ),
      AdivinaWord(
        word: 'Maquillaje cine',
        clue: 'Transforma caras con prótesis y pintura.',
      ),
      AdivinaWord(
        word: 'Efectos especiales',
        clue: 'Explosiones y trucos sin ordenador.',
      ),
      AdivinaWord(word: 'CGI', clue: 'Gráficos por ordenador hiperrealistas.'),
      AdivinaWord(
        word: 'Banda sonora',
        clue: 'Música que acompaña la película.',
      ),
      AdivinaWord(word: 'Secuela', clue: 'Continuación con misma historia.'),
      AdivinaWord(word: 'Precuela', clue: 'Historia anterior a la original.'),
      AdivinaWord(word: 'Remake', clue: 'Nueva versión de clásico antiguo.'),
      AdivinaWord(
        word: 'Spin-off',
        clue: 'Historia derivada de personaje secundario.',
      ),
      AdivinaWord(
        word: 'Cliffhanger',
        clue: 'Final en suspenso que deja a medias.',
      ),
      AdivinaWord(word: 'Spoiler', clue: 'Revela final y arruina sorpresa.'),
      AdivinaWord(word: 'Taquilla', clue: 'Recaudación y venta de entradas.'),
      AdivinaWord(
        word: 'Alfombra roja',
        clue: 'Desfile de estrellas ante flashes.',
      ),
      AdivinaWord(word: 'Streaming', clue: 'Ver series online sin descargar.'),
      AdivinaWord(word: 'Serie', clue: 'Capítulos semanales con misma trama.'),
      AdivinaWord(
        word: 'Reality',
        clue: 'Concurso con gente real conviviendo.',
      ),
      AdivinaWord(word: 'Anime', clue: 'Dibujo japonés con ojos grandes.'),
      AdivinaWord(
        word: 'Sitcom',
        clue: 'Comedia con risas grabadas y capítulos cortos.',
      ),
      AdivinaWord(
        word: 'Blockbuster',
        clue: 'Película taquillera que rompe récords.',
      ),
      AdivinaWord(word: 'Making of', clue: 'Cómo se hizo, detrás de cámaras.'),
      AdivinaWord(word: 'Créditos', clue: 'Nombres que desfilan al final.'),
      AdivinaWord(
        word: 'Palomitas',
        clue: 'Maíz inflado que cruje en sala oscura.',
      ),
      AdivinaWord(
        word: 'Cameo',
        clue: 'Famoso que aparece unos segundos por sorpresa.',
      ),
      AdivinaWord(
        word: 'Claqueta',
        clue: 'Tabla que chasca antes de grabar para sincronizar.',
      ),
      AdivinaWord(
        word: 'Steadicam',
        clue: 'Arnés que estabiliza cámara en movimiento fluido.',
      ),
      AdivinaWord(
        word: 'Chroma key',
        clue: 'Tela verde que luego se vuelve fondo digital.',
      ),
      AdivinaWord(
        word: 'Stop motion',
        clue: 'Foto a foto con muñecos que parecen moverse solos.',
      ),
      AdivinaWord(
        word: 'Motion capture',
        clue: 'Traje con puntos que copian movimientos al ordenador.',
      ),
      AdivinaWord(
        word: 'Dobles de acción',
        clue: 'Sustituyen al actor en saltos y choques peligrosos.',
      ),
      AdivinaWord(
        word: 'Storyboarding',
        clue: 'Viñetas que dibujan la peli antes de rodar.',
      ),
      AdivinaWord(
        word: 'Travelling',
        clue: 'Cámara que avanza sobre raíles hacia el actor.',
      ),
      AdivinaWord(
        word: 'Maqueta',
        clue: 'Ciudad en miniatura que explota sin gastar tanto.',
      ),
      AdivinaWord(
        word: 'Animatrónico',
        clue: 'Muñeco robótico que mueve ojos y boca realista.',
      ),
      AdivinaWord(
        word: 'Showrunner',
        clue: 'Jefe que escribe y manda en toda la serie.',
      ),
      AdivinaWord(
        word: 'Prime time',
        clue: 'Hora de máxima audiencia nocturna.',
      ),
      AdivinaWord(
        word: 'Binge watching',
        clue: 'Ver temporada entera sin parar hasta madrugada.',
      ),
      AdivinaWord(
        word: 'Teaser',
        clue: 'Avance muy corto que apenas muestra nada y engancha.',
      ),
      AdivinaWord(
        word: 'Pitch',
        clue: 'Presentación rápida para vender idea en minutos.',
      ),
      AdivinaWord(
        word: 'Zapping',
        clue: 'Cambiar de canal sin parar con mando.',
      ),
      AdivinaWord(
        word: 'Late night',
        clue: 'Programa nocturno con sofá y chistes de monólogo.',
      ),
      AdivinaWord(
        word: 'Treatment',
        clue: 'Resumen largo del guion antes de escribirlo entero.',
      ),
      AdivinaWord(
        word: 'Prueba de cámara',
        clue: 'Grabación previa para ver si actor encaja en papel.',
      ),
      AdivinaWord(
        word: 'Ensayo',
        clue: 'Repaso de escena sin rodar aún, solo practicando.',
      ),

      AdivinaWord(
        word: 'Dolly zoom',
        clue: 'Cámara avanza y lente retrocede a la vez. ',
      ),
      AdivinaWord(
        word: 'Montaje',
        clue: 'Corte y pegado de escenas para contar historia. ',
      ),
      AdivinaWord(
        word: 'Guion',
        clue: 'Texto con diálogos y acotaciones para rodar. ',
      ),
      AdivinaWord(
        word: 'Continuidad',
        clue: 'Que el vaso no cambie de mano entre planos. ',
      ),
      AdivinaWord(
        word: 'Raccord',
        clue: 'Coherencia visual entre tomas seguidas. ',
      ),
      AdivinaWord(
        word: 'Plano secuencia',
        clue: 'Toma larga sin cortes que sigue acción. ',
      ),
      AdivinaWord(
        word: 'Plano detalle',
        clue: 'Ojos o manos enormes en pantalla. ',
      ),
      AdivinaWord(
        word: 'Cámara lenta',
        clue: 'Acción a mitad de velocidad dramática. ',
      ),
      AdivinaWord(
        word: 'Time-lapse',
        clue: 'Nubes veloces en segundos comprimidos. ',
      ),
      AdivinaWord(
        word: 'Foley',
        clue: 'Pasos y puertas creados en sala de sonido. ',
      ),
      AdivinaWord(word: 'Voice over', clue: 'Voz en off que narra sin verse. '),
      AdivinaWord(
        word: 'Casting director',
        clue: 'Elige caras para cada papel del reparto. ',
      ),
      AdivinaWord(
        word: 'Figurante',
        clue: 'Persona que pasa al fondo sin hablar. ',
      ),
      AdivinaWord(
        word: 'Doble de riesgo',
        clue: 'Salta por el actor en escena peligrosa. ',
      ),
      AdivinaWord(
        word: 'Antagonista',
        clue: 'Opuesto al héroe que pone trabas. ',
      ),
      AdivinaWord(
        word: 'Plot twist',
        clue: 'Giro inesperado que cambia toda la trama. ',
      ),
      AdivinaWord(
        word: 'Trilogía',
        clue: 'Tres películas conectadas con arco completo. ',
      ),
      AdivinaWord(word: 'Reboot', clue: 'Reinicio de saga desde cero. '),
      AdivinaWord(
        word: 'Mockumentary',
        clue: 'Falso documental con entrevistas cómicas. ',
      ),
      AdivinaWord(
        word: 'Docuserie',
        clue: 'Serie documental episódica con hechos reales. ',
      ),
      AdivinaWord(
        word: 'Stand-up',
        clue: 'Monólogo cómico en escenario solo. ',
      ),
      AdivinaWord(word: 'Continuista', clue: 'Anota que el vaso no cambie de mano entre planos.'),
      AdivinaWord(word: 'Script', clue: 'Alias anglo de continuista en rodaje.'),
      AdivinaWord(word: 'Gaffer', clue: 'Jefe de eléctricos que ilumina escena.'),
      AdivinaWord(word: 'Best boy', clue: 'Segundo de eléctricos que ayuda al gaffer.'),
      AdivinaWord(word: 'Runner', clue: 'Recadero que trae cafés y cintas.'),
      AdivinaWord(word: 'Location scout', clue: 'Busca localizaciones antes de rodar.'),
      AdivinaWord(word: 'Color grading', clue: 'Etalona colores en postproducción.'),
      AdivinaWord(word: 'Dolly grip', clue: 'Empuja carrito de cámara sobre vías.'),
      AdivinaWord(word: 'Boom operator', clue: 'Sostiene pértiga de micro sobre actores.'),
      AdivinaWord(word: 'Focus puller', clue: 'Gira anillo para mantener foco nítido.'),
      AdivinaWord(word: 'Matte painting', clue: 'Fondo pintado hiperrealista antes de CGI.'),
      AdivinaWord(word: 'Animatic', clue: 'Storyboard animado con sonido temporal.'),
      AdivinaWord(word: 'Previsualización', clue: 'Versión 3D tosca para planear acción.'),
      AdivinaWord(word: 'Postcréditos', clue: 'Escena tras créditos que engancha secuela.'),
      AdivinaWord(word: 'Spin-off serie', clue: 'Derivada centrada en secundario popular.'),
      AdivinaWord(word: 'Bottle episode', clue: 'Capítulo barato en una sola localización.'),
      AdivinaWord(word: 'Cold open', clue: 'Escena antes de cabecera que atrapa.'),
      AdivinaWord(word: 'Cliffhanger final', clue: 'Corte abrupto que deja en vilo temporada.'),
      AdivinaWord(word: 'Recap', clue: 'Resumen de temporada anterior al inicio.'),
    ],
    'NATURALEZA': [
      AdivinaWord(word: 'Volcán', clue: 'Montaña que erupa lava y ceniza.'),
      AdivinaWord(
        word: 'Cascada',
        clue: 'Agua que cae desde altura, ruido y espuma.',
      ),
      AdivinaWord(
        word: 'Desierto',
        clue: 'Extensión de arena, poca agua y mucho calor.',
      ),
      AdivinaWord(
        word: 'Glaciar',
        clue: 'Masa de hielo grande y lenta, en montañas.',
      ),
      AdivinaWord(
        word: 'Bosque',
        clue: 'Árboles juntos, hogar de animales y sombra.',
      ),
      AdivinaWord(
        word: 'Lago',
        clue: 'Agua dulce rodeada de tierra, se puede pescar.',
      ),
      AdivinaWord(
        word: 'Tornado',
        clue: 'Viento giratorio, levanta todo a su paso.',
      ),
      AdivinaWord(
        word: 'Aurora ártica',
        clue: 'Luces de colores en el cielo nocturno polar.',
      ),
      AdivinaWord(word: 'Cueva', clue: 'Hueco en la roca, oscuro y húmedo.'),
      AdivinaWord(
        word: 'Coral',
        clue: 'Formaciones marinas de colores, hogar de peces.',
      ),
      AdivinaWord(
        word: 'Relámpago',
        clue: 'Rayo de luz en tormenta, dura un segundo.',
      ),
      AdivinaWord(
        word: 'Isla',
        clue: 'Tierra rodeada de agua por todos lados.',
      ),
      AdivinaWord(word: 'Oasis', clue: 'Agua y palmeras en medio de la arena.'),
      AdivinaWord(
        word: 'Huracán',
        clue: 'Viento circular gigante que arrasa costas.',
      ),
      AdivinaWord(word: 'Tsunami', clue: 'Ola gigante por terremoto bajo mar.'),
      AdivinaWord(word: 'Terremoto', clue: 'Tierra que tiembla y agrieta.'),
      AdivinaWord(word: 'Géiser', clue: 'Chorro de agua caliente que erupa.'),
      AdivinaWord(
        word: 'Manglar',
        clue: 'Bosque en agua salada con raíces zancudas.',
      ),
      AdivinaWord(
        word: 'Selva',
        clue: 'Vegetación densa y húmeda llena de vida.',
      ),
      AdivinaWord(word: 'Sabana', clue: 'Llanura con hierba alta y acacias.'),
      AdivinaWord(word: 'Tundra', clue: 'Suelo helado con musgo y poco árbol.'),
      AdivinaWord(word: 'Pradera', clue: 'Extensión de hierba sin árboles.'),
      AdivinaWord(word: 'Pantano', clue: 'Agua estancada con barro y juncos.'),
      AdivinaWord(
        word: 'Arrecife',
        clue: 'Barrera de coral llena de peces colores.',
      ),
      AdivinaWord(word: 'Dunas', clue: 'Montañas de arena movidas por viento.'),
      AdivinaWord(word: 'Meseta', clue: 'Llanura alta y plana sobre el nivel.'),
      AdivinaWord(word: 'Cañón', clue: 'Garganta profunda excavada por río.'),
      AdivinaWord(word: 'Acantilado', clue: 'Pared rocosa vertical al mar.'),
      AdivinaWord(word: 'Península', clue: 'Tierra casi rodeada por agua.'),
      AdivinaWord(
        word: 'Archipiélago',
        clue: 'Conjunto de islas cercanas entre sí.',
      ),
      AdivinaWord(word: 'Fiordo', clue: 'Valle glaciar inundado por mar.'),
      AdivinaWord(word: 'Delta', clue: 'Desembocadura en abanico del río.'),
      AdivinaWord(word: 'Jungla', clue: 'Selva impenetrable y enmarañada.'),
      AdivinaWord(word: 'Estepa', clue: 'Llanura seca de hierba corta.'),
      AdivinaWord(
        word: 'Prado alpino',
        clue: 'Hierba de montaña con flores en verano.',
      ),
      AdivinaWord(
        word: 'Aurora austral',
        clue: 'Luces del sur como la boreal pero en polo opuesto.',
      ),
      AdivinaWord(word: 'Llanura', clue: 'Terreno plano sin elevaciones.'),
      AdivinaWord(
        word: 'Caverna marina',
        clue: 'Hueco rocoso inundado por olas.',
      ),
      AdivinaWord(
        word: 'Río subterráneo',
        clue: 'Corriente que fluye bajo tierra en cueva.',
      ),
      AdivinaWord(
        word: 'Bosque boreal',
        clue: 'Coníferas infinitas en el norte frío.',
      ),
      AdivinaWord(
        word: 'Cascada de Ángel',
        clue: 'La más alta del mundo cayendo desde tepuy venezolano.',
      ),
      AdivinaWord(
        word: 'Cueva de Waitomo',
        clue: 'Gusanos brillantes azules que iluminan cueva neozelandesa.',
      ),
      AdivinaWord(
        word: 'Bosque de bambú',
        clue: 'Tallos altos y huecos que crecen un metro al día en Kioto.',
      ),
      AdivinaWord(
        word: 'Lago Titicaca',
        clue: 'El navegable más alto del mundo entre Perú y Bolivia.',
      ),
      AdivinaWord(
        word: 'Río Nilo',
        clue: 'El más largo del mundo que cruza Egipto.',
      ),
      AdivinaWord(
        word: 'Río Amazonas',
        clue: 'El más caudaloso que lleva selva al Atlántico.',
      ),
      AdivinaWord(
        word: 'Monte Kilimanjaro',
        clue: 'Nevado africano solitario en Tanzania.',
      ),
      AdivinaWord(
        word: 'Cordillera de los Andes',
        clue: 'La más larga del mundo recorriendo Sudamérica.',
      ),
      AdivinaWord(
        word: 'Gran Barrera de Coral',
        clue: 'La estructura viva más grande vista desde el espacio, en Australia.',
      ),
      AdivinaWord(
        word: 'Parque de Yellowstone',
        clue: 'Géiseres y bisontes en el primer parque nacional del mundo.',
      ),
      AdivinaWord(
        word: 'Isla de Komodo',
        clue: 'Dragones gigantes que viven solo allí en Indonesia.',
      ),
      AdivinaWord(
        word: 'Península de Kamchatka',
        clue: 'Tierra rusa de volcanes y osos pardos.',
      ),
      AdivinaWord(
        word: 'Desierto de Gobi',
        clue: 'Estepa fría mongola de dinosaurios fósiles.',
      ),
      AdivinaWord(
        word: 'Desierto de Namib',
        clue: 'Dunas rojas milenarias junto al Atlántico africano.',
      ),
      AdivinaWord(
        word: 'Taiga',
        clue: 'Bosque infinito de coníferas bajo nieve siberiana.',
      ),
      AdivinaWord(
        word: 'Páramo andino',
        clue: 'Altura con frailejones esponjosos que guardan agua.',
      ),
      AdivinaWord(
        word: 'Fosa de las Marianas',
        clue: 'El punto más profundo del océano, 11 km bajo el mar.',
      ),
      AdivinaWord(
        word: 'Volcán Stromboli',
        clue: 'Faro del Mediterráneo que erupa cada pocos minutos.',
      ),
      AdivinaWord(
        word: 'Bosque nuboso',
        clue: 'Selva siempre entre niebla en montaña tropical.',
      ),
      AdivinaWord(
        word: 'Delta del Okavango',
        clue: 'Río que muere en desierto formando oasis en Botsuana.',
      ),

      AdivinaWord(
        word: 'Estepa helada',
        clue: 'Llanura seca y fría de hierba baja. ',
      ),
      AdivinaWord(
        word: 'Estuario',
        clue: 'Boca ancha donde río y mar se abrazan. ',
      ),
      AdivinaWord(word: 'Humedal', clue: 'Tierra encharcada rica en aves. '),
      AdivinaWord(
        word: 'Morrena',
        clue: 'Montón de piedras que deja glaciar al retroceder. ',
      ),
      AdivinaWord(
        word: 'Caldera',
        clue: 'Crater enorme colapsado tras erupción. ',
      ),
      AdivinaWord(
        word: 'Lava solidificada',
        clue: 'Roca negra que dejó río de magma. ',
      ),
      AdivinaWord(
        word: 'Fumarola',
        clue: 'Humo sulfuroso que sale de grieta volcánica. ',
      ),
      AdivinaWord(
        word: 'Cenote abierto',
        clue: 'Piscina natural turquesa en selva yucateca. ',
      ),
      AdivinaWord(
        word: 'Salar rosa',
        clue: 'Lago salado rosado por microalgas. ',
      ),
      AdivinaWord(
        word: 'Bosque de secuoyas',
        clue: 'Troncos gigantes que tocan cielo en California. ',
      ),
      AdivinaWord(
        word: 'Bosque magallánico',
        clue: 'Bosque austral de lengas y coihues. ',
      ),
      AdivinaWord(
        word: 'Chapparal',
        clue: 'Matorral seco mediterráneo que arde fácil. ',
      ),
      AdivinaWord(
        word: 'Lago glaciar',
        clue: 'Agua turquesa con témpanos flotando. ',
      ),
      AdivinaWord(
        word: 'Catarata invertida',
        clue: 'Viento que levanta agua hacia arriba. ',
      ),
      AdivinaWord(
        word: 'Aurora inversa',
        clue: 'Luces del polo sur menos vistas. ',
      ),
      AdivinaWord(
        word: 'Playa bioluminiscente',
        clue: 'Olas que brillan azul al pisar de noche. ',
      ),
      AdivinaWord(
        word: 'Valle colgante',
        clue: 'Valle que queda alto tras glaciar. ',
      ),
      AdivinaWord(
        word: 'Doline',
        clue: 'Hoyo circular por colapso de cueva kárstica. ',
      ),
      AdivinaWord(
        word: 'Karst',
        clue: 'Paisaje de roca caliza con cuevas y simas. ',
      ),
      AdivinaWord(
        word: 'Badlands',
        clue: 'Tierras baldías erosionadas en crestas. ',
      ),
      AdivinaWord(word: 'Lago Moraine', clue: 'Azul turquesa con Valley of Ten Peaks en Canadá.'),
      AdivinaWord(word: 'Cerro Torre', clue: 'Aguja imposible de granito patagónico.'),
      AdivinaWord(word: 'Fitz Roy', clue: 'Pico dentado emblema de Patagonia.'),
      AdivinaWord(word: 'Altiplano', clue: 'Llanura a 4000 m con vicuñas y salares.'),
      AdivinaWord(word: 'Puna', clue: 'Desierto alto con queñoas y flamencos.'),
      AdivinaWord(word: 'Yungas', clue: 'Selva de niebla en ladera andina.'),
      AdivinaWord(word: 'Chaco', clue: 'Bosque seco con quebracho y tatú.'),
      AdivinaWord(word: 'Esteros del Iberá', clue: 'Humedal con carpinchos y yacarés.'),
      AdivinaWord(word: 'Ischigualasto', clue: 'Valle de la luna con formas extraterrestres argentino.'),
      AdivinaWord(word: 'Talampaya', clue: 'Cañón rojo con paredones y petroglifos.'),
      AdivinaWord(word: 'Quebrada Humahuaca', clue: 'Cerro de 7 colores y cardones.'),
      AdivinaWord(word: 'Glaciar Grey', clue: 'Lengua azul que cae al lago en Torres.'),
      AdivinaWord(word: 'Campo de hielo sur', clue: 'Tercera reserva dulce tras Antártida.'),
      AdivinaWord(word: 'Bosque valdiviano', clue: 'Alerces milenarios y helechos gigantes.'),
      AdivinaWord(word: 'Araucaria', clue: 'Pequeño paraguas prehistórico chileno.'),
      AdivinaWord(word: 'Desierto florido', clue: 'Atacama que estalla en flores tras lluvia.'),
      AdivinaWord(word: 'Guanaco', clue: 'Camélido silvestre que escupe y galopa.'),
      AdivinaWord(word: 'Huemul', clue: 'Ciervo andino escurridizo en escudo chileno.'),
      AdivinaWord(word: 'Cóndor juvenil', clue: 'Plumón y collar blanco antes de madurar.'),
      AdivinaWord(word: 'Pudu', clue: 'Ciervo enano del bosque templado.'),
    ],
    'TECNOLOGÍA': [
      AdivinaWord(
        word: 'Smartphone',
        clue: 'Teléfono inteligente, pantalla táctil y apps.',
      ),
      AdivinaWord(word: 'WiFi', clue: 'Conexión inalámbrica, sin cables.'),
      AdivinaWord(
        word: 'Robot',
        clue: 'Máquina programada, hace tareas automáticamente.',
      ),
      AdivinaWord(
        word: 'Código',
        clue: 'Instrucciones para computadoras, letras y números.',
      ),
      AdivinaWord(
        word: 'Pantalla',
        clue: 'Superficie que muestra imágenes, se mira.',
      ),
      AdivinaWord(
        word: 'Batería de litio',
        clue: 'Almacena energía, se recarga.',
      ),
      AdivinaWord(
        word: 'Cargador',
        clue: 'Conecta a la corriente, recarga el dispositivo.',
      ),
      AdivinaWord(
        word: 'Nube digital',
        clue: 'Almacenamiento en internet, no ocupa espacio físico.',
      ),
      AdivinaWord(
        word: 'Ciberseguridad',
        clue: 'Protege datos en línea, firewall y antivirus.',
      ),
      AdivinaWord(
        word: 'Impresora',
        clue: 'Saca documentos en papel, usa tinta o láser.',
      ),
      AdivinaWord(
        word: 'Cámaras',
        clue: 'Capturan imágenes, las hay de fotos y videos.',
      ),
      AdivinaWord(
        word: 'GPS',
        clue: 'Ubicador satelital, te dice dónde estás.',
      ),
      AdivinaWord(
        word: 'Bluetooth',
        clue: 'Conexión corta y sin cables entre dispositivos.',
      ),
      AdivinaWord(
        word: 'Tablet',
        clue: 'Pantalla plana y grande, entre móvil y portátil.',
      ),
      AdivinaWord(
        word: 'Dron',
        clue: 'Aparato volador con cámara, se controla con mando.',
      ),
      AdivinaWord(
        word: 'Laptop',
        clue: 'Ordenador portátil con teclado integrado.',
      ),
      AdivinaWord(word: 'Servidor', clue: 'Ordenador que sirve datos a otros.'),
      AdivinaWord(
        word: 'Algoritmo',
        clue: 'Pasos ordenados que resuelve problema.',
      ),
      AdivinaWord(
        word: 'Inteligencia artificial',
        clue: 'Máquina que aprende y decide sola.',
      ),
      AdivinaWord(
        word: 'Realidad virtual',
        clue: 'Gafas que te meten en mundo digital.',
      ),
      AdivinaWord(
        word: 'Realidad aumentada',
        clue: 'Digital superpuesto al mundo real.',
      ),
      AdivinaWord(
        word: 'Blockchain',
        clue: 'Cadena de bloques para datos seguros.',
      ),
      AdivinaWord(word: 'Criptomoneda', clue: 'Dinero digital como bitcoin.'),
      AdivinaWord(word: 'USB', clue: 'Conector pequeño para pasar datos.'),
      AdivinaWord(word: 'SSD', clue: 'Disco ultrarrápido sin partes móviles.'),
      AdivinaWord(
        word: 'Procesador',
        clue: 'Cerebro que calcula todo en chip.',
      ),
      AdivinaWord(
        word: 'Tarjeta gráfica',
        clue: 'Chip que dibuja juegos en pantalla.',
      ),
      AdivinaWord(word: 'Consola', clue: 'Aparato para jugar en tele.'),
      AdivinaWord(word: 'Smartwatch', clue: 'Reloj que mide pasos y notifica.'),
      AdivinaWord(
        word: 'Fibra óptica',
        clue: 'Cable de vidrio que lleva internet veloz.',
      ),
      AdivinaWord(
        word: '5G',
        clue: 'Red móvil superrápida de quinta generación.',
      ),
      AdivinaWord(
        word: 'Satélite',
        clue: 'Aparato que orbita la Tierra y transmite.',
      ),
      AdivinaWord(
        word: 'Cohete reutilizable',
        clue: 'Lanza y aterriza de pie para reusar.',
      ),
      AdivinaWord(
        word: 'Impresora 3D',
        clue: 'Fabrica objetos capa a capa con plástico.',
      ),
      AdivinaWord(
        word: 'Nanotecnología',
        clue: 'Manipula materia a escala diminuta.',
      ),
      AdivinaWord(
        word: 'Biometría',
        clue: 'Reconoce rostro o huella para desbloquear.',
      ),
      AdivinaWord(
        word: 'Quantum',
        clue: 'Computación cuántica con qubits superpuestos.',
      ),
      AdivinaWord(
        word: 'ChatGPT',
        clue: 'Asistente que conversa y escribe por ti.',
      ),
      AdivinaWord(
        word: 'Domótica',
        clue: 'Casa inteligente que se controla con voz.',
      ),
      AdivinaWord(
        word: 'Gafas de realidad mixta',
        clue: 'Mezclan mundo real y digital ante tus ojos.',
      ),
      AdivinaWord(
        word: 'Edge computing',
        clue: 'Procesa datos cerca del dispositivo, no en la nube lejana.',
      ),
      AdivinaWord(
        word: 'Exoesqueleto',
        clue: 'Armadura robótica que te hace más fuerte al caminar.',
      ),
      AdivinaWord(
        word: 'Vehículo autónomo',
        clue: 'Coche que conduce solo con sensores y mapas.',
      ),
      AdivinaWord(word: 'Lidar', clue: 'Láser que mapea distancias en 3D.'),
      AdivinaWord(
        word: 'CRISPR',
        clue: 'Tijeras genéticas que cortan ADN con precisión.',
      ),
      AdivinaWord(
        word: 'ARN mensajero',
        clue: 'Molécula que llevó instrucciones en vacunas recientes.',
      ),
      AdivinaWord(
        word: 'Holograma',
        clue: 'Imagen 3D flotante que parece sin pantalla.',
      ),
      AdivinaWord(
        word: 'Metaverso',
        clue: 'Mundo virtual donde avatares se reúnen.',
      ),
      AdivinaWord(
        word: 'NFT',
        clue: 'Certificado digital único que dice que posees algo.',
      ),
      AdivinaWord(
        word: 'Smart contract',
        clue: 'Acuerdo que se ejecuta solo en cadena de bloques.',
      ),
      AdivinaWord(
        word: 'Web3',
        clue: 'Internet descentralizado con cartera digital.',
      ),
      AdivinaWord(
        word: 'Kubernetes',
        clue: 'Orquesta contenedores como director de tráfico.',
      ),
      AdivinaWord(
        word: 'Docker',
        clue: 'Caja ligera que empaqueta app para que corra en cualquier lado.',
      ),
      AdivinaWord(
        word: 'Microservicios',
        clue: 'App partida en piezas pequeñas independientes.',
      ),
      AdivinaWord(
        word: 'Neuralink',
        clue: 'Chip cerebral de empresa que quiere conectar mente y máquina.',
      ),
      AdivinaWord(
        word: 'Impresión de órganos',
        clue: 'Bioimpresora que fabrica tejido humano capa a capa.',
      ),
      AdivinaWord(
        word: 'DeFi',
        clue: 'Finanzas sin banco, todo con protocolos.',
      ),
      AdivinaWord(
        word: 'Fog computing',
        clue: 'Nube intermedia entre dispositivo y centro de datos.',
      ),
      AdivinaWord(
        word: 'Radar cuántico',
        clue: 'Detecta sigilo usando entrelazamiento.',
      ),
      AdivinaWord(
        word: 'Biotecnología',
        clue: 'Usa seres vivos para crear productos y medicinas.',
      ),

      AdivinaWord(
        word: 'Machine learning',
        clue: 'Algoritmo que mejora con ejemplos. ',
      ),
      AdivinaWord(
        word: 'Deepfake',
        clue: 'Vídeo falso hiperrealista de cara. ',
      ),
      AdivinaWord(
        word: 'Prompt',
        clue: 'Instrucción que escribes a IA para que genere. ',
      ),
      AdivinaWord(
        word: 'Token',
        clue: 'Fragmento con que IA cuenta palabras. ',
      ),
      AdivinaWord(
        word: 'NPU',
        clue: 'Chip que acelera tareas de IA en móvil. ',
      ),
      AdivinaWord(
        word: 'Sensor LiDAR sólido',
        clue: 'Láser compacto que mapea entorno sin partes móviles. ',
      ),
      AdivinaWord(
        word: 'Radar milimétrico',
        clue: 'Onda que ve a través de niebla para coches. ',
      ),
      AdivinaWord(
        word: 'Starlink',
        clue: 'Constelación que da internet desde órbita baja. ',
      ),
      AdivinaWord(
        word: 'Beacon',
        clue: 'Baliza pequeña que avisa por cercanía. ',
      ),
      AdivinaWord(
        word: 'Firmware',
        clue: 'Software grabado en chip del aparato. ',
      ),
      AdivinaWord(
        word: 'Overclock',
        clue: 'Forzar chip más allá de su velocidad. ',
      ),
      AdivinaWord(
        word: 'Watercooling',
        clue: 'Tubos con líquido que enfrían ordenador. ',
      ),
      AdivinaWord(
        word: 'SSD NVMe',
        clue: 'Disco que va directo al bus rápido. ',
      ),
      AdivinaWord(
        word: 'Ray tracing',
        clue: 'Trazado de luz realista en juegos. ',
      ),
      AdivinaWord(
        word: 'DLSS',
        clue: 'IA que reescala fotogramas para más fps. ',
      ),
      AdivinaWord(
        word: 'OLED',
        clue: 'Píxel que emite luz propia sin retroiluminación. ',
      ),
      AdivinaWord(
        word: 'QLED',
        clue: 'Puntos cuánticos que mejoran brillo de tele. ',
      ),
      AdivinaWord(word: 'E-ink', clue: 'Tinta que permanece sin energía. '),
      AdivinaWord(
        word: 'Malla mesh',
        clue: 'Varios nodos que amplían wifi sin cortes. ',
      ),
      AdivinaWord(word: 'VPN', clue: 'Túnel que oculta tu IP y ubicación. '),
      AdivinaWord(word: 'RISC-V', clue: 'Arquitectura abierta que rivaliza con ARM.'),
      AdivinaWord(word: 'Chiplet', clue: 'Mosaico que une varios chips en uno.'),
      AdivinaWord(word: 'Photonics', clue: 'Datos con luz en lugar de cobre.'),
      AdivinaWord(word: 'Twin digital', clue: 'Gemelo virtual que simula fábrica.'),
      AdivinaWord(word: 'Federated learning', clue: 'Entrena sin mover datos del móvil.'),
      AdivinaWord(word: 'Homomorphic', clue: 'Calcula cifrado sin descifrar.'),
      AdivinaWord(word: 'Zero trust', clue: 'Nunca confíes, verifica siempre red.'),
      AdivinaWord(word: 'SASE', clue: 'Red y seguridad unidas en nube.'),
      AdivinaWord(word: 'eBPF', clue: 'Filtra kernel sin reiniciar sistema.'),
      AdivinaWord(word: 'WASM', clue: 'Binario veloz que corre en navegador.'),
      AdivinaWord(word: 'IPFS', clue: 'Almacenamiento distribuido por hash.'),
      AdivinaWord(word: 'Solid', clue: 'Pods donde guardas tus datos y prestas acceso.'),
      AdivinaWord(word: 'Matter', clue: 'Estándar que une bombillas de marcas distintas.'),
      AdivinaWord(word: 'Thread', clue: 'Malla de bajo consumo para hogar.'),
      AdivinaWord(word: 'UWB', clue: 'Ubicación centimétrica entre móviles.'),
      AdivinaWord(word: 'WiFi 7', clue: 'Banda que agrega canales para velocidad.'),
      AdivinaWord(word: 'LiFi', clue: 'Internet por luz parpadeante invisible.'),
      AdivinaWord(word: '6G demo', clue: 'Terahercios que prometen holograma móvil.'),
      AdivinaWord(word: 'DNA storage', clue: 'Guarda datos en hebras de ADN.'),
      AdivinaWord(word: 'Biochip', clue: 'Laboratorio en sello que analiza sangre.'),
    ],
    'VEHÍCULOS': [
      AdivinaWord(
        word: 'Coche eléctrico',
        clue: 'Sin gasolina, se enchufa y acelera silencioso.',
      ),
      AdivinaWord(
        word: 'Moto',
        clue: 'Dos ruedas motorizadas y casco obligatorio.',
      ),
      AdivinaWord(
        word: 'Autobús',
        clue: 'Grande y lleva muchos pasajeros por carriles.',
      ),
      AdivinaWord(word: 'Tranvía', clue: 'Tren urbano por railes en la calle.'),
      AdivinaWord(
        word: 'Tren bala',
        clue: 'Rapidísimo y puntual, flota casi en raíl.',
      ),
      AdivinaWord(
        word: 'Metro',
        clue: 'Subterráneo que conecta barrios bajo tierra.',
      ),
      AdivinaWord(word: 'Avión', clue: 'Alas fijas que vuela con turbinas.'),
      AdivinaWord(
        word: 'Helicóptero',
        clue: 'Hélice superior que vuela vertical.',
      ),
      AdivinaWord(
        word: 'Globo aerostático',
        clue: 'Cesta colgando de tela inflada con aire caliente.',
      ),
      AdivinaWord(word: 'Crucero', clue: 'Hotel flotante gigante por el mar.'),
      AdivinaWord(word: 'Velero', clue: 'Barco con velas empujado por viento.'),
      AdivinaWord(
        word: 'Camión',
        clue: 'Grande para carga pesada por carretera.',
      ),
      AdivinaWord(word: 'Tractor', clue: 'Trabaja campo y arrastra arado.'),
      AdivinaWord(
        word: 'Excavadora',
        clue: 'Brazo articulado que cava tierra.',
      ),
      AdivinaWord(word: 'Furgoneta', clue: 'Mediana para reparto y mudanzas.'),
      AdivinaWord(
        word: 'Bicicleta eléctrica',
        clue: 'Pedaleo asistido con batería.',
      ),
      AdivinaWord(
        word: 'Patinete eléctrico',
        clue: 'Pequeño de pie con motor en plataforma.',
      ),
      AdivinaWord(
        word: 'Submarino turístico',
        clue: 'Ventanas bajo el agua para ver peces.',
      ),
      AdivinaWord(
        word: 'Yate',
        clue: 'Barco de lujo para ricos en puerto deportivo.',
      ),
      AdivinaWord(
        word: 'Submarino militar',
        clue: 'Navega sumergido y lanza torpedos.',
      ),
      AdivinaWord(
        word: 'Telesilla',
        clue: 'Asientos colgados que suben esquiadores.',
      ),
      AdivinaWord(
        word: 'Monopatín eléctrico',
        clue: 'Tabla pequeña con motor para ciudad.',
      ),
      AdivinaWord(
        word: 'Carro de caballos',
        clue: 'Carruaje tirado por equinos.',
      ),
      AdivinaWord(
        word: 'Hoverboard',
        clue: 'Tabla flotante sin ruedas de ciencia ficción.',
      ),
      AdivinaWord(
        word: 'Segway',
        clue: 'Dos ruedas y manillar, te inclinas para avanzar.',
      ),
      AdivinaWord(
        word: 'Tuk tuk',
        clue: 'Moto taxi de tres ruedas muy ruidoso.',
      ),
      AdivinaWord(
        word: 'Limousina',
        clue: 'Coche larguísimo para fiestas y bodas.',
      ),
      AdivinaWord(
        word: 'Caravana',
        clue: 'Casa rodante que arrastras con coche.',
      ),
      AdivinaWord(word: 'Quad', clue: 'Cuatro ruedas para campo y dunas.'),
      AdivinaWord(word: 'Jet ski', clue: 'Moto de agua para saltar olas.'),
      AdivinaWord(
        word: 'Parapente motorizado',
        clue: 'Paracaídas con hélice en la espalda.',
      ),
      AdivinaWord(
        word: 'Tren de mercancías',
        clue: 'Vagones largos que llevan carbón.',
      ),
      AdivinaWord(
        word: 'Teleférico',
        clue: 'Cabina suspendida por cable sobre ciudad.',
      ),
      AdivinaWord(word: 'Hidroavión', clue: 'Despega y aterriza sobre el mar.'),
      AdivinaWord(
        word: 'Trineo',
        clue: 'Desliza sobre nieve tirado por perros.',
      ),
      AdivinaWord(
        word: 'Autocaravana',
        clue: 'Furgón vivienda para viajar y dormir.',
      ),
      AdivinaWord(
        word: 'Coche de carreras',
        clue: 'Bajo y veloz para circuitos.',
      ),
      AdivinaWord(
        word: 'Barco pesquero',
        clue: 'Sale a faenar con redes gigantes.',
      ),
      AdivinaWord(
        word: 'Avioneta',
        clue: 'Pequeña de hélice para vuelos cortos.',
      ),
      AdivinaWord(
        word: 'Moto de agua',
        clue: 'Chorros y velocidad sobre olas.',
      ),
      AdivinaWord(
        word: 'Monorraíl',
        clue: 'Tren elevado sobre un solo raíl en parques.',
      ),
      AdivinaWord(
        word: 'Maglev',
        clue: 'Flota magnéticamente y vuela sin tocar vía.',
      ),
      AdivinaWord(
        word: 'Trolebús',
        clue: 'Autobús eléctrico con dos pértigas al cable.',
      ),
      AdivinaWord(
        word: 'Autobús articulado',
        clue: 'Largo con acordeón en medio para muchos pasajeros.',
      ),
      AdivinaWord(
        word: 'Autobús de dos pisos',
        clue: 'Rojo londinense con escalera a la planta superior.',
      ),
      AdivinaWord(
        word: 'Camión cisterna',
        clue: 'Depósito cilíndrico que lleva líquidos peligrosos.',
      ),
      AdivinaWord(
        word: 'Camión frigorífico',
        clue: 'Caja blanca que mantiene frío en carretera.',
      ),
      AdivinaWord(
        word: 'Grúa torre',
        clue: 'Alta con brazo giratorio en obras de rascacielos.',
      ),
      AdivinaWord(
        word: 'Apisonadora',
        clue: 'Rodillo pesado que aplana asfalto recién echado.',
      ),
      AdivinaWord(
        word: 'Bulldozer',
        clue: 'Hoja frontal que empuja tierra y escombros.',
      ),
      AdivinaWord(
        word: 'Sidecar',
        clue: 'Carrito lateral pegado a moto para un pasajero extra.',
      ),
      AdivinaWord(word: 'Buggie', clue: 'Coche ligero sin puertas para dunas.'),
      AdivinaWord(
        word: 'Aerodeslizador',
        clue: 'Flota sobre colchón de aire en agua y tierra.',
      ),
      AdivinaWord(
        word: 'Hidroplano',
        clue: 'Avión pequeño que ameriza con flotadores.',
      ),
      AdivinaWord(
        word: 'Dirigible',
        clue: 'Globo alargado con hélices que flota lento.',
      ),
      AdivinaWord(
        word: 'Cohete espacial tripulado',
        clue: 'Cápsula que lleva astronautas más allá de la atmósfera.',
      ),
      AdivinaWord(
        word: 'Cuatriciclo',
        clue: 'Cuatro ruedas con manillar para campo.',
      ),
      AdivinaWord(
        word: 'Moto de trial',
        clue: 'Ligera para subir rocas sin apoyar pies.',
      ),
      AdivinaWord(
        word: 'Mototrailer',
        clue: 'Remolque cerrado para llevar motos de carrera.',
      ),
      AdivinaWord(
        word: 'Hidroavión anfibio',
        clue: 'Versión ligera con flotadores para amerizar.',
      ),

      AdivinaWord(word: 'Superyate', clue: 'Mansión flotante con helipuerto. '),
      AdivinaWord(
        word: 'Catamarán',
        clue: 'Dos cascos y red entre ellos para navegar. ',
      ),
      AdivinaWord(
        word: 'Trimarán',
        clue: 'Casco central con dos flotadores laterales. ',
      ),
      AdivinaWord(
        word: 'Ferri',
        clue: 'Transbordador que lleva coches entre islas. ',
      ),
      AdivinaWord(
        word: 'Glider',
        clue: 'Planeador sin motor que surca termales. ',
      ),
      AdivinaWord(
        word: 'Paramotor',
        clue: 'Parapente con motor a la espalda. ',
      ),
      AdivinaWord(
        word: 'Ultraligero',
        clue: 'Avioneta mínima de dos plazas y tela. ',
      ),
      AdivinaWord(
        word: 'Jet privado',
        clue: 'Pequeño reactor para ejecutivos. ',
      ),
      AdivinaWord(word: 'A380', clue: 'Superjumbo de dos pisos completo. '),
      AdivinaWord(
        word: 'Concorde',
        clue: 'Supersónico retirado con morro articulado. ',
      ),
      AdivinaWord(
        word: 'Hyperloop',
        clue: 'Cápsula al vacío a 1000 por hora. ',
      ),
      AdivinaWord(
        word: 'Monociclo eléctrico',
        clue: 'Rueda única que avanzas inclinándote. ',
      ),
      AdivinaWord(word: 'Kart', clue: 'Pequeño sin carrocería para circuito. '),
      AdivinaWord(
        word: 'Tuk-tuk eléctrico',
        clue: 'Versión silenciosa del triciclo asiático. ',
      ),
      AdivinaWord(
        word: 'Rickshaw',
        clue: 'Carro tirado a pie o bici en Asia. ',
      ),
      AdivinaWord(
        word: 'Carroza',
        clue: 'Carruaje elegante para desfiles reales. ',
      ),
      AdivinaWord(
        word: 'Cremallera',
        clue: 'Tren que sube con diente en montaña empinada. ',
      ),
      AdivinaWord(
        word: 'Funicular',
        clue: 'Vagones tirados por cable en pendiente empinada. ',
      ),
      AdivinaWord(
        word: 'Coche autónomo nivel 4',
        clue: 'Sin volante en zonas mapeadas. ',
      ),
      AdivinaWord(
        word: 'Ambulancia',
        clue: 'Sirena y camilla que corre al hospital. ',
      ),
      AdivinaWord(word: 'E-bike cargo', clue: 'Bici larga con cajón delantero para niños.'),
      AdivinaWord(word: 'Bici plegable', clue: 'Bisagra central que cabe en maleta.'),
      AdivinaWord(word: 'Velomóvil', clue: 'Triciclo carenado que pedaleas tumbado.'),
      AdivinaWord(word: 'Tandem', clue: 'Dos ciclistas en una sola bici.'),
      AdivinaWord(word: 'Bicitaxi', clue: 'Triciclo con asiento para turistas.'),
      AdivinaWord(word: 'Car sharing', clue: 'Coche por minutos con app.'),
      AdivinaWord(word: 'Moto trail', clue: 'Alta para asfalto y pista de tierra.'),
      AdivinaWord(word: 'Scrambler', clue: 'Retro con neumático mixto para campo ligero.'),
      AdivinaWord(word: 'Cafe racer', clue: 'Depósito alargado y colín recortado.'),
      AdivinaWord(word: 'Chopper', clue: 'Horquilla larga y manillar alto.'),
      AdivinaWord(word: 'Bobber', clue: 'Minimalista sin guardabarros trasero.'),
      AdivinaWord(word: 'Motocarro', clue: 'Tres ruedas con caja trasera para reparto.'),
      AdivinaWord(word: 'Autobús BRT', clue: 'Carril exclusivo y estaciones cerradas.'),
      AdivinaWord(word: 'Tranvía sin catenaria', clue: 'Carga por suelo en tramos históricos.'),
      AdivinaWord(word: 'Tren cremallera Montserrat', clue: 'Piñón que sube montaña sagrada.'),
      AdivinaWord(word: 'Ferry híbrido', clue: 'Batería y diésel que cruza fiordo sin humo.'),
      AdivinaWord(word: 'Hidroala', clue: 'Alas bajo agua que levantan casco y vuelan.'),
      AdivinaWord(word: 'Hovercraft rescate', clue: 'Colchón que entra a playa sin muelle.'),
      AdivinaWord(word: 'Zeppelin NT', clue: 'Dirigible moderno semirrígido para turismo.'),
      AdivinaWord(word: 'Jet eVTOL', clue: 'Taxi aéreo eléctrico que despega vertical.'),
    ],
    'HOGAR': [
      AdivinaWord(
        word: 'Sofá cama',
        clue: 'Se abre y se hace cama para invitados.',
      ),
      AdivinaWord(
        word: 'Lámpara de pie',
        clue: 'Alta y delgada que alumbra salón.',
      ),
      AdivinaWord(word: 'Alfombra', clue: 'Tejido suave para pisar descalzo.'),
      AdivinaWord(
        word: 'Cortina',
        clue: 'Tela que tapa ventana y da intimidad.',
      ),
      AdivinaWord(word: 'Estantería', clue: 'Baldas para libros y adornos.'),
      AdivinaWord(
        word: 'Lavadora',
        clue: 'Lava ropa girando con agua y jabón.',
      ),
      AdivinaWord(
        word: 'Secadora',
        clue: 'Seca ropa con aire caliente girando.',
      ),
      AdivinaWord(
        word: 'Lavavajillas',
        clue: 'Lava platos con chorros y pastilla.',
      ),
      AdivinaWord(
        word: 'Batidora',
        clue: 'Mezcla y tritura ingredientes girando cuchillas.',
      ),
      AdivinaWord(word: 'Tostadora', clue: 'Dora rebanadas con resistencia.'),
      AdivinaWord(
        word: 'Cafetera espresso',
        clue: 'Hace café con presión y espuma.',
      ),
      AdivinaWord(
        word: 'Aspiradora robot',
        clue: 'Ronda sola y vuelve a su base.',
      ),
      AdivinaWord(word: 'Plancha', clue: 'Alisa ropa con calor y vapor.'),
      AdivinaWord(word: 'Espejo de pie', clue: 'Refleja cuerpo entero.'),
      AdivinaWord(
        word: 'Cuadro decorativo',
        clue: 'Imagen artística que cuelga en pared.',
      ),
      AdivinaWord(word: 'Jarrón', clue: 'Recipiente para flores y adorno.'),
      AdivinaWord(word: 'Cojín', clue: 'Mullido para apoyar espalda o cabeza.'),
      AdivinaWord(word: 'Manta', clue: 'Abriga en sofá con tejido suave.'),
      AdivinaWord(
        word: 'Sillón',
        clue: 'Asiento grande para una persona con brazos.',
      ),
      AdivinaWord(
        word: 'Mesa de centro',
        clue: 'Baja delante del sofá para café.',
      ),
      AdivinaWord(
        word: 'Persiana',
        clue: 'Láminas que suben y bajan para oscurecer.',
      ),
      AdivinaWord(word: 'Toallero', clue: 'Barra para colgar trapos de baño.'),
      AdivinaWord(word: 'Ducha', clue: 'Rocía agua desde arriba para lavar.'),
      AdivinaWord(word: 'Armario', clue: 'Guarda ropa con puertas y estantes.'),
      AdivinaWord(
        word: 'Cómoda',
        clue: 'Cajonera baja para guardar camisetas.',
      ),
      AdivinaWord(
        word: 'Taburete',
        clue: 'Asiento alto sin respaldo para barra.',
      ),
      AdivinaWord(word: 'Puff', clue: 'Asiento blando sin patas para suelo.'),
      AdivinaWord(
        word: 'Vitrina',
        clue: 'Armario con cristal para exponer vajilla.',
      ),
      AdivinaWord(word: 'Cabecero', clue: 'Panel tras almohada en la cama.'),
      AdivinaWord(word: 'Mecedora', clue: 'Silla que se balancea sola.'),
      AdivinaWord(word: 'Tendedero', clue: 'Cuerdas para secar ropa al sol.'),
      AdivinaWord(
        word: 'Aspiradora escoba',
        clue: 'Vertical sin bolsa que pega a pared.',
      ),
      AdivinaWord(
        word: 'Frigorífico americano',
        clue: 'Dos puertas grandes con dispensador.',
      ),
      AdivinaWord(
        word: 'Horno de microondas grill',
        clue: 'Dora además de calentar.',
      ),
      AdivinaWord(
        word: 'Encimera',
        clue: 'Superficie de cocina para cortar alimentos.',
      ),
      AdivinaWord(word: 'Fregadero', clue: 'Pila de cocina con grifo.'),
      AdivinaWord(
        word: 'Campana extractora',
        clue: 'Absorbe humo sobre la cocina.',
      ),
      AdivinaWord(word: 'Mampara', clue: 'Cristal que cierra la ducha.'),
      AdivinaWord(
        word: 'Moqueta',
        clue: 'Suelo textil que cubre toda la habitación.',
      ),
      AdivinaWord(word: 'Hucha', clue: 'Cerdo cerámico para guardar monedas.'),
      AdivinaWord(
        word: 'Buró',
        clue: 'Escritorio pequeño con cajones para cartas.',
      ),
      AdivinaWord(
        word: 'Aparador',
        clue: 'Mueble bajo largo para vajilla en comedor.',
      ),
      AdivinaWord(
        word: 'Biombo',
        clue: 'Paneles plegables que separan ambiente y dan intimidad.',
      ),
      AdivinaWord(
        word: 'Perchero',
        clue: 'Pie con ganchos para colgar abrigos al entrar.',
      ),
      AdivinaWord(
        word: 'Zapatero',
        clue: 'Mueble estrecho donde guardas calzado en fila.',
      ),
      AdivinaWord(
        word: 'Isla de cocina',
        clue: 'Bloque central con encimera y taburetes alrededor.',
      ),
      AdivinaWord(
        word: 'Barra americana',
        clue: 'Mostrador alto que une cocina y salón.',
      ),
      AdivinaWord(
        word: 'Mesa extensible',
        clue: 'Se alarga con alas ocultas para invitados.',
      ),
      AdivinaWord(
        word: 'Silla plegable',
        clue: 'Se dobla plana y se guarda tras la puerta.',
      ),
      AdivinaWord(
        word: 'Hamaca',
        clue: 'Tela colgante entre dos árboles para siesta.',
      ),
      AdivinaWord(
        word: 'Tumbona',
        clue: 'Silla larga reclinable para tomar el sol.',
      ),
      AdivinaWord(word: 'Somier', clue: 'Base de láminas bajo colchón.'),
      AdivinaWord(
        word: 'Canapé abatible',
        clue: 'Cama que se levanta y esconde almacenaje debajo.',
      ),
      AdivinaWord(
        word: 'Colchón viscoelástico',
        clue: 'Espuma que recuerda tu forma al dormir.',
      ),
      AdivinaWord(
        word: 'Edredón nórdico',
        clue: 'Relleno cálido de plumas dentro de funda.',
      ),
      AdivinaWord(
        word: 'Cortina blackout',
        clue: 'Tela opaca que deja habitación a oscuras total.',
      ),
      AdivinaWord(
        word: 'Chifonier',
        clue: 'Cómoda alta y estrecha de muchos cajones.',
      ),
      AdivinaWord(
        word: 'Bodeguero',
        clue: 'Estante en X para botellas tumbadas.',
      ),
      AdivinaWord(
        word: 'Taburete de bar',
        clue: 'Asiento alto con reposapiés para barra.',
      ),
      AdivinaWord(
        word: 'Almohada viscoelástica',
        clue: 'Co jín que se adapta a cuello y cabeza.',
      ),

      AdivinaWord(
        word: 'Hornacina',
        clue: 'Hueco en pared para figura o jarrón. ',
      ),
      AdivinaWord(
        word: 'Otomana',
        clue: 'Sofá sin respaldo de estilo oriental. ',
      ),
      AdivinaWord(
        word: 'Chaise longue',
        clue: 'Silla larga para recostarse elegante. ',
      ),
      AdivinaWord(word: 'Escabel', clue: 'Banquito bajo para apoyar pies. '),
      AdivinaWord(
        word: 'Librero',
        clue: 'Mueble de baldas altas para libros. ',
      ),
      AdivinaWord(
        word: 'Celosía',
        clue: 'Panel calado que filtra luz y separa. ',
      ),
      AdivinaWord(word: 'Ménsula', clue: 'Repisa pequeña anclada sin patas. '),
      AdivinaWord(word: 'Cornisa', clue: 'Moldura saliente bajo el techo. '),
      AdivinaWord(
        word: 'Rodapié',
        clue: 'Listón que cubre junta suelo pared. ',
      ),
      AdivinaWord(
        word: 'Zócalo de pared',
        clue: 'Frase ya usada pero aquí revestimiento bajo de pared. ',
      ),
      AdivinaWord(
        word: 'Mosquitera',
        clue: 'Malla que deja aire pero no insectos. ',
      ),
      AdivinaWord(
        word: 'Estor',
        clue: 'Tela que se enrolla vertical en ventana. ',
      ),
      AdivinaWord(
        word: 'Visillo',
        clue: 'Cortina fina traslúcida que deja luz. ',
      ),
      AdivinaWord(
        word: 'Cubrecolchón',
        clue: 'Funda acolchada que protege colchón. ',
      ),
      AdivinaWord(
        word: 'Bajera',
        clue: 'Sábana que ajusta con gomas al colchón. ',
      ),
      AdivinaWord(
        word: 'Alfombra kilim',
        clue: 'Tejido plano sin pelo de origen turco. ',
      ),
      AdivinaWord(word: 'Plaid', clue: 'Manta ligera de cuadros para sofá. '),
      AdivinaWord(
        word: 'Perchero de pared',
        clue: 'Ganchos alineados para abrigos. ',
      ),
      AdivinaWord(
        word: 'Bandeja de desayuno',
        clue: 'Tabla con patas para comer en cama. ',
      ),
      AdivinaWord(
        word: 'Revistero',
        clue: 'Soporte vertical para revistas junto al sofá. ',
      ),
      AdivinaWord(word: 'Humidificador', clue: 'Niebla ultrasónica que alivia sequedad.'),
      AdivinaWord(word: 'Deshumidificador', clue: 'Extrae agua del aire con depósito.'),
      AdivinaWord(word: 'Purificador', clue: 'HEPA que atrapa polvo y alérgenos.'),
      AdivinaWord(word: 'Aroma difusor', clue: 'Vaporiza aceites esenciales con luz.'),
      AdivinaWord(word: 'Luz nocturna', clue: 'Enchufe tenue con sensor crepuscular.'),
      AdivinaWord(word: 'Tira LED', clue: 'Cinta adhesiva que cambia color con mando.'),
      AdivinaWord(word: 'Foco inteligente', clue: 'Bombilla que obedece a voz y app.'),
      AdivinaWord(word: 'Enchufe wifi', clue: 'Temporiza y mide consumo desde móvil.'),
      AdivinaWord(word: 'Regleta con USB', clue: 'Toma múltiple con carga rápida integrada.'),
      AdivinaWord(word: 'Alargador enrollable', clue: 'Tambor que recoge cable largo.'),
      AdivinaWord(word: 'Escalera telescópica', clue: 'Se pliega en tramos para altillo.'),
      AdivinaWord(word: 'Taburete plegable de tres patas', clue: 'Tripié que cabe en mochila.'),
      AdivinaWord(word: 'Carro de cocina', clue: 'Isla con ruedas y cajones estrecha.'),
      AdivinaWord(word: 'Escurridor plegable', clue: 'Silicona que se enrolla tras fregar.'),
      AdivinaWord(word: 'Tabla bambú', clue: 'Madera clara anti bacterias para cortar.'),
      AdivinaWord(word: 'Cuchillero magnético', clue: 'Barra que sostiene filos en pared.'),
      AdivinaWord(word: 'Organizador cajón', clue: 'Bandeja con compartimentos a medida.'),
      AdivinaWord(word: 'Bote hermético', clue: 'Tapa con goma que conserva galletas.'),
      AdivinaWord(word: 'Dispensador jabón automático', clue: 'Sensor infrarrojo sin tocar.'),
      AdivinaWord(word: 'Cepillo vapor', clue: 'Plancha vertical que alisa colgada.'),
    ],
    'PELICULAS': [
      AdivinaWord(
        word: 'Titanic',
        clue: 'Barco que choca con hielo y amor imposible.',
      ),
      AdivinaWord(
        word: 'Avatar',
        clue: 'Pandora, seres azules y árbol gigante.',
      ),
      AdivinaWord(word: 'Star Wars', clue: 'Galaxia, sables de luz y fuerza.'),
      AdivinaWord(
        word: 'El Rey León',
        clue: 'Cachorro que pierde a su padre y vuelve a reinar.',
      ),
      AdivinaWord(
        word: 'Frozen',
        clue: 'Hermana que congela reino y canta suelta.',
      ),
      AdivinaWord(
        word: 'Harry Potter',
        clue: 'Niño con cicatriz que va a escuela de magia.',
      ),
      AdivinaWord(
        word: 'El Padrino',
        clue: 'Familia mafiosa y oferta que no rechazarás.',
      ),
      AdivinaWord(
        word: 'Jurassic Park',
        clue: 'Parque con dinosaurios clonados que se escapan.',
      ),
      AdivinaWord(
        word: 'Toy Story',
        clue: 'Juguetes cobran vida cuando no miras.',
      ),
      AdivinaWord(
        word: 'Coco',
        clue: 'Niño viaja al mundo de muertos para cantar.',
      ),
      AdivinaWord(
        word: 'Avengers',
        clue: 'Grupo de héroes contra titán con guante.',
      ),
      AdivinaWord(
        word: 'Shrek',
        clue: 'Ogros verde que vive en pantano con burro.',
      ),
      AdivinaWord(
        word: 'Buscando a Nemo',
        clue: 'Pez payaso busca a hijo perdido.',
      ),
      AdivinaWord(
        word: 'La La Land',
        clue: 'Jazz, sueño en Los Ángeles y baile.',
      ),
      AdivinaWord(
        word: 'Matrix',
        clue: 'Pastilla roja y realidad simulada en código.',
      ),
      AdivinaWord(
        word: 'Los Vengadores',
        clue: 'Alternativa hispana del equipo de superhéroes.',
      ),
      AdivinaWord(
        word: 'Up',
        clue: 'Abuelo vuela casa con globos y niño explorador.',
      ),
      AdivinaWord(
        word: 'El Señor de los Anillos',
        clue: 'Anillo que debe destruirse en volcán.',
      ),
      AdivinaWord(
        word: 'Piratas del Caribe',
        clue: 'Capitán con ron y perla negra.',
      ),
      AdivinaWord(word: 'Cars', clue: 'Rayos y coches con ojos que compiten.'),
      AdivinaWord(
        word: 'Moana',
        clue: 'Chica del mar busca semidiós con anzuelo.',
      ),
      AdivinaWord(
        word: 'Aladdin',
        clue: 'Lámpara con genio y alfombra voladora.',
      ),
      AdivinaWord(
        word: 'Encanto',
        clue: 'Casa mágica en Colombia y vela que brilla.',
      ),
      AdivinaWord(
        word: 'Soul',
        clue: 'Alma de pianista que cae y busca chispa.',
      ),
      AdivinaWord(
        word: 'Inside Out',
        clue: 'Emociones dentro de cabeza de niña.',
      ),
      AdivinaWord(
        word: 'Minions',
        clue: 'Bichitos amarillos que sirven al villano.',
      ),
      AdivinaWord(
        word: 'Gru mi villano favorito',
        clue: 'Calvo que adopta niñas y roba luna.',
      ),
      AdivinaWord(
        word: 'Zootrópolis',
        clue: 'Zorro y coneja policía en ciudad animal.',
      ),
      AdivinaWord(
        word: 'Wall-E',
        clue: 'Robot solitario que limpia Tierra vacía.',
      ),
      AdivinaWord(
        word: 'Indiana Jones',
        clue: 'Sombrero y látigo buscando tesoros.',
      ),
      AdivinaWord(
        word: 'Volver al Futuro',
        clue: 'DeLorean que viaja en el tiempo.',
      ),
      AdivinaWord(
        word: 'El Joker',
        clue: 'Payaso triste que ríe y baila en escaleras.',
      ),
      AdivinaWord(word: 'Barbie', clue: 'Muñeca rosa que va al mundo real.'),
      AdivinaWord(
        word: 'Oppenheimer',
        clue: 'Físico que crea bomba y gana premio.',
      ),
      AdivinaWord(
        word: 'Interstellar',
        clue: 'Piloto cruza agujero para salvar humanidad.',
      ),
      AdivinaWord(word: 'Dune', clue: 'Desierto, especias y gusanos gigantes.'),
      AdivinaWord(
        word: 'Gladiator',
        clue: 'General que se vuelve luchador en arena.',
      ),
      AdivinaWord(
        word: 'Braveheart',
        clue: 'Escocés pintado que grita libertad.',
      ),
      AdivinaWord(
        word: 'Casablanca',
        clue: 'Bar en guerra con frase siempre nos quedará París.',
      ),
      AdivinaWord(
        word: 'Inception',
        clue: 'Sueños dentro de sueños y peonza que gira.',
      ),
      AdivinaWord(
        word: 'Pulp Fiction',
        clue: 'Maletín misterioso, baile y diálogos de gángsters.',
      ),
      AdivinaWord(
        word: 'El club de la lucha',
        clue: 'Primera regla: no hables de ello; jabón y peleas.',
      ),
      AdivinaWord(
        word: 'Cadena perpetua',
        clue: 'Prisión, túnel tras póster y esperanza.',
      ),
      AdivinaWord(
        word: 'Forrest Gump',
        clue: 'Corre sin parar, caja de bombones y vida simple.',
      ),
      AdivinaWord(
        word: 'El silencio de los corderos',
        clue: 'Caníbal que ayuda a cazar asesino con polillas.',
      ),
      AdivinaWord(word: 'Psicosis', clue: 'Ducha, motel y madre que no está.'),
      AdivinaWord(
        word: 'Ciudadano Kane',
        clue: 'Trineo llamado Rosebud y magnate de prensa.',
      ),
      AdivinaWord(
        word: 'Parásitos',
        clue: 'Sótano, familia pobre que se infiltra en mansión.',
      ),
      AdivinaWord(
        word: 'El pianista',
        clue: 'Varsovia en guerra y manos que tocan entre ruinas.',
      ),
      AdivinaWord(
        word: 'La vida es bella',
        clue: 'Padre que convierte campo en juego para su hijo.',
      ),
      AdivinaWord(
        word: 'El laberinto del fauno',
        clue: 'Niña, fauno y posguerra española con magia oscura.',
      ),
      AdivinaWord(
        word: 'Amélie',
        clue: 'Camarera parisina que arregla vidas ajenas a escondidas.',
      ),
      AdivinaWord(
        word: 'Intocable',
        clue: 'Millonario tetrapléjico y cuidador sin filtros.',
      ),
      AdivinaWord(
        word: 'Oldboy',
        clue: '15 años encerrado y martillo como venganza.',
      ),
      AdivinaWord(
        word: 'Seven',
        clue: 'Siete pecados y caja final bajo la lluvia.',
      ),
      AdivinaWord(
        word: 'El sexto sentido',
        clue: 'Veo gente muerta y niño con secreto.',
      ),
      AdivinaWord(
        word: 'El gran Lebowski',
        clue: 'Alfombra que unía la habitación y bolos.',
      ),
      AdivinaWord(
        word: 'Blade Runner',
        clue: 'Cazador de replicantes bajo lluvia y neón.',
      ),
      AdivinaWord(
        word: '2001 Odisea del espacio',
        clue: 'Monolito negro y HAL que no abre puertas.',
      ),
      AdivinaWord(
        word: 'Whiplash',
        clue: 'Batería sangrante y profesor que exige tempo perfecto.',
      ),

      AdivinaWord(
        word: 'El viaje de Chihiro',
        clue: 'Niña en casa de baños de espíritus y sin cara. ',
      ),
      AdivinaWord(
        word: 'Raya y el último dragón',
        clue: 'Guerrera busca fragmentos de gema de dragón. ',
      ),
      AdivinaWord(word: 'Luca', clue: 'Niño pez que quiere Vespa en Riviera. '),
      AdivinaWord(
        word: 'Turning Red',
        clue: 'Adolescente que se convierte en panda rojo al emocionarse. ',
      ),
      AdivinaWord(
        word: 'Spider-Verse',
        clue: 'Multiverso arácnido con animación punteada. ',
      ),
      AdivinaWord(
        word: 'Top Gun Maverick',
        clue: 'Piloto veterano enseña a jóvenes y vuela rasante. ',
      ),
      AdivinaWord(
        word: 'Elemental',
        clue: 'Fuego y agua que no deben mezclarse en ciudad. ',
      ),
      AdivinaWord(
        word: 'Jurado Nº2',
        clue: 'Juicio donde el jurado es el culpable. ',
      ),
      AdivinaWord(
        word: 'La sociedad de la nieve',
        clue: 'Accidente andino y supervivencia extrema uruguaya. ',
      ),
      AdivinaWord(
        word: 'Robot salvaje',
        clue: 'Autómata que cría ganso en isla. ',
      ),
      AdivinaWord(
        word: 'Flow',
        clue: 'Gato mudo en arca tras inundación mundial. ',
      ),
      AdivinaWord(
        word: 'Past Lives',
        clue: 'Reencuentro infantil coreano tras 24 años. ',
      ),
      AdivinaWord(
        word: 'Anatomía de una caída',
        clue: 'Juicio por caída mortal y perro guía. ',
      ),
      AdivinaWord(
        word: 'Ocho apellidos vascos',
        clue: 'Sevillano que finge ser vasco por amor. ',
      ),
      AdivinaWord(
        word: 'Campeones',
        clue: 'Entrenador castigado entrena equipo con discapacidad. ',
      ),
      AdivinaWord(
        word: 'Celda 211',
        clue: 'Funcionario atrapado en motín carcelario. ',
      ),
      AdivinaWord(
        word: 'El orfanato',
        clue: 'Madre busca niño perdido en casona misteriosa. ',
      ),
      AdivinaWord(
        word: 'REC',
        clue: 'Cámara en edificio infectado y oscuridad. ',
      ),
      AdivinaWord(
        word: 'Lo imposible',
        clue: 'Tsunami separa familia en Tailandia. ',
      ),
      AdivinaWord(
        word: 'Mar adentro',
        clue: 'Gallego pide morir dignamente tras accidente. ',
      ),
      AdivinaWord(word: 'Encanto 2 rumor', clue: 'Secuela casa mágica colombiana aún no oficial.'),
      AdivinaWord(word: 'Avatar 3', clue: 'Tercera parte de Pandora con fuego y ceniza.'),
      AdivinaWord(word: 'Misión Imposible 8', clue: 'Crucero final de Ethan con sentencia mortal.'),
      AdivinaWord(word: 'John Wick 4', clue: 'Neón y escalera infinita en París.'),
      AdivinaWord(word: 'Spider-Man No Way Home', clue: 'Tres arañas abren multiverso nostálgico.'),
      AdivinaWord(word: 'The Batman', clue: 'Murciélago detective bajo lluvia y emo.'),
      AdivinaWord(word: 'Joker 2 Folie', clue: 'Musical en Arkham con Lady Gaga.'),
      AdivinaWord(word: 'Barbie Dreamhouse', clue: 'Variante live action rosado alternativo título.'),
      AdivinaWord(word: 'Oppenheimer IMAX', clue: 'Bomba en 70mm sin CGI añadido.'),
      AdivinaWord(word: 'Killers Flower Moon', clue: 'Osage y petróleo con Scorsese épico.'),
      AdivinaWord(word: 'Past Lives Seoul', clue: 'Reencuentro coreano con déjà vu.'),
      AdivinaWord(word: 'Anatomía caída perro', clue: 'Messi el border colie testigo clave.'),
      AdivinaWord(word: 'Flow cat', clue: 'Gato sin diálogos en diluvio animado.'),
      AdivinaWord(word: 'Robot Dreams', clue: 'Perro y robot amigos en Nueva York 80.'),
      AdivinaWord(word: 'Nimona', clue: 'Metamorfa punk contra caballero medieval.'),
      AdivinaWord(word: 'Wish', clue: 'Estrella que cumple deseos Disney 100.'),
      AdivinaWord(word: 'Elemental Pixar', clue: 'Fuego y agua románticos en ciudad.'),
      AdivinaWord(word: 'Mario Bros película', clue: 'Fontanero arcades que salva princesa en cine.'),
      AdivinaWord(word: 'Gran Turismo', clue: 'Gamer que se vuelve piloto real.'),
      AdivinaWord(word: 'Napoleón Ridley', clue: 'Corona y cañones con Joaquin Phoenix.'),
    ],
    'SERIES/VIDEOJUEGOS': [
      AdivinaWord(
        word: 'Stranger Things',
        clue: 'Niños en bicicleta contra mundo del revés.',
      ),
      AdivinaWord(
        word: 'La Casa de Papel',
        clue: 'Atraco con monos rojos y profesor.',
      ),
      AdivinaWord(
        word: 'Game of Thrones',
        clue: 'Tronos de hierro y dragones en invierno.',
      ),
      AdivinaWord(
        word: 'Breaking Bad',
        clue: 'Profesor de química cocina cristal azul.',
      ),
      AdivinaWord(
        word: 'Minecraft',
        clue: 'Cubos infinitos para picar y construir.',
      ),
      AdivinaWord(
        word: 'Fortnite',
        clue: 'Cien caen en isla y construyen rampas.',
      ),
      AdivinaWord(
        word: 'FIFA',
        clue: 'Simulador de goles con cartas y sobres.',
      ),
      AdivinaWord(
        word: 'Mario Bros',
        clue: 'Fontanero salta sobre tortugas y setas.',
      ),
      AdivinaWord(word: 'Zelda', clue: 'Elfo con espada y princesa hyliana.'),
      AdivinaWord(
        word: 'Among Us',
        clue: 'Tripulantes buscan impostor que sabotea.',
      ),
      AdivinaWord(
        word: 'Call of Duty',
        clue: 'Disparos en primera persona y guerra.',
      ),
      AdivinaWord(
        word: 'League of Legends',
        clue: 'Cinco contra cinco y grieta del invocador.',
      ),
      AdivinaWord(
        word: 'Grand Theft Auto',
        clue: 'Mundo abierto con atracos y coches.',
      ),
      AdivinaWord(
        word: 'Pokémon',
        clue: 'Atrapar criaturas con bolas y gimnasios.',
      ),
      AdivinaWord(
        word: 'Los Simpsons',
        clue: 'Familia amarilla de cinco en Springfield.',
      ),
      AdivinaWord(word: 'Friends', clue: 'Seis cafeteros en sofá neoyorquino.'),
      AdivinaWord(
        word: 'The Last of Us',
        clue: 'Hongo zombie y viaje padre-hija postapocalíptico.',
      ),
      AdivinaWord(
        word: 'The Witcher',
        clue: 'Lobo blanco caza monstruos con dos espadas.',
      ),
      AdivinaWord(word: 'Naruto', clue: 'Ninja rubio con zorro dentro.'),
      AdivinaWord(word: 'Dragon Ball', clue: 'Siete bolas que invocan dragón.'),
      AdivinaWord(word: 'Elite', clue: 'Instituto pijo con secretos y muerte.'),
      AdivinaWord(
        word: 'The Mandalorian',
        clue: 'Cazarrecompensas y bebé verde con orejas.',
      ),
      AdivinaWord(
        word: 'Casa del Dragón',
        clue: 'Precuela con targaryens y fuego.',
      ),
      AdivinaWord(
        word: 'One Piece',
        clue: 'Sombrero de paja busca tesoro gigante.',
      ),
      AdivinaWord(
        word: 'Clash Royale',
        clue: 'Cartas y torres a derribar en arena.',
      ),
      AdivinaWord(
        word: 'Valorant',
        clue: 'Agentes con habilidades y disparos tácticos.',
      ),
      AdivinaWord(
        word: 'Overwatch',
        clue: 'Héroes con ulti y partida de Payload.',
      ),
      AdivinaWord(
        word: 'Animal Crossing',
        clue: 'Isla con vecinos animales y museo.',
      ),
      AdivinaWord(
        word: 'Elden Ring',
        clue: 'Mundo abierto difícil con caballero y anillo.',
      ),
      AdivinaWord(
        word: 'Cyberpunk',
        clue: 'Ciudad neón con implantes y Keanu.',
      ),
      AdivinaWord(
        word: 'Squid Game',
        clue: 'Trajes verdes, muñeca gigante y luz roja luz verde.',
      ),
      AdivinaWord(
        word: 'Wednesday',
        clue: 'Colegio Nevermore, trenzas y thing sin palabras.',
      ),
      AdivinaWord(
        word: 'Dark',
        clue: 'Cueva, viajes en el tiempo y familias en bucle alemán.',
      ),
      AdivinaWord(
        word: 'Black Mirror',
        clue: 'Antología tecnológica que deja mal cuerpo.',
      ),
      AdivinaWord(
        word: 'Better Call Saul',
        clue: 'Abogado que pasa de estafador a criminal.',
      ),
      AdivinaWord(
        word: 'The Office',
        clue: 'Oficina de papel y jefe que quiere ser gracioso.',
      ),
      AdivinaWord(
        word: 'Brooklyn Nine-Nine',
        clue: 'Comisaría, chistes y detective fan de Jungla.',
      ),
      AdivinaWord(
        word: 'Severance',
        clue: 'Ascensor que separa memoria de trabajo y vida.',
      ),
      AdivinaWord(
        word: 'Ted Lasso',
        clue: 'Entrenador optimista americano con galletas.',
      ),
      AdivinaWord(
        word: 'Halo',
        clue: 'Casco verde y anillo gigante contra alienígenas.',
      ),
      AdivinaWord(
        word: 'Gears of War',
        clue: 'Motosierra en fusil y enemigos subterráneos.',
      ),
      AdivinaWord(
        word: 'Uncharted',
        clue: 'Cazatesoros con bromas y escalada imposible.',
      ),
      AdivinaWord(
        word: 'Horizon Zero Dawn',
        clue: 'Pelirroja contra dinosaurios robot en futuro tribal.',
      ),
      AdivinaWord(
        word: 'Ghost of Tsushima',
        clue: 'Samurái que duda entre honor y sigilo en isla invadida.',
      ),
      AdivinaWord(
        word: 'Sekiro',
        clue: 'Shinobi manco con prótesis y cuervo que resucita.',
      ),
      AdivinaWord(
        word: 'Bloodborne',
        clue: 'Cazador victoriano contra bestias y sangre.',
      ),
      AdivinaWord(
        word: 'Dark Souls',
        clue: 'Hoguera, mueres y vuelves a intentarlo difícil.',
      ),
      AdivinaWord(
        word: 'Resident Evil',
        clue: 'Mansión, zombis y hierbas verdes para curar.',
      ),
      AdivinaWord(
        word: 'Silent Hill',
        clue: 'Niebla, radio que cruje y enfermera sin rostro.',
      ),
      AdivinaWord(
        word: 'Red Dead Redemption',
        clue: 'Vaquero en mundo abierto que busca redención.',
      ),

      AdivinaWord(
        word: 'Peaky Blinders',
        clue: 'Boinas con cuchillas en Birmingham postguerra. ',
      ),
      AdivinaWord(
        word: 'Succession',
        clue: 'Familia dueña de imperio mediático que se traiciona. ',
      ),
      AdivinaWord(
        word: 'Euphoria',
        clue: 'Brillos, instituto y caos adolescente americano. ',
      ),
      AdivinaWord(
        word: 'Ahsoka',
        clue: 'Jedi que abandona orden y busca mapa estelar. ',
      ),
      AdivinaWord(
        word: 'Fleabag',
        clue: 'Mujer londinense que mira a cámara con culpa. ',
      ),
      AdivinaWord(
        word: 'The Bear',
        clue: 'Sándwich de Chicago y cocina caótica tras herencia. ',
      ),
      AdivinaWord(
        word: 'Chernobyl',
        clue: 'Serie de explosión nuclear y contador Geiger. ',
      ),
      AdivinaWord(
        word: 'Mindhunter',
        clue: 'FBI entrevista asesinos para perfilar mentes. ',
      ),
      AdivinaWord(word: 'Narcos', clue: 'Pablo y DEA en Colombia. '),
      AdivinaWord(
        word: 'Vikings',
        clue: 'Ragnar surca mares con hachas y escudos. ',
      ),
      AdivinaWord(
        word: 'The Crown',
        clue: 'Reina inglesa y palacio con décadas. ',
      ),
      AdivinaWord(
        word: 'Bridgerton',
        clue: 'Bailes y chismes en Londres regencia. ',
      ),
      AdivinaWord(
        word: 'Sex Education',
        clue: 'Hijo de terapeuta da consejos en instituto. ',
      ),
      AdivinaWord(
        word: 'Heartstopper',
        clue: 'Dos chicos y hojas que crecen entre ellos. ',
      ),
      AdivinaWord(
        word: 'Arcane',
        clue: 'Hermanas y hextech en ciudades divididas animadas. ',
      ),
      AdivinaWord(
        word: 'Hades',
        clue: 'Príncipe que escapa del inframundo con dash. ',
      ),
      AdivinaWord(
        word: 'Hollow Knight',
        clue: 'Caballero insecto en reino subterráneo difícil. ',
      ),
      AdivinaWord(
        word: 'God of War',
        clue: 'Padre con hacha y hijo rubio contra dioses nórdicos. ',
      ),
      AdivinaWord(
        word: 'Baldur\'s Gate 3',
        clue: 'Dados, mente con renacuajo y rol épico. ',
      ),
      AdivinaWord(
        word: 'Stardew Valley',
        clue: 'Granja pixelada y pueblo acogedor para cultivar. ',
      ),
      AdivinaWord(
        word: 'Celeste',
        clue: 'Chica escala montaña con fresas y ansiedad. ',
      ),
      AdivinaWord(
        word: 'Cuphead',
        clue: 'Tazas con jefe difícil estilo años 30. ',
      ),
      AdivinaWord(
        word: 'Fall Guys',
        clue: 'Salchichas que tropiezan en carrera loca. ',
      ),
      AdivinaWord(
        word: 'Genshin Impact',
        clue: 'Mundo abierto anime con resina y gacha. ',
      ),
      AdivinaWord(
        word: 'Apex Legends',
        clue: 'Battle royale con leyendas y ping. ',
      ),
      AdivinaWord(
        word: 'Silksong',
        clue: 'Secuela insecto que espera fans con aguijón. ',
      ),
      AdivinaWord(
        word: 'Lies of P',
        clue: 'Pinocho oscuro en ciudad Belle Époque. ',
      ),
      AdivinaWord(
        word: 'Starfield',
        clue: 'Nave y planetas generados infinitos de Bethesda. ',
      ),
      AdivinaWord(
        word: 'Hogwarts Legacy',
        clue: 'Alumno tardío en castillo mágico abierto. ',
      ),
      AdivinaWord(
        word: 'It Takes Two',
        clue: 'Pareja convertida en muñecos coop obligatoria. ',
      ),
      AdivinaWord(word: 'House of Dragon S2', clue: 'Danza de dragones continúa con más fuego.'),
      AdivinaWord(word: 'The Bear S2', clue: 'Cocina que busca estrella Michelin.'),
      AdivinaWord(word: 'One Punch Man', clue: 'Calvo que mata de un golpe y se aburre.'),
      AdivinaWord(word: 'Jujutsu Kaisen', clue: 'Dedos malditos y exorcistas adolescentes.'),
      AdivinaWord(word: 'Demon Slayer', clue: 'Respiración y tren infinito en anime.'),
      AdivinaWord(word: 'Attack Titan', clue: 'Murallas y titanes con giro final.'),
      AdivinaWord(word: 'Death Note', clue: 'Cuaderno que mata al escribir nombre.'),
      AdivinaWord(word: 'Fullmetal Alchemist', clue: 'Equivalencia y piedra filosofal hermanos.'),
      AdivinaWord(word: 'Steins Gate', clue: 'Microondas que manda mensajes al pasado.'),
      AdivinaWord(word: 'Cyberpunk Edgerunners', clue: 'Anime de Night City con final triste.'),
      AdivinaWord(word: 'Arcane S2', clue: 'Hextech y Jinx más caótica.'),
      AdivinaWord(word: 'Elden Ring DLC', clue: 'Sombra del Erdtree difícil y vasta.'),
      AdivinaWord(word: 'Zelda Tears Kingdom', clue: 'Islas cielo y construcción con ultrahand.'),
      AdivinaWord(word: 'Mario Wonder', clue: 'Efecto sorpresa que cambia nivel entero.'),
      AdivinaWord(word: 'Spider-Man 2 PS5', clue: 'Dos arañas y simbionte en Nueva York.'),
      AdivinaWord(word: 'Alan Wake 2', clue: 'Escritor atrapado y FBI con linterna.'),
      AdivinaWord(word: 'Baldur 4 rumor', clue: 'Sucesor con más dados y romance.'),
      AdivinaWord(word: 'Hogwarts Quidditch', clue: 'Escoba deportiva en juego aparte.'),
      AdivinaWord(word: 'Starfield Shattered', clue: 'Expansión serpentina espacial.'),
      AdivinaWord(word: 'GTA 6 Trailer', clue: 'Vice City con Lucía y filtración histórica.'),
    ],
    'PAISES': [
      AdivinaWord(
        word: 'Japón',
        clue: 'Islas del sol naciente, sushi y anime.',
      ),
      AdivinaWord(
        word: 'Brasil',
        clue: 'Río gigante, carnaval y fútbol en Copacabana.',
      ),
      AdivinaWord(
        word: 'Canadá',
        clue: 'Hoja de arce, cataratas del Niágara y sirope.',
      ),
      AdivinaWord(
        word: 'Italia',
        clue: 'Bota mediterránea, coliseo y pizza napolitana.',
      ),
      AdivinaWord(
        word: 'Egipto',
        clue: 'Pirámides, Nilo y faraones momificados.',
      ),
      AdivinaWord(
        word: 'Australia',
        clue: 'Canguros, ópera de Sídney y gran barrera de coral.',
      ),
      AdivinaWord(
        word: 'México',
        clue: 'Capital con Zócalo, tacos y mariachis.',
      ),
      AdivinaWord(
        word: 'Argentina',
        clue: 'Tango, pampas y glaciar Perito Moreno.',
      ),
      AdivinaWord(
        word: 'España',
        clue: 'Paella, flamenco y capital con oso y madroño.',
      ),
      AdivinaWord(
        word: 'Francia',
        clue: 'Torre de hierro, vino y croissant parisino.',
      ),
      AdivinaWord(
        word: 'Alemania',
        clue: 'Muro caído, cerveza y capital a orillas del Spree.',
      ),
      AdivinaWord(
        word: 'India',
        clue: 'Taj Mahal, Ganges y especias coloridas.',
      ),
      AdivinaWord(
        word: 'China',
        clue: 'Muralla infinita, dragones y capital con Ciudad Prohibida.',
      ),
      AdivinaWord(
        word: 'Reino Unido',
        clue: 'Big Ben, té y reina con guardia de oso.',
      ),
      AdivinaWord(
        word: 'Rusia',
        clue: 'Kremlin, tundra y el país más extenso del mundo.',
      ),
      AdivinaWord(word: 'Sudáfrica', clue: 'Tres capitales, safari y mandela.'),
      AdivinaWord(
        word: 'Noruega',
        clue: 'Fiordos, auroras y capital de barcos vikingos.',
      ),
      AdivinaWord(
        word: 'Grecia',
        clue: 'Acrópolis, olivos y cuna de Juegos Olímpicos.',
      ),
      AdivinaWord(
        word: 'Turquía',
        clue: 'Estambul a dos continentes y mezquita azul.',
      ),
      AdivinaWord(
        word: 'Tailandia',
        clue: 'Templos dorados, pad thai y elefantes.',
      ),
      AdivinaWord(
        word: 'Perú',
        clue: 'Machu Picchu, ceviche y andes quechuas.',
      ),
      AdivinaWord(
        word: 'Chile',
        clue: 'País largo y estrecho con desierto de Atacama.',
      ),
      AdivinaWord(
        word: 'Colombia',
        clue: 'Café, arepas y capital a 2600 metros.',
      ),
      AdivinaWord(
        word: 'Suecia',
        clue: 'ABBA, IKEA y auroras sobre Estocolmo.',
      ),
      AdivinaWord(
        word: 'Nueva Zelanda',
        clue: 'Kiwi, hobbits y capital del viento Wellington.',
      ),
      AdivinaWord(
        word: 'Marruecos',
        clue: 'Medina azul, zocos y capital con torre Hassan.',
      ),
      AdivinaWord(
        word: 'Portugal',
        clue: 'Fado, bacalao y capital de tranvías amarillos.',
      ),
      AdivinaWord(
        word: 'Islandia',
        clue: 'Géiseres, volcanes y capital más al norte del mundo.',
      ),
      AdivinaWord(
        word: 'Suiza',
        clue: 'Alpes, chocolate y capital con oso de Berna.',
      ),
      AdivinaWord(
        word: 'Irlanda',
        clue: 'Trébol, pub y capital con río Liffey.',
      ),
      AdivinaWord(word: 'Polonia', clue: 'Varsovia reconstruida y pierogis.'),
      AdivinaWord(
        word: 'Corea del Sur',
        clue: 'K-pop, Seúl y frontera con el norte.',
      ),
      AdivinaWord(
        word: 'Estados Unidos',
        clue: 'Barras y estrellas, Hollywood y capital con Casa Blanca.',
      ),
      AdivinaWord(
        word: 'Países Bajos',
        clue: 'Tulipanes, bicicletas y canales de Ámsterdam.',
      ),
      AdivinaWord(
        word: 'Bélgica',
        clue: 'Chocolate, gofres y capital con Manneken Pis.',
      ),
      AdivinaWord(
        word: 'Dinamarca',
        clue: 'Sirenita, LEGO y capital ciclista.',
      ),
      AdivinaWord(
        word: 'Finlandia',
        clue: 'Saunas, lagos y capital con catedral blanca sobre el Báltico.',
      ),
      AdivinaWord(word: 'Austria', clue: 'Vals, Alpes y capital de Mozart.'),
      AdivinaWord(
        word: 'Hungría',
        clue: 'Parlamento junto al Danubio y goulash.',
      ),
      AdivinaWord(
        word: 'República Checa',
        clue: 'Castillo de Praga y cerveza dorada.',
      ),

      AdivinaWord(
        word: 'Mongolia',
        clue: 'Estepa, yurtas y Gengis Kan a caballo. ',
      ),
      AdivinaWord(
        word: 'Kazajistán',
        clue: 'Estepa infinita y cosmódromo de Baikonur. ',
      ),
      AdivinaWord(
        word: 'Uzbekistán',
        clue: 'Mezquitas azules de Samarcanda en Ruta de la Seda. ',
      ),
      AdivinaWord(
        word: 'Nepal',
        clue: 'Techos del mundo y templo de Katmandú. ',
      ),
      AdivinaWord(word: 'Bután', clue: 'Reino del dragón que mide felicidad. '),
      AdivinaWord(word: 'Malasia', clue: 'Torres Petronas y selva de Borneo. '),
      AdivinaWord(
        word: 'Indonesia',
        clue: 'Mil islas, Bali y dragones de Komodo. ',
      ),
      AdivinaWord(
        word: 'Filipinas',
        clue: '7000 islas, jeepneys y arrozales en terrazas. ',
      ),
      AdivinaWord(
        word: 'Vietnam',
        clue: 'Sombrero cónico, bahía de Halong y pho. ',
      ),
      AdivinaWord(word: 'Camboya', clue: 'Templos de Angkor entre selva. '),
      AdivinaWord(
        word: 'Myanmar',
        clue: 'Pagodas doradas y lago Inle con remeros de pie. ',
      ),
      AdivinaWord(
        word: 'Sri Lanka',
        clue: 'Lágrima del Índico con té y elefantes. ',
      ),
      AdivinaWord(word: 'Pakistán', clue: 'Karachi, K2 y valle de Hunza. '),
      AdivinaWord(
        word: 'Bangladés',
        clue: 'Delta del Ganges y rickshaws coloridos. ',
      ),
      AdivinaWord(
        word: 'Etiopía',
        clue: 'Cuna de Lucy, iglesias excavadas y café. ',
      ),
      AdivinaWord(word: 'Kenia', clue: 'Sabana, masaís y gran migración. '),
      AdivinaWord(
        word: 'Tanzania',
        clue: 'Kilimanjaro y Serengeti con baobabs. ',
      ),
      AdivinaWord(word: 'Senegal', clue: 'Dakar, isla de Gorée y teranga. '),
      AdivinaWord(word: 'Ghana', clue: 'Costa de Oro y mercado de Makola. '),
      AdivinaWord(word: 'Nigeria', clue: 'Lagos, Nollywood y afrobeats. '),
      AdivinaWord(
        word: 'Catar',
        clue: 'Península con perlas y mundial de estadios. ',
      ),
      AdivinaWord(
        word: 'Emiratos Árabes',
        clue: 'Dunas y rascacielos en Dubái. ',
      ),
      AdivinaWord(
        word: 'Arabia Saudita',
        clue: 'Desierto, La Meca y futurismo NEOM. ',
      ),
      AdivinaWord(word: 'Jordania', clue: 'Petra rosa y mar Muerto flotante. '),
      AdivinaWord(
        word: 'Líbano',
        clue: 'Cedros, Beirut y mezcla mediterránea. ',
      ),
      AdivinaWord(
        word: 'Israel',
        clue: 'Muro de lamentaciones y Tel Aviv Bauhaus. ',
      ),
      AdivinaWord(
        word: 'Panamá',
        clue: 'Canal que une dos océanos y sombrero no panameño. ',
      ),
      AdivinaWord(
        word: 'Costa Rica',
        clue: 'Pura vida, selva y volcán Arenal. ',
      ),
      AdivinaWord(
        word: 'Uruguay',
        clue: 'Mansa y chivito entre Brasil y Argentina. ',
      ),
      AdivinaWord(
        word: 'Paraguay',
        clue: 'Guaraní, tereré y represa de Itaipú. ',
      ),
      AdivinaWord(
        word: 'Bolivia',
        clue: 'Altiplano, salar de Uyuni y cholitas. ',
      ),
      AdivinaWord(
        word: 'Ecuador',
        clue: 'Mitad del mundo y Galápagos de Darwin. ',
      ),
      AdivinaWord(word: 'Cuba', clue: 'Habana, mojito y coches de los 50. '),
      AdivinaWord(
        word: 'Jamaica',
        clue: 'Reggae, Blue Mountains y jerk chicken. ',
      ),
      AdivinaWord(
        word: 'Haití',
        clue: 'Primera república negra y palacios sin terminar. ',
      ),
      AdivinaWord(
        word: 'Luxemburgo',
        clue: 'Pequeño ducado entre bosques y fortalezas. ',
      ),
      AdivinaWord(
        word: 'Malta',
        clue: 'Cruz de caballeros y agua azul mediterránea. ',
      ),
      AdivinaWord(
        word: 'Chipre',
        clue: 'Isla dividida de Afrodita y halloumi. ',
      ),
      AdivinaWord(
        word: 'Estonia',
        clue: 'Tallin medieval y país digital báltico. ',
      ),
      AdivinaWord(word: 'Letonia', clue: 'Riga art nouveau y ámbar báltico. '),
      AdivinaWord(word: 'Fiyi', clue: 'Islas con agua cristalina y kava ceremonial.'),
      AdivinaWord(word: 'Vanuatu', clue: 'Volcán activo y chozas sobre agua.'),
      AdivinaWord(word: 'Samoa', clue: 'Tatuaje tradicional y playas de lava.'),
      AdivinaWord(word: 'Tonga', clue: 'Reino polinesio donde ballenas paren.'),
      AdivinaWord(word: 'Micronesia', clue: 'Atolones y ruinas de Nan Madol.'),
      AdivinaWord(word: 'Palaos', clue: 'Lago de medusas sin aguijón donde nadas.'),
      AdivinaWord(word: 'Maldivas detallada', clue: 'Atolones y villas sobre agua palafito.'),
      AdivinaWord(word: 'Seichelles', clue: 'Granito rosa y coco de mer.'),
      AdivinaWord(word: 'Mauricio', clue: 'Dodo extinto y playa con montaña Le Morne.'),
      AdivinaWord(word: 'Ruanda', clue: 'Gorilas de niebla y colinas mil.'),
      AdivinaWord(word: 'Uganda', clue: 'Fuente del Nilo y chimpancés.'),
      AdivinaWord(word: 'Botswana', clue: 'Delta y safari sin vallas.'),
      AdivinaWord(word: 'Namibia extendida', clue: 'Esqueleto coast y tribu Himba.'),
      AdivinaWord(word: 'Zimbabue', clue: 'Ruinas de Gran Zimbabue y Victoria Falls lado.'),
      AdivinaWord(word: 'Mozambique', clue: 'Isla de Mozambique y buceo con mantas.'),
      AdivinaWord(word: 'Angola', clue: 'Desierto y palanca negra gigante antílope.'),
      AdivinaWord(word: 'Argelia', clue: 'Sahara con ciudades romanas y casbah.'),
      AdivinaWord(word: 'Túnez', clue: 'Cartago y desierto de Star Wars.'),
      AdivinaWord(word: 'Omán', clue: 'Zocos de incienso y fortalezas de barro.'),
      AdivinaWord(word: 'Baréin', clue: 'Perlas y circuito de F1 en desierto.'),
    ],
    'MARCAS': [
      AdivinaWord(
        word: 'Nike',
        clue: 'Swoosh que viste a deportistas y dice hazlo.',
      ),
      AdivinaWord(
        word: 'Apple',
        clue: 'Fruta mordida que vende teléfonos y ordenadores minimalistas.',
      ),
      AdivinaWord(
        word: 'Coca-Cola',
        clue: 'Refresco burbujeante rojo con oso polar en Navidad.',
      ),
      AdivinaWord(
        word: 'McDonald\'s',
        clue: 'Arcos dorados con payaso y cajita feliz.',
      ),
      AdivinaWord(
        word: 'Samsung',
        clue: 'Gigante coreano de móviles y teles con galaxia en nombre.',
      ),
      AdivinaWord(
        word: 'Adidas',
        clue: 'Tres franjas alemanas que compiten con el swoosh.',
      ),
      AdivinaWord(
        word: 'Google',
        clue: 'Buscador colorido que responde todo y tiene doodles.',
      ),
      AdivinaWord(
        word: 'Amazon',
        clue: 'Sonrisa de flecha que envía paquetes a casa en un día.',
      ),
      AdivinaWord(
        word: 'Tesla',
        clue: 'Rayo que hace coches eléctricos con piloto automático.',
      ),
      AdivinaWord(
        word: 'Starbucks',
        clue: 'Sirena verde que sirve cafés con tu nombre escrito mal.',
      ),
      AdivinaWord(
        word: 'Netflix',
        clue: 'N roja que hace maratones y pregunta ¿sigues ahí?',
      ),
      AdivinaWord(
        word: 'Spotify',
        clue:
            'Logo verde que hace playlists y te dice qué escuchaste en el año.',
      ),
      AdivinaWord(
        word: 'Instagram',
        clue: 'Cámara retro que ahora son reels y filtros infinitos.',
      ),
      AdivinaWord(
        word: 'YouTube',
        clue: 'Play rojo donde ves tutoriales y te recomiendan más.',
      ),
      AdivinaWord(
        word: 'Facebook',
        clue: 'Libro de caras azul que inventó el me gusta.',
      ),
      AdivinaWord(
        word: 'Twitter',
        clue: 'Pájaro azul que ahora es una X y limita caracteres.',
      ),
      AdivinaWord(
        word: 'TikTok',
        clue: 'Nota musical negra que engancha con bailes de 15 segundos.',
      ),
      AdivinaWord(
        word: 'Ikea',
        clue: 'Laberinto sueco de muebles planos y albóndigas.',
      ),
      AdivinaWord(
        word: 'Zara',
        clue: 'Moda rápida española con tienda en dos plantas en cada centro.',
      ),
      AdivinaWord(
        word: 'H&M',
        clue: 'Iniciales suecas de ropa barata y colaboraciones de diseñador.',
      ),
      AdivinaWord(
        word: 'Gucci',
        clue: 'Doble G italiana de pasarela y cinturón caro.',
      ),
      AdivinaWord(
        word: 'Lego',
        clue: 'Ladrillitos daneses que encajan y pisan duelen.',
      ),
      AdivinaWord(
        word: 'PlayStation',
        clue: 'Consola japonesa con mando de triángulo y círculo.',
      ),
      AdivinaWord(
        word: 'Nintendo',
        clue: 'Fontanero y consola roja que hace mover mandos.',
      ),
      AdivinaWord(word: 'Xbox', clue: 'Caja verde americana con Game Pass.'),
      AdivinaWord(
        word: 'Puma',
        clue: 'Felino alemán que compite con las tres franjas.',
      ),
      AdivinaWord(
        word: 'Ferrari',
        clue: 'Caballo rampante rojo que ruge en Fórmula 1.',
      ),
      AdivinaWord(
        word: 'BMW',
        clue: 'Hélice bávara que conduce placer en autovía sin límite.',
      ),
      AdivinaWord(
        word: 'Mercedes',
        clue: 'Estrella plateada alemana que inventó el coche.',
      ),
      AdivinaWord(
        word: 'Heineken',
        clue: 'Estrella verde holandesa que espuma en bares.',
      ),
      AdivinaWord(
        word: 'Red Bull',
        clue: 'Dos toros que dan alas en lata azul y plata.',
      ),
      AdivinaWord(
        word: 'Pepsi',
        clue: 'Rival azul del refresco rojo más famoso.',
      ),
      AdivinaWord(
        word: 'Burger King',
        clue: 'Corona y parrilla que hace la hamburguesa a la brasa.',
      ),
      AdivinaWord(
        word: 'KFC',
        clue: 'Coronel blanco con balde de pollo frito y 11 especias.',
      ),
      AdivinaWord(
        word: 'Pringles',
        clue: 'Tubo con bigote que apila patatas con forma de silla.',
      ),
      AdivinaWord(
        word: 'Oreo',
        clue: 'Galleta negra que se separa y lame crema blanca.',
      ),
      AdivinaWord(
        word: 'Nutella',
        clue: 'Tarro de avellana y cacao que untas en crepes.',
      ),
      AdivinaWord(
        word: 'Harley-Davidson',
        clue: 'Moto americana que suena grave y lleva cuero.',
      ),
      AdivinaWord(
        word: 'Rolex',
        clue: 'Corona dorada que mide tiempo de ricos en muñeca.',
      ),
      AdivinaWord(
        word: 'Levi\'s',
        clue: 'Vaqueros con etiqueta roja y remaches desde 1873.',
      ),

      AdivinaWord(
        word: 'Shein',
        clue: 'Ropa ultra barata china que llega en bolsa. ',
      ),
      AdivinaWord(
        word: 'Temu',
        clue: 'App naranja que vende de todo baratísimo. ',
      ),
      AdivinaWord(
        word: 'Decathlon',
        clue: 'Tienda francesa que equipa todo deporte. ',
      ),
      AdivinaWord(word: 'Primark', clue: 'Ropa a precio de ganga irlandesa. '),
      AdivinaWord(
        word: 'Mercadona',
        clue: 'Supermercado verde que vende hummus. ',
      ),
      AdivinaWord(
        word: 'El Corte Inglés',
        clue: 'Grandes almacenes con triángulo verde. ',
      ),
      AdivinaWord(word: 'Repsol', clue: 'Gasolinera española con antorcha. '),
      AdivinaWord(
        word: 'Iberdrola',
        clue: 'Torre verde que vende luz eléctrica. ',
      ),
      AdivinaWord(
        word: 'Santander',
        clue: 'Banco rojo con llama y sucursal en esquina. ',
      ),
      AdivinaWord(word: 'BBVA', clue: 'Siglas azules que patrocinó liga. '),
      AdivinaWord(
        word: 'CaixaBank',
        clue: 'Estrella amarilla y azul de banco catalán. ',
      ),
      AdivinaWord(
        word: 'Movistar',
        clue: 'M azul que conecta fibra y fútbol. ',
      ),
      AdivinaWord(word: 'Vodafone', clue: 'Círculo rojo con comilla blanca. '),
      AdivinaWord(
        word: 'Orange',
        clue: 'Cuadrado naranja que antes era Amena. ',
      ),
      AdivinaWord(word: 'Peugeot', clue: 'León francés que fabrica 208. '),
      AdivinaWord(word: 'Renault', clue: 'Rombo francés que lanzó Clio. '),
      AdivinaWord(word: 'Seat', clue: 'S roja española que hace Ibiza. '),
      AdivinaWord(word: 'Toyota', clue: 'Óvalo japonés que vende Corolla. '),
      AdivinaWord(
        word: 'Honda',
        clue: 'H plateada que fabrica motos y Civic. ',
      ),
      AdivinaWord(
        word: 'Uniqlo',
        clue: 'Básicos japoneses de calidad y minimalismo. ',
      ),
      AdivinaWord(word: 'Pull&Bear', clue: 'Joven de grupo Inditex con oso. '),
      AdivinaWord(
        word: 'Bershka',
        clue: 'Moda joven nocturna del mismo grupo. ',
      ),
      AdivinaWord(
        word: 'Stradivarius',
        clue: 'Tienda de ropa femenina con clave de sol. ',
      ),
      AdivinaWord(word: 'Oysho', clue: 'Lencería y sport del grupo gallego. '),
      AdivinaWord(
        word: 'Massimo Dutti',
        clue: 'Elegancia clásica del mismo grupo. ',
      ),
      AdivinaWord(
        word: 'Desigual',
        clue: 'Colores locos barceloneses y patchwork. ',
      ),
      AdivinaWord(word: 'Mango', clue: 'Fruta y moda catalana minimal. '),
      AdivinaWord(word: 'Lacoste', clue: 'Cocodrilo verde en polo piqué. '),
      AdivinaWord(word: 'Ralph Lauren', clue: 'Polo con jinete a caballo. '),
      AdivinaWord(
        word: 'Tommy Hilfiger',
        clue: 'Rojo blanco azul con bandera. ',
      ),
      AdivinaWord(word: 'Calvin Klein', clue: 'Siglas CK en ropa interior. '),
      AdivinaWord(word: 'Chanel', clue: 'Dos C entrelazadas de lujo francés. '),
      AdivinaWord(word: 'Dior', clue: 'Bar jacket y bolso Lady. '),
      AdivinaWord(word: 'Louis Vuitton', clue: 'Monograma marrón con flores. '),
      AdivinaWord(
        word: 'Balenciaga',
        clue: 'Vasca que hace zapatillas rotas caras. ',
      ),
      AdivinaWord(
        word: 'Supreme',
        clue: 'Caja roja con letras blancas skater. ',
      ),
      AdivinaWord(
        word: 'North Face',
        clue: 'Cara norte con chaqueta de plumas. ',
      ),
      AdivinaWord(word: 'Patagonia', clue: 'Monte y ropa outdoor sostenible. '),
      AdivinaWord(word: 'Lidl', clue: 'Amarillo azul que vende croissants baratos.'),
      AdivinaWord(word: 'Aldi', clue: 'Descuento alemán con pasillo sorpresa.'),
      AdivinaWord(word: 'Carrefour', clue: 'Hiper francés con tarjeta pass.'),
      AdivinaWord(word: 'Dia', clue: 'Rojo con % y marca blanca.'),
      AdivinaWord(word: 'Alcampo', clue: 'Gallina con huevo y gasolina.'),
      AdivinaWord(word: 'Eroski', clue: 'Cooperativa vasca con viaje.'),
      AdivinaWord(word: 'El Corte descuento', clue: 'Variante outlet de grandes almacenes.'),
      AdivinaWord(word: 'Sfera', clue: 'Moda de grandes almacenes con percha joven.'),
      AdivinaWord(word: 'Cortefiel', clue: 'Ahora Pedro del Hierro clásico español.'),
      AdivinaWord(word: 'Springfield', clue: 'Casual americano del grupo Tendam.'),
      AdivinaWord(word: 'Women secret', clue: 'Ropa íntima femenina del mismo grupo.'),
      AdivinaWord(word: 'Kiabi', clue: 'Familia francesa con tallas grandes.'),
      AdivinaWord(word: 'Hipp', clue: 'Potitos bio alemanes con cara de bebé.'),
      AdivinaWord(word: 'Nestlé', clue: 'Nido con pájaro y leche condensada.'),
      AdivinaWord(word: 'Danone', clue: 'Yogur con niño que crece sano.'),
      AdivinaWord(word: 'Colacao', clue: 'Negrito que agita vaso y grumitos.'),
      AdivinaWord(word: 'Nocilla', clue: 'Merendilla que pones a rebanada.'),
      AdivinaWord(word: 'Valor', clue: 'Chocolate de Villajoyosa puro.'),
      AdivinaWord(word: 'Campofrío', clue: 'Embutido con humor y pavo.'),
      AdivinaWord(word: 'ElPozo', clue: 'Cerdito con jamón bien.'),
      AdivinaWord(word: 'Cruzcampo', clue: 'Cerveza sevillana con Gambrinus.'),
      AdivinaWord(word: 'Estrella Galicia', clue: 'Cerveza con estrella y pulpo en etiqueta.'),
    ],
  };

  // ─── TABÚ ────────────────────────────────────────────────────

  static const tabooCards = [
    TabooCard(
      word: 'Fútbol',
      forbidden: ['pelota', 'gol', 'cancha', 'jugador'],
    ),
    TabooCard(word: 'Pizza', forbidden: ['queso', 'horno', 'masa', 'italiana']),
    TabooCard(word: 'Playa', forbidden: ['arena', 'mar', 'sol', 'traje']),
    TabooCard(
      word: 'Cine',
      forbidden: ['película', 'pantalla', 'butaca', 'taquilla'],
    ),
    TabooCard(
      word: 'Escuela',
      forbidden: ['clase', 'profesor', 'libro', 'nota'],
    ),
    TabooCard(
      word: 'Móvil',
      forbidden: ['teléfono', 'pantalla', 'llamar', 'mensaje'],
    ),
    TabooCard(
      word: 'Navidad',
      forbidden: ['árbol', 'regalo', 'Papá Noel', 'vacaciones'],
    ),
    TabooCard(
      word: 'Cumpleaños',
      forbidden: ['pastel', 'velas', 'fiesta', 'regalo'],
    ),
    TabooCard(
      word: 'Avión',
      forbidden: ['volar', 'aeropuerto', 'piloto', 'alas'],
    ),
    TabooCard(
      word: 'Gato',
      forbidden: ['felino', 'maullido', 'ratón', 'bigotes'],
    ),
    TabooCard(
      word: 'Reloj',
      forbidden: ['tiempo', 'hora', 'manecillas', 'alarma'],
    ),
    TabooCard(
      word: 'Helado',
      forbidden: ['frío', 'vainilla', 'cono', 'verano'],
    ),
    TabooCard(
      word: 'Bicicleta',
      forbidden: ['ruedas', 'pedales', 'ciclista', 'montar'],
    ),
    TabooCard(
      word: 'Constructor',
      forbidden: ['edificio', 'ladrillo', 'obrero', 'cemento'],
    ),
    TabooCard(
      word: 'Carpintero',
      forbidden: ['madera', 'martillo', 'clavo', 'sierra'],
    ),
    TabooCard(
      word: 'Wifi',
      forbidden: ['internet', 'señal', 'router', 'conexión'],
    ),
    TabooCard(
      word: 'Spotify',
      forbidden: ['música', 'canción', 'escuchar', 'lista'],
    ),
    TabooCard(
      word: 'Instagram',
      forbidden: ['foto', 'filtro', 'seguir', 'like'],
    ),
    TabooCard(
      word: 'Netflix',
      forbidden: ['película', 'serie', 'ver', 'pantalla'],
    ),
    TabooCard(
      word: 'Twitter',
      forbidden: ['tweet', 'tuitar', 'seguir', 'trending'],
    ),
    TabooCard(
      word: 'Microondas',
      forbidden: ['caliente', 'cocina', 'plato', 'calentar'],
    ),
    TabooCard(
      word: 'Aspiradora',
      forbidden: ['limpiar', 'suciedad', 'bolsa', 'ruido'],
    ),
    TabooCard(
      word: 'Calcetines',
      forbidden: ['pies', 'zapatos', 'calzar', 'manchados'],
    ),
    TabooCard(
      word: 'Espejo',
      forbidden: ['reflejo', 'cara', 'verse', 'vidrio'],
    ),
    TabooCard(
      word: 'Llavero',
      forbidden: ['llaves', 'puerta', 'colgar', 'bolso'],
    ),
    TabooCard(
      word: 'Paraguas',
      forbidden: ['lluvia', 'agua', 'abrir', 'mojado'],
    ),
    TabooCard(
      word: 'Chancla',
      forbidden: ['pie', 'verano', 'playa', 'sandalia'],
    ),
    TabooCard(
      word: 'Ventilador',
      forbidden: ['aire', 'calor', 'giro', 'viento'],
    ),
    TabooCard(
      word: 'Almohada',
      forbidden: ['dormir', 'cama', 'sueño', 'suave'],
    ),
    TabooCard(
      word: 'Perro',
      forbidden: ['ladrar', 'mascota', 'cola', 'adiestrador'],
    ),
    TabooCard(
      word: 'Chocolate',
      forbidden: ['cacao', 'dulce', 'tableta', 'postre'],
    ),
    TabooCard(
      word: 'Boda',
      forbidden: ['novia', 'anillo', 'iglesia', 'casarse'],
    ),
    TabooCard(
      word: 'Hospital',
      forbidden: ['médico', 'enfermera', 'paciente', 'operación'],
    ),
    TabooCard(
      word: 'Verano',
      forbidden: ['calor', 'vacaciones', 'sol', 'helado'],
    ),
    TabooCard(
      word: 'Invierno',
      forbidden: ['frío', 'nieve', 'abrigo', 'navidad'],
    ),
    TabooCard(
      word: 'Dentista',
      forbidden: ['diente', 'muela', 'empaste', 'boca'],
    ),
    TabooCard(word: 'Barba', forbidden: ['bigote', 'afeitar', 'cara', 'pelo']),
    TabooCard(
      word: 'Zapatos',
      forbidden: ['pies', 'suela', 'cordones', 'calzar'],
    ),
    TabooCard(
      word: 'Gafas de sol',
      forbidden: ['ojos', 'verano', 'lentes', 'proteger'],
    ),
    TabooCard(
      word: 'Ascensor',
      forbidden: ['planta', 'subir', 'botón', 'edificio'],
    ),
    TabooCard(
      word: 'Semáforo',
      forbidden: ['rojo', 'verde', 'cruzar', 'coche'],
    ),
    TabooCard(
      word: 'Biblioteca',
      forbidden: ['libros', 'leer', 'silencio', 'prestar'],
    ),
    TabooCard(
      word: 'Camping',
      forbidden: ['tienda', 'naturaleza', 'acampar', 'montaña'],
    ),
    TabooCard(
      word: 'Halloween',
      forbidden: ['disfraz', 'calabaza', 'miedo', 'dulces'],
    ),
    TabooCard(
      word: 'San Valentín',
      forbidden: ['amor', 'pareja', 'rosas', 'febrero'],
    ),
    TabooCard(
      word: 'WhatsApp',
      forbidden: ['mensaje', 'chat', 'enviar', 'grupo'],
    ),
    TabooCard(
      word: 'YouTube',
      forbidden: ['vídeo', 'canal', 'suscribirse', 'ver'],
    ),
    TabooCard(
      word: 'Amazon',
      forbidden: ['comprar', 'online', 'paquete', 'envío'],
    ),
    TabooCard(word: 'Uber', forbidden: ['taxi', 'app', 'viaje', 'conductor']),
    TabooCard(
      word: 'Tostadora',
      forbidden: ['pan', 'tostada', 'desayuno', 'ranura'],
    ),
    TabooCard(
      word: 'Nevera',
      forbidden: ['frío', 'comida', 'congelar', 'cocina'],
    ),
    TabooCard(word: 'Secador', forbidden: ['pelo', 'aire', 'mojado', 'secar']),
    TabooCard(
      word: 'Dinosaurio',
      forbidden: ['extinto', 'rex', 'jurásico', 'fósil'],
    ),
    TabooCard(
      word: 'Cactus',
      forbidden: ['planta', 'espinas', 'desierto', 'agua'],
    ),
  ];

  // ─── YO NUNCA ────────────────────────────────────────────────

  static const yoNuncaPrompts = [
    'Yo nunca me he comido algo que se me cayó al suelo',
    'Yo nunca he mentido para no ir a un plan',
    'Yo nunca he llorado viendo una película',
    'Yo nunca he revisado el teléfono de alguien',
    'Yo nunca he mandado un mensaje al equivocado',
    'Yo nunca he fingido estar enfermo para no ir al trabajo o cole',
    'Yo nunca me he quedado dormido en el cine',
    'Yo nunca he cantado en la ducha a todo pulmón',
    'Yo nunca he comido en la cama',
    'Yo nunca me he caído en la calle y mirado a ver si alguien vio',
    'Yo nunca he buscado algo vergonzoso en Google',
    'Yo nunca he fantaseado con ser famoso',
    'Yo nunca he dicho "ya voy" y estaba en casa',
    'Yo nunca he rogado por un ascenso o una nota',
    'Yo nunca he sido el último en darse cuenta de un chiste',
    'Yo nunca he hecho multitarea mientras veo una serie',
    'Yo nunca he dicho "estoy bien" cuando no lo estaba',
    'Yo nunca he tenido una conversación con mi mascota como si entendiera',
    'Yo nunca he googlado mis propios síntomas',
    'Yo nunca he fingido no ver a alguien por la calle',
    'Yo nunca he comido la comida de otra persona sin permiso',
    'Yo nunca he mandado un voice note de más de 1 minuto',
    'Yo nunca he tenido crush con un personaje de serie',
    'Yo nunca he llorado por una canción',
    'Yo nunca he dicho "última vez" y seguí jugando',
    'Yo nunca he pedido un pizza entero solo para mí',
    'Yo nunca he stalkedo a alguien en redes sociales',
    'Yo nunca he tenido un diálogo con el espejo',
    'Yo nunca he dicho "no sé qué hacer con mi vida" dramáticamente',
    'Yo nunca he comido a las 3am',
    'Yo nunca he googlado "cómo ser productivo" sin hacer nada',
    'Yo nunca he tenido un argumento con Siri o Alexa',
    'Yo nunca he fingido estar en una llamada para evitar a alguien',
    'Yo nunca he mezclado ropa que no combinaba y salí igual',
    'Yo nunca he esperado a que alguien lea mi mente',
    'Yo nunca he dicho "mañana empiezo" y no empezé',
    'Yo nunca he tenido miedo de algo que vi en una película de terror',
    'Yo nunca he pagado por algo y no lo usé',
    'Yo nunca he mentido diciendo que no vi el mensaje',
    'Yo nunca he hecho la vista gorda con algo obvio',
    'Yo nunca me he hecho pasar por desconocido para no saludar a alguien',
    'Yo nunca he dicho "no como nada" y luego me he comido todo',
    'Yo nunca he tenido una pelea imaginaria en la ducha',
    'Yo nunca he abierto la nevera sin saber qué quería',
    'Yo nunca he puesto alarma 10 veces y me he levantado a la última',
    'Yo nunca me he reído solo recordando algo vergonzoso',
    'Yo nunca he enviado un audio por error al grupo equivocado',
    'Yo nunca he googlado a mi propio nombre',
    'Yo nunca he fingido que mi wifi falla para colgar una llamada',
    'Yo nunca he comido algo solo porque alguien dijo que estaba rico',
    'Yo nunca me he ido a dormir sin cerrar una serie que me enganchó',
    'Yo nunca he llegado tarde porque me quedé viendo el móvil',
    'Yo nunca he dicho "no me mires así" a mi mascota',
    'Yo nunca he pagado delivery de algo que tengo en la cocina',
    'Yo nunca me he puesto los auriculares sin música para evitar hablar',
    'Yo nunca he comprado algo online a las 3am y me arrepentí',
    'Yo nunca he buscado "cuántos años tiene [famoso]" por curiosidad',
    'Yo nunca he dicho "esto es lo último" y he seguido rato',
    'Yo nunca he hecho una selfie y la he borrado inmediatamente',
    'Yo nunca he fingido estar busy para no salir de casa',
    'Yo nunca me he comido los últimos doritos y he dejado la bolsa vacía',
    'Yo nunca he tenido miedo de algo tan tonto que no se lo cuento a nadie',
    'Yo nunca he chorreado un lío y he dicho que era el perro',
    'Yo nunca he borrado un mensaje porque lo escribí mal',
    'Yo nunca he contestado un "estás bien" con un "sí" siendo mentira',
    'Yo nunca he tenido un crush con un profesor o profesora',
    'Yo nunca he gastado dinero en algo que no necesitaba para impresionar a alguien',
    'Yo nunca he abierto Instagram y cerrado 5 segundos después',
    'Yo nunca he dicho "ya estoy listo" y faltaban 30 minutos',
    'Yo nunca he hecho como que no veía el mensaje de alguien',
    'Yo nunca me he hecho pasar por dormido para no contestar una llamada',
    'Yo nunca he dicho "mañana sí voy al gym" y no fui',
    'Yo nunca he guardado algo en el bolsillo y lo he encontrado una semana después',
    'Yo nunca he dicho "no sé de qué hablas" sabiendo exactamente de qué hablan',
    'Yo nunca me he asustado con mi propia sombra',
    'Yo nunca he mirado el móvil mientras alguien me habla por la espalda',
    'Yo nunca he prometido "nunca más" y lo he vuelto a hacer',
    'Yo nunca he hecho un purge de contactos en WhatsApp por aburrimiento',
    'Yo nunca he tenido una discusión conmigo mismo sobre qué ver en Netflix',
    'Yo nunca he fingido entender una conversación asintiendo',
    'Yo nunca me he comido un chocolate escondido de alguien',
    'Yo nunca he practicado una conversación frente al espejo',
    'Yo nunca he dicho "salgo en 5 minutos" y he salido una hora después',
    'Yo nunca he pasado 20 minutos con el mando sin decidir qué ver',
    'Yo nunca he mentido sobre mi edad',
    'Yo nunca he usado la excusa de "no me llegó el mensaje"',
    'Yo nunca me he puesto la camiseta al revés y he salido a la calle',
  ];

  // ─── DEBATE ──────────────────────────────────────────────────

  static const debateTopics = [
    '¿Las redes sociales hacen más mal que bien a los jóvenes?',
    '¿Debería ser legal drogarse sin consecuencias?',
    '¿Los padres que revisan el teléfono de sus hijos están justificados?',
    '¿Es mejor ser soltero toda la vida que estar en una relación tóxica?',
    '¿Las universidades son una estafa o una inversión?',
    '¿Debería existir la pena de muerte para criminales violentos?',
    '¿Los hombres y las mujeres son iguales en todo?',
    '¿Es mejor vivir sin WiFi que sin pareja?',
    '¿Los refugios de animales deberían tener prioridad sobre los hospitales?',
    '¿Instagram y TikTok están arruinando la autoestima?',
    '¿Debería existir un límite de edad para las redes sociales?',
    '¿Los ex deberían volver o son del pasado?',
    '¿Comer carne es inmoral en 2026?',
    '¿Deberían prohibirse los coches en el centro de las ciudades?',
    '¿Los profesores deberían ganar más que los futbolistas?',
    '¿Es justificable mentir en una relación?',
    '¿La inteligencia artificial nos hará más inteligentes o más tontos?',
    '¿Debería ser obligatorio votar?',
    '¿Los niños deberían tener smartphones antes de los 12 años?',
    '¿Es peor ser cornudo o ser el que corna?',
    '¿Las bodas son una pérdida de dinero o una inversión emocional?',
    '¿Deberían pagar más impuestos los ricos?',
    '¿Los sueldos de los políticos deberían ser públicos?',
    '¿Está bien que una amiga salga con tu ex?',
    '¿Debería existir un impuesto por tener demasiado dinero?',
    '¿Los animales en cautiverio están bien si es para conservación?',
    '¿Vivir con tus padres después de los 30 es de perdedores?',
    '¿La monogamia es natural o una imposición social?',
    '¿Deberían existir ciudades solo para peatones?',
    '¿Los Premios Nobel siguen siendo relevantes?',
    '¿Es mejor ser inteligente y feo o guapo y tonto?',
    '¿Deberían los robots tener derechos?',
    '¿Está bien que tu pareja tenga amigos del sexo opuesto?',
    '¿Las vacunas deberían ser obligatorias para viajar?',
    '¿Comprar ropa de segunda mano es coqueto o es tacañería?',
    '¿Los toros deberían seguir siendo legal en España?',
    '¿Deberían los streamers pagar impuestos por sus donaciones?',
    '¿Es peor un mentiroso que un ladrón?',
    '¿Deberían existir islas solo para famosos?',
    '¿La felicidad se puede comprar o es un mito?',
    '¿Debería prohibirse la publicidad dirigida a niños?',
    '¿Trabajar 4 días a la semana mejoraría la productividad?',
    '¿Es ético clonar mascotas por dinero?',
    '¿Deberían los influencers necesitar título para opinar de salud?',
    '¿Vivir en el campo es mejor que en la ciudad?',
    '¿Debería ser gratis el transporte público?',
    '¿Las notas escolares matan la creatividad?',
    '¿Debería haber un límite de herencia máxima?',
    '¿Es justificable espiar a tu pareja si sospechas infidelidad?',
    '¿Deberían los robots pagar impuestos si quitan empleos?',
    '¿El arte generado por IA es arte de verdad?',
    '¿Debería ser ilegal la tauromaquia en toda Europa?',
    '¿La cancel culture hace justicia o censura?',
    '¿Se debería enseñar educación financiera en el cole?',
    '¿Viajar en avión debería estar más gravado por el clima?',
    '¿Es mejor adoptar o comprar mascotas?',
    '¿Deberían las empresas poder rastrear tu ubicación por seguridad?',
    '¿La procrastinación es flojera o gestión emocional?',
    '¿Debería existir renta básica universal?',
    '¿Los e-sports deberían ser olímpicos?',
    '¿Deberían los colegios prohibir los deberes los fines de semana?',
    '¿Es mejor el libro físico que el ebook para aprender?',
    '¿Debería haber un salario máximo además de mínimo?',
    '¿Las notas deberían sustituirse por evaluación sin números?',
    '¿Debería ser obligatorio un año de servicio social tras el instituto?',
    '¿Es ético usar reconocimiento facial en calles?',
    '¿Deberían los alquileres tener tope por ley en grandes ciudades?',
    '¿Es justo heredar pisos sin pagar gran herencia?',
    '¿Debería multarse a quien no recicle correctamente?',
    '¿Es mejor vivir toda la vida en un mismo sitio o mudarse cada 5 años?',
    '¿Deberían los menores de 16 necesitar permiso para subir vídeos públicos?',
    '¿La universidad gratuita mejora o empeora su calidad?',
    '¿Debería limitarse el número de mascotas por hogar en la ciudad?',
    '¿Es legítimo mentir en el currículum para conseguir primer empleo?',
    '¿Debería pagarse por cuidar a familiares dependientes como trabajo?',
    '¿Las ciudades deberían cobrar peaje por entrar en coche todos los días?',
    '¿Es mejor trabajar remoto siempre o híbrido obligatorio?',
    '¿Deberían prohibirse los ultraprocesados en comedores escolares?',
    '¿La propina debería estar incluida siempre o ser voluntaria?',
    '¿Debería haber un carnet para ser padre o madre?',
    '¿Es ético que influencers promocionen casas de apuestas?',
    '¿Deberían los gobiernos regular el precio de la vivienda vacía con recargo?',
    '¿Merece la pena aprender a programar si la IA ya programa?',
    '¿Deberían los exámenes ser a libro abierto siempre?',
    '¿Es mejor tener pocos amigos íntimos o muchos conocidos?',
    '¿Debería ser delito difundir fake news aunque sea sin intención?',
    '¿Las empresas deberían tener límite de beneficios y repartir resto?',
    '¿Es justo que artistas cobren por streaming tan poco por reproducción?',
    '¿Debería la semana laboral ser de 32 horas sin bajar sueldo?',
    '¿El turismo masivo debería limitarse con cupos por ciudad?',
    '¿Deberían los robots que generan arte citar a artistas originales y pagarles?',
    '¿Es mejor comunicar por audio que por texto en el trabajo?',
    '¿Debería haber un impuesto específico para jets privados?',
    '¿La historia debería enseñarse más con memoria oral que con fechas?',
    '¿Debería permitirse a adolescentes votar desde los 16?',
    '¿Es ético criar pulpos en granjas si son tan inteligentes?',
    '¿Deberían las apps mostrar cuánto tiempo te quitan al día de forma obligatoria?',
    '¿Es mejor una vida sin redes pero con más tiempo libre?',
    '¿Deberían las marcas estar obligadas a mostrar su huella de carbono en etiqueta?',
    '¿El humor negro debería tener límites legales o solo sociales?',
    '¿Debería prohibirse el uso de animales en circos en todo el mundo?',
    '¿Es justo que un algoritmo decida a quién contratan en una entrevista?',
  ];

  static const debateProfundasTopics = [
    'Si te quedaran 24 horas de vida, ¿qué harías?',
    '¿Cuánto crees que debería vivir el ser humano?',
    'Si pudieras despertar con todos tus sueños cumplidos, pero sin saber cómo los has conseguido, ¿lo harías?',
    '¿Prefieres una vida corta e intensa o larga y tranquila?',
    '¿Qué harías si supieras que nadie te va a juzgar nunca?',
    'Si pudieras borrar un recuerdo para siempre, ¿cuál sería?',
    '¿Crees que el destino existe o lo construimos todo?',
    '¿Qué significa para ti ser feliz de verdad?',
    'Si pudieras hablar con tu yo de 10 años, ¿qué le dirías?',
    '¿Perdonarías algo imperdonable por amor?',
    '¿Qué dejarías atrás si empezaras de cero mañana?',
    '¿Vives como quieres o como esperan que vivas?',
    'Si pudieras revivir un día de tu vida, ¿cuál elegirías?',
    '¿Qué es más difícil: decir adiós o pedir perdón?',
    '¿Crees que algún día te arrepentirás de algo que no hiciste?',
  ];

  static const debatePicanteTopics = [
    '¿Poliamor sí o no? ¿Debería normalizarse?',
    '¿Fotos sin ropa en pareja: confianza o riesgo?',
    '¿Sexting es infidelidad o juego?',
    '¿Debería ser legal el trabajo sexual?',
    '¿Celos: prueba de amor o inseguridad tóxica?',
    '¿Compartir contraseñas es amor o control?',
    '¿Las relaciones abiertas funcionan mejor que la monogamia?',
    '¿Fantasías con otras personas son infidelidad?',
    '¿Usar apps de citas estando en pareja por curiosidad está mal?',
    '¿El porno afecta negativamente a las relaciones?',
    '¿Sexo en la primera cita: sí o no?',
    '¿Esconder el pasado sexual es mentir?',

    '¿Amor a primera vista o flechazo construido: qué crees más?',
    '¿Celos retrospectivos: se debe contar todo el pasado?',
    '¿Perdonarías microinfidelidad por chat?',
    '¿Fantasear con ex es ser infiel mentalmente?',
    '¿Sexo sin amor: puede separar bien la gente?',
    '¿Debe tu pareja saber cuánto ganas y gastas?',
    '¿Vivir juntos antes de casarse: imprescindible?',
    '¿Apps de citas para subir ego estando en pareja: traición?',
    '¿Diferencia de edad grande: amor o interés?',
    '¿Hijos: tenerlos por presión social está bien?',
    '¿Pornografía en pareja: ayuda o estorba?',
    '¿Dinero separado o cuenta común en matrimonio?',
    '¿Amistad con ex: madurez o bomba?',
    '¿Kink: hasta dónde normalizar en pareja?',
    '¿Celos como motor o como veneno?',
    '¿Ghosting: alguna vez justificable?',
    '¿Sexo telefónico cuenta como infidelidad?',
    '¿Poliamor jerárquico vs no jerárquico: cuál prefieres?',
    '¿Cuándo presentar a padres: pronto o tarde?',
    '¿Mandar ubicación 24/7 es cuidado o control?',
    '¿Perdonarías mentira piadosa sobre pasado sexual?',
    '¿OnlyFans en pareja: trabajo o ruptura?',
    '¿Terapia de pareja: signo de fracaso o madurez?',
    '¿Sexo de reconciliación: sana o tapa problemas?',
      '¿Verbalizar todo mata la magia?',
      '¿Reglas en relación abierta: cuántas son sanas?',
      '¿Amor sin atracción física dura?',
      '¿Besar a tu ex para despedirte estando en pareja es infidelidad?',
      '¿Compartir fantasías oscuras fortalece o rompe la pareja?',
      '¿Relación sin sexo puede ser feliz a largo plazo?',
      '¿Ver OnlyFans de tu pareja sin permiso rompe la confianza?',
      '¿Pedir un trío puede salvar o hundir una relación?',
      '¿Diferencia de libido: se negocia o se termina?',
      '¿Coquetear por DM sin quedar es traición?',
      '¿Sexo por aburrimiento es peor que una infidelidad?',
      '¿Love bombing al inicio es amor o manipulación?',
      '¿Usar juguetes en pareja es tabú o saludable?',
      '¿Perdonar una infidelidad una vez es madurez o autoengaño?',
      '¿Dormir separados mejora o mata la pasión?',
      '¿Decir te quiero muy pronto es valentía o presión?',
      '¿Relación a distancia abierta funciona o es excusa?',
      '¿Negar un beso en público por vergüenza es falta de amor?',
      '¿Mantener amistad con ex con sexo ocasional es sano o tóxico?',
  ];

  static const debatePlanes = [
    DebatePlan(
      title: 'Encontrar deporte que nadie sepa y reírnos haciéndolo',
      description:
          'Reto Volcán: buscad un deporte o disciplina que nadie del grupo haya practicado nunca — kin-ball, tchoukball, bossaball, quidditch muggle o slackline. Alquilad material básico, mirad un tutorial de 5 minutos y jugad sin tomarlo en serio. El objetivo no es ganar, es reírse de las caídas y celebrar el intento más épico. Llevad rodilleras, agua y ganas de hacer el ridículo juntos.',
      emoji: '🤹',
    ),
    DebatePlan(
      title: 'Buscar el punto más alto y ver el amanecer',
      description:
          'Reto Volcán: investigad cuál es el punto más alto cercano donde viváis — mirador, azotea accesible, colina o pico suave. Quedad una hora antes del amanecer, llevad mantas, termo con chocolate caliente y frontal. Subid con calma, haced foto grupal con el sol asomando y desayunad allí. Ideal para cerrar noche o empezar día épico.',
      emoji: '🌄',
    ),
    DebatePlan(
      title: 'Encontrar algo en lo que todos seamos malos y reírnos haciéndolo',
      description: 'Elegid una actividad donde nadie destaque: baile, dibujo, canto. Lo importante es reír, no competir.',
      emoji: '🤹',
    ),
    DebatePlan(
      title: 'Buscar evento deportivo que requiera entrenamiento previo para mejorar equipo',
      description: 'Airsoft, escalada, crossfit o artes marciales. Entrenad juntos varias semanas y competid como equipo.',
      emoji: '🎯',
    ),
    DebatePlan(
      title: 'Buscar el punto más alto donde vivamos y ver el amanecer',
      description: 'Investigad miradores, azoteas o montes cercanos. Madrugad, llevad mantas y chocolate caliente.',
      emoji: '🌄',
    ),
    DebatePlan(
      title: 'Ruta de bares sin repetir',
      description: 'Cada bar, una consumición distinta y una mini-prueba. Sin repetir local ni bebida.',
      emoji: '🍻',
    ),
    DebatePlan(
      title: 'Karaoke a capela',
      description: 'Sin música de fondo: solo voces. Votad la interpretación más valiente y la más divertida.',
      emoji: '🎤',
    ),
    DebatePlan(
      title: 'Cocinar todos juntos',
      description: 'Elegid receta, repartid roles y cocinad sin mirar el móvil. Luego cenáis lo que salga.',
      emoji: '🍳',
    ),
    DebatePlan(
      title: 'Noche de juegos de mesa',
      description: 'Cada uno trae un juego. Haced torneo corto y el perdedor pone la próxima quedada.',
      emoji: '🎲',
    ),
    DebatePlan(
      title: 'Escape room casero',
      description: 'Montad enigmas con lo que hay en casa. Un equipo crea, el otro resuelve contra reloj.',
      emoji: '🔐',
    ),
    DebatePlan(
      title: 'Foto reto',
      description: 'Lista de fotos absurdas por la ciudad: con un perro, haciendo yoga, etc. Gana quien complete más.',
      emoji: '📸',
    ),
    DebatePlan(
      title: 'Voluntariado express',
      description: 'Dedicad una mañana a ayudar: banco de alimentos, refugio o limpieza de parque. Plan con huella.',
      emoji: '🤝',
    ),
    DebatePlan(
      title: 'Taller de origami gigante',
      description: 'Papel continuo y mesa larga. Haced grullas de un metro.',
      emoji: '🦢',
    ),
    DebatePlan(
      title: 'Noche de doblaje',
      description: 'Escena muda y poned voces absurdas. Grabad y votad.',
      emoji: '🎬',
    ),
    DebatePlan(
      title: 'Ruta de murales',
      description: 'Mapa de arte urbano. Foto frente a cada mural con pose.',
      emoji: '🎨',
    ),
    DebatePlan(
      title: 'Picnic temático por colores',
      description: 'Cada uno trae comida de un color. Montad arcoíris comestible.',
      emoji: '🥗',
    ),
    DebatePlan(
      title: 'Olimpiadas absurdas caseras',
      description: 'Carrera de cucharas, lanzamiento de calcetín, silla musical.',
      emoji: '🏅',
    ),
    DebatePlan(
      title: 'Cata a ciegas',
      description: 'Venda y prueba sabores. Puntúa sin ver marca.',
      emoji: '👅',
    ),
    DebatePlan(
      title: 'Intercambio de talentos',
      description: 'Cada uno enseña algo en 15 minutos: truco, acorde, receta.',
      emoji: '✨',
    ),
    DebatePlan(
      title: 'Cine bajo estrellas',
      description: 'Proyector en azotea o pared y palomitas.',
      emoji: '🌌',
    ),
    DebatePlan(
      title: 'Búsqueda del tesoro de barrio',
      description: 'Pistas con QR y prueba final con premio simbólico.',
      emoji: '🗺️',
    ),
    DebatePlan(
      title: 'Noche sin móviles',
      description: 'Caja cerrada 3 horas. Juegos, charlas y fotos con cámara desechable.',
      emoji: '📵',
    ),
  ];

  // ─── QUIÉN ES MÁS ────────────────────────────────────────────

  static const quienEsMasQuestions = [
    '¿Quién es más probable que llegue tarde a todo?',
    '¿Quién es más probable que se caiga bailando?',
    '¿Quién es más probable que mienta para quedar bien?',
    '¿Quién es más probable que coma algo del suelo?',
    '¿Quién es más probable que se haga un tatuaje sin pensar?',
    '¿Quién es más probable que llame a su madre por todo?',
    '¿Quién es más probable que se quede dormido en el cine?',
    '¿Quién es más probable que gaste todo su dinero en comida?',
    '¿Quién es más probable que se pelee por el control remoto?',
    '¿Quién es más probable que invente una excusa ridícula?',
    '¿Quién es más probable que se pierda yendo al baño?',
    '¿Quién es más probable que hable solo?',
    '¿Quién es más probable que se ría en el momento menos indicado?',
    '¿Quién es más probable que suba una foto vergonzosa?',
    '¿Quién es más probable que le tenga miedo a algo tonto?',
    '¿Quién es más probable que se ponga a llorar con una canción?',
    '¿Quién es más probable que pida delivery 7 días seguidos?',
    '¿Quién es más probable que se ponga a bailar en la calle?',
    '¿Quién es más probable que hable con su reflejo?',
    '¿Quién es más probable que se trague algo que no es comida?',
    '¿Quién es más probable que se ríe de sus propios chistes?',
    '¿Quién es más probable que se quede sin batería siempre?',
    '¿Quién es más probable que invente una excusa para no salir?',
    '¿Quién es más probable que se ponga a cantar en público?',
    '¿Quién es más probable que se pierda en su propia casa?',

    '¿Quién es más probable que se olvide su cumpleaños?',
    '¿Quién es más probable que adopte un animal sin avisar?',
    '¿Quién es más probable que se apunte a todo plan?',
    '¿Quién es más probable que haga una lista y no la cumpla?',
    '¿Quién es más probable que se ría por todo?',
    '¿Quién es más probable que pierda las llaves semanalmente?',
    '¿Quién es más probable que haga spoiler sin darse cuenta?',
    '¿Quién es más probable que compre regalos a último minuto?',
    '¿Quién es más probable que se quede sin datos el primer día?',
    '¿Quién es más probable que organice fiesta sorpresa?',
  ];

  static const quienEsMasPicanteQuestions = [
    '¿Quién es más probable que haya enviado una foto subida de tono?',
    '¿Quién es más probable que tenga un crush con alguien del grupo?',
    '¿Quién es más probable que se líe esta noche con alguien de la fiesta?',
    '¿Quién es más probable que haya hecho sexting en clase o trabajo?',
    '¿Quién es más probable que haya mentido sobre con cuánta gente ha estado?',
    '¿Quién es más probable que haya tenido un rollo con el ex de un amigo/a?',
    '¿Quién es más probable que acabe teniendo un OnlyFans?',
    '¿Quién es más probable que haya sido pillado en un momento íntimo?',
    '¿Quién es más probable que fantasee con alguien prohibido?',
    '¿Quién es más probable que haya usado una app de citas estando en pareja?',
    '¿Quién es más probable que bese a dos personas en la misma noche?',
    '¿Quién es más probable que haya tenido un sueño picante con alguien del grupo?',

    '¿Quién es más probable que tenga un chat archivado sospechoso?',
    '¿Quién es más probable que mienta sobre su historial amoroso?',
    '¿Quién es más probable que haya vuelto con su ex?',
    '¿Quién es más probable que ligue en una boda?',
    '¿Quién es más probable que tenga un amor platónico en el trabajo?',
    '¿Quién es más probable que haya hecho ghosting y se arrepienta?',
    '¿Quién es más probable que envíe señales mixtas?',
    '¿Quién es más probable que tenga OnlyFans secreto?',
    '¿Quién es más probable que bese a alguien por apuesta?',
    '¿Quién es más probable que haya mentido para ligar?',
  ];

  // ─── PUEBLO DUERME ROLES ─────────────────────────────────────

  static const puebloDuermeRoles = {
    'Aldeano': _RoleData(
      icon: '👤',
      description: 'Duermes tranquilo. Espera al amanecer.',
      color: 0xFF25E6D0,
    ),
    'Lobo': _RoleData(
      icon: '🐺',
      description: 'Elegid a quién devorar esta noche.',
      color: 0xFFE74C3C,
    ),
    'Vidente': _RoleData(
      icon: '👁️',
      description: 'Elige a un jugador para descubrir su rol.',
      color: 0xFF63F5E5,
    ),
    'Bruja': _RoleData(
      icon: '🧙',
      description: 'Puedes salvar a alguien o envenenar a otro.',
      color: 0xFF9B59B6,
    ),
    'Cupido': _RoleData(
      icon: '💘',
      description: 'Une a dos jugadores. Si uno muere, el otro también.',
      color: 0xFFE91E63,
    ),
    'Médico': _RoleData(
      icon: '💊',
      description: 'Protege a un jugador cada noche del lobo.',
      color: 0xFF2ECC71,
    ),
    'Cazador': _RoleData(
      icon: '🏹',
      description: 'Si mueres, puedes llevarte a alguien contigo al instante.',
      color: 0xFFEA580C,
    ),
    'Ladrón': _RoleData(
      icon: '🗡️',
      description: 'Puedes intercambiar tu rol con otro jugador una vez.',
      color: 0xFFF39C12,
    ),
  };

  // ─── MÍMICA ────────────────────────────────────────────────

  static const mimicaWords = [
    'Cepillarse los dientes',
    'Correr en la lluvia',
    'Mirar un móvil',
    'Nadar en el mar',
    'Montar en bicicleta',
    'Comer pizza',
    'Hacer una llamada',
    'Bailar en una fiesta',
    'Abrir un regalo',
    'Dormir una siesta',
    'Soplar una vela',
    'Saltar la cuerda',
    'Jugar al fútbol',
    'Cortar papel con tijeras',
    'Lavar los platos',
    'Hacer la compra',
    'Ponerse una chaqueta',
    'Beber un refresco',
    'Peinarse el pelo',
    'Leer un libro',
    'Llamar a la puerta',
    'Arreglar un coche',
    'Lanzar una pelota',
    'Mirar por un telescopio',
    'Pintar una pared',
    'Subir una montaña',
    'Cargar una maleta',
    'Hacer una foto',
    'Sujetar un paraguas',
    'Cocinar pasta',
    'Lavar un coche',
    'Hacer yoga',
    'Escribir en un cuaderno',
    'Tocar la guitarra',
    'Buscar algo perdido',
    'Aplaudir en un concierto',
    'Hacer de árbitro',
    'Escuchar música',
    'Ir de compras',
    'Abrazar a alguien',
    'Bailar salsa',
    'Cantar a todo pulmón',
    'Dibujar en una pizarra',
    'Pelar un plátano',
    'Freír un huevo',
    'Cortar una cebolla',
    'Maquillarse ante el espejo',
    'Secarse el pelo',
    'Gritar en una montaña rusa',
    'Susurrar un secreto',
    'Buscar las llaves perdidas',
    'Esconderse en el armario',
    'Pelear con una almohada',
    'Hacer flexiones',
    'Tocar el piano',
    'Jugar al tenis',
    'Esquiar en la nieve',
    'Surfear una ola',
    'Pescar en el río',
    'Pasear al perro',
    'Imitar a un león',
    'Saltar como un canguro',
    'Volar como un pájaro',
    'Repartir el correo',
    'Apagar un incendio',
    'Operar como cirujano',
    'Cortar el pelo',
    'Servir en un restaurante',
    'Regar las plantas',
    'Barrer la calle',
    'Bucear entre peces',
    'Hacerse una selfie',
  ];

  // ─── ¿QUIÉN SOY? ────────────────────────────────────────────

  static const quienSoy = [
    'Lionel Messi',
    'Cristiano Ronaldo',
    'Neymar',
    'Kylian Mbappé',
    'LeBron James',
    'Usain Bolt',
    'Serena Williams',
    'Rafael Nadal',
    'Lewis Hamilton',
    'Mike Tyson',
    'Shakira',
    'Rosalía',
    'Bad Bunny',
    'Karol G',
    'Taylor Swift',
    'Rihanna',
    'Beyoncé',
    'Madonna',
    'Michael Jackson',
    'Elvis Presley',
    'Einstein',
    'Isaac Newton',
    'Marie Curie',
    'Galileo Galilei',
    'Stephen Hawking',
    'Leonardo da Vinci',
    'Mozart',
    'Beethoven',
    'Frida Kahlo',
    'Pablo Picasso',
    'Salvador Dalí',
    'Cleopatra',
    'Napoleón',
    'Julio César',
    'Mahatma Gandhi',
    'Nelson Mandela',
    'Abraham Lincoln',
    'Winston Churchill',
    'Simón Bolívar',
    'Isabel La Católica',
    'Spider-Man',
    'Batman',
    'Superman',
    'Iron Man',
    'Wonder Woman',
    'Harry Potter',
    'Hermione Granger',
    'Darth Vader',
    'Yoda',
    'Gollum',
    'Shrek',
    'Mickey Mouse',
    'Bob Esponja',
    'Homero Simpson',
    'Mario Bros',
    'Sonic',
    'Pikachu',
    'Goku',
    'Naruto',
    'Buzz Lightyear',
    'Antonio Banderas',
    'Penélope Cruz',
    'Javier Bardem',
    'Enrique Iglesias',
    'Dua Lipa',
    'Ariana Grande',
    'Drake',
    'Novak Djokovic',
    'Ronaldinho',
    'Michael Jordan',
    'Fernando Alonso',
    'Bruce Lee',
    'Charlie Chaplin',
    'James Bond',
    'Don Quijote',
  ];

  // ─── ES UN 10 PERO... ────────────────────────────────────────

  static const esUn10Phrases = [
    'Es un 10 pero tarda 3 días en responder el WhatsApp',
    'Es un 10 pero sigue hablando con su ex',
    'Es un 10 pero siempre llega una hora tarde',
    'Es un 10 pero tiene 50 alarmas y se levanta a la última',
    'Es un 10 pero nunca reconoce que se equivoca',
    'Es un 10 pero pone fotos de hace 5 años',
    'Es un 10 pero nunca invita a nada',
    'Es un 10 pero menciona a su ex cada media hora',
    'Es un 10 pero duerme hasta las dos de la tarde',
    'Es un 10 pero no sabe freír un huevo',
    'Es un 10 pero responde todo con un "jajaja"',
    'Es un 10 pero les debe dinero a todos',
    'Es un 10 pero se ríe de sus propios chistes',
    'Es un 10 pero dice "te llamo luego" y nunca llama',
    'Es un 10 pero deja los platos en el fregadero',
    'Es un 10 pero solo va al gimnasio en enero',
  ];

  // ─── QUIÉN ES EL ESPIA ──────────────────────────────────────

  static const espiaLocations = [
    'Aeropuerto',
    'Playa',
    'Hospital',
    'Restaurante',
    'Escuela',
    'Supermercado',
    'Parque',
    'Cine',
    'Biblioteca',
    'Gimnasio',
    'Zoo',
    'Museo',
    'Iglesia',
    'Cárcel',
    'Fábrica',
    'Hotel',
    'Banco',
    'Estación de tren',
    'Circo',
    'Taberna',
    'Castillo',
    'Faro',
    'Desierto',
    'Volcán',
    'Montaña',
    'Barco',
    'Submarino',
    'Cueva',
    'Templo',
    'Mercado',
    'Acuario',
    'Estadio',
    'Casino',
    'Salón de juegos',
    'Helipuerto',
    'Granja',
    'Vivero',
    'Convento',
    'Farmacia',
    'Ópera',
    'Piscina',
    'Sauna',
    'Camping',
    'Costa Brava',
    'Isla desierta',
    'Universidad',
    'Teatro',
    'Puerto',
    'Catedral',
    'Fábrica',
    'Colegio',
    'Academia de música',
    'Jardín',
    'Parque de bomberos',
    'Comisaría',
    'Tribunal',
    'Ayuntamiento',
    'Mercadillo',
    'Centro comercial',
    'Outlet',
    'Parque acuático',
    'Spa',
    'Gimnasio de escalada',
    'Rocódromo',
    'Skatepark',
    'Bolera',
    'Karaoke',
    'Discoteca',
    'Bar de copas',
    'Pub',
    'Cervecería',
    'Viñedo',
    'Bodega',
    'Plaza mayor',
    'Mirador panorámico',
    'Embalse',
    'Presa',
    'Central hidroeléctrica',
    'Mina',
    'Cantera',
    'Observatorio astronómico',
    'Planetario',
    'Laboratorio',
    'Invernadero',
    'Orfanato',
    'Residencia',
    'Guardería',
    'Albergue',
    'Refugio de montaña',
  ];

  // ─── VERDAD O RETO ──────────────────────────────────────────

  static const verdadORetos = [
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor miedo?'),
    _VerdadOReto(type: 'reto', text: 'Haz 10 flexiones ahora mismo'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has llorado por una serie?',
    ),
    _VerdadOReto(type: 'reto', text: 'Imita al último animal que viste'),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor secreto vergonzoso?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Dale un abrazo a alguien durante 10 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has mentido para salir de un plan?',
    ),
    _VerdadOReto(type: 'reto', text: 'Canta tu canción favorita a viva voz'),
    _VerdadOReto(type: 'verdad', text: '¿Quién es tu crush secreto?'),
    _VerdadOReto(type: 'reto', text: 'Haz tu mejor imitación de un profesor'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has revisado el teléfono de alguien?',
    ),
    _VerdadOReto(type: 'reto', text: 'Habla con acento extranjero 2 minutos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es la cosa más rara que has comido?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Baila como si nadie te viera durante 30 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has fingido estar enfermo?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que alguien revise tu galería de fotos',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor arrepentimiento?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una pose de yoga y aguanta 15 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has besado a alguien de tu grupo?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Escribe con la mano que no usas tu nombre',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es el último mensaje que enviaste?',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz una selfie con la cara más graciosa'),
    _VerdadOReto(type: 'verdad', text: '¿Alguna vez has stalkedo a un ex?'),
    _VerdadOReto(type: 'reto', text: 'Sal al pasillo y grita "soy genial"'),
    _VerdadOReto(type: 'verdad', text: '¿Cuánto dinero tienes en la cuenta?'),
    _VerdadOReto(type: 'reto', text: 'Llama a alguien y dile que le quieres'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has robado algo (aunque sea pequeño)?',
    ),
    _VerdadOReto(type: 'reto', text: 'Dibuja tu cara en un papel y muéstralo'),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor cita?'),
    _VerdadOReto(type: 'reto', text: 'Haz 20 saltos de rana'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es el apodo más raro que te han puesto?',
    ),
    _VerdadOReto(type: 'reto', text: 'Habla solo en rimas durante 3 turnos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es la mejor mentira que has contado?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que el grupo te dibuje en la frente una cosa',
    ),
    _VerdadOReto(type: 'verdad', text: '¿A quién del grupo perdonarías nunca?'),
    _VerdadOReto(type: 'reto', text: 'Haz el pino contra la pared 10 segundos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es la cosa más cara que has roto?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Cuenta un chiste malísimo hasta que alguien se ría',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor mentira reciente?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Intercambia una prenda con la persona de tu derecha',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿De quién te has enamorado en secreto últimamente?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que alguien publique un estado en tu WhatsApp',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu momento más vergonzoso en una fiesta?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una declaración de amor dramática a una silla',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has ghosteado a alguien? ¿A quién?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Habla sin usar la letra ’a’ durante un minuto',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es la última foto en tu galería? Muéstrala',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Imita a la persona de tu izquierda hasta que adivinen quién es',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor hábito oculto?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Cuenta un secreto tuyo que nadie del grupo conozca',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si fueras invisible un día?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Bebe un chupito de agua con sal preparado por el grupo',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es la cosa más cara que has comprado y no usas?',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz 20 sentadillas gritando tu nombre'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Con quién del grupo te irías a una isla desierta?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que el grupo te maquille con los ojos cerrados',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor inseguridad?'),
    _VerdadOReto(type: 'reto', text: 'Actúa como un gato durante 30 segundos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Has llorado por alguien esta semana? ¿Por quién?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Envía un meme al último chat de tu lista sin contexto',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es el rumor más falso que han dicho de ti?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una coreografía con la canción que ponga el grupo',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Qué superpoder te gustaría tener?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una llamada en altavoz y canta cumpleaños feliz',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu crush famoso?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Ponte los zapatos al revés hasta tu próximo turno',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has mentido a tus padres para salir de fiesta?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Dibuja con la boca un retrato de alguien del grupo',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué cambiarías de tu vida ahora mismo?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Come una cucharada de algo que el grupo elija con ojos vendados',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz 20 sentadillas sin parar'),
    _VerdadOReto(
      type: 'reto',
      text: 'Imita a alguien del grupo hasta que adivinen quién es',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que te maquillen a ciegas durante 1 minuto',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz 20 saltos de tijera cantando tu canción favorita',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz el gusano en el suelo durante 5 segundos',
    ),
    _VerdadOReto(type: 'reto', text: 'Habla como un bebé durante 1 minuto'),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que el grupo te despeine y hazte una selfie',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu fantasía más picante que nunca has contado?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Manda un audio diciendo algo picante con voz seductora',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz twerking 10 segundos sin reírte'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has enviado una foto subida de tono? ¿A quién?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Baila reggaetón pegado 20 segundos con quien elija el grupo',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es el lugar más atrevido donde te gustaría tener una cita picante?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que alguien te escriba algo picante en la frente y muéstralo',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Has tenido un sueño picante con alguien de aquí? ¿Con quién?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una mirada seductora a cada jugador durante 3 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál ha sido tu mayor mentira para ligar?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Susurra algo atrevido al oído de la persona de tu derecha',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Imita un beso de película con una almohada de forma dramática',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué es lo más loco que harías por una noche inolvidable?',
    ),

    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es el chat que más revisas y por qué?',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz 5 burpees sin parar'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si te ofrecieran 1 millón por dejar tu móvil un año?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Imita a un influencer famoso 30 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu mayor drama familiar reciente?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que alguien elija tu fondo de pantalla por un día',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has mentido en este juego?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Habla solo en preguntas durante 3 turnos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué superpoder te daría más vergüenza tener?',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz una sentadilla y mantén 10 segundos'),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor compra por impulso?'),
    _VerdadOReto(type: 'reto', text: 'Baila 15 segundos con los ojos cerrados'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué foto borrarías de tu galería si te obligaran?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Cuenta un chiste y no pares hasta que alguien se ría',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿A quién stalkeas más sin que lo sepa?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una imitación de alguien del grupo sin decir quién',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu mayor mentira en el trabajo o clase?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Ponte un filtro tonto y habla serio 1 minuto',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si vieras a tu pareja coqueteando ahora?',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz 10 jumping jacks gritando tu apodo'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu recuerdo más incómodo de la infancia?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Canta el estribillo con boca llena de agua',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si te despiertas con otra identidad?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Intercambia calcetines con alguien por 2 rondas',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor miedo irracional?'),
    _VerdadOReto(type: 'reto', text: 'Haz el moonwalk aunque sea mal'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué mensaje nunca enviaste y te arrepientes?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que el grupo te ponga un peinado ridículo',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor cita a ciegas?'),
    _VerdadOReto(type: 'reto', text: 'Habla como villano de película 1 minuto'),
    _VerdadOReto(type: 'verdad', text: '¿Qué comerías cada día sin cansarte?'),
    _VerdadOReto(type: 'reto', text: 'Haz una pose de superhéroe 10 segundos'),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu talento más inútil?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Imita un animal hasta que adivinen cuál es',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si fueras invisible 1 hora aquí?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Escribe un piropo con la mano no dominante',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor fobia confesable?'),
    _VerdadOReto(type: 'reto', text: 'Bebe agua sin usar las manos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué serie te da vergüenza admitir que ves?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz un rap de 30 segundos sobre el grupo',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu excusa favorita para no salir?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que alguien te escriba algo en el brazo y muéstralo',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Qué canción cantas mal a propósito?'),
    _VerdadOReto(type: 'reto', text: 'Haz un puente o intenta'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu mayor gasto tonto del mes?',
    ),
    _VerdadOReto(type: 'reto', text: 'Habla al revés 30 segundos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si ganas la lotería mañana?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz 15 abdominales mientras cuentas chiste',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu momento más valiente?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Actúa como robot que se queda sin batería',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué app borrarías para siempre si te pagaran?',
    ),
    _VerdadOReto(type: 'reto', text: 'Haz una voltereta si puedes'),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor hábito en casa?'),
    _VerdadOReto(type: 'reto', text: 'Canta con voz de pito 15 segundos'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si te encuentras 1000 euros ahora?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz que alguien te use como almohada 30 segundos',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor logro tonto?'),
    _VerdadOReto(type: 'reto', text: 'Imita un meme famoso'),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si te regalan un viaje sorpresa?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que el grupo decida tu foto de perfil 1 hora',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es la última mentira que le dijiste a tu mejor amigo?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Ponte la camiseta al revés y habla así toda la ronda siguiente',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué es lo que más te da celos de alguien de aquí?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una imitación de tu cantante favorito 20 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál fue tu peor borrachera y con quién?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una flexión con alguien sentado en tu espalda',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué secreto le ocultas a tu familia desde hace años?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Deja que te hagan una entrevista absurda 1 minuto sin reír',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Alguna vez has llorado por celos? ¿Cuándo?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Canta el estribillo de una canción infantil con voz grave',
    ),
    _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor complejo físico?'),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz 10 sentadillas mientras recitas el abecedario al revés',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué harías si tu crush te escribe ahora mismo?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Imita a un animal salvaje hasta que alguien lo adivine',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu peor hábito cuando estás solo en casa?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz un discurso motivacional de 30 segundos como entrenador',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿A quién del grupo le pedirías perdón y por qué?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Baila 20 segundos como si tuvieras dos pies izquierdos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu recuerdo más feliz con amigos?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz una pose de estatua y que el grupo te mueva sin caerte',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿A quién de aquí besarías si nadie se enterase nunca?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Da un beso en la mejilla de la persona que elijas durante 3 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál es tu fantasía pendiente que no te atreves a confesar?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Susurra una fantasía al oído del grupo sin decir nombres',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Has tenido que besar a alguien y fingido que no te gustó?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Manda un beso volado a cámara y dedica con frase picante',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué beso recuerdas como el más atrevido de tu vida?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz un baile atrevido 10 segundos sin tocar a nadie',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué fantasía te da vergüenza admitir que tienes?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Escribe un mensaje picante ficticio y léelo con voz seductora',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Has tenido un sueño picante esta semana? ¿Con quién?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Da un abrazo atrevido de 5 segundos a quien elija el grupo',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Qué es lo más picante que te han dicho y te gustó?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Seduce a una silla como si fuera tu crush 15 segundos',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Besarías a tu ex si vuelve a aparecer hoy?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Susurra al oído de tu derecha un cumplido picante',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Cuál fue tu fantasía de adolescente más loca?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Da un beso a tu propia mano como en telenovela y declara amor',
    ),
    _VerdadOReto(
      type: 'verdad',
      text: '¿Has enviado un mensaje hot a la persona equivocada?',
    ),
    _VerdadOReto(
      type: 'reto',
      text: 'Haz twerking picante 5 segundos a ritmo que ponga el grupo',
    ),
  ];

  // ─── MATAR, CASAR, BESAR ────────────────────────────────────

  // Static data not needed - players provide the names

  // ─── SECRETOS ────────────────────────────────────────────────

  static const secretos = [
    'Alguien aquí tiene un crush secreto con alguien del grupo',
    'Alguien aquí ha revisado el teléfono de otro sin permiso',
    'Alguien aquí ha mentido para no salir con el grupo',
    'Alguien aquí ha comido la comida de otro sin preguntar',
    'Alguien aquí ha stalkedo a un ex recientemente',
    'Alguien aquí tiene una foto vergonzosa de otro',
    'Alguien aquí ha mandado un mensaje al equivocado esta semana',
    'Alguien aquí ha fingido no ver a alguien por la calle',
    'Alguien aquí ha cantado en la ducha a todo pulmón hoy',
    'Alguien aquí ha llorado viendo una película recientemente',
    'Alguien aquí ha googlado algo vergonzoso últimamente',
    'Alguien aquí ha comido algo del suelo sin que nadie viera',
    'Alguien aquí ha tenido una conversación con su mascota',
    'Alguien aquí ha dicho "ya estoy listo" y faltaban 30 minutos',
    'Alguien aquí ha pagado por algo que no necesitaba',
    'Alguien aquí ha mezclado ropa que no combinaba',
    'Alguien aquí ha tenido un crush con un profesor',
    'Alguien aquí ha abierto un mensaje y no ha respondido a propósito',
    'Alguien aquí ha dicho "mañana empiezo" y no empezó',
    'Alguien aquí ha tenido miedo de algo que vio en una película',
    'Alguien aquí ha fingido que le gustaba un regalo',
    'Alguien aquí se ha quedado dormido en casa de otro',
    'Alguien aquí ha hablado dormido esta semana',
    'Alguien aquí ha mentido sobre lo que se gastó',
    'Alguien aquí ha mandado un corazón a quien no debía',
    'Alguien aquí se ha probado ropa en una tienda sin comprarla',
    'Alguien aquí ha buscado a un compañero de trabajo en redes',
    'Alguien aquí ha cogido un bolígrafo del curro sin pensarlo',
    'Alguien aquí ha enviado una foto subida de tono',
    'Alguien aquí ha tenido un sueño picante con alguien del grupo',
    'Alguien aquí ha mentido sobre su experiencia sexual',
    'Alguien aquí ha hecho sexting en el trabajo o en clase',
    'Alguien aquí ha sido pillado en un momento íntimo',
    'Alguien aquí ha tenido un lío con el ex de un amigo/a',
    'Alguien aquí fantasea con alguien prohibido del grupo',
    'Alguien aquí ha usado una app de citas estando en pareja',
    'Alguien aquí ha besado a dos personas en la misma noche',
    'Alguien aquí ha visto contenido +18 en un lugar inapropiado',

    'Alguien aquí ha llorado a escondidas esta semana',
    'Alguien aquí ha guardado un regalo sin darlo',
    'Alguien aquí ha fingido estar enfermo para no ver a alguien',
    'Alguien aquí ha borrado un chat entero por vergüenza',
    'Alguien aquí ha reenviado un chisme que no debía',
    'Alguien aquí ha comprado algo y dijo que fue regalo',
    'Alguien aquí ha mirado el móvil de su pareja dormida',
    'Alguien aquí ha llorado con una canción en repeat',
    'Alguien aquí ha mentido sobre su edad real',
    'Alguien aquí ha hecho un perfil falso para stalkear',
    'Alguien aquí ha dicho te quiero sin sentirlo',
    'Alguien aquí ha guardado una foto que debería borrar',
    'Alguien aquí ha tenido un crush con alguien prohibido este mes',
    'Alguien aquí ha fingido reírse de un chiste malo',
    'Alguien aquí ha prometido dieta y la rompió el mismo día',
    'Alguien aquí ha enviado un mensaje y se arrepintió al instante',
    'Alguien aquí ha soñado con alguien del grupo',
    'Alguien aquí ha ocultado una compra a su pareja',
    'Alguien aquí ha hablado mal de alguien que está aquí',
    'Alguien aquí ha usado la tarjeta de otro sin permiso pequeño',
    'Alguien aquí ha besado a alguien y no lo recuerda bien',
    'Alguien aquí ha mentido sobre dónde estuvo anoche',
    'Alguien aquí ha borrado fotos para que no las vea su pareja',
    'Alguien aquí ha inventado una excusa para no ir a trabajar',
    'Alguien aquí ha llorado en el baño del trabajo',
    'Alguien aquí ha stalkedo a su jefe en redes',
    'Alguien aquí ha mentido sobre su sueldo real',
    'Alguien aquí ha comprado seguidores o likes',
    'Alguien aquí ha fingido que no tenía batería para no contestar',
    'Alguien aquí ha enviado un audio de 5 minutos',
    'Alguien aquí ha hecho ghosting y luego volvió como si nada',
    'Alguien aquí ha tenido un crush con alguien 10 años mayor o menor',
    'Alguien aquí ha mentido diciendo que estaba enfermo para ir de fiesta',
    'Alguien aquí ha roto algo en casa ajena y lo ocultó',
    'Alguien aquí ha probado comida de su mascota por curiosidad',
    'Alguien aquí ha cantado en karaoke y se arrepintió',
    'Alguien aquí ha usado Tinder solo para subir autoestima',
    'Alguien aquí ha discutido por un juego de mesa',
    'Alguien aquí ha escondido chuches para no compartir',
    'Alguien aquí ha fingido entender un chiste que no pilló',
    'Alguien aquí ha besado a alguien del grupo sin que el resto lo sepa',
    'Alguien aquí guarda un chat picante que no ha borrado por si acaso',
    'Alguien aquí ha fantaseado con la pareja de un amigo/a',
    'Alguien aquí ha mentido sobre su número de parejas sexuales',
    'Alguien aquí ha usado una excusa para quedarse a dormir fuera y no era verdad',
    'Alguien aquí ha enviado un audio hot y se arrepintió al segundo',
    'Alguien aquí ha tenido un casi algo con alguien prohibido del trabajo',
    'Alguien aquí ha borrado una app de citas justo antes de que su pareja viera el móvil',
    'Alguien aquí ha recibido un piropo subido y no lo contó a su pareja',
    'Alguien aquí ha soñado despierto con besar a alguien de aquí esta semana',
    'Alguien aquí ha llorado viendo un anuncio y lo ocultó',
    'Alguien aquí ha pedido comida y se arrepintió antes de que llegue',
    'Alguien aquí ha fingido estar ocupado para no ayudar en casa',
    'Alguien aquí ha enviado un sticker por error a su jefe',
    'Alguien aquí ha borrado el historial del navegador hoy',
    'Alguien aquí ha mirado el sueldo de un compañero a escondidas',
    'Alguien aquí ha dicho que estaba en camino y seguía duchándose',
    'Alguien aquí ha comprado algo y lo devolvió usado',
    'Alguien aquí ha usado filtro para parecer más alto',
    'Alguien aquí ha stalkedo a su ex hoy mismo',
    'Alguien aquí ha soñado que besaba a alguien de aquí y se despertó raro',
    'Alguien aquí guarda un meme que no entiende pero guarda por si acaso',
    'Alguien aquí ha mentido sobre haber visto una serie famosa',
    'Alguien aquí ha hecho spoiler y fingió no saber final',
    'Alguien aquí ha reenviado cadena sabiendo que es mentira',
  ];

  // ─── LA MÁSCARA INFILTRADA ─────────────────────────────────

  static const mascaras = [
    _Mascara(emoji: '🐶', name: 'Perro'),
    _Mascara(emoji: '🐸', name: 'Rana'),
    _Mascara(emoji: '🤡', name: 'Payaso'),
    _Mascara(emoji: '👽', name: 'Alien'),
    _Mascara(emoji: '🐱', name: 'Gato'),
    _Mascara(emoji: '🦊', name: 'Zorro'),
    _Mascara(emoji: '🐵', name: 'Mono'),
    _Mascara(emoji: '🤖', name: 'Robot'),
    _Mascara(emoji: '👻', name: 'Fantasma'),
    _Mascara(emoji: '🦄', name: 'Unicornio'),
  ];

  // ─── BOMBA ─────────────────────────────────────────────────

  static const bombaSilabas = [
    'TRA',
    'PLA',
    'PER',
    'CON',
    'VER',
    'PAR',
    'POR',
    'TER',
    'MAN',
    'COM',
    'PRA',
    'PRE',
    'PRO',
    'CRA',
    'CRE',
    'CLA',
    'CLO',
    'BRA',
    'BRE',
    'BRI',
    'STA',
    'STO',
    'EST',
    'ENT',
    'ANT',
    'ADO',
    'IDO',
    'OSA',
    'URA',
    'ANA',
    'ENA',
    'INA',
    'ARO',
    'ERO',
    'IRA',
    'ORO',
    'MOR',
    'MAR',
    'CAR',
    'BAR',
  ];

  // ─── ALIENÍGENA ────────────────────────────────────────────

  static const alienWords = [
    'Playa',
    'Bosque',
    'Ciudad',
    'Desierto',
    'Montaña',
    'Océano',
    'Selva',
    'Volcán',
    'Biblioteca',
    'Hospital',
    'Aeropuerto',
    'Estadio',
    'Museo',
    'Restaurante',
    'Fiesta',
    'Boda',
    'Concierto',
    'Carnaval',
    'Navidad',
    'Halloween',
  ];

  // ─── ENSALADA ────────────────────────────────────────────

  static const ensaladaPool = [
    'Silla',
    'Guitarra',
    'Elefante',
    'Correr',
    'Helicóptero',
    'Piscina',
    'León',
    'Saltar',
    'Ordenador',
    'Ballena',
    'Bailar',
    'Cuchara',
    'Tortuga',
    'Cantar',
    'Lámpara',
    'Cocodrilo',
    'Escribir',
    'Bicicleta',
    'Delfín',
    'Nadar',
    'Martillo',
    'Jirafa',
    'Cocinar',
    'Sombrero',
    'Tiburón',
    'Dibujar',
    'Paraguas',
    'Pingüino',
    'Volar',
    'Reloj',
    'Pulpo',
    'Pintar',
    'Maleta',
    'Lobo',
    'Conducir',
    'Taza',
    'Águila',
    'Silbar',
    'Tijeras',
    'Mono',
    'Reír',
    'Teléfono',
    'Cebra',
    'Llorar',
    'Balón',
    'Oso',
    'Aplaudir',
    'Libro',
    'Serpiente',
    'Empujar',
    'Auriculares',
    'Koala',
    'Gatear',
    'Ventana',
    'Camello',
    'Brincar',
    'Caja',
    'Panda',
    'Trepar',
    'Mochila',
    'Gorila',
    'Susurrar',
    'Botella',
    'Flamenco',
    'Gritar',
    'Llave',
    'Rinoceronte',
    'Dormir',
    'Cámara',
    'Zorro',
    'Esconder',
    'Cuerda',
    'Camaleón',
    'Rodar',
    'Espejo',
    'Hipopótamo',
    'Arrastrar',
    'Sofá',
    'Canguro',
    'Soplar',
  ];

  static const dosPalabrasWords = [
    'Tigre', 'Avión', 'Fuego', 'Castillo', 'Bicicleta', 'Fantasma', 'Montaña', 'Reloj', 'Doctor', 'Pizza',
    'Dragón', 'Playa', 'Guitarra', 'Elefante', 'Correr', 'Helicóptero', 'Piscina', 'León', 'Saltar', 'Ordenador',
    'Ballena', 'Bailar', 'Cuchara', 'Tortuga', 'Cantar', 'Lámpara', 'Cocodrilo', 'Escribir', 'Delfín', 'Nadar',
    'Martillo', 'Jirafa', 'Cocinar', 'Sombrero', 'Tiburón', 'Dibujar', 'Paraguas', 'Pingüino', 'Volar', 'Pulpo',
    'Pintar', 'Maleta', 'Silla', 'Volcán', 'Desierto', 'Bosque', 'Río', 'Isla', 'Trueno', 'Viento',
    'Lluvia', 'Nieve', 'Biblioteca', 'Hospital', 'Cine', 'Teatro', 'Gimnasio', 'Museo', 'Parque', 'Zoo',
  ];

  // ─── DIBUJA Y ADIVINA ──────────────────────────────────────

  static const dibujaWords = [
    'Gato',
    'Casa',
    'Árbol',
    'Sol',
    'Luna',
    'Estrella',
    'Corazón',
    'Flor',
    'Coche',
    'Bicicleta',
    'Mariposa',
    'Pez',
    'Helado',
    'Pizza',
    'Hamburguesa',
    'Guitarra',
    'Pelota',
    'Sombrero',
    'Zapatilla',
    'Reloj',
    'Paraguas',
    'Cohete',
    'Cohete espacial',
    'Castillo',
    'Dragón',
    'Dinosaurio',
    'Fantasía',
    'Alien',
    'Robot',
    'Caballo',
    'Elefante',
    'Tortuga',
    'Pulpo',
    'Delfín',
    'Canguro',
    'León',
    'Abeja',
    'Araña',
    'Cactus',
    'Montaña',
    'Volcán',
    'Playa',
    'Nieve',
    'Cerveza',
    'Taza de café',
    'Martillo',
    'Libro',
    'Lápiz',
  ];

  // ─── YO NUNCA MODOS ────────────────────────────────────────

  static const yoNuncaModos = <String, List<String>>{
    '😇 Normal': yoNuncaPrompts,
    '😂 Gracioso': [
      'Yo nunca me he reído tanto que me saliera la bebida por la nariz',
      'Yo nunca he bailado delante del espejo creyéndome famoso',
      'Yo nunca he fingido un estornudo para no responder a una pregunta',
      'Yo nunca he hablado con mi mascota en un idioma inventado',
      'Yo nunca me he reído en mitad de algo muy serio',
      'Yo nunca he hecho una videollamada y se me ha visto haciendo el tonto',
      'Yo nunca he gritado de susto por un susto propio tonto',
      'Yo nunca me he quedado atrapado en un sitio y he tenido que pedir ayuda',
      'Yo nunca he imitado a un famoso delante de todo el mundo',
      'Yo nunca he hecho una broma pesada que salió mal',
    ],
    '🔥 Picante': [
      'Yo nunca he besado a dos personas del mismo grupo',
      'Yo nunca he enviado un mensaje muy atrevido a la persona equivocada',
      'Yo nunca me he enamorado de un amigo o amiga',
      'Yo nunca he fantaseado con alguien del grupo',
      'Yo nunca he tenido una cita y la he cancelado a última hora',
      'Yo nunca he visto algo que no debía en el móvil de otra persona',
      'Yo nunca he hablado con mi ex después de cortar',
      'Yo nunca he hecho algo de lo que me arrepiento al día siguiente',
      'Yo nunca me he fijado en alguien dentro del grupo',
      'Yo nunca he usado una app de citas',
    ],
    '👫 Parejas': [
      'Yo nunca he discutido con mi pareja por algo tonto',
      'Yo nunca he estado celoso sin tener motivo',
      'Yo nunca he dicho "estoy bien" estando enfadado con mi pareja',
      'Yo nunca he revisado el móvil de mi pareja',
      'Yo nunca he hecho esperar a mi pareja más de una hora',
      'Yo nunca he dormido pegado al borde por una discusión',
      'Yo nunca he olvidado una fecha importante',
      'Yo nunca he fingido dormir para no hablar',
      'Yo nunca he comparado a mi pareja con otra persona',
      'Yo nunca me he llevado un enfado a la cama',
    ],
    '🥳 Fiesta': [
      'Yo nunca he sido el primero en irme de una fiesta',
      'Yo nunca he bailado en una mesa',
      'Yo nunca he cantado karaoke desafinando a propósito',
      'Yo nunca he roto algo en una fiesta sin avisar',
      'Yo nunca he hecho de DJ con mi móvil en una fiesta',
      'Yo nunca me he perdido dentro de la propia fiesta',
      'Yo nunca he llegado de casualidad a la mejor fiesta del año',
      'Yo nunca he hecho un "allá vamos" y me he arrepentido',
      'Yo nunca he sido el alma de la fiesta sin querer',
      'Yo nunca he inventado una excusa para quedarme a la fiesta',
    ],
    '🤪 Caótico': [
      'Yo nunca he mandado un mensaje a medianoche del que me arrepiento',
      'Yo nunca he comprado online algo que no necesitaba a las 3am',
      'Yo nunca he puesto 10 alarmas y me he levantado a la última',
      'Yo nunca he hecho una comida que salió desastre',
      'Yo nunca he vuelto a casa tarde y me he escondido',
      'Yo nunca he hecho un plan de locos con mis amigos',
      'Yo nunca he gastado dinero en algo absurdamente caro',
      'Yo nunca he tenido una idea genial a las 2am',
      'Yo nunca he constestado una llamada y me he arrepentido',
      'Yo nunca he hecho una apuesta loca que perdí',
    ],
  };

  // ─── VERDAD O RETO CATEGORÍAS ──────────────────────────────

  static const verdadORetoCategorias = <String, List<_VerdadOReto>>{
    '😇 Suave': [
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu comida favorita?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Dile un cumplido a la persona de tu izquierda',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu película favorita y por qué?',
      ),
      _VerdadOReto(type: 'reto', text: 'Inventa un baile nuevo ahora mismo'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué es lo primero que miras en una persona?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz tu mejor imitación de un animal'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor talento oculto?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Canta tu canción favorita durante 15 segundos',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué harías si te toca la lotería?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Cuenta tu historia favorita de la niñez',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu lugar soñado para viajar?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un cumplido sincero a cada persona del grupo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu recuerdo favorito de la infancia?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Dibuja tu animal favorito en 20 segundos',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué serie no te cansas de ver?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Comparte tu foto favorita del móvil y explica por qué',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu comida que odias y por qué?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Inventa una poesía de 4 versos sobre el grupo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué habilidad te gustaría aprender este año?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz mímica de tu película favorita hasta que adivinen',
      ),

      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu desayuno ideal?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un cumplido a cada persona con aliteración',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué animal te representa mejor?'),
      _VerdadOReto(type: 'reto', text: 'Dibuja tu casa ideal en 30 segundos'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu olor favorito?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Canta una nana como si durmieras a un bebé',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué superpoder suave elegirías: volar lento o invisibilidad parcial?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz tu mejor sonrisa para foto grupal'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu película cozy favorita?'),
      _VerdadOReto(type: 'reto', text: 'Cuenta tu chiste favorito limpio'),
      _VerdadOReto(type: 'verdad', text: '¿Qué lugar te da paz instantánea?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz mímica de abrir un regalo sorpresa',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu postre que siempre repites?',
      ),
      _VerdadOReto(type: 'reto', text: 'Da un abrazo grupal de 5 segundos'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué canción te pone de buen humor siempre?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz una reverencia dramática'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu plan perfecto de domingo?',
      ),
      _VerdadOReto(type: 'reto', text: 'Imita tu emoji favorito con la cara'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué habilidad blanda te hace único?',
      ),
      _VerdadOReto(type: 'reto', text: 'Comparte un dato curioso que sepas'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu recuerdo más dulce?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un corazón con las manos para cada persona',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué te hace reír sin control?'),
      _VerdadOReto(type: 'reto', text: 'Canta tu parte favorita de Disney'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu tradición familiar favorita?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz un saludo en 3 idiomas diferentes'),
      _VerdadOReto(type: 'verdad', text: '¿Qué libro recomendarías siempre?'),
      _VerdadOReto(type: 'reto', text: 'Actúa como si ganaras un premio'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu estación favorita y por qué?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un dibujo a ciegas de una estrella',
      ),
    ],
    '😂 Divertido': [
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es la cosa más vergonzosa que has hecho?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Habla con acento de otro país durante 2 minutos',
      ),
      _VerdadOReto(type: 'verdad', text: '¿A quién del grupo imitarías mejor?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Baila como si no hubiera mañana 20 segundos',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor ridículo en público?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que otro elija tu foto de perfil por un día',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es el mensaje más raro que has enviado?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz 10 flexiones cantando el himno'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál fue tu peor caída en público?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Pon cara de estreñido hasta que salte tu turno',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu excusa más rara para llegar tarde?',
      ),
      _VerdadOReto(type: 'reto', text: 'Habla como robot durante 2 minutos'),
      _VerdadOReto(type: 'verdad', text: '¿Qué palabra te cuesta pronunciar?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Ponte un filtro gracioso y haz una selfie grupal',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu meme favorito? Muéstralo',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una pasarela como modelo exagerado',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu manía más rara?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Intercambia zapatos con alguien por una ronda',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si fueras alcalde un día?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Inventa un anuncio vendiendo un zapato viejo',
      ),

      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor corte de pelo?'),
      _VerdadOReto(type: 'reto', text: 'Habla como pirata 1 minuto'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si te persigue una gallina gigante?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz la danza del pollo completa'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu sonido más tonto al estornudar?',
      ),
      _VerdadOReto(type: 'reto', text: 'Imita un bebé llorando y riendo'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu peor imitación? Demuéstrala',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Ponte dos calcetines en las manos y aplaude',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si tu voz cambiara a pito?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Cuenta una historia con voz de ardilla',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor fail en cocina?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Bebe agua haciendo gárgaras con canción',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué disfraz te daría vergüenza llevar?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz el limbo bajo una escoba imaginaria',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu peor chiste que aún cuentas?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un desfile con zapatos gigantes imaginarios',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si fueras alcalde por 5 minutos?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz sombras chinescas de un perro'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor momento vergonzoso en gym?',
      ),
      _VerdadOReto(type: 'reto', text: 'Intenta lamerte el codo'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si tu mascota hablara un día?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una cara de susto 10 segundos sin reír',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu peor regalo recibido?'),
      _VerdadOReto(type: 'reto', text: 'Haz un baile de TikTok inventado'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué palabra inventarías para tu risa?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz mímica de atrapar mosca con palillos',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor mentira piadosa divertida?',
      ),
      _VerdadOReto(type: 'reto', text: 'Canta ópera con boca llena de aire'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si todo fuera de gelatina?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un anuncio de pasta de dientes muy serio',
      ),
    ],
    '🔥 Picante': [
      _VerdadOReto(
        type: 'verdad',
        text: '¿A quién del grupo besarías sin pensarlo?',
      ),
      _VerdadOReto(type: 'reto', text: 'Cuenta una fantasía secreta'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor fantasía?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Envía el emoji 😘 a la última persona con la que hablaste',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Alguna vez has seducido a alguien a propósito?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una llamada y di "me gustas mucho"',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu cita más vergonzosa?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que el grupo escriba por ti un estado de WhatsApp',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es la persona que más te ha gustado sin decírselo?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Susurra algo picante al oído de la persona de tu derecha',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor red flag en una pareja?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Mándale un piropo atrevido al último contacto',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Has tenido un sueño picante con alguien del grupo?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una mirada seductora a cada persona 5 segundos',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué es lo más loco que harías por amor?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Escribe ’me gustas’ en el chat grupal sin contexto',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu tipo ideal detallado?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Baila pegado 20 segundos con la persona que elija el grupo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Alguna vez has besado a alguien y te arrepentiste?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que alguien revise tu último chat picante censurado',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Manda un audio diciendo algo picante con voz susurrada',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz twerking 10 segundos sin parar'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu parte favorita del cuerpo de otra persona?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Baila en el centro 20 segundos como si estuvieras en una discoteca picante',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Has fantaseado con alguien del trabajo o clase?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que el grupo te ponga un apodo picante por toda la noche',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué mensaje picante nunca te atreviste a enviar?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una declaración de amor picante a la persona que elija el grupo',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Imita un beso de película con pasión durante 5 segundos',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál ha sido tu momento más caliente en una fiesta?',
      ),

      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué mensaje hot borrarías si te pillan?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Manda un piropo subido a tu crush con emojis',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor arrepentimiento romántico?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una declaración dramática a la cámara',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Has stalkedo a tu ex esta semana?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que alguien elija tu estado picante por 10 min',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu fantasía de cita perfecta atrevida?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Baila bachata 20 segundos muy pegado solo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué es lo más atrevido que has buscado en internet?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Susurra un secreto picante al oído izq',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Con quién del grupo tendrías una cita prohibida?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una mirada intensa 5 segundos a cada uno',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si te escribe tu crush ahora?',
      ),
      _VerdadOReto(type: 'reto', text: 'Imita un beso de telenovela con mano'),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor celo confesable?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Escribe te echo de menos a contacto aleatorio con permiso',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Has mentido para gustar a alguien? ¿Cómo?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un corazón con manos y guiño a cada persona',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué te pone nervioso en una cita?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Baila como si ligaras en discoteca 15 seg',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué parte del cuerpo te pone más nervioso que te toquen y por qué?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Intercambia prenda con alguien 1 ronda',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Susurra al oído algo que nunca dirías en voz alta a la persona de tu izquierda',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál fue tu beso más inesperado y dónde fue?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un baile lento de 15 segundos mirando fijo a alguien del grupo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué mensaje picante te hubiera gustado recibir y nunca llegó?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que alguien te haga un masaje de 10 segundos en hombros',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Con quién famoso tendrías una noche prohibida sin que nadie se enterase?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Ponte a 10 cm de la cara de alguien 5 segundos sin reír',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué es lo más atrevido que has hecho por celos?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Envía un te he soñado anoche a la persona que elija el grupo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué prefieres: beso lento o beso salvaje? ¿Por qué?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una descripción seductora de tu desayuno ideal como si fuera anuncio hot',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Has enviado alguna vez un me arrepiento después de besar a alguien?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Imita cómo ligarías en un bar en 20 segundos',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor fantasía inconfesable sin decir nombre?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que el grupo elija una foto tuya y ponga un caption picante 1 minuto',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si tu crush te pide un beso ahora mismo delante de todos?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un cumplido subido de tono sin ser vulgar a cada persona',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Has mentido sobre besar a alguien para impresionar?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Baila 20 segundos sobre una silla con mirada seductora',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Dónde te gustaría que te besaran sin avisar?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Susurra tu frase para ligar más ridícula con voz seductora',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es el lugar más raro donde has tenido un momento íntimo?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Intercambia asiento y siéntate en piernas de alguien 10 segundos si todos consienten',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué fantasía de película te gustaría recrear?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un top 3 de besos del grupo sin decir por qué',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Te pondrías celoso si tu pareja baila muy pegado con otro?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Mándale un emoji picante al contacto que elija el grupo con texto pensé en ti',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué secreto picante guardarías hasta la tercera cita?',
      ),
    ],
    '💀 Extremo': [
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es el mayor secreto que nunca has contado?',
      ),
      _VerdadOReto(type: 'reto', text: 'Sal a la calle y grita "¡SOY GENIAL!"'),
      _VerdadOReto(type: 'verdad', text: '¿Alguna vez has robado algo?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Llámalo y dile que le quieres sin contexto',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Ha algo que harías por dinero que daría vergüenza?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Come algo sin mirar que el grupo elija',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor arrepentimiento?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Envía un audio cantando al último contacto de tu lista',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu secreto inconfesable más oscuro?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja tu móvil encendido y que el grupo envíe lo que quiera a tu última conversación',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si te quedaran 24 horas de vida?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Publica ’soy el mejor’ en tu Instagram y déjalo 5 minutos',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es la cosa más ilegal que has hecho?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Llama a tu ex y di ’gracias por todo’ y cuelga',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué secreto familiar nunca has contado?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Come algo picante extremo sin beber agua 30 segundos',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor miedo a futuro?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que el grupo publique lo que quiera en tu estado',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Alguna vez has traicionado a un amigo? ¿Cómo?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una confesión dramática mirando a la cámara del móvil',
      ),

      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es la peor traición que has hecho?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Publica te amo en tu estado y bórralo en 2 min',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si te ofrecen irte del país hoy?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Llama a un familiar y canta sin explicar',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor deuda oculta?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja tu galería 30 seg en manos del grupo',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué secreto te avergüenza más contar aquí?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Come mezcla rara que prepare el grupo (segura)',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué harías si te despiden mañana?'),
      _VerdadOReto(type: 'reto', text: 'Grita tu mayor miedo por la ventana'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor mentira a tus padres?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz 30 sentadillas seguidas sin quejarte',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué cambiarías de tu vida aunque duela?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Deja que el grupo te quite una prenda ligera',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Cuál es tu mayor fracaso amoroso?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Escribe perdón a quien debes y muéstralo',
      ),
      _VerdadOReto(type: 'verdad', text: '¿Qué harías ilegal por 1 millón?'),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz un directo de 30 seg contando tu secreto suave',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor vergüenza pública?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Intercambia móvil 1 minuto con alguien',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué es lo peor que has dicho borracho?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Pide perdón en voz alta por algo que no hiciste',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor adicción confesable?',
      ),
      _VerdadOReto(type: 'reto', text: 'Haz un baile extremo en silla'),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Qué harías si solo te quedan 7 días?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Publica emoji misterioso y no expliques',
      ),
      _VerdadOReto(
        type: 'verdad',
        text: '¿Cuál es tu mayor envidia hacia alguien aquí?',
      ),
      _VerdadOReto(
        type: 'reto',
        text: 'Haz una confesión mirando al suelo 20 seg',
      ),
    ],
  };

  // ─── PLANES REALES MADRID (15 lugares mock creíbles) ─────────
  // Categorías: ciudad (Plaza Mayor, Malasaña, Lavapiés), comer (Mercado San Miguel, Lateral, 100 Montaditos), juegos (Arcade/Bowling), sierra (Sierra de Guadarrama, Cercedilla, Navacerrada), campo/ciudad extra.
  static const madridRealPlaces = <MadridPlace>[
    MadridPlace(title: 'Paseo por Plaza Mayor + chocolate en San Ginés', description: 'Ruta por Plaza Mayor y Austrias + chocolate con churros en Chocolatería San Ginés', address: 'Plaza Mayor, 27, 28012 Madrid', schedule: '09:30-23:30', emoji: '🏛️', type: 'cultura', costValue: 12, distanceKm: 0.7, durationHours: 2.0, rating: 4.7),
    MadridPlace(title: 'Ruta por Malasaña + vermú en Mercado San Antón', description: 'Recorre Malasaña, Fuencarral y vermú con tapa en Mercado San Antón (Chueca)', address: 'C. de Augusto Figueroa, 24, 28004 Madrid', schedule: '10:00-00:00', emoji: '🥂', type: 'gastronomía', costValue: 18, distanceKm: 1.1, durationHours: 2.5, rating: 4.6),
    MadridPlace(title: 'Arte urbano por Lavapiés + cañas en Tabacalera', description: 'Murales de Lavapiés, Tabacalera y cañas en bar castizo con terraza', address: 'C. de Embajadores, 53, 28012 Madrid', schedule: '12:00-23:30', emoji: '🎨', type: 'cultura', costValue: 10, distanceKm: 1.3, durationHours: 2.0, rating: 4.5),
    MadridPlace(title: 'Tardeo por Las Letras y Huertas', description: 'Bares de Huertas, Plaza de Santa Ana y tardeo con amigos hasta la noche', address: 'C. de Huertas, 42, 28014 Madrid', schedule: '13:00-01:00', emoji: '🍻', type: 'fiesta', costValue: 20, distanceKm: 0.9, durationHours: 3.0, rating: 4.6),
    MadridPlace(title: 'Tapeo en Mercado de San Miguel', description: 'Puestos de gildas, tortilla y vermut en Mercado de San Miguel junto a Plaza Mayor', address: 'Pl. de San Miguel, s/n, 28005 Madrid', schedule: '10:00-00:00', emoji: '🥘', type: 'gastronomía', costValue: 22, distanceKm: 0.6, durationHours: 1.5, rating: 4.7),
    MadridPlace(title: 'Cañas y raciones en Lateral Castellana', description: 'Barra de Lateral en Paseo Castellana: tostas, ensaladilla y cañas bien tiradas', address: 'P.º de la Castellana, 89, 28046 Madrid', schedule: '12:00-00:00', emoji: '🍢', type: 'gastronomía', costValue: 28, distanceKm: 3.8, durationHours: 2.0, rating: 4.5),
    MadridPlace(title: '100 Montaditos en Preciados + paseo por Sol', description: 'Montaditos y jarras en 100 Montaditos de Preciados y paseo hasta Sol-Kilómetro Cero', address: 'C. de Preciados, 19, 28013 Madrid', schedule: '12:00-23:30', emoji: '🥖', type: 'gastronomía', costValue: 12, distanceKm: 0.5, durationHours: 1.5, rating: 4.3),
    MadridPlace(title: 'Bowling en Ozone Chamartín', description: 'Partidas de bolos, billar y recreativos en Ozone Bowling Chamartín', address: 'C. de Arturo Soria, 126, 28043 Madrid', schedule: '16:00-02:00', emoji: '🎳', type: 'aventura', costValue: 14, distanceKm: 5.5, durationHours: 2.0, rating: 4.4),
    MadridPlace(title: 'Arcade y juegos en YOKAI Malasaña', description: 'Máquinas retro, pinball y neones en Arcade Bar YOKAI (Malasaña)', address: 'C. de San Vicente Ferrer, 29, 28004 Madrid', schedule: '17:00-01:30', emoji: '🕹️', type: 'aventura', costValue: 16, distanceKm: 1.2, durationHours: 2.0, rating: 4.6),
    MadridPlace(title: 'Barcas en Retiro + picnic', description: 'Barca en el Estanque Grande del Retiro y picnic en césped bajo los plátanos', address: 'Parque del Retiro, P.º del Paraguay, 28009 Madrid', schedule: '10:00-20:30', emoji: '🦢', type: 'relax', costValue: 8, distanceKm: 1.8, durationHours: 2.0, rating: 4.8),
    MadridPlace(title: 'Senderismo en La Pedriza (Sierra de Guadarrama)', description: 'Ruta circular por La Pedriza, rocas y pozas. Llevar coche y agua', address: 'La Pedriza, 28410 Manzanares el Real, Madrid', schedule: '08:00-20:00', emoji: '🥾', type: 'naturaleza', costValue: 0, distanceKm: 48, durationHours: 4.0, rating: 4.8),
    MadridPlace(title: 'Ruta familiar en Cercedilla – Dehesas (en Cercanías C-8)', description: 'Senda accesible por bus/Cercanías a Cercedilla, bosque y riachuelo ideal familia', address: 'Estación de Cercedilla, 28470 Cercedilla, Madrid', schedule: '09:00-19:30', emoji: '🌲', type: 'naturaleza', costValue: 5, distanceKm: 52, durationHours: 3.0, rating: 4.7),
    MadridPlace(title: 'Miradores en Puerto de Navacerrada', description: 'Puerto de Navacerrada, miradores de Sierra y bocata con vistas', address: 'Puerto de Navacerrada, 28470 Navacerrada, Madrid', schedule: '08:00-19:30', emoji: '🏔️', type: 'naturaleza', costValue: 8, distanceKm: 58, durationHours: 3.5, rating: 4.7),
    MadridPlace(title: 'Campo y bici en Casa de Campo – Lago', description: 'Vuelta en bici/patinete por Casa de Campo, Lago y mirador de la Almudena', address: 'Lago Casa de Campo, P.º del Embarcadero, 28011 Madrid', schedule: '07:00-22:00', emoji: '🚲', type: 'naturaleza', costValue: 6, distanceKm: 3.2, durationHours: 2.5, rating: 4.6),
    MadridPlace(title: 'Paseo campestre en El Pardo', description: 'Encinar de El Pardo, bici suave y picnic campestre sin coche si hace falta', address: 'Monte de El Pardo, 28048 Madrid', schedule: '09:00-19:00', emoji: '🌳', type: 'naturaleza', costValue: 0, distanceKm: 12, durationHours: 3.0, rating: 4.5),
  ];
}

class MadridPlace {
  final String title;
  final String description;
  final String address;
  final String schedule;
  final String emoji;
  final String type;
  final int costValue;
  final double distanceKm;
  final double durationHours;
  final double rating;
  const MadridPlace({required this.title, required this.description, required this.address, required this.schedule, required this.emoji, required this.type, required this.costValue, required this.distanceKm, required this.durationHours, required this.rating});
}

class _ImpostorPair {
  final String word;
  final String fake;
  final String hint;

  const _ImpostorPair({
    required this.word,
    required this.fake,
    required this.hint,
  });
}

class AdivinaWord {
  final String word;
  final String clue;

  const AdivinaWord({required this.word, required this.clue});
}

class TabooCard {
  final String word;
  final List<String> forbidden;

  const TabooCard({required this.word, required this.forbidden});
}

class _RoleData {
  final String icon;
  final String description;
  final int color;

  const _RoleData({
    required this.icon,
    required this.description,
    required this.color,
  });
}

class _VerdadOReto {
  final String type;
  final String text;

  const _VerdadOReto({required this.type, required this.text});
}

class _Mascara {
  final String emoji;
  final String name;

  const _Mascara({required this.emoji, required this.name});
}

class DebatePlan {
  final String title;
  final String description;
  final String emoji;

  const DebatePlan({
    required this.title,
    required this.description,
    required this.emoji,
  });
}
