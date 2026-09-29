import 'package:flutter/foundation.dart';

/// Lightweight singleton holding the active consultation state
/// Extends ChangeNotifier so HomeScreen and WaitingRoom can reactively update.
class ActiveConsultationState extends ChangeNotifier {
  ActiveConsultationState._();
  static final ActiveConsultationState _i = ActiveConsultationState._();
  static ActiveConsultationState get instance => _i;

  // ─── Queue entry (Instant Call / Live Triage) ───────────────
  String? queueAppointmentId;
  String? queueDoctorId;
  String? queueDoctorName;
  String? queueDoctorImage;
  String? queueDoctorSpecialization;
  String? queueDoctorClinic;
  String? queueToken; // e.g. 'Q-04'
  String? queueServingToken; // e.g. 'Q-02'
  int? queuePosition; // 1-based overall position
  int? queuePositionAhead; // Number of patients ahead
  int? queueEstimatedMinutes; // e.g. 6 mins
  String? queueExpectedTime;
  String? queueAnimalName;
  String? queueAnimalTag;
  String? queueSpecies;
  List<String> queueSymptoms = [];
  String queueDescription = '';
  List<String> queuePhotos = [];

  // ─── Booked appointment (Book Appointment tab) ─────────────
  String? appointmentId;
  String? appointmentNumber; // e.g. 'APT-2026-8912'
  String? appointmentStatus; // 'scheduled', 'accepted', 'completed'
  String? appointmentDoctorId;
  String? appointmentDoctorName;
  String? appointmentDoctorImage;
  String? appointmentDoctorSpecialization;
  String? appointmentDate;
  String? appointmentTime;
  String? appointmentAnimal;
  String? appointmentAnimalTag;
  String? appointmentSpecies;
  List<String> appointmentSymptoms = [];
  List<String> appointmentPhotos = [];
  String? appointmentNotes;

  // ─── Booked lab test (Tests & Reports) ─────────────────────
  String? testBookingId;
  String? testName;
  String? testAnimal;
  String? testAnimalTag;
  String? testDate;
  String? testSlotTime;
  String? testStatus;
  String? collectionOtp;
  String? collectorName;
  String? collectorPhone;
  String? testReportId;
  String? testReportSummary;
  bool? testIsAbnormal;

  // ─── Additional Confirmed Appointments Tracker ──────────────
  int additionalAppointmentsToday = 0;

  // ─── Live Video Call State ─────────────────────────────────
  bool isInActiveCall = false;
  String? activeCallAppointmentId;

  void startCall(String aptId) {
    isInActiveCall = true;
    activeCallAppointmentId = aptId;
    notifyListeners();
  }

  void endCall() {
    isInActiveCall = false;
    activeCallAppointmentId = null;
    notifyListeners();
  }

  // ─── Convenience getters ───────────────────────────────────
  bool get hasQueue => queueDoctorName != null;
  bool get hasAppointment => appointmentDoctorName != null;
  bool get isTestCompleted {
    final s = (testStatus ?? '').toUpperCase();
    return s == 'REPORT_AVAILABLE' || s == 'COMPLETED' || s == 'DONE' || s == 'TEST_COMPLETED';
  }
  bool get hasTestBooking => testName != null && !isTestCompleted;
  bool get hasAny => hasQueue || hasAppointment || hasTestBooking;

  /// Returns real, dynamic appointments count for today
  int get realAppointmentsTodayCount {
    int count = additionalAppointmentsToday;
    if (hasQueue) count++;
    if (hasAppointment) {
      final d = appointmentDate?.toLowerCase() ?? '';
      if (d.contains('today') || d.contains('26 sep') || d.contains('sat')) {
        count++;
      } else if (d.isNotEmpty &&
          !d.contains('tomorrow') &&
          !d.contains('mon') &&
          !d.contains('tue') &&
          !d.contains('wed') &&
          !d.contains('thu') &&
          !d.contains('fri') &&
          !d.contains('sun')) {
        count++;
      }
    }
    if (hasTestBooking) {
      final td = testDate?.toLowerCase() ?? '';
      if (td.contains('today') || td.contains('26 sep') || td.contains('sat')) {
        count++;
      }
    }
    return count;
  }

  void setQueue({
    required String doctorName,
    required String doctorImage,
    required int position,
    required String animalName,
    String? appointmentId,
    String? doctorId,
    String? doctorSpecialization,
    String? doctorClinic,
    String? queueToken,
    String? servingToken,
    int? positionAhead,
    int? estimatedMinutes,
    String expectedTime = '3-5 mins',
    String? animalTag,
    String? species,
    List<String>? symptoms,
    String? description,
    List<String>? photos,
  }) {
    queueAppointmentId = appointmentId ?? queueAppointmentId;
    queueDoctorId = doctorId ?? queueDoctorId;
    queueDoctorName = doctorName;
    queueDoctorImage = doctorImage;
    queueDoctorSpecialization = doctorSpecialization ?? 'Bovine Medicine & Surgery';
    queueDoctorClinic = doctorClinic ?? 'Veterinary Dispensary';
    this.queueToken = queueToken ?? 'Q-01';
    queueServingToken = servingToken ?? 'Q-01';
    queuePosition = position;
    queuePositionAhead = positionAhead ?? (position > 1 ? position - 1 : 0);
    queueEstimatedMinutes = estimatedMinutes ?? ((queuePositionAhead ?? 1) * 3);
    queueExpectedTime = expectedTime;
    queueAnimalName = animalName;
    queueAnimalTag = animalTag ?? 'ANML-01';
    queueSpecies = species ?? 'Cattle';
    queueSymptoms = symptoms ?? [];
    queueDescription = description ?? '';
    queuePhotos = photos ?? [];
    notifyListeners();
  }

