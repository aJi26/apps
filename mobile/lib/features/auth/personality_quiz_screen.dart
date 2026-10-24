import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/routing/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class PersonalityQuizScreen extends StatefulWidget {
  const PersonalityQuizScreen({super.key});

  @override
  State<PersonalityQuizScreen> createState() => _PersonalityQuizScreenState();
}

class _PersonalityQuizScreenState extends State<PersonalityQuizScreen> {
  // Map menyimpan jawaban: {questionId: 'A' | 'B'}
  final Map<int, String> _answers = {};
  bool _saving = false;
  Map<String, dynamic>? _resultData;

  // 32 Soal Refleksi MBTI (4 Dimensi x 8 Soal)
  final List<Map<String, dynamic>> _questions = const [
    // --- DIMENSI 1: E / I (Energi & Interaksi) ---
    {
      'id': 1,
      'dim': 'EI',
      'q': '01. Setelah aktivitas yang padat, saya biasanya merasa lebih pulih dengan:',
      'optA': 'A. Bertemu atau mengobrol dengan beberapa orang.',
      'optB': 'B. Menghabiskan waktu sendiri atau bersama satu-dua orang dekat.',
    },
    {
      'id': 2,
      'dim': 'EI',
      'q': '02. Saat punya ide baru, saya cenderung:',
      'optA': 'A. Membicarakannya sambil mengembangkan ide.',
      'optB': 'B. Memikirkannya sendiri sampai lebih jelas.',
    },
    {
      'id': 3,
      'dim': 'EI',
      'q': '03. Ketika berada di acara dengan banyak orang:',
      'optA': 'A. Saya cukup mudah memulai percakapan.',
      'optB': 'B. Saya lebih nyaman setelah mengamati suasana terlebih dahulu.',
    },
    {
      'id': 4,
      'dim': 'EI',
      'q': '04. Dalam kerja kelompok, saya lebih produktif ketika:',
      'optA': 'A. Bisa sering berdiskusi secara langsung.',
      'optB': 'B. Punya waktu bekerja sendiri sebelum menyampaikan hasil.',
    },
    {
      'id': 5,
      'dim': 'EI',
      'q': '05. Saat mempelajari hal baru, saya lebih suka:',
      'optA': 'A. Bertanya dan bertukar pikiran dengan orang lain.',
      'optB': 'B. Mencoba atau membaca sendiri lebih dulu.',
    },
    {
      'id': 6,
      'dim': 'EI',
      'q': '06. Lingkungan yang biasanya membantu saya berenergi adalah:',
      'optA': 'A. Ramai, aktif, dan memiliki banyak interaksi.',
      'optB': 'B. Tenang dan tidak terlalu banyak rangsangan.',
    },
    {
      'id': 7,
      'dim': 'EI',
      'q': '07. Ketika bertemu orang baru, saya biasanya:',
      'optA': 'A. Cepat terlibat dalam percakapan.',
      'optB': 'B. Membuka diri secara bertahap setelah merasa nyaman.',
    },
    {
      'id': 8,
      'dim': 'EI',
      'q': '08. Dalam hubungan sosial, saya cenderung memiliki:',
      'optA': 'A. Banyak kenalan dari berbagai lingkungan.',
      'optB': 'B. Beberapa hubungan dekat yang saya rawat secara mendalam.',
    },

    // --- DIMENSI 2: S / N (Memperhatikan Informasi) ---
    {
      'id': 9,
      'dim': 'SN',
      'q': '09. Saat memahami situasi, perhatian awal saya tertuju pada:',
      'optA': 'A. Fakta yang terlihat, detail, dan keadaan saat ini.',
      'optB': 'B. Pola, makna, dan kemungkinan di balik situasi.',
    },
    {
      'id': 10,
      'dim': 'SN',
      'q': '10. Saat menerima instruksi, saya lebih terbantu oleh:',
      'optA': 'A. Langkah konkret dan contoh yang jelas.',
      'optB': 'B. Tujuan umum dan kebebasan menentukan cara.',
    },
    {
      'id': 11,
      'dim': 'SN',
      'q': '11. Ketika menceritakan pengalaman, saya biasanya:',
      'optA': 'A. Menguraikan apa yang terjadi secara berurutan.',
      'optB': 'B. Menekankan makna, hubungan, atau pelajaran dari kejadian.',
    },
    {
      'id': 12,
      'dim': 'SN',
      'q': '12. Saat menghadapi masalah, saya cenderung:',
      'optA': 'A. Menggunakan cara yang sudah terbukti berhasil.',
      'optB': 'B. Menjajaki pendekatan baru yang mungkin lebih baik.',
    },
    {
      'id': 13,
      'dim': 'SN',
      'q': '13. Hal yang paling mudah saya ingat dari suatu peristiwa adalah:',
      'optA': 'A. Rincian spesifik dan fakta yang terjadi.',
      'optB': 'B. Inti kejadian dan kaitannya dengan hal lain.',
    },
    {
      'id': 14,
      'dim': 'SN',
      'q': '14. Ketika memulai proyek baru, saya biasanya:',
      'optA': 'A. Mengumpulkan informasi nyata sebelum melangkah.',
      'optB': 'B. Membayangkan berbagai arah atau kemungkinan terlebih dahulu.',
    },
    {
      'id': 15,
      'dim': 'SN',
      'q': '15. Penjelasan yang paling menarik bagi saya adalah:',
      'optA': 'A. Contoh konkret yang dekat dengan kehidupan nyata.',
      'optB': 'B. Konsep, analogi, atau ide abstrak yang membuka perspektif.',
    },
    {
      'id': 16,
      'dim': 'SN',
      'q': '16. Saya lebih tertarik pada:',
      'optA': 'A. Apa yang realistis dilakukan dengan sumber daya saat ini.',
      'optB': 'B. Apa yang berpotensi dikembangkan pada masa mendatang.',
    },

    // --- DIMENSI 3: T / F (Dasar Pengambilan Keputusan) ---
    {
      'id': 17,
      'dim': 'TF',
      'q': '17. Saat mengambil keputusan sulit, hal yang terutama saya timbang adalah:',
      'optA': 'A. Logika, konsistensi, dan dampak sebab-akibat.',
      'optB': 'B. Nilai yang penting bagi saya dan dampaknya pada orang terkait.',
    },
    {
      'id': 18,
      'dim': 'TF',
      'q': '18. Ketika memberi masukan, saya cenderung:',
      'optA': 'A. Mengutamakan kejelasan dan hal yang perlu diperbaiki.',
      'optB': 'B. Mempertimbangkan cara menyampaikan agar tetap membangun.',
    },
    {
      'id': 19,
      'dim': 'TF',
      'q': '19. Dalam konflik, saya biasanya lebih dulu:',
      'optA': 'A. Memeriksa fakta dan prinsip yang berlaku.',
      'optB': 'B. Memahami sudut pandang serta perasaan pihak-pihak terkait.',
    },
    {
      'id': 20,
      'dim': 'TF',
      'q': '20. Saya lebih mudah menerima keputusan jika:',
      'optA': 'A. Alasannya konsisten dan diterapkan dengan adil.',
      'optB': 'B. Keputusan mempertimbangkan kebutuhan manusia yang terlibat.',
    },
    {
      'id': 21,
      'dim': 'TF',
      'q': '21. Saat teman menceritakan masalah, respons spontan saya adalah:',
      'optA': 'A. Membantu mengurai penyebab dan pilihan solusi.',
      'optB': 'B. Mendengarkan dan menunjukkan bahwa perasaannya dipahami.',
    },
    {
      'id': 22,
      'dim': 'TF',
      'q': '22. Untuk menilai suatu usulan, saya paling mengutamakan:',
      'optA': 'A. Kriteria objektif dan hasil yang dapat dievaluasi.',
      'optB': 'B. Kesesuaian dengan nilai dan kebutuhan orang yang terdampak.',
    },
    {
      'id': 23,
      'dim': 'TF',
      'q': '23. Ketika tidak sepakat dengan seseorang:',
      'optA': 'A. Saya bisa membahas ide secara langsung tanpa menganggapnya sebagai serangan pribadi.',
      'optB': 'B. Saya berhati-hati dengan nada bicara agar hubungan tetap terjaga.',
    },
    {
      'id': 24,
      'dim': 'TF',
      'q': '24. Saat mengevaluasi pekerjaan, saya cenderung:',
      'optA': 'A. Menilai berdasarkan hasil dan standar yang terukur.',
      'optB': 'B. Mempertimbangkan usaha, konteks, serta dampak pada orang lain.',
    },

    // --- DIMENSI 4: J / P (Struktur dan Fleksibilitas) ---
    {
      'id': 25,
      'dim': 'JP',
      'q': '25. Saat merencanakan perjalanan, saya lebih suka:',
      'optA': 'A. Menyusun jadwal dan memesan hal penting lebih awal.',
      'optB': 'B. Menentukan gambaran umum dan memutuskan sebagian hal saat tiba.',
    },
    {
      'id': 26,
      'dim': 'JP',
      'q': '26. Untuk menghadapi tenggat, saya cenderung:',
      'optA': 'A. Mengerjakan secara bertahap agar selesai lebih awal.',
      'optB': 'B. Menjaga fleksibilitas dan sering bekerja intensif mendekati tenggat.',
    },
    {
      'id': 27,
      'dim': 'JP',
      'q': '27. Dalam mengatur tugas sehari-hari, saya biasanya:',
      'optA': 'A. Membuat daftar serta urutan prioritas.',
      'optB': 'B. Memilih tugas sesuai situasi dan energi saat itu.',
    },
    {
      'id': 28,
      'dim': 'JP',
      'q': '28. Jika rencana tiba-tiba berubah:',
      'optA': 'A. Saya ingin segera menyusun rencana pengganti.',
      'optB': 'B. Saya relatif mudah menyesuaikan diri dan membuka pilihan baru.',
    },
    {
      'id': 29,
      'dim': 'JP',
      'q': '29. Ketika mengerjakan beberapa hal, saya lebih suka:',
      'optA': 'A. Menuntaskan satu hal sebelum berpindah ke hal lain.',
      'optB': 'B. Berpindah di antara beberapa tugas sesuai kebutuhan.',
    },
    {
      'id': 30,
      'dim': 'JP',
      'q': '30. Setelah membuat keputusan penting:',
      'optA': 'A. Saya merasa lega ketika keputusan sudah ditetapkan.',
      'optB': 'B. Saya tetap ingin mengeksplorasi pilihan lain jika ada informasi baru.',
    },
    {
      'id': 31,
      'dim': 'JP',
      'q': '31. Bagi saya, lingkungan yang nyaman adalah lingkungan yang:',
      'optA': 'A. Teratur sehingga saya tahu apa yang harus dilakukan.',
      'optB': 'B. Fleksibel sehingga saya bebas menyesuaikan cara.',
    },
    {
      'id': 32,
      'dim': 'JP',
      'q': '32. Dalam mengatur waktu, saya cenderung:',
      'optA': 'A. Menjadwalkan kegiatan terlebih dahulu.',
      'optB': 'B. Menyisakan banyak ruang untuk hal spontan.',
    },
  ];

