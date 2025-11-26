import '../models/process.dart';
import '../utils/statistics_calculator.dart';

class NonPreemptivePriority {
  static const double contextSwitchTime = 0.001;

  static AlgorithmResult schedule(List<Process> processes) {
    final List<Process> processCopies = processes.map((p) => p.copy()).toList();
    final List<TimeSlot> timeTable = [];
    final List<Process> completedProcesses = [];
    int currentTime = 0;
    int contextSwitches = 0;
    final List<Process> readyQueue = [];
    final Set<Process> inQueue = {};

    while (processCopies.any((p) => p.remainingTime > 0) || readyQueue.isNotEmpty) {
      for (final process in processCopies) {
        if (process.arrivalTime <= currentTime && 
            process.remainingTime > 0 && 
            !inQueue.contains(process)) {
          readyQueue.add(process);
          inQueue.add(process);
        }
      }

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

      readyQueue.sort((a, b) {
        final priorityCompare = a.getPriorityValue().compareTo(b.getPriorityValue());
        if (priorityCompare != 0) return priorityCompare;
        return a.arrivalTime.compareTo(b.arrivalTime);
      });

      final selectedProcess = readyQueue.removeAt(0);
      inQueue.remove(selectedProcess);

      if (timeTable.isNotEmpty && 
          timeTable.last.processId != 'IDLE' && 
          timeTable.last.processId != selectedProcess.id) {
        contextSwitches++;
      }

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

    return StatisticsCalculator.calculateResult(
      timeTable: timeTable,
      completedProcesses: completedProcesses,
      originalProcesses: processes,
      currentTime: currentTime,
      contextSwitches: contextSwitches,
      contextSwitchTime: contextSwitchTime,
    );
  }
}

