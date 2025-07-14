// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/user_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/stats_api.dart';
import 'package:intl/intl.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class UserOperationsPage extends StatefulWidget {
  final UserModel user;
  const UserOperationsPage({super.key, required this.user});

  @override
  State<UserOperationsPage> createState() => _UserOperationsPageState();
}

class _UserOperationsPageState extends State<UserOperationsPage> {
  ServicesStats api = ServicesStats();
  String selectedFilter = 'jour';

  List<Map<String, dynamic>> ventes = [];
  List<Map<String, dynamic>> produitsVendus = [];
  List<Map<String, dynamic>> reglements = [];
  List<Map<String, dynamic>> mouvements = [];
  List<Map<String, dynamic>> depenses = [];

  int totalVentes = 0;
  int totalReglements = 0;
  int totalDepenses = 0;

  @override
  void initState() {
    super.initState();
    fetchUserOperations();
  }

  Future<void> fetchUserOperations() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res =
          await api.getOperationUser(token, selectedFilter, widget.user.id);

      if (res.statusCode == 200) {
        final data = res.data;
        setState(() {
          ventes = List<Map<String, dynamic>>.from(data['ventes']);
          produitsVendus =
              List<Map<String, dynamic>>.from(data['produitsVendus']);
          reglements = List<Map<String, dynamic>>.from(data['reglements']);
          mouvements = List<Map<String, dynamic>>.from(data['mouvements']);
          depenses = List<Map<String, dynamic>>.from(data['depenses']);

          totalVentes = ventes.fold(
              0, (sum, item) => sum + ((item['total'] ?? 0) as int));
          totalReglements = reglements.fold(
              0, (sum, item) => sum + ((item['montant'] ?? 0) as int));
          totalDepenses = depenses.fold(
              0, (sum, item) => sum + ((item['montants'] ?? 0) as int));
        });
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
          // 👉 Afficher message spécifique abonnement expiré
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

      // 🚫 Autres DioException (ex: réseau)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Problème de connexion : Vérifiez votre Internet.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    }
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

    // Vérification initiale de l'authentification
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

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        elevation: 1,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.white,
            )),
        title: Text(
          "Opérations de ${widget.user.name}",
          style: GoogleFonts.poppins(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            onPressed: fetchUserOperations,
            icon: const Icon(Icons.refresh, color: Colors.blue),
          )
        ],
      ),
     body: SafeArea(
  child: LayoutBuilder(
    builder: (context, constraints) {
      return Column(
        children: [
          SingleChildScrollView(
            //padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterBar(isMobile),
                const SizedBox(height: 16),
                _buildStatsCards(isMobile),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Le TabView occupe le reste de l'espace (ou scrolle lui aussi si nécessaire)
          SizedBox(
            height: constraints.maxHeight * 0.55, // ou un autre pourcentage
            child: _buildTabView(),
          ),
        ],
      );
    },
  ),
),

    );
  }

  Widget _buildFilterBar(bool isMobile) {
  final filters = ['jour', 'semaine', 'mois'];

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: isMobile
        ? SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = filters[index];
                final isSelected = selectedFilter == value;
                return ChoiceChip(
                  label: Text(
                    value == 'jour'
                        ? 'Aujourd\'hui'
                        : value == 'semaine'
                            ? 'Cette semaine'
                            : 'Ce mois',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0077B6),
                  backgroundColor: Colors.grey[200],
                  onSelected: (_) {
                    setState(() => selectedFilter = value);
                    fetchUserOperations();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: filters.map((value) {
              final isSelected = selectedFilter == value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(
                    value == 'jour'
                        ? 'Aujourd\'hui'
                        : value == 'semaine'
                            ? 'Cette semaine'
                            : 'Ce mois',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0077B6),
                  backgroundColor: Colors.grey[200],
                  onSelected: (_) {
                    setState(() => selectedFilter = value);
                    fetchUserOperations();
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }).toList(),
          ),
  );
}


  Widget _buildStatsCards(bool isMobile) {
  final cards = [
    _statCard("Ventes", totalVentes, "Fcfa", Icons.shopping_cart, const Color(0xFF00B4D8)),
    _statCard("Règlements", totalReglements, "Fcfa", Icons.payment, const Color(0xFF0077B6)),
    _statCard("Dépenses", totalDepenses, "Fcfa", Icons.money_off, const Color(0xFFE63946)),
    _statCard("Transactions", ventes.length, "", Icons.list_alt, const Color(0xFF2A9D8F)),
  ];

  return isMobile
      ? SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => SizedBox(width: 330, child: cards[index]),
          ),
        )
      : Row(
          children: cards
              .map((card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: card,
                    ),
                  ))
              .toList(),
        );
}


  Widget _statCard(
      String title, int value, String unit, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                Expanded(
                  child: Text(
                    "$value $unit",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView() {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              dividerColor:Colors.transparent, // 👈 empêche le petit trait du bas
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF0077B6),
              ),
              tabs: [
                Tab(child: _buildTabItem("Ventes", Icons.shopping_cart)),
                Tab(child: _buildTabItem("Produits", Icons.inventory)),
                Tab(child: _buildTabItem("Règlements", Icons.payment)),
                Tab(child: _buildTabItem("Mouvements", Icons.compare_arrows)),
                Tab(child: _buildTabItem("Dépenses", Icons.money_off)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBarView(
                children: [
                  _buildOperationList(ventes, "total", "createdAt"),
                  _buildProductList(produitsVendus),
                  _buildOperationList(reglements, "montant", null),
                  _buildMovementList(mouvements),
                  _buildOperationList(depenses, "montants", null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(title, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOperationList(
      List<Map<String, dynamic>> items, String amountKey, String? dateKey) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          "Aucune donnée disponible",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0077B6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForOperation(item),
                size: 20,
                color: const Color(0xFF0077B6),
              ),
            ),
            title: Text(
              _getOperationTitle(item),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: dateKey != null
                ? Text(
                    _formatDate(item[dateKey]),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
            trailing: Text(
              "${item[amountKey]} Fcfa",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: item['type'] == "règlement"
                    ? Colors.green
                    : item['type'] == "remboursement"
                        ? Colors.red
                        : const Color(0xFF0077B6),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          "Aucun produit vendu",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: product["image"] != null
                  ? Image.network(
                      product["image"],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset("assets/images/defaultImg.png"),
                    )
                  : Image.asset("assets/images/defaultImg.png"),
            ),
            title: Text(
              product['nom'] ?? 'Produit inconnu',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              "Quantité: ${product['quantite']} x ${product['prix_unitaire']} Fcfa",
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            trailing: Text(
              "${(product['quantite'] as int) * (product['prix_unitaire'] as int)} Fcfa",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2A9D8F),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMovementList(List<Map<String, dynamic>> movements) {
    if (movements.isEmpty) {
      return Center(
        child: Text(
          "Aucun mouvement enregistré",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final movement = movements[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF4A261).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: movement["productId"]?["image"] != null
                  ? Image.network(
                      movement["productId"]?["image"],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset("assets/images/defaultImg.png"),
                    )
                  : Image.asset("assets/images/defaultImg.png"),
            ),
            title: Text(
              movement['productId']?['nom'] ??
                  'Produit inconnu', // Utilisez plutôt le nom du produit',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              "Quantité: ${movement['quantite']} unités",
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            trailing: Column(
              children: [
                Text(
                  movement['type'] ?? 'Mouvement',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  movement['quantite'].toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF4A261),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForOperation(Map<String, dynamic> item) {
    if (item.containsKey('total')) return Icons.shopping_cart;
    if (item.containsKey('montant')) return Icons.payment;
    if (item.containsKey('montants')) return Icons.money_off;
    return Icons.list_alt;
  }

  String _getOperationTitle(Map<String, dynamic> item) {
    if (item.containsKey('total')) return "Vente à ${item['nom']}";
    if (item.containsKey('montant')) return "Règlement (${item['type']})";
    if (item.containsKey('montants')) return "Dépense: ${item['motifs']}";
    return "Opération";
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat("dd/MM/yyyy HH:mm").format(date);
    } catch (_) {
      return isoDate;
    }
  }
}