  Map<String, dynamic> _calculateScores() {
    int countE = 0, countI = 0;
    int countS = 0, countN = 0;
    int countT = 0, countF = 0;
    int countJ = 0, countP = 0;

    for (final q in _questions) {
      final id = q['id'] as int;
      final dim = q['dim'] as String;
      final ans = _answers[id];

      if (dim == 'EI') {
        if (ans == 'A') countE++;
        if (ans == 'B') countI++;
      } else if (dim == 'SN') {
        if (ans == 'A') countS++;
        if (ans == 'B') countN++;
      } else if (dim == 'TF') {
        if (ans == 'A') countT++;
        if (ans == 'B') countF++;
      } else if (dim == 'JP') {
        if (ans == 'A') countJ++;
        if (ans == 'B') countP++;
      }
    }

    final letter1 = countE >= countI ? 'E' : 'I';
    final letter2 = countS >= countN ? 'S' : 'N';
    final letter3 = countT >= countF ? 'T' : 'F';
    final letter4 = countJ >= countP ? 'J' : 'P';
    final mbtiCode = '$letter1$letter2$letter3$letter4';

    return {
      'code': mbtiCode,
      'type': mbtiCode,
      'subtitle': _getMbtiTitle(mbtiCode),
      'scores': {
        'E': ((countE / 8) * 100).round(),
        'I': ((countI / 8) * 100).round(),
        'S': ((countS / 8) * 100).round(),
        'N': ((countN / 8) * 100).round(),
        'T': ((countT / 8) * 100).round(),
        'F': ((countF / 8) * 100).round(),
        'J': ((countJ / 8) * 100).round(),
        'P': ((countP / 8) * 100).round(),
      },
    };
  }

