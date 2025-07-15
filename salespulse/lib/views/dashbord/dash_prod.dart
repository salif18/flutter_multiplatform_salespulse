// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:salespulse/utils/format_prix.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  final ServicesStats api = ServicesStats();
  final FormatPrice _formatPrice = FormatPrice();
bool loading = true;

  int totalVentes = 0;
  int montantEncaisse = 0;
  int resteTotal = 0;
  int montantRembourse = 0;
  int nombreVentes = 0;
  int nombreClients = 0;
  int produitsEnStock = 0;
  int totalPiecesEnStock = 0;
  int produitsRupture = 0;
  int totalDepenses = 0;
  int etatCaisse = 0;
  int coutAchatTotal = 0;
  int coutAchatPertes = 0;
  int quantitePertes = 0;
  int benefice = 0;
  int totalRemises = 0;
  int totalTVACollectee = 0;
  double margeMoyennePromo = 0;
  int nbPromoActifs = 0;
  Map<String, dynamic> impactPromoVentes = {};

  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<Map<String, dynamic>> moisFiltres = [];
  List<Map<String, dynamic>> ventesDuJour = [];
  List<Map<String, dynamic>> ventesAnnee = [];
  Map<String, dynamic> statsParMois = {};
  List<Map<String, dynamic>> ventesHebdo = [];

  @override
  void initState() {
    super.initState();
    _generateMonthFilters();
    _fetchStats();
    _fetchStatsCharts();
  }

  void _generateMonthFilters() {
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      moisFiltres.add({
        "label": DateFormat("MMMM yyyy", "fr_FR").format(date),
        "value": DateFormat("yyyy-MM").format(date),
      });
    }
  }

  Future<void> _fetchStats() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    final res = await api.getStatsGenerales(selectedMonth, token);
    try {
      if (res.statusCode == 200) {
        final data = res.data;
        if (!mounted) return;
        setState(() {
          totalVentes = data['totalVentesBrutes'] ?? 0;
          montantEncaisse = data['montantEncaisse'] ?? 0;
          resteTotal = data['resteTotal'] ?? 0;
          montantRembourse = data["montantRembourse"] ?? 0;
          nombreVentes = data['nombreVentes'] ?? 0;
          nombreClients = data['nombreClients'] ?? 0;
          produitsEnStock = data['produitsEnStock'] ?? 0;
          totalPiecesEnStock = data["totalPiecesEnStock"] ?? "";
          produitsRupture = data['produitsRupture'] ?? 0;
          totalDepenses = data['totalDepenses'] ?? 0;
          coutAchatTotal = data['coutAchatTotal'] ?? 0;
          etatCaisse = data["etatCaisse"] ?? 0;
          benefice = data['benefice'] ?? 0;
          coutAchatPertes = data["coutAchatPertes"] ?? 0;
          quantitePertes = data["quantitePertes"] ?? 0;
          totalRemises = data["totalRemises"] ?? 0;
          totalTVACollectee = data["totalTVACollectee"] ?? 0;
          statsParMois = data['statsParMois'] ?? {};
          margeMoyennePromo = (data['margeMoyennePromo'] ?? 0).toDouble();
          nbPromoActifs = data['nbPromoActifs'] ?? 0;
          impactPromoVentes = data['impactPromoVentes'] ?? {};

          loading = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Abonnement expiré"),
              content: const Text(
                  "Votre abonnement a expiré. Veuillez le renouveler."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AbonnementScreen()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Problème de connexion : Vérifiez votre Internet.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchStatsCharts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final resJour = await api.getVentesDuJour(token);
      final resAnnee = await api.getVentesAnnee(token);
      final resHebdo = await api.getVentesHebdomadaires(token);

      if (resJour.statusCode == 200 &&
          resAnnee.statusCode == 200 &&
          resHebdo.statusCode == 200) {
        final rawJour = resJour.data;
        List<Map<String, dynamic>> mergedJour = [];
        if (rawJour is List && rawJour.isNotEmpty) {
          final firstItem = rawJour[0];
          final List totalParHeure = firstItem['totalParHeure'] ?? [];
          final List quantiteParHeure = firstItem['quantiteParHeure'] ?? [];

          final Map<int, int> quantiteMap = {
            for (var q in quantiteParHeure)
              (q['_id'] ?? 0) as int: (q['quantite'] ?? 0) as int
          };

          mergedJour = totalParHeure.map<Map<String, dynamic>>((item) {
            final heure = (item['_id'] ?? 0) as int;
            return {
              '_id': heure,
              'total': item['total'] ?? 0,
              'quantite': quantiteMap[heure] ?? 0,
            };
          }).toList();
        }

        final rawAnnee = resAnnee.data;
        List<Map<String, dynamic>> mergedAnnee = [];
        if (rawAnnee is List && rawAnnee.isNotEmpty) {
          final firstItem = rawAnnee[0];
          final List totalParMois = firstItem['totalParMois'] ?? [];
          final List quantiteParMois = firstItem['quantiteParMois'] ?? [];

          final Map<int, int> quantiteMapAnnee = {
            for (var q in quantiteParMois)
              (q['_id'] ?? 0) as int: (q['quantite'] ?? 0) as int
          };

          mergedAnnee = totalParMois.map<Map<String, dynamic>>((item) {
            final mois = (item['_id'] ?? 0) as int;
            return {
              '_id': mois,
              'total': item['total'] ?? 0,
              'quantite': quantiteMapAnnee[mois] ?? 0,
            };
          }).toList();
        }
        if (!mounted) return;

        setState(() {
          ventesDuJour = mergedJour;
          ventesAnnee = mergedAnnee;
          ventesHebdo = List<Map<String, dynamic>>.from(resHebdo.data);
          loading = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Abonnement expiré"),
              content: const Text(
                  "Votre abonnement a expiré. Veuillez le renouveler."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AbonnementScreen()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Problème de connexion : Vérifiez votre Internet.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    }
  }

  Widget _buildCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                 overflow: TextOverflow.ellipsis,
                maxLines: 1,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logoutButton();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!authProvider.isAuthenticated && mounted) {
        await _handleLogout(context);
      }
    });

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 1024;
        final isVerySmallScreen = constraints.maxWidth < 600;
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text("Statistiques Générales",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            backgroundColor: Colors.blueGrey,
          ),
          body: loading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.orange, size: 50))
            :
           RefreshIndicator(
            onRefresh: _fetchStats,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Filtre par mois
                  _buildMonthFilter(),
                  const SizedBox(height: 20),

                  // Section principale adaptative
                  if (isSmallScreen) ...[
                    _buildWeeklyChartSectionMobile(),
                    const SizedBox(height: 20),
                    _buildDailyStatsSectionMobile(isVerySmallScreen),
                  ] else ...[
                    _buildTopSectionDesktop(),
                  ],
                  const SizedBox(height: 20),

                  // Grille de statistiques
                  _buildStatsGrid(isSmallScreen, isVerySmallScreen),
                  const SizedBox(height: 20),

                  // Graphique annuel
                  _buildYearlyChartSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthFilter() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)
      ),
      child: DropdownButtonFormField(
        value: selectedMonth,
        items: moisFiltres.map((m) {
          return DropdownMenuItem(
            value: m["value"],
            child: Text(m["label"], style: GoogleFonts.poppins()),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedMonth = value! as String;
            _fetchStats();
          });
        },
        decoration: const InputDecoration(
          labelText: "Filtrer par mois",
          prefixIcon: Icon(Icons.date_range),
        ),
      ),
    );
  }

  Widget _buildTopSectionDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: _buildWeeklyChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard("📦 Total des produits", "$totalPiecesEnStock",
                  Icons.inventory_rounded, Colors.blue),
              const SizedBox(height: 4),
              _buildCard("📦 Variétes en stock", "$produitsEnStock",
                  Icons.inventory, Colors.teal),
              const SizedBox(height: 4),
              _buildCard("⛔ En rupture", "$produitsRupture",
                  Icons.warning, Colors.red),
              const SizedBox(height: 8),
              Text("📅 Ventes du jour",
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: _buildChartJour(ventesDuJour),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChartSectionMobile() {
    return Column(
      children: [
        _buildWeeklyChart(),
        const SizedBox(height: 16),
        _buildInventoryStatsRow(),
      ],
    );
  }

  Widget _buildInventoryStatsRow() {
    return Column(
      children: [
        _buildCard("Produits", "$totalPiecesEnStock",
            Icons.inventory_rounded, Colors.blue),
        const SizedBox(height:2 ),
        _buildCard("Variétés", "$produitsEnStock",
            Icons.inventory, Colors.teal),
        const SizedBox(height:2 ),
        _buildCard("Rupture", "$produitsRupture",
            Icons.warning, Colors.red),
      ],
    );
  }

  Widget _buildDailyStatsSectionMobile(bool isVerySmallScreen) {
    return Column(
      children: [
        Text("📅 Ventes du jour",
            style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          height: isVerySmallScreen ? 120 : 150,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10)),
          child: _buildChartJour(ventesDuJour),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isSmallScreen, bool isVerySmallScreen) {
    final crossAxisCount = isVerySmallScreen ? 1 : (isSmallScreen ? 2 : 3);
    
    final statsItems = [
      _StatItem("👥 Clients", "$nombreClients", Icons.people, Colors.blue),
      _StatItem("📈 Coût d'achat", _formatPrice.formatNombre(coutAchatTotal.toString()), 
          Icons.trending_up, Colors.purple),
      _StatItem("🧾 Ventes", "$nombreVentes", Icons.receipt_long, Colors.indigo),
      _StatItem("💰 Total", _formatPrice.formatNombre(totalVentes.toString()), 
          Icons.attach_money, Colors.green),
      _StatItem("📥 Encaissé", _formatPrice.formatNombre(montantEncaisse.toString()), 
          Icons.payments, Colors.teal),
      _StatItem("🧾 Crédit", _formatPrice.formatNombre(resteTotal.toString()), 
          Icons.pending_actions, Colors.redAccent),
      // _StatItem("👥 Remboursé", _formatPrice.formatNombre(montantRembourse.toString()), 
      //     FontAwesomeIcons.replyAll, Colors.blue),
      // _StatItem("🏦 Remises", _formatPrice.formatNombre(totalRemises.toString()), 
      //     Icons.savings, Colors.orange),
      // _StatItem("🏦 TVA", _formatPrice.formatNombre(totalTVACollectee.toString()), 
      //     Icons.receipt, Colors.deepPurple),
      // _StatItem("📅 Pertes", "$quantitePertes", Icons.warning, Colors.yellow),
      // _StatItem("💳 Pertes €", _formatPrice.formatNombre(coutAchatPertes.toString()), 
      //     Icons.trending_down, Colors.red),
      // _StatItem("💸 Dépenses", _formatPrice.formatNombre(totalDepenses.toString()), 
      //     Icons.money_off, Colors.brown),
      // _StatItem("💼 Bénéfice", _formatPrice.formatNombre(benefice.toString()), 
      //     Icons.account_balance_wallet, Colors.deepPurple),
      // _StatItem("📊 Caisse", _formatPrice.formatNombre(etatCaisse.toString()), 
      //     Icons.account_balance, Colors.pink),
      // _StatItem("Marge promo", _formatPrice.formatNombre(margeMoyennePromo.toString()), 
      //     Icons.show_chart, Colors.green),
      // _StatItem("Promos actives", nbPromoActifs.toString(), 
      //     Icons.local_offer, Colors.orange),
      // _StatItem("Ventes régulières des produits avant promotion", "${impactPromoVentes['avant']?['quantite'] ?? 0}", 
      //     Icons.trending_up, Colors.blue),
      // _StatItem( "Ventes de tous les produits en promotion ", "${impactPromoVentes['apres']?['quantite'] ?? 0}", 
      //     Icons.trending_down, Colors.red),
    ];

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: crossAxisCount,
      childAspectRatio: isVerySmallScreen ? 4 : (isSmallScreen ? 4.8 : 6),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: statsItems.map((item) => _buildCard(
        item.title, 
        item.value, 
        item.icon, 
        item.color
      )).toList(),
    );
  }

  Widget _buildYearlyChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("📆 Ventes de l'année",
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          height: 250,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10)),
          child: _buildLineChartAnnee(ventesAnnee),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final maxValue = ventesHebdo.fold(
        0.0, (max, e) => e['total'] > max ? e['total'].toDouble() : max);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📊 Statistiques hebdomadaires",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 2.63,
            child: Container(
              padding: const EdgeInsets.only(top: 25, bottom: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(207, 65, 71, 124),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: BarChart(
                 swapAnimationDuration: const Duration(milliseconds: 20),
                 swapAnimationCurve: Curves.linear,
                BarChartData(
                  minY: 0,
                  maxY: maxValue * 1.2,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dayData = ventesHebdo[groupIndex];
                        return BarTooltipItem(
                          '${['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][groupIndex]}\n'
                          'Total: ${dayData['total']} Fcfa\n'
                          'Quantité: ${dayData['quantity']}',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final days = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[value.toInt()],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: ventesHebdo.map((data) {
                    return BarChartGroupData(
                      x: data['day'],
                      barRods: [
                        BarChartRodData(
                          toY: data['total'].toDouble(),
                          width: 20,
                          gradient: const LinearGradient(
                            colors: [Colors.amber, Colors.red],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.1, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxValue * 1.2,
                            color: const Color.fromARGB(24, 3, 3, 3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartJour(List<Map<String, dynamic>> data) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.lightBlueAccent,
          borderRadius: BorderRadius.circular(10)),
      child: BarChart(
         swapAnimationDuration: const Duration(milliseconds: 20),
         swapAnimationCurve: Curves.linear,
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final heure = value.toInt();
                  return Padding(
                    padding: const EdgeInsets.only(top: 7.0),
                    child: Text("$heure h",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.white)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final heure = group.x;
                final total = rod.toY;
                final item = data.firstWhere((el) => el['_id'] == heure,
                    orElse: () => {});
                final quantite = item['quantite'] ?? 0;

                return BarTooltipItem(
                  "Heure: $heure h\nTotal: ${total.toStringAsFixed(0)} Fcfa\nQté: $quantite",
                  GoogleFonts.poppins(color: Colors.white),
                );
              },
            ),
          ),
          barGroups: data.map((e) {
            final x = (e['_id'] ?? 0) is int
                ? e['_id']
                : int.tryParse('${e['_id']}') ?? 0;
            final y =
                (e['total'] ?? 0) is num ? (e['total'] as num).toDouble() : 0.0;

            return BarChartGroupData(
              x: x,
              barRods: [
                BarChartRodData(
                  toY: y,
                  gradient: const LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLineChartAnnee(List<Map<String, dynamic>> rawData) {
  final data = List.generate(12, (i) {
    final mois = i + 1;
    final found = rawData.firstWhere((e) => e['_id'] == mois, orElse: () => {});
    return {
      '_id': mois,
      'total': found['total'] ?? 0,
      'quantite': found['quantite'] ?? 0,
    };
  });

  final spots = data.map((e) {
    return FlSpot(e['_id'] * 1.0, (e['total'] as num).toDouble());
  }).toList();

  final currentMonth = DateTime.now().month;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: const Color(0xff001c30),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 29, 28, 28).withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        height: isMobile ? 300 : 400,
        child: LineChart(
            duration: const Duration(milliseconds: 20),
            curve: Curves.easeOut,
          LineChartData(
            minX: 1,
            maxX: 12,
            minY: 0,
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [Colors.redAccent, Colors.orangeAccent],
                ),
                barWidth: isMobile ? 2 : 3,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      Colors.redAccent.withOpacity(.4),
                      Colors.orangeAccent.withOpacity(.4),
                    ],
                  ),
                ),
                dotData: const FlDotData(show: true),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: isMobile ? 30 : 50,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    const moisLabels = [
                      'Jan','Fév','Mar','Avr','Mai','Juin',
                      'Juil','Aoû','Sep','Oct','Nov','Déc'
                    ];
                    final index = value.toInt() - 1;
                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        (index >= 0 && index < 12) ? moisLabels[index] : '',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 10 : 14,
                          fontWeight: value.toInt() == currentMonth
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: value.toInt() == currentMonth
                              ? Colors.orange
                              : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineTouchData: LineTouchData(
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> indicators) {
                return indicators.map((int index) {
                  return const TouchedSpotIndicatorData(
                    FlLine(color: Colors.transparent, strokeWidth: 0),
                    FlDotData(show: true),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final index = touchedSpot.x.toInt() - 1;
                    final moisData = data[index];
                    final mois = DateFormat.MMM('fr_FR').format(DateTime(2025, index + 1));
                    return LineTooltipItem(
                      "$mois\n"
                      "Montant: ${moisData['total']} Fcfa\n"
                      "Qté: ${moisData['quantite']}",
                      TextStyle(
                        fontSize: isMobile ? 10 : 12,
                        color: const Color.fromRGBO(255, 167, 51, 1),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
}

class _StatItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.title, this.value, this.icon, this.color);
}