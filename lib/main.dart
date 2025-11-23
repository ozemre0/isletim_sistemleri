import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:google_fonts/google_fonts.dart';
import 'models/process.dart';
import 'utils/csv_reader.dart';
import 'utils/result_writer.dart';
import 'algorithms/fcfs.dart';
import 'algorithms/preemptive_sjf.dart';
import 'algorithms/non_preemptive_sjf.dart';
import 'algorithms/round_robin.dart';
import 'algorithms/preemptive_priority.dart';
import 'algorithms/non_preemptive_priority.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPU Scheduling Algorithms',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C5CE7)),
        useMaterial3: true,
        textTheme: GoogleFonts.fredokaTextTheme(),
      ),
      home: const SchedulingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SchedulingPage extends StatefulWidget {
  const SchedulingPage({super.key});

  @override
  State<SchedulingPage> createState() => _SchedulingPageState();
}

class _SchedulingPageState extends State<SchedulingPage> {
  String? selectedCase;
  bool isRunning = false;
  final Map<String, AlgorithmResult?> results = {};
  final Map<String, bool> algorithmStatus = {};
  final List<String> algorithms = [
    'FCFS', 'Preemptive SJF', 'Non-Preemptive SJF',
    'Round Robin', 'Preemptive Priority', 'Non-Preemptive Priority',
  ];

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFFF093FB)],
  );

  static const _algorithmRunners = {
    'FCFS': _runFCFS,
    'Preemptive SJF': _runPreemptiveSJF,
    'Non-Preemptive SJF': _runNonPreemptiveSJF,
    'Round Robin': _runRoundRobin,
    'Preemptive Priority': _runPreemptivePriority,
    'Non-Preemptive Priority': _runNonPreemptivePriority,
  };

  @override
  void initState() {
    super.initState();
    for (final algo in algorithms) {
      algorithmStatus[algo] = false;
    }
  }

  Future<void> runAlgorithms() async {
    if (selectedCase == null) {
      _showSnackBar('Lütfen bir case seçin', Colors.orange);
      return;
    }

    if (mounted) {
      setState(() {
        isRunning = true;
        results.clear();
        for (final algo in algorithms) {
          algorithmStatus[algo] = false;
          results[algo] = null;
        }
      });
    }

    try {
      final csvPath = selectedCase == 'Case 1' ? 'odev1_case1.txt' : 'odev1_case2.txt';
      final processes = await CsvReader.readProcessesFromAsset(csvPath);
      final caseName = selectedCase == 'Case 1' ? 'case1' : 'case2';

      int delay = 100;
      int completedCount = 0;
      final totalAlgorithms = _algorithmRunners.length;

      for (final entry in _algorithmRunners.entries) {
        Future.delayed(
          Duration(milliseconds: delay),
          () => compute(entry.value, processes),
        ).then((result) {
          completedCount++;
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  results[entry.key] = result;
                  algorithmStatus[entry.key] = true;
                });
              }
            });
          }
          if (!kIsWeb && mounted) {
            ResultWriter.writeResultToFile(entry.key, caseName, result, processes)
                .catchError((_) {});
          }
          if (completedCount == totalAlgorithms && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showSnackBar('Tüm algoritmalar tamamlandı', Colors.green);
                setState(() => isRunning = false);
              }
            });
          }
        }).catchError((e) {
          completedCount++;
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => algorithmStatus[entry.key] = true);
                _showSnackBar('${entry.key} hatası: $e', Colors.red);
              }
            });
          }
          if (completedCount == totalAlgorithms && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => isRunning = false);
            });
          }
        });
        delay += 100;
      }

    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSnackBar('Hata: $e', Colors.red);
            setState(() => isRunning = false);
          }
        });
      }
    }
  }

  Future<void> downloadResults() async {
    if (selectedCase == null || results.isEmpty) {
      _showSnackBar('Önce algoritmaları çalıştırın', Colors.orange);
      return;
    }

    if (kIsWeb) {
      final caseName = selectedCase == 'Case 1' ? 'case1' : 'case2';
      for (final entry in results.entries) {
        if (entry.value != null) {
          final content = _generateResultFile(entry.key, entry.value!);
          _downloadFile('${caseName}_${entry.key.toLowerCase().replaceAll(' ', '_')}.txt', content);
        }
      }
    }
  }

  String _generateResultFile(String algorithmName, AlgorithmResult result) {
    final buffer = StringBuffer();
    buffer.writeln('=== ZAMAN TABLOSU ===');
    for (final slot in result.timeTable) {
      buffer.writeln('[${slot.startTime.toString().padLeft(3)}] - - ${slot.processId} - - [${slot.endTime.toString().padLeft(3)}]');
    }
    buffer.writeln('\n=== BEKLEME SÜRELERİ ===');
    buffer.writeln('Maksimum: ${result.maxWaitingTime.toStringAsFixed(2)}');
    buffer.writeln('Ortalama: ${result.avgWaitingTime.toStringAsFixed(2)}');
    buffer.writeln('\n=== TAMAMLANMA SÜRELERİ ===');
    buffer.writeln('Maksimum: ${result.maxTurnaroundTime.toStringAsFixed(2)}');
    buffer.writeln('Ortalama: ${result.avgTurnaroundTime.toStringAsFixed(2)}');
    buffer.writeln('\n=== THROUGHPUT ===');
    for (final e in result.throughput.entries) {
      buffer.writeln('T=${e.key}: ${e.value} iş tamamlandı');
    }
    buffer.writeln('\n=== CPU VERİMLİLİĞİ ===');
    buffer.writeln('Ortalama: ${(result.avgCpuEfficiency * 100).toStringAsFixed(2)}%');
    buffer.writeln('\n=== BAĞLAM DEĞİŞTİRME ===');
    buffer.writeln('Toplam: ${result.totalContextSwitches}');
    return buffer.toString();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _downloadFile(String fileName, String content) {
    if (kIsWeb) {
      final blob = html.Blob([content], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute('download', fileName)..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: _gradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildCaseSelector(),
                const SizedBox(height: 20),
                _buildButton(
                  onPressed: isRunning ? null : runAlgorithms,
                  icon: isRunning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : const Icon(Icons.play_arrow, size: 28),
                  label: isRunning ? 'Çalışıyor...' : 'Algoritmaları Çalıştır',
                  gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                ),
                if (results.isNotEmpty && !isRunning) ...[
                  const SizedBox(height: 12),
                  _buildButton(
                    onPressed: downloadResults,
                    icon: const Icon(Icons.download, size: 24),
                    label: 'Sonuçları İndir',
                    gradient: const LinearGradient(colors: [Color(0xFF00E676), Color(0xFF00C853)]),
                  ),
                  const SizedBox(height: 20),
                ],
                _buildStatusCard(),
                if (results.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Sonuçlar', style: GoogleFonts.fredoka(fontSize: 28, color: Colors.white, letterSpacing: 1, shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))])),
                  const SizedBox(height: 16),
                  ...results.entries.where((e) => e.value != null).map((e) => _buildResultCard(e.key, e.value!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return _buildCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
            ),
            child: const Icon(Icons.memory, size: 48, color: Color(0xFF667EEA)),
          ),
          const SizedBox(height: 16),
          Text('CPU Scheduling', style: GoogleFonts.fredoka(fontSize: 32, color: Colors.white, letterSpacing: 1.5, shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))])),
          Text('Algorithms', style: GoogleFonts.fredoka(fontSize: 24, color: Colors.white70, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildCaseSelector() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.folder_open, 'Case Seçimi'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: DropdownButton<String>(
              value: selectedCase,
              isExpanded: true,
              hint: const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Bir case seçin', style: TextStyle(color: Colors.grey))),
              items: const [
                DropdownMenuItem(value: 'Case 1', child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Case 1', style: TextStyle(fontSize: 16)))),
                DropdownMenuItem(value: 'Case 2', child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Case 2', style: TextStyle(fontSize: 16)))),
              ],
              onChanged: isRunning ? null : (value) => setState(() {
                selectedCase = value;
                results.clear();
              }),
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.speed, 'Algoritma Durumu'),
          const SizedBox(height: 16),
          ...algorithms.map((algo) => _buildStatusItem(algo)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(title, style: GoogleFonts.fredoka(fontSize: 22, color: Colors.white, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatusItem(String algo) {
    final isCompleted = algorithmStatus[algo] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompleted ? Colors.green.withOpacity(0.5) : Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withOpacity(0.2) : isRunning ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                : isRunning
                    ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.orange)))
                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(algo, style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: child,
    );
  }

  Widget _buildButton({required VoidCallback? onPressed, required Widget icon, required String label, required Gradient gradient}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            decoration: BoxDecoration(
              gradient: onPressed == null ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]) : gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(label, style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white, letterSpacing: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String algorithmName, AlgorithmResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.analytics, color: Colors.white, size: 24),
          ),
          title: Text(algorithmName, style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Ortalama Bekleme: ${result.avgWaitingTime.toStringAsFixed(2)} | Ortalama Tamamlanma: ${result.avgTurnaroundTime.toStringAsFixed(2)}',
              style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w400),
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricRow('Maksimum Bekleme Süresi', result.maxWaitingTime.toStringAsFixed(2)),
                _buildMetricRow('Ortalama Bekleme Süresi', result.avgWaitingTime.toStringAsFixed(2)),
                _buildMetricRow('Maksimum Tamamlanma Süresi', result.maxTurnaroundTime.toStringAsFixed(2)),
                _buildMetricRow('Ortalama Tamamlanma Süresi', result.avgTurnaroundTime.toStringAsFixed(2)),
                _buildMetricRow('Toplam Bağlam Değiştirme', result.totalContextSwitches.toString()),
                _buildMetricRow('Ortalama CPU Verimliliği', '${(result.avgCpuEfficiency * 100).toStringAsFixed(2)}%'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Throughput:', style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 8),
                      ...result.throughput.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4),
                            child: Text('T=${e.key}: ${e.value} iş tamamlandı', style: GoogleFonts.fredoka(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400)),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  onPressed: () => _showTimeTable(algorithmName, result),
                  icon: const Icon(Icons.table_chart, size: 20),
                  label: 'Zaman Tablosunu Göster',
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.fredoka(fontSize: 15, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w400)),
          Text(value, style: GoogleFonts.fredoka(fontSize: 16, color: Colors.white)),
        ],
      ),
    );
  }

  void _showTimeTable(String algorithmName, AlgorithmResult result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          constraints: BoxConstraints(maxWidth: 1200, maxHeight: MediaQuery.of(context).size.height * 0.9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Text('$algorithmName - Zaman Tablosu', style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: result.timeTable.map((slot) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          decoration: BoxDecoration(
                            color: slot.processId == 'IDLE' ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: Text(
                            '[${slot.startTime.toString().padLeft(3)}] - - ${slot.processId} - - [${slot.endTime.toString().padLeft(3)}]',
                            style: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w400, color: slot.processId == 'IDLE' ? Colors.white.withOpacity(0.7) : Colors.white).copyWith(fontFamily: 'monospace'),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  label: 'Kapat',
                  gradient: const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AlgorithmResult _runFCFS(List<Process> processes) => FCFS.schedule(processes);
AlgorithmResult _runPreemptiveSJF(List<Process> processes) => PreemptiveSJF.schedule(processes);
AlgorithmResult _runNonPreemptiveSJF(List<Process> processes) => NonPreemptiveSJF.schedule(processes);
AlgorithmResult _runRoundRobin(List<Process> processes) => RoundRobin.schedule(processes);
AlgorithmResult _runPreemptivePriority(List<Process> processes) => PreemptivePriority.schedule(processes);
AlgorithmResult _runNonPreemptivePriority(List<Process> processes) => NonPreemptivePriority.schedule(processes);
