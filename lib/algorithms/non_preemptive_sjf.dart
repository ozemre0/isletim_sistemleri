import '../models/process.dart';

class NonPreemptiveSJF {
  static const double contextSwitchTime = 0.001;

  static AlgorithmResult schedule(List<Process> processes) {
    final List<Process> processCopies = processes.map((p) => p.copy()).toList();
    final List<TimeSlot> timeTable = [];
    final List<Process> completedProcesses = [];
    int currentTime = 0;
    int contextSwitches = 0;
    final List<Process> readyQueue = [];

    while (processCopies.any((p) => p.remainingTime > 0) || readyQueue.isNotEmpty) {
      // yeni gelen processleri kuyruğa ekle
      for (final process in processCopies) {
        if (process.arrivalTime <= currentTime && 
            process.remainingTime > 0 && 
            !readyQueue.contains(process)) {
          readyQueue.add(process);
        }
      }

      // kuyruk boşsa bekle
      if (readyQueue.isEmpty) {
        final nextArrival = processCopies
            .where((p) => p.remainingTime > 0)
            .map((p) => p.arrivalTime)
            .reduce((a, b) => a < b ? a : b);
        
        if (timeTable.isEmpty || timeTable.last.processId != 'IDLE') {
          timeTable.add(TimeSlot(
            startTime: currentTime,
            endTime: nextArrival,
            processId: 'IDLE',
          ));
        } else {
          final lastSlot = timeTable.removeLast();
          timeTable.add(TimeSlot(
            startTime: lastSlot.startTime,
            endTime: nextArrival,
            processId: 'IDLE',
          ));
        }
        currentTime = nextArrival;
        continue;
      }

      // en kısa burst time'a göre sırala
      readyQueue.sort((a, b) {
        final timeCompare = a.cpuBurstTime.compareTo(b.cpuBurstTime);
        if (timeCompare != 0) return timeCompare;
        return a.arrivalTime.compareTo(b.arrivalTime);
      });

      final selectedProcess = readyQueue.removeAt(0);

      // context switch kontrolü
      if (timeTable.isNotEmpty && 
          timeTable.last.processId != 'IDLE' && 
          timeTable.last.processId != selectedProcess.id) {
        contextSwitches++;
      }

      // process'i sonuna kadar çalıştır (non-preemptive)
      selectedProcess.startTime = currentTime;
      timeTable.add(TimeSlot(
        startTime: currentTime,
        endTime: currentTime + selectedProcess.cpuBurstTime,
        processId: selectedProcess.id,
      ));
      
      currentTime += selectedProcess.cpuBurstTime;
      selectedProcess.remainingTime = 0;
      selectedProcess.finishTime = currentTime;
      selectedProcess.turnaroundTime = selectedProcess.finishTime - selectedProcess.arrivalTime;
      selectedProcess.waitingTime = selectedProcess.turnaroundTime - selectedProcess.cpuBurstTime;
      completedProcesses.add(selectedProcess);
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

    final totalCpuTime = processes
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

