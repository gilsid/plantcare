enum CareType {
  watering,
  fertilizing,
  pruning,
  pestCheck,
  repotting;

  String get displayName {
    switch (this) {
      case CareType.watering:
        return 'Penyiraman';
      case CareType.fertilizing:
        return 'Pemupukan';
      case CareType.pruning:
        return 'Pemangkasan';
      case CareType.pestCheck:
        return 'Pengecekan Hama';
      case CareType.repotting:
        return 'Ganti Pot';
    }
  }

  String get iconLabel {
    switch (this) {
      case CareType.watering:
        return 'water_drop';
      case CareType.fertilizing:
        return 'science';
      case CareType.pruning:
        return 'content_cut';
      case CareType.pestCheck:
        return 'bug_report';
      case CareType.repotting:
        return 'replay';
    }
  }
}

enum IntervalUnit {
  hour,
  day,
  week,
  month;

  String get displayName {
    switch (this) {
      case IntervalUnit.hour:
        return 'Jam';
      case IntervalUnit.day:
        return 'Hari';
      case IntervalUnit.week:
        return 'Minggu';
      case IntervalUnit.month:
        return 'Bulan';
    }
  }

  String get displayNamePlural {
    switch (this) {
      case IntervalUnit.hour:
        return 'Jam';
      case IntervalUnit.day:
        return 'Hari';
      case IntervalUnit.week:
        return 'Minggu';
      case IntervalUnit.month:
        return 'Bulan';
    }
  }

  Duration get asDuration {
    switch (this) {
      case IntervalUnit.hour:
        return const Duration(hours: 1);
      case IntervalUnit.day:
        return const Duration(days: 1);
      case IntervalUnit.week:
        return const Duration(days: 7);
      case IntervalUnit.month:
        return const Duration(days: 30);
    }
  }
}
