import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

/// Wrapper fino sobre o Firebase Analytics. Centraliza os eventos do
/// funil do profissional para manter os nomes consistentes entre as telas.
class AnalyticsService extends GetxService {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: analytics);

  Future<void> logLogin(String method) =>
      analytics.logLogin(loginMethod: method);

  Future<void> logSignUp(String method) =>
      analytics.logSignUp(signUpMethod: method);

  Future<void> logAppointmentConfirmed(String appointmentId) =>
      analytics.logEvent(
          name: 'appointment_confirmed',
          parameters: {'appointment_id': appointmentId});

  Future<void> logAppointmentRejected(String appointmentId) =>
      analytics.logEvent(
          name: 'appointment_rejected',
          parameters: {'appointment_id': appointmentId});

  Future<void> logAppointmentCompleted(String appointmentId) =>
      analytics.logEvent(
          name: 'appointment_completed',
          parameters: {'appointment_id': appointmentId});
}
