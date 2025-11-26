import '../models/process.dart';

class StatisticsCalculator {
  static AlgorithmResult calculateResult({
    required List<TimeSlot> timeTable,
    required List<Process> completedProcesses,
    required List<Process> originalProcesses,
    required int currentTime,
    required int contextSwitches,
    required double contextSwitchTime,
  }) {
    if (completedProcesses.isEmpty) {
      return AlgorithmResult(
        timeTable: timeTable,
        maxWaitingTime: 0,
        avgWaitingTime: 0,
        maxTurnaroundTime: 0,
        avgTurnaroundTime: 0,
        throughput: {},
        avgCpuEfficiency: 0,
        totalContextSwitches: contextSwitches,
      );
    }

    final maxWaitingTime = completedProcesses
        .map((p) => p.waitingTime.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final avgWaitingTime = completedProcesses
        .map((p) => p.waitingTime.toDouble())
        .reduce((a, b) => a + b) / completedProcesses.length;
    
    final maxTurnaroundTime = completedProcesses
        .map((p) => p.turnaroundTime.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final avgTurnaroundTime = completedProcesses
        .map((p) => p.turnaroundTime.toDouble())
        .reduce((a, b) => a + b) / completedProcesses.length;

    final Map<int, int> throughput = {};
    for (final t in [50, 100, 150, 200]) {
      throughput[t] = completedProcesses
          .where((p) => p.finishTime <= t)
          .length;
    }

    final totalCpuTime = originalProcesses
        .map((p) => p.cpuBurstTime.toDouble())
        .reduce((a, b) => a + b);
    final totalTime = currentTime.toDouble();
    final totalContextSwitchOverhead = contextSwitches * contextSwitchTime;
    final avgCpuEfficiency = totalCpuTime / (totalTime + totalContextSwitchOverhead);

    return AlgorithmResult(
      timeTable: timeTable,
      maxWaitingTime: maxWaitingTime,
      avgWaitingTime: avgWaitingTime,
      maxTurnaroundTime: maxTurnaroundTime,
      avgTurnaroundTime: avgTurnaroundTime,
      throughput: throughput,
      avgCpuEfficiency: avgCpuEfficiency,
      totalContextSwitches: contextSwitches,
    );
  }
}

