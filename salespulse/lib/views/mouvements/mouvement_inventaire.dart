
// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
// import 'package:flutter/material.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'package:salespulse/models/mouvements_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/mouvement_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class HistoriqueMouvementsScreen extends StatefulWidget {
  const HistoriqueMouvementsScreen({super.key});

  @override
  State<HistoriqueMouvementsScreen> createState() =>
      _HistoriqueMouvementsScreenState();
}

class _HistoriqueMouvementsScreenState
    extends State<HistoriqueMouvementsScreen> {
  List<MouvementModel> mouvements = [];
  int currentPage = 1;
  int totalPages = 1;
  int rowsPerPage = 12;

  String selectedType = "Tous";
  DateTime? dateDebut;
  DateTime? dateFin;

  bool isLoading = false;

  final List<String> types = [
    "Tous",
    "vente",
    "ajout",
    "correction",
    "suppression"
  ];

  @override
  void initState() {
    super.initState();
    _fetchMouvements();
  }

  Future<void> _fetchMouvements() async {
    setState(() {
      isLoading = true;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
    try {
      final res = await ServicesMouvements().getMouvements(
        adminId: adminId,
        token: token,
        productId: "",
        type: selectedType != "Tous" ? selectedType : null,
        dateDebut: dateDebut,
        dateFin: dateFin,
        page: currentPage,
        limit: rowsPerPage,
      );

      setState(() {
        mouvements = res["mouvements"];
        final pagination = res["pagination"];
        totalPages = pagination["totalPages"] ?? 1;
      });
    } on DioException catch (e) {
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
                      MaterialPageRoute(builder: (_) => const AbonnementScreen()),
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onTypeChanged(String? val) {
    if (val != null) {
      setState(() {
        selectedType = val;
        currentPage = 1;
      });
      _fetchMouvements();
    }
  }

  Future<void> _selectDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebut ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateDebut = picked;
        currentPage = 1;
      });
      _fetchMouvements();
    }
  }

  Future<void> _selectDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateFin = picked;
        currentPage = 1;
      });
      _fetchMouvements();
    }
  }

  void _resetFilters() {
    setState(() {
      selectedType = "Tous";
      dateDebut = null;
      dateFin = null;
      currentPage = 1;
    });
    _fetchMouvements();
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      _fetchMouvements();
    }
  }

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
      _fetchMouvements();
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

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

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
         automaticallyImplyLeading: false,
        title: Text("Historique des mouvements",
            style: GoogleFonts.poppins(
                fontSize: isDesktop ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.white),
            tooltip: "Imprimer le rapport",
            onPressed: _generatePdf,
          ),
          if (isDesktop || isTablet)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: "Réinitialiser filtres",
              onPressed: _resetFilters,
            ),
          if (!isDesktop && !isTablet)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: _resetFilters,
                  child: Text("Réinitialiser",style: GoogleFonts.roboto(fontSize: 14),),
                ),
              ],
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isDesktop ? 24 : 12),
        child: Column(
          children: [
            // Filtres
            _buildFilterSection(isDesktop, isTablet),
            const SizedBox(height: 16),

            // Table & Loading
            Expanded(
              child: isLoading
                  ?  Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.orange, size: 50))
                  : _buildDataTable(isDesktop, isTablet),
            ),

            // Pagination
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isDesktop, bool isTablet) {
    return Column(
      children: [
        if (!isDesktop && !isTablet) // Mobile filters in column
          Column(
            children: [
              _buildTypeDropdown(isDesktop),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDateDebutPicker(isDesktop)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateFinPicker(isDesktop)),
                ],
              ),
            ],
          ),
        if (isDesktop || isTablet) // Desktop/Tablet filters in row
          Row(
            children: [
              Expanded(flex: 3, child: _buildTypeDropdown(isDesktop)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _buildDateDebutPicker(isDesktop)),
              const SizedBox(width: 16),
              Expanded(flex: 3, child: _buildDateFinPicker(isDesktop)),
            ],
          ),
      ],
    );
  }

  Widget _buildTypeDropdown(bool isDesktop) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Type",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 12,
          vertical: isDesktop ? 16 : 12,
        ),
      ),
      value: selectedType,
      items: types
          .map((t) => DropdownMenuItem(
                value: t,
                child: Text(t[0].toUpperCase() + t.substring(1)),
              ))
          .toList(),
      onChanged: _onTypeChanged,
    );
  }

  Widget _buildDateDebutPicker(bool isDesktop) {
    return InkWell(
      onTap: _selectDateDebut,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Date début",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12,
            vertical: isDesktop ? 16 : 12,
          ),
        ),
        child: Text(
          dateDebut != null
              ? DateFormat('dd/MM/yyyy').format(dateDebut!)
              : "Sélectionner...",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDateFinPicker(bool isDesktop) {
    return InkWell(
      onTap: _selectDateFin,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Date fin",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20 : 12,
            vertical: isDesktop ? 16 : 12,
          ),
        ),
        child: Text(
          dateFin != null
              ? DateFormat('dd/MM/yyyy').format(dateFin!)
              : "Sélectionner...",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

 Widget _buildDataTable(bool isDesktop, bool isTablet) {
  final columns = [
    DataColumn(
      label: Text(
        "Date",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    DataColumn(
      label: Text(
        "Type",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    DataColumn(
      label: Text(
        "Produit",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    DataColumn(
      label: Text(
        "Quantité",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    DataColumn(
      label: Text(
        "Ancien stock",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    DataColumn(
      label: Text(
        "Nouveau stock",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
    DataColumn(
      label: Text(
        "Description",
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    ),
  ];

  return SingleChildScrollView(
    child: LayoutBuilder(
      builder:(context ,constraints){
      return  SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
           constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.blueGrey),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              headingRowHeight: 35,
              columnSpacing: 20, // Espacement constant entre colonnes
              columns: columns,
              rows: mouvements.map((m) {
                return DataRow(
                  cells: [
                    DataCell(
                      Tooltip(
                        message: DateFormat('dd/MM/yyyy HH:mm').format(m.date),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(m.date),
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        m.type[0].toUpperCase() + m.type.substring(1),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m.productNom,
                        style: GoogleFonts.poppins(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        m.quantite.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m.ancienStock.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        m.nouveauStock.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: m.description,
                        child: SizedBox(
                          width: 200, // Largeur fixe pour la description
                          child: Text(
                            m.description,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      );}
    ),
  );
}

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Page $currentPage / $totalPages",
              style: GoogleFonts.poppins(fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: currentPage > 1 ? _previousPage : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: currentPage < totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  void _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Historique des mouvements",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: [
                  "Date",
                  "Type",
                  "Produit",
                  "Quantité",
                  "Ancien stock",
                  "Nouveau stock",
                  "Description"
                ],
                data: mouvements.map((m) {
                  return [
                    DateFormat('dd/MM/yyyy HH:mm').format(m.date),
                    m.type[0].toUpperCase() + m.type.substring(1),
                    m.productNom,
                    m.quantite.toString(),
                    m.ancienStock.toString(),
                    m.nouveauStock.toString(),
                    m.description,
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                   const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}

// // ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// // import 'package:flutter/material.dart' as pw;
// import 'package:pdf/widgets.dart' as pw;
// import 'package:pdf/pdf.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';

// import 'package:salespulse/models/mouvements_model_pro.dart';
// import 'package:salespulse/providers/auth_provider.dart';
// import 'package:salespulse/services/mouvement_api.dart';
// import 'package:salespulse/views/abonnement/choix_abonement.dart';

// class HistoriqueMouvementsScreen extends StatefulWidget {
//   const HistoriqueMouvementsScreen({super.key});

//   @override
//   State<HistoriqueMouvementsScreen> createState() =>
//       _HistoriqueMouvementsScreenState();
// }

// class _HistoriqueMouvementsScreenState
//     extends State<HistoriqueMouvementsScreen> {
//   List<MouvementModel> mouvements = [];
//   int currentPage = 1;
//   int totalPages = 1;
//   int rowsPerPage = 12;

//   String selectedType = "Tous";
//   DateTime? dateDebut;
//   DateTime? dateFin;

//   bool isLoading = false;

//   final List<String> types = [
//     "Tous",
//     "vente",
//     "ajout",
//     "correction",
//     "suppression"
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fetchMouvements();
//   }

//   Future<void> _fetchMouvements() async {
//     setState(() {
//       isLoading = true;
//     });

//     final token = Provider.of<AuthProvider>(context, listen: false).token;
//     final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
//     try {
//       final res = await ServicesMouvements().getMouvements(
//         adminId: adminId,
//         token: token,
//         productId: "", // vide pour global
//         type: selectedType != "Tous" ? selectedType : null,
//         dateDebut: dateDebut,
//         dateFin: dateFin,
//         page: currentPage,
//         limit: rowsPerPage,
//       );

//       setState(() {
//         mouvements = res["mouvements"];
//         final pagination = res["pagination"];
//         totalPages = pagination["totalPages"] ?? 1;
//       });
//     } on DioException catch (e) {
//       if (e.response != null && e.response?.statusCode == 403) {
//         final errorMessage = e.response?.data['error'] ?? '';

//         if (errorMessage.toString().contains("abonnement")) {
//           // 👉 Afficher message spécifique abonnement expiré
//           showDialog(
//             context: context,
//             builder: (_) => AlertDialog(
//               title: const Text("Abonnement expiré"),
//               content: const Text(
//                   "Votre abonnement a expiré. Veuillez le renouveler."),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const AbonnementScreen()),
//                     );
//                   },
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//           );
//           return;
//         }
//       }

//       // 🚫 Autres DioException (ex: réseau)
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Problème de connexion : Vérifiez votre Internet.",
//             style: GoogleFonts.poppins(fontSize: 14),
//           ),
//         ),
//       );
//     } on TimeoutException {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(
//         "Le serveur ne répond pas. Veuillez réessayer plus tard.",
//         style: GoogleFonts.poppins(fontSize: 14),
//       )));
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
//       debugPrint(e.toString());
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _onTypeChanged(String? val) {
//     if (val != null) {
//       setState(() {
//         selectedType = val;
//         currentPage = 1;
//       });
//       _fetchMouvements();
//     }
//   }

//   Future<void> _selectDateDebut() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: dateDebut ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         dateDebut = picked;
//         currentPage = 1;
//       });
//       _fetchMouvements();
//     }
//   }

//   Future<void> _selectDateFin() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: dateFin ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       setState(() {
//         dateFin = picked;
//         currentPage = 1;
//       });
//       _fetchMouvements();
//     }
//   }

//   void _resetFilters() {
//     setState(() {
//       selectedType = "Tous";
//       dateDebut = null;
//       dateFin = null;
//       currentPage = 1;
//     });
//     _fetchMouvements();
//   }

//   void _previousPage() {
//     if (currentPage > 1) {
//       setState(() {
//         currentPage--;
//       });
//       _fetchMouvements();
//     }
//   }

//   void _nextPage() {
//     if (currentPage < totalPages) {
//       setState(() {
//         currentPage++;
//       });
//       _fetchMouvements();
//     }
//   }

//   Future<void> _handleLogout(BuildContext context) async {
//     final authProvider = context.read<AuthProvider>();
//     await authProvider.logoutButton();
//     if (mounted) {
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();

//     // Vérification initiale de l'authentification
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!authProvider.isAuthenticated && mounted) {
//         await _handleLogout(context);
//       }
//     });

//     if (authProvider.isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: Text("Historique des mouvements",
//             style: GoogleFonts.poppins(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white)),
//         backgroundColor: Colors.blueGrey, //const Color(0xff001c30),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 IconButton(
//                   icon: const Icon(
//                     Icons.print,
//                     color: Colors.blue,
//                   ),
//                   tooltip: "Imprimer le rapport",
//                   onPressed: _generatePdf,
//                 ),
//                 IconButton(
//                   icon: const Icon(
//                     Icons.refresh,
//                     size: 28,
//                     color: Colors.blueGrey,
//                   ),
//                   tooltip: "Réinitialiser filtres",
//                   onPressed: _resetFilters,
//                 )
//               ],
//             ),
//             // Filtres
//             Row(
//               children: [
//                 Expanded(
//                   flex: 3,
//                   child: DropdownButtonFormField<String>(
//                     decoration: InputDecoration(
//                       labelText: "Type",
//                       border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8)),
//                       filled: true,
//                       fillColor: Colors.white,
//                     ),
//                     value: selectedType,
//                     items: types
//                         .map((t) => DropdownMenuItem(
//                               value: t,
//                               child: Text(t[0].toUpperCase() + t.substring(1)),
//                             ))
//                         .toList(),
//                     onChanged: _onTypeChanged,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   flex: 3,
//                   child: InkWell(
//                     onTap: _selectDateDebut,
//                     child: InputDecorator(
//                       decoration: InputDecoration(
//                         labelText: "Date début",
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       child: Text(
//                         dateDebut != null
//                             ? DateFormat('dd/MM/yyyy').format(dateDebut!)
//                             : "Sélectionner...",
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   flex: 3,
//                   child: InkWell(
//                     onTap: _selectDateFin,
//                     child: InputDecorator(
//                       decoration: InputDecoration(
//                         labelText: "Date fin",
//                         border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       child: Text(
//                         dateFin != null
//                             ? DateFormat('dd/MM/yyyy').format(dateFin!)
//                             : "Sélectionner...",
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),

//             // Table & Loading
//             Expanded(
//                 child: isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : SingleChildScrollView(
//   child: LayoutBuilder(
//     builder: (context, constraints) {
//       final isSmallScreen = constraints.maxWidth < 900;
      
//       return Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 8,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: SingleChildScrollView(
//           scrollDirection: Axis.horizontal,
//           child: ConstrainedBox(
//             constraints: BoxConstraints(minWidth: constraints.maxWidth),
//             child: DataTable(
//               headingRowColor: MaterialStateProperty.all(Colors.blueGrey),
//               headingTextStyle: const TextStyle(
//                 color: Colors.white, // Changé de black à white pour meilleur contraste
//                 fontWeight: FontWeight.bold,
//                 fontSize: 12,
//               ),
//               headingRowHeight: 35,
//               columnSpacing: isSmallScreen ? 12 : 20,
//               columns: [
//                 DataColumn(
//                   label: Text(
//                     "Date".toUpperCase(),
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Text(
//                     "Type".toUpperCase(),
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 if (!isSmallScreen)
//                   DataColumn(
//                     label: Text(
//                       "Produit".toUpperCase(),
//                       style: GoogleFonts.poppins(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 DataColumn(
//                   label: Text(
//                     isSmallScreen ? "Qté".toUpperCase() : "Quantité".toUpperCase(),
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 if (!isSmallScreen) DataColumn(
//                   label: Text(
//                     "Ancien stock".toUpperCase(),
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 DataColumn(
//                   label: Text(
//                     isSmallScreen ? "Nv stock".toUpperCase() : "Nouveau stock".toUpperCase(),
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//                 if (!isSmallScreen) DataColumn(
//                   label: Text(
//                     "Description".toUpperCase(),
//                     style: GoogleFonts.poppins(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//               rows: mouvements.map((m) {
//                 return DataRow(
//                   cells: [
//                     DataCell(
//                       Tooltip(
//                         message: DateFormat('dd/MM/yyyy HH:mm').format(m.date),
//                         child: Text(
//                           isSmallScreen 
//                             ? DateFormat('dd/MM').format(m.date)
//                             : DateFormat('dd/MM/yyyy').format(m.date),
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             fontWeight: FontWeight.w400,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ),
//                     ),
//                     DataCell(
//                       Text(
//                         isSmallScreen 
//                           ? m.type[0].toUpperCase()
//                           : m.type[0].toUpperCase() + m.type.substring(1),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     if (!isSmallScreen) DataCell(
//                       Text(
//                         m.productNom,
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                     DataCell(
//                       Text(
//                         m.quantite.toString(),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     if (!isSmallScreen) DataCell(
//                       Text(
//                         m.ancienStock.toString(),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     DataCell(
//                       Text(
//                         m.nouveauStock.toString(),
//                         style: GoogleFonts.poppins(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                     if (!isSmallScreen) DataCell(
//                       Tooltip(
//                         message: m.description,
//                         child: SizedBox(
//                           width: 200,
//                           child: Text(
//                             m.description,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w400,
//                               color: Colors.black,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       );
//     },
//   ),
// )),

//             // Pagination
//             Padding(
//               padding: const EdgeInsets.only(top: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Text("Page $currentPage / $totalPages",
//                       style: GoogleFonts.poppins(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w400,
//                           color: Colors.black)),
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios),
//                     onPressed: currentPage > 1 ? _previousPage : null,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.arrow_forward_ios),
//                     onPressed: currentPage < totalPages ? _nextPage : null,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _generatePdf() async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         // pageFormat: PdfPageFormat.a4.landscape,
//         build: (context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text("Historique des mouvements",
//                   style: pw.TextStyle(
//                       fontSize: 24, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 16),
//               // ignore: deprecated_member_use
//               pw.Table.fromTextArray(
//                 headers: [
//                   "Date",
//                   "Type",
//                   "Produit",
//                   "Quantité",
//                   "Ancien stock",
//                   "Nouveau stock",
//                   "Description"
//                 ],
//                 data: mouvements.map((m) {
//                   return [
//                     DateFormat('dd/MM/yyyy HH:mm').format(m.date),
//                     m.type[0].toUpperCase() + m.type.substring(1),
//                     m.productNom,
//                     m.quantite.toString(),
//                     m.ancienStock.toString(),
//                     m.nouveauStock.toString(),
//                     m.description,
//                   ];
//                 }).toList(),
//                 headerStyle: pw.TextStyle(
//                     fontWeight: pw.FontWeight.bold, color: PdfColors.white),
//                 headerDecoration:
//                     const pw.BoxDecoration(color: PdfColors.blue800),
//                 cellAlignment: pw.Alignment.centerLeft,
//                 cellPadding: const pw.EdgeInsets.all(5),
//               ),
//             ],
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(onLayout: (format) => pdf.save());
//   }
// }
