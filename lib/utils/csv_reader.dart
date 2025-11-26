import 'package:flutter/services.dart';
import '../models/process.dart';

class CsvReader {
  static Future<List<Process>> readProcessesFromAsset(String assetPath) async {
    try {
      final String data = await rootBundle.loadString(assetPath);
      return parseCsvData(data);
    } catch (e) {
      throw Exception('Error reading CSV file: $e');
    }
  }

  static Future<List<Process>> readProcessesFromString(String csvData) async {
    return parseCsvData(csvData);
  }

  static List<Process> parseCsvData(String data) {
    final List<Process> processes = [];
    final lines = data.split('\n');


    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length >= 4) {
        try {
          final process = Process(
            id: parts[0].trim(),
            arrivalTime: int.parse(parts[1].trim()),
            cpuBurstTime: int.parse(parts[2].trim()),
            priority: parts[3].trim(),
          );
          processes.add(process);
        } catch (e) {
          // skip invalid lines
          continue;
        }
      }
    }

    return processes;
  }
}

