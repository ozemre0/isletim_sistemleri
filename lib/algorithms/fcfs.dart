import '../models/process.dart';

class FCFS {
  static const double contextSwitchTime = 0.001;

  static AlgorithmResult schedule(List<Process> processes) {
    // önce geliş zamanına göre sırala
    final List<Process> sortedProcesses = List.from(processes)
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    
    final List<TimeSlot> timeTable = [];
    final List<Process> completedProcesses = [];
    int currentTime = 0;
    int contextSwitches = 0;

    for (final process in sortedProcesses) {
      // eğer process henüz gelmediyse bekle
      if (currentTime < process.arrivalTime) {
        // yeni idle slotu ekle veya mevcut olanı uzat
        if (timeTable.isEmpty || timeTable.last.processId != 'IDLE') {
          timeTable.add(TimeSlot(
            startTime: currentTime,
            endTime: process.arrivalTime,
            processId: 'IDLE',
          ));
        } else {
          final lastSlot = timeTable.removeLast();
          timeTable.add(TimeSlot(
            startTime: lastSlot.startTime,
            endTime: process.arrivalTime,
            processId: 'IDLE',
          ));
        }
        currentTime = process.arrivalTime;
      }

      // process değiştiyse context switch say
      if (timeTable.isNotEmpty && timeTable.last.processId != 'IDLE') {
        contextSwitches++;
      }

      // process'i çalıştır
      process.startTime = currentTime;
      timeTable.add(TimeSlot(
        startTime: currentTime,
        endTime: currentTime + process.cpuBurstTime,
        processId: process.id,
      ));
      
      currentTime += process.cpuBurstTime;
      process.finishTime = currentTime;
      process.turnaroundTime = process.finishTime - process.arrivalTime;
      process.waitingTime = process.turnaroundTime - process.cpuBurstTime;
      
      completedProcesses.add(process);
    }

    // istatistikleri hesapla
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

    // belirli zamanlarda kaç process bitti
    final Map<int, int> throughput = {};
    for (final t in [50, 100, 150, 200]) {
      throughput[t] = completedProcesses
          .where((p) => p.finishTime <= t)
          .length;
    }

    // cpu verimliliği hesapla
    final totalCpuTime = completedProcesses
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

