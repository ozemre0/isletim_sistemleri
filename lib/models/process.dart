class Process {
  final String id;
  final int arrivalTime;
  final int cpuBurstTime;
  final String priority;
  int remainingTime;
  int startTime;
  int finishTime;
  int waitingTime;
  int turnaroundTime;

  Process({
    required this.id,
    required this.arrivalTime,
    required this.cpuBurstTime,
    required this.priority,
  })  : remainingTime = cpuBurstTime,
        startTime = -1,
        finishTime = -1,
        waitingTime = 0,
        turnaroundTime = 0;

  int getPriorityValue() {
    switch (priority.toLowerCase()) {
      case 'high':
        return 1;
      case 'normal':
        return 2;
      case 'low':
        return 3;
      default:
        return 2;
    }
  }

  Process copy() {
    return Process(
      id: id,
      arrivalTime: arrivalTime,
      cpuBurstTime: cpuBurstTime,
      priority: priority,
    );
  }
}

class TimeSlot {
  final int startTime;
  final int endTime;
  final String processId;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.processId,
  });
}

class AlgorithmResult {
  final List<TimeSlot> timeTable;
  final double maxWaitingTime;
  final double avgWaitingTime;
  final double maxTurnaroundTime;
  final double avgTurnaroundTime;
  final Map<int, int> throughput; 
  final double avgCpuEfficiency;
  final int totalContextSwitches;

  AlgorithmResult({
    required this.timeTable,
    required this.maxWaitingTime,
    required this.avgWaitingTime,
    required this.maxTurnaroundTime,
    required this.avgTurnaroundTime,
    required this.throughput,
    required this.avgCpuEfficiency,
    required this.totalContextSwitches,
  });
}