  void updateQueueStatus({
    String? queueToken,
    String? servingToken,
    int? positionAhead,
    int? estimatedMinutes,
    String? expectedTime,
  }) {
    if (queueToken != null) this.queueToken = queueToken;
    if (servingToken != null) queueServingToken = servingToken;
    if (positionAhead != null) {
      queuePositionAhead = positionAhead;
      queuePosition = positionAhead + 1;
    }
    if (estimatedMinutes != null) queueEstimatedMinutes = estimatedMinutes;
    if (expectedTime != null) queueExpectedTime = expectedTime;
    notifyListeners();
  }

  void clearQueue() {
    queueAppointmentId = null;
    queueDoctorId = null;
    queueDoctorName = null;
    queueDoctorImage = null;
    queueDoctorSpecialization = null;
    queueDoctorClinic = null;
    queueToken = null;
    queueServingToken = null;
    queuePosition = null;
    queuePositionAhead = null;
    queueEstimatedMinutes = null;
    queueAnimalName = null;
    queueAnimalTag = null;
    queueSpecies = null;
    queueExpectedTime = null;
    queueSymptoms = [];
    queueDescription = '';
    queuePhotos = [];
    notifyListeners();
  }

  void setAppointment({
    required String doctorName,
    required String doctorImage,
    required String date,
    required String time,
    required String animal,
    String? appointmentId,
    String? appointmentNumber,
    String? appointmentStatus,
    String? doctorId,
    String? doctorSpecialization,
    String? animalTag,
    String? species,
    List<String>? symptoms,
    List<String>? photos,
    String? notes,
  }) {
    this.appointmentId = appointmentId;
    this.appointmentNumber = appointmentNumber;
    this.appointmentStatus = appointmentStatus ?? 'scheduled';
    appointmentDoctorId = doctorId;
    appointmentDoctorName = doctorName;
    appointmentDoctorImage = doctorImage;
    appointmentDoctorSpecialization = doctorSpecialization ?? 'Veterinary Officer';
    appointmentDate = date;
    appointmentTime = time;
    appointmentAnimal = animal;
    appointmentAnimalTag = animalTag;
    appointmentSpecies = species ?? 'Cattle';
    appointmentSymptoms = symptoms ?? [];
    appointmentPhotos = photos ?? [];
    appointmentNotes = notes;
    notifyListeners();
  }

  void updateAppointmentStatus(String status, {String? appointmentNumber}) {
    appointmentStatus = status;
    if (appointmentNumber != null) this.appointmentNumber = appointmentNumber;
    notifyListeners();
  }

  void clearAppointment() {
    appointmentId = null;
    appointmentNumber = null;
    appointmentStatus = null;
    appointmentDoctorId = null;
    appointmentDoctorName = null;
    appointmentDoctorImage = null;
    appointmentDoctorSpecialization = null;
    appointmentDate = null;
    appointmentTime = null;
    appointmentAnimal = null;
    appointmentAnimalTag = null;
    appointmentSpecies = null;
    appointmentSymptoms = [];
    appointmentPhotos = [];
    appointmentNotes = null;
    notifyListeners();
  }

  void setTestBooking({
    required String testName,
    required String animal,
    required String date,
    String? bookingId,
    String? animalTag,
    String? slotTime,
    String? status,
    String? otp,
    String? collector,
    String? phone,
    String? reportId,
    String? reportSummary,
    bool? isAbnormal,
  }) {
    this.testName = testName;
    testAnimal = animal;
    testDate = date;
    testBookingId = bookingId ?? testBookingId;
    testAnimalTag = animalTag ?? testAnimalTag;
    testSlotTime = slotTime ?? testSlotTime;
    testStatus = status ?? 'TEST_BOOKED';
    collectionOtp = otp ?? collectionOtp;
    collectorName = collector ?? collectorName;
    collectorPhone = phone ?? collectorPhone;
    testReportId = reportId ?? testReportId;
    testReportSummary = reportSummary ?? testReportSummary;
    testIsAbnormal = isAbnormal ?? testIsAbnormal;
    notifyListeners();
  }

  void updateTestStatus({
    String? status,
    String? collector,
    String? phone,
    String? otp,
    String? reportId,
    String? reportSummary,
    bool? isAbnormal,
  }) {
    if (status != null) testStatus = status;
    if (collector != null) collectorName = collector;
    if (phone != null) collectorPhone = phone;
    if (otp != null) collectionOtp = otp;
    if (reportId != null) testReportId = reportId;
    if (reportSummary != null) testReportSummary = reportSummary;
    if (isAbnormal != null) testIsAbnormal = isAbnormal;
    notifyListeners();
  }

  void clearTestBooking() {
    testBookingId = null;
    testName = null;
    testAnimal = null;
    testAnimalTag = null;
    testDate = null;
    testSlotTime = null;
    testStatus = null;
    collectionOtp = null;
    collectorName = null;
    collectorPhone = null;
    testReportId = null;
    testReportSummary = null;
    testIsAbnormal = null;
    notifyListeners();
  }

  void clearAll() {
    clearQueue();
    clearAppointment();
    clearTestBooking();
  }
}
