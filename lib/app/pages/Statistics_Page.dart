import 'package:flutter/material.dart';
import 'package:sapient/services/firestore_services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';



class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    print('🧪 UID actuel : ${FirestoreService.getCurrentUserUid()}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.statistics,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Raleway',
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
      ),



      body: FutureBuilder<Map<String, dynamic>>(
        future: _firestoreService.getTodayGlobalSummary(
          FirestoreService.getCurrentUserUid()!,


        ),

        builder: (context, snapshot) {
          print('📦 snapshot.connectionState = ${snapshot.connectionState}');
          print('📦 snapshot.hasData = ${snapshot.hasData}');
          print('📦 snapshot.hasError = ${snapshot.hasError}');
          if (snapshot.hasError) print('❌ snapshot.error = ${snapshot.error}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          print('📊 Données reçues dans snapshot : $data');
          final seen = data['flashcardsSeen'] ?? 0;
          final revisions = data['revisionCount'] ?? 0;
          final successRate = data['successRate'] ?? 0;
          print('👀 flashcardsSeen = $seen');
          print('🔁 revisionCount = $revisions');
          print('✅ successRate = $successRate%');

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Screen statistique.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: local.flashcards_reviewed,
                              leftValue: seen.toString(),
                              leftLabel: local.seen,
                              rightValue: '?',
                              rightLabel: local.never_seen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PieStatCard(
                              title: local.total_revisions,
                              value: revisions.toString(),
                              percentage: successRate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 👇 le reste de tes widgets comme avant
                      _BarStatCard(
                        title: local.success_by_subject,
                        bars: [30, 50, 70, 90],
                        labels: ['Math', 'Hist', 'Angl', 'Bio'],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniCard(
                              title: local.avg_time,
                              value: '20 min',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MiniCard(
                              title: local.time_per_quizz,
                              value: '1 min 12 s',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RevisionRateCard(
                        title: local.revision_rates,
                        subjects: {
                          'Math': 0.8,
                          'Histoire': 0.6,
                          'Anglais': 0.5,
                          'SVT': 0.4,
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

    );
  }
}

// 🔹 Widgets personnalisés
class _StatCard extends StatelessWidget {
  final String title, leftValue, leftLabel, rightValue, rightLabel;
  const _StatCard({
    required this.title,
    required this.leftValue,
    required this.leftLabel,
    required this.rightValue,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) => _baseCard(
    title: title,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(children: [Text(leftValue, style: _numberStyle), Text(leftLabel)]),
        Column(children: [Text(rightValue, style: _numberStyle), Text(rightLabel)]),
      ],
    ),
  );
}

class _PieStatCard extends StatelessWidget {
  final String title, value;
  final int percentage;
  const _PieStatCard({required this.title, required this.value, required this.percentage});

  @override
  Widget build(BuildContext context) => _baseCard(
    title: title,
    child: Row(
      children: [
        Text(value, style: _numberStyle),
        const SizedBox(width: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: percentage / 100,
                color: Colors.green,
                strokeWidth: 6,
              ),
            ),
            Text("$percentage%"),
          ],
        ),
      ],
    ),
  );
}

class _BarStatCard extends StatelessWidget {
  final String title;
  final int? percentage;
  final List<int> bars;
  final List<String> labels;

  const _BarStatCard({required this.title, this.percentage, required this.bars, required this.labels});

  @override
  Widget build(BuildContext context) => _baseCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (percentage != null)
          Text("$percentage%", style: _numberStyle),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(bars.length, (i) => Column(
            children: [
              Container(
                width: 14,
                height: bars[i].toDouble(),
                color: Colors.teal,
              ),
              const SizedBox(height: 4),
              Text(labels[i], style: const TextStyle(fontSize: 10)),
            ],
          )),
        ),
      ],
    ),
  );
}

class _MiniCard extends StatelessWidget {
  final String title, value;
  const _MiniCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => _baseCard(
    title: title,
    child: Text(value, style: _numberStyle, textAlign: TextAlign.center),
  );
}

class _RevisionRateCard extends StatelessWidget {
  final String title;
  final Map<String, double> subjects;
  const _RevisionRateCard({required this.title, required this.subjects});

  @override
  Widget build(BuildContext context) => _baseCard(
    title: title,
    child: Column(
      children: subjects.entries.map((e) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(width: 60, child: Text(e.key)),
            Expanded(
              child: LinearProgressIndicator(
                value: e.value,
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      )).toList(),
    ),
  );
}

Widget _baseCard({required String title, required Widget child}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 3))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

const _numberStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
