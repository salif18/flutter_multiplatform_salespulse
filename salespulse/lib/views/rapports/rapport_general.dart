// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:salespulse/utils/format_prix.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RapportGeneralScreen extends StatefulWidget {
  const RapportGeneralScreen({super.key});

  @override
  State<RapportGeneralScreen> createState() => _RapportGeneralScreenState();
}

class _RapportGeneralScreenState extends State<RapportGeneralScreen> {
  final ServicesStats api = ServicesStats();
  final FormatPrice _formatPrice = FormatPrice();

  // Données statistiques
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

  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _generateMonthFilters();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await Future.wait([_fetchStats(), _fetchStatsCharts()]);
    setState(() => isLoading = false);
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
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await api.getStatsGenerales(selectedMonth, token);

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
          totalPiecesEnStock = data["totalPiecesEnStock"] ?? 0;
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
        });
      }
    } on DioException catch (e) {
      _handleApiError(e);
    } on TimeoutException {
      _showError("Le serveur ne répond pas. Veuillez réessayer plus tard.");
    } catch (e) {
      _showError("Erreur: ${e.toString()}");
    }
  }

  Future<void> _fetchStatsCharts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final resJour = await api.getVentesDuJour(token);
      final resAnnee = await api.getVentesAnnee(token);
      final resHebdo = await api.getVentesHebdomadaires(token);

      if (resJour.statusCode == 200 && resAnnee.statusCode == 200 && resHebdo.statusCode == 200) {
        final mergedJour = _mergeChartData(resJour.data, 'totalParHeure', 'quantiteParHeure');
        final mergedAnnee = _mergeChartData(resAnnee.data, 'totalParMois', 'quantiteParMois');
        
        if (!mounted) return;
        setState(() {
          ventesDuJour = mergedJour;
          ventesAnnee = mergedAnnee;
          ventesHebdo = List<Map<String, dynamic>>.from(resHebdo.data);
        });
      }
    } on DioException catch (e) {
      _handleApiError(e);
    } on TimeoutException {
      _showError("Le serveur ne répond pas. Veuillez réessayer plus tard.");
    } catch (e) {
      _showError("Erreur: ${e.toString()}");
    }
  }

  List<Map<String, dynamic>> _mergeChartData(dynamic rawData, String totalKey, String quantityKey) {
    if (rawData is! List || rawData.isEmpty) return [];
    
    final firstItem = rawData[0];
    final List totalData = firstItem[totalKey] ?? [];
    final List quantityData = firstItem[quantityKey] ?? [];

    final Map<int, int> quantityMap = {
      for (var q in quantityData)
        (q['_id'] ?? 0) as int: (q['quantite'] ?? 0) as int
    };

    return totalData.map<Map<String, dynamic>>((item) {
      final id = (item['_id'] ?? 0) as int;
      return {
        '_id': id,
        'total': item['total'] ?? 0,
        'quantite': quantityMap[id] ?? 0,
      };
    }).toList();
  }

  void _handleApiError(DioException e) {
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
      
    } else {
      _showError("Problème de connexion : Vérifiez votre Internet.");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.poppins(fontSize: 14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
      automaticallyImplyLeading: false,
            title: Text("Vue d'ensemble",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
            backgroundColor: Colors.blueGrey,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => isRefreshing = true);
              _loadData().then((_) => setState(() => isRefreshing = false));
            },
          ),
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 780;
                  final isTablet = constraints.maxWidth < 1024;
                  
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filtre par mois
                        _buildMonthFilter(),
                        const SizedBox(height: 20),

                        // Section résumé
                        _buildSummarySection(isMobile, isTablet),
                        const SizedBox(height: 20),

                        // Graphiques
                        _buildChartsSection(isMobile, isTablet),
                        const SizedBox(height: 20),

                        // Statistiques détaillées
                        _buildDetailedStatsSection(isMobile, isTablet),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildMonthFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))
        ],
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
        decoration: InputDecoration(
          labelText: "Période",
          labelStyle: GoogleFonts.poppins(),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        style: GoogleFonts.poppins(fontSize: 14,color: Colors.black),
      ),
    );
  }

  Widget _buildSummarySection(bool isMobile, bool isTablet) {
  final screenWidth = MediaQuery.of(context).size.width;

  final cards = [
    _StatCard("Ventes Total", _formatPrice.formatNombre(totalVentes.toString()),
        Icons.shopping_cart, const Color(0xFF3B82F6)),
    _StatCard("Encaissements", _formatPrice.formatNombre(montantEncaisse.toString()),
        Icons.payments, const Color(0xFF10B981)),
    _StatCard("Bénéfice", _formatPrice.formatNombre(benefice.toString()),
        Icons.trending_up, const Color(0xFFF59E0B)),
    _StatCard("Dépenses", _formatPrice.formatNombre(totalDepenses.toString()),
        Icons.money_off, const Color(0xFFEF4444)),
  ];

  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: isMobile
        ? 2
        : isTablet
            ? 3
            : 4,
    childAspectRatio: isMobile
        ? screenWidth < 750
            ? 1
            : 1.2
        : 1.5,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    children: cards.map((card) => _buildSummaryCard(card)).toList(),
  );
}


  Widget _buildSummaryCard(_StatCard card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: card.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(card.icon, color: card.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(card.title,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(card.value,
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(bool isMobile, bool isTablet) {
    return Column(
      children: [
       // Graphique des ventes hebdomadaires
_buildChartCard(
  title: "Ventes Hebdomadaires",
  child: SizedBox(
    height: 250,
    child: SfCartesianChart(
      primaryXAxis: const CategoryAxis(
        title: AxisTitle(text: 'Semaine'),
      ),
      primaryYAxis: const NumericAxis(
        title: AxisTitle(text: 'Montant (€)'),
      ),
      series: <CartesianSeries<Map<String, dynamic>, String>>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: ventesHebdo,
          xValueMapper: (Map<String, dynamic> data, _) => data['_id']?.toString() ?? 'Sem. ${data['_id']}',
          yValueMapper: (Map<String, dynamic> data, _) => data['total']?.toDouble() ?? 0,
          name: 'Ventes',
          color: const Color(0xFF3B82F6),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    ),
  ),
),
const SizedBox(height: 16),

// Graphique des ventes par heure
_buildChartCard(
  title: "Ventes par Heure",
  child: SizedBox(
    height: 250,
    child: SfCartesianChart(
      primaryXAxis: const CategoryAxis(
        title: AxisTitle(text: 'Heure'),
      ),
      primaryYAxis: const NumericAxis(
        title: AxisTitle(text: 'Montant (€)'),
      ),
      series: <CartesianSeries<Map<String, dynamic>, String>>[
        LineSeries<Map<String, dynamic>, String>(
          dataSource: ventesDuJour,
          xValueMapper: (Map<String, dynamic> data, _) => "${data['_id']}h",
          yValueMapper: (Map<String, dynamic> data, _) => data['total']?.toDouble() ?? 0,
          name: 'Ventes',
          color: const Color(0xFF10B981),
          markerSettings: const MarkerSettings(isVisible: true),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    ),
  ),
),
      ],
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsSection(bool isMobile, bool isTablet) {
    final statsItems = [
      _StatItem("Clients", "$nombreClients", Icons.people, Colors.blue),
      _StatItem("Transactions", "$nombreVentes", Icons.receipt, Colors.indigo),
      _StatItem("Crédit", _formatPrice.formatNombre(resteTotal.toString()), 
          Icons.credit_card, Colors.orange),
      _StatItem("Remboursé", _formatPrice.formatNombre(montantRembourse.toString()), 
          FontAwesomeIcons.reply, Colors.blue),
      _StatItem("Remises", _formatPrice.formatNombre(totalRemises.toString()), 
          Icons.discount, Colors.purple),
      _StatItem("TVA", _formatPrice.formatNombre(totalTVACollectee.toString()), 
          Icons.receipt, Colors.deepPurple),
      _StatItem("Pertes (qté)", "$quantitePertes", Icons.warning, Colors.yellow),
      _StatItem("Pertes (€)", _formatPrice.formatNombre(coutAchatPertes.toString()), 
          Icons.trending_down, Colors.red),
      _StatItem("Caisse", _formatPrice.formatNombre(etatCaisse.toString()), 
          Icons.account_balance, Colors.pink),
      _StatItem("Marge promo", "${margeMoyennePromo.toStringAsFixed(2)}%", 
          Icons.show_chart, Colors.green),
      _StatItem("Promos actives", nbPromoActifs.toString(), 
          Icons.local_offer, Colors.orange),
      _StatItem("Stock (variétés)", "$produitsEnStock", 
          Icons.inventory, Colors.teal),
      _StatItem("Stock (total)", "$totalPiecesEnStock", 
          Icons.inventory_2, Colors.blue),
      _StatItem("Ruptures", "$produitsRupture", 
          Icons.warning_amber, Colors.red),
      _StatItem("Coût achat", _formatPrice.formatNombre(coutAchatTotal.toString()), 
          Icons.trending_up, Colors.purple),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
      childAspectRatio: isMobile ? 1.8 : 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: statsItems.map((item) => _buildStatItemCard(item)).toList(),
    );
  }

  Widget _buildStatItemCard(_StatItem item) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 200;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: isSmall ? 16 : 20, color: item.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isSmall ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.value,
              style: GoogleFonts.poppins(
                fontSize: isSmall ? 14 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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

class _StatCard {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCard(this.title, this.value, this.icon, this.color);
}