  String _getMbtiTitle(String code) {
    const titles = {
      'INTJ': 'The Architect',
      'INTP': 'The Thinker',
      'ENTJ': 'The Commander',
      'ENTP': 'The Visionary',
      'INFJ': 'The Advocate',
      'INFP': 'The Mediator',
      'ENFJ': 'The Protagonist',
      'ENFP': 'The Campaigner',
      'ISTJ': 'The Inspector',
      'ISFJ': 'The Protector',
      'ESTJ': 'The Executive',
      'ESFJ': 'The Consul',
      'ISTP': 'The Craftsman',
      'ISFP': 'The Artist',
      'ESTP': 'The Dynamo',
      'ESFP': 'The Entertainer',
    };
    return titles[code] ?? 'The Reflector';
  }

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Harap isi semua soal (${_answers.length}/${_questions.length} terisi).',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final calculatedResult = _calculateScores();

      // Simpan ke HP lokal dulu agar Home langsung bisa membaca MBTI
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mbti_code', calculatedResult['code'].toString());
      await prefs.setString('mbti_result', jsonEncode(calculatedResult));

      // Kirim juga ke server backend
      await ApiService.request(
        'POST',
        'quiz/submit',
        body: {
          'code': calculatedResult['code'],
          'result': calculatedResult,
          'answers': _answers.entries
              .map((e) => {'question_id': e.key, 'answer': e.value})
              .toList(),
        },
      );

