import '../models/process.dart';

class RoundRobin {
  static const double contextSwitchTime = 0.001;
  static const int quantum = 2; // zaman dilimi

  static AlgorithmResult schedule(List<Process> processes) {
    final List<Process> processCopies = processes.map((p) => p.copy()).toList();
    final List<TimeSlot> timeTable = [];
    final List<Process> completedProcesses = [];
    final List<Process> readyQueue = [];
    int currentTime = 0;
    int contextSwitches = 0;

    while (processCopies.any((p) => p.remainingTime > 0) || readyQueue.isNotEmpty) {
      // yeni gelen processleri kuyruğa ekle
      for (final process in processCopies) {
        if (process.arrivalTime <= currentTime && 
            process.remainingTime > 0 && 
            !readyQueue.contains(process)) {
          readyQueue.add(process);
        }
      }

      // kuyruk boşsa bekliyoruzz
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

      // kuyruktan ilk process'i al
      final selectedProcess = readyQueue.removeAt(0);

      // context switch var mı bak
      if (timeTable.isNotEmpty && 
          timeTable.last.processId != 'IDLE' && 
          timeTable.last.processId != selectedProcess.id) {
        contextSwitches++;
      }

      if (selectedProcess.startTime == -1) {
        selectedProcess.startTime = currentTime;
      }

       //kalan süre kadar çalıştır
      final executionTime = selectedProcess.remainingTime < quantum 
          ? selectedProcess.remainingTime 
          : quantum;
      
      final previousTime = currentTime;
      currentTime += executionTime;
      selectedProcess.remainingTime -= executionTime;

      // zaman tablosunu güncelle
      if (timeTable.isNotEmpty && 
          timeTable.last.processId == selectedProcess.id &&
          timeTable.last.endTime == previousTime) {
        final lastSlot = timeTable.removeLast();
        timeTable.add(TimeSlot(
          startTime: lastSlot.startTime,
          endTime: currentTime,
          processId: selectedProcess.id,
        ));
      } else {
        timeTable.add(TimeSlot(
          startTime: previousTime,
          endTime: currentTime,
          processId: selectedProcess.id,
        ));
      }

      // çalışma sırasında gelen processleri  ekle
      for (final process in processCopies) {
        if (process.arrivalTime > previousTime && 
            process.arrivalTime <= currentTime && 
            process.remainingTime > 0 && 
            !readyQueue.contains(process)) {
          readyQueue.add(process);
        }
      }

      //process bittiyse tamamlananlara ekle, değilse kuyruğa geri koy
      if (selectedProcess.remainingTime == 0) {
        selectedProcess.finishTime = currentTime;
        selectedProcess.turnaroundTime = selectedProcess.finishTime - selectedProcess.arrivalTime;
        selectedProcess.waitingTime = selectedProcess.turnaroundTime - selectedProcess.cpuBurstTime;
        completedProcesses.add(selectedProcess);
      } else {
        readyQueue.add(selectedProcess);
      }
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

