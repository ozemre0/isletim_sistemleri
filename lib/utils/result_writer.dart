import '../models/process.dart';

class ResultWriter {
  static const double contextSwitchTime = 0.001;

  static Future<void> writeResultToFile(
    String algorithmName,
    String caseName,
    AlgorithmResult result,
    List<Process> processes,
  ) async {
    // Web platform doesn't support file writing
    // Use download functionality in main.dart instead
    // This function is kept for API compatibility but does nothing
  }

  static String formatResultAsString(
    String algorithmName,
    AlgorithmResult result,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== $algorithmName ===');
    buffer.writeln('Maksimum Bekleme Süresi: ${result.maxWaitingTime.toStringAsFixed(2)}');
    buffer.writeln('Ortalama Bekleme Süresi: ${result.avgWaitingTime.toStringAsFixed(2)}');
    buffer.writeln('Maksimum Tamamlanma Süresi: ${result.maxTurnaroundTime.toStringAsFixed(2)}');
    buffer.writeln('Ortalama Tamamlanma Süresi: ${result.avgTurnaroundTime.toStringAsFixed(2)}');
    buffer.writeln('Toplam Bağlam Değiştirme: ${result.totalContextSwitches}');
    buffer.writeln('Ortalama CPU Verimliliği: ${(result.avgCpuEfficiency * 100).toStringAsFixed(2)}%');
    
    return buffer.toString();
  }
}

