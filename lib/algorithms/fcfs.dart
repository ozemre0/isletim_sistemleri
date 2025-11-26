import '../models/process.dart';
import '../utils/statistics_calculator.dart';

class FCFS {
  static const double contextSwitchTime = 0.001;

  static AlgorithmResult schedule(List<Process> processes) {
    final List<Process> sortedProcesses = List.from(processes)
      ..sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    
    final List<TimeSlot> timeTable = [];
    final List<Process> completedProcesses = [];
    int currentTime = 0;
    int contextSwitches = 0;

    for (final process in sortedProcesses) {
      if (currentTime < process.arrivalTime) {
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

      if (timeTable.isNotEmpty && timeTable.last.processId != 'IDLE') {
        contextSwitches++;
      }

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