      if (mounted) {
        setState(() {
          _resultData = calculatedResult;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resultData = _calculateScores();
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finishAndContinue() async {
    final gateResult = await AppRouter.resolve(context);
    if (!mounted) return;
    if (gateResult == GateResult.retry) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cek koneksi internet Anda dan coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _resultData == null ? 'Kuesioner Refleksi MBTI' : 'Hasil Refleksi Diri',
        ),
        elevation: 0,
      ),
      body: _resultData != null
          ? _buildResultView()
          : _buildQuizQuestionsView(),
    );
  }

  Widget _buildQuizQuestionsView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Disclaimer Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡 ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disclaimer Refleksi Diri',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF8C5800),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kuesioner 32 soal ini dirancang untuk refleksi diri mengenali kecenderungan preferensi pribadi, bukan instrumen tes MBTI® resmi maupun diagnosis psikologis.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Pilih A atau B yang paling menggambarkan kebiasaan alami Anda.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),

        for (final item in _questions)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['q'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(item['optA'].toString()),
                    value: 'A',
                    groupValue: _answers[item['id'] as int],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _answers[item['id'] as int] = val);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(item['optB'].toString()),
                    value: 'B',
                    groupValue: _answers[item['id'] as int],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _answers[item['id'] as int] = val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _saving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text('Selesaikan Kuis (${_answers.length}/32)'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildResultView() {
    final code = _resultData?['code']?.toString() ?? 'INFJ';
    final subtitle = _resultData?['subtitle']?.toString() ?? 'The Advocate';
    final scores = (_resultData?['scores'] as Map<String, dynamic>?) ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.sageSoft,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'TIPE PREFERENSI MBTI ANDA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian 4 Dimensi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildDimBar('Extraversion (E)', scores['E'] ?? 0, 'Introversion (I)', scores['I'] ?? 0),
                  _buildDimBar('Sensing (S)', scores['S'] ?? 0, 'Intuition (N)', scores['N'] ?? 0),
                  _buildDimBar('Thinking (T)', scores['T'] ?? 0, 'Feeling (F)', scores['F'] ?? 0),
                  _buildDimBar('Judging (J)', scores['J'] ?? 0, 'Perceiving (P)', scores['P'] ?? 0),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: _finishAndContinue,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Lanjutkan ke Her Space'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDimBar(String leftLabel, dynamic leftVal, String rightLabel, dynamic rightVal) {
    final int left = (leftVal is num) ? leftVal.toInt() : 50;
    final int right = (rightVal is num) ? rightVal.toInt() : (100 - left);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$leftLabel ($left%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('$rightLabel ($right%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: left / 100,
              backgroundColor: AppTheme.sageSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}