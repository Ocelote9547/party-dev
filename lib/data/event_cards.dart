// ignore_for_file: public_member_api_docs
import 'dart:math';

class EventCard {
  final String emoji;
  final String title;
  final String description;

  const EventCard({
    required this.emoji,
    required this.title,
    required this.description,
  });
}

const List<EventCard> eventCards = [
  EventCard(
    emoji: '🔄',
    title: 'Todos cambian de sitio',
    description: '¡Todos se levantan y cambian de asiento! El juego sigue desde la nueva posición.',
  ),
  EventCard(
    emoji: '🙃',
    title: 'El líder habla al revés',
    description: 'Quien va ganando debe hablar al revés hasta la próxima ronda.',
  ),
  EventCard(
    emoji: '📱',
    title: 'Cambio de manos (pasa el móvil)',
    description: 'Pasa el móvil a la persona de tu izquierda usando la mano no dominante.',
  ),
  EventCard(
    emoji: '🤫',
    title: 'Silencio 10s',
    description: '¡Silencio total durante 10 segundos! Quien hable pierde el turno.',
  ),
  EventCard(
    emoji: '✨',
    title: 'Dobla puntos esta ronda',
    description: '¡Ronda x2! Todos los puntos de esta ronda valen el doble.',
  ),
  EventCard(
    emoji: '👀',
    title: 'Ojos cerrados',
    description: 'El siguiente jugador actúa con los ojos cerrados durante 5 segundos.',
  ),
  EventCard(
    emoji: '🐢',
    title: 'Cámara lenta',
    description: 'Haz la próxima acción a cámara lenta. ¡Todo en slow motion!',
  ),
  EventCard(
    emoji: '🧍',
    title: '¡Todos de pie!',
    description: '¡Todos de pie! Quien se quede sentado hace la próxima mímica.',
  ),
  EventCard(
    emoji: '🤖',
    title: 'Voz de robot',
    description: 'Habla como un robot hasta tu próximo turno. Bip bop.',
  ),
  EventCard(
    emoji: '🙌',
    title: 'Manos a la espalda',
    description: 'Solo puedes usar cara y cuerpo, ¡manos tras la espalda!',
  ),
  EventCard(
    emoji: '⚡',
    title: 'Turno relámpago',
    description: '¡10 segundos menos en el temporizador de esta ronda!',
  ),
  EventCard(
    emoji: '🎭',
    title: 'Cambio de rol',
    description: 'Intercambia tu rol con el jugador de enfrente para esta ronda.',
  ),
];

class EventDeck {
  static final _random = Random();

  static EventCard randomCard() =>
      eventCards[_random.nextInt(eventCards.length)];

  static EventCard byIndex(int index) =>
      eventCards[index % eventCards.length];
}
