// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/components/add_photo.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/views/abonnement/abonement_historiques.dart';
import 'package:salespulse/views/auth/login_view.dart';
import 'package:salespulse/views/categories/categories_view.dart';
import 'package:salespulse/views/cliens/client_pro.dart';
import 'package:salespulse/views/dashbord/dash_prod.dart';
import 'package:salespulse/views/depenses/depense_view.dart';
import 'package:salespulse/views/fournisseurs/fournisseurs_view.dart';
import 'package:salespulse/views/impaye/impaye_pro.dart';
import 'package:salespulse/views/inventaire/inventaire.dart';
import 'package:salespulse/views/mouvements/mouvement_inventaire.dart';
import 'package:salespulse/views/panier/add_vente_pro.dart';
import 'package:salespulse/views/parametre.dart/parametre.dart';
import 'package:salespulse/views/populaires/populaire_view.dart';
import 'package:salespulse/views/rapports/rapport_general.dart';
import 'package:salespulse/views/reglements/reglement_view.dart';
import 'package:salespulse/views/creer_stocks/add_stock_pro_screen.dart';
import 'package:salespulse/views/stocks/stocks.dart';
import 'package:salespulse/views/users/user_pro.dart';
import 'package:salespulse/views/ventes/historique_vente_pro.dart';

class Routes extends StatefulWidget {
  const Routes({super.key});

  @override
  State<Routes> createState() => _RoutesState();
}

class _RoutesState extends State<Routes> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? currentBackPressTime;
  bool _analyseMenuExpanded = false;
  bool _ventesMenuExpanded = false;
  bool _stockMenuExpanded = false;
  bool _catalogueMenuExpanded = false;
  bool _relationsMenuExpanded = false;
  bool _financesMenuExpanded = false;
  bool _adminMenuExpanded = false;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final role = authProvider.role;
    
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
      return false;
    }
    
    final allowedIndexes = [
      1, 2, 3, 4, 5, 6, 8, 9, 11, 12, 13,
      if (role == "admin") ...[0, 7, 10, 14, 15]
    ];
    
    final firstAllowedIndex = allowedIndexes.first;
    if (_currentIndex != firstAllowedIndex) {
      setState(() => _currentIndex = firstAllowedIndex);
      return false;
    }
    
    if (currentBackPressTime == null || 
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appuyez encore pour quitter'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = Provider.of<AuthProvider>(context).token.isNotEmpty;
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return isLoggedIn
        ? WillPopScope(
            onWillPop: _onWillPop,
            child: Scaffold(
              key: _scaffoldKey,
              drawer: isMobile ? _buildMobileDrawer() : null,
              body: isMobile
                  ? _buildPage()
                  : Row(
                      children: [
                        _buildDesktopSidebar(),
                        Expanded(child: _buildPage()),
                      ],
                    ),
              appBar: isMobile
                  ? AppBar(
                      backgroundColor: Colors.blueGrey,
                      title: const Text(""),
                      leading: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    )
                  : null,
            ),
          )
        : const LoginView();
  }

  Widget _buildDesktopSidebar() {
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final number = Provider.of<AuthProvider>(context, listen: false).societeNumber;
    final role = Provider.of<AuthProvider>(context, listen: false).role;
    final ScrollController scrollController = ScrollController();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        colors: [Color(0xFF001C30), Color(0xFF001C40)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )),
      child: Theme(
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.white10),
            trackColor: MaterialStateProperty.all(Colors.white10),
            thickness: MaterialStateProperty.all(6),
            radius: const Radius.circular(8),
          ),
        ),
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: false,
          trackVisibility: false,
          interactive: true,
          child: ListView(
            controller: scrollController,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xff001c30),
                  border: Border(bottom: BorderSide(width: 2, color: Colors.orange))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const PikedPhoto(),
                    const SizedBox(height: 10),
                    Text(
                      store,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        number,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color.fromARGB(255, 231, 231, 231),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildExpandableSectionHeader(
                'ANALYSE',
                 Icons.analytics,
                expanded: _analyseMenuExpanded,
                onTap: () => setState(() => _analyseMenuExpanded = !_analyseMenuExpanded),
              ),
              if (_analyseMenuExpanded) ...[
                if (role == "admin")
                  _buildDrawerItem(
                      Icons.stacked_bar_chart_rounded, "Tableau de bord", 0,
                      iconBgColor: Colors.blueGrey),
                 if (role == "admin")
                  _buildDrawerItem(Icons.stacked_line_chart_outlined, "Rapports généraux", 1,
                      iconBgColor: Colors.green),
                  _buildDrawerItem(
                    Icons.workspace_premium, "Tendance des produits", 2,
                    iconBgColor: Colors.orange),
              ],

              _buildExpandableSectionHeader(
                'VENTES',
                   Icons.shopping_cart,
              
                expanded: _ventesMenuExpanded,
                onTap: () => setState(() => _ventesMenuExpanded = !_ventesMenuExpanded),
              ),
              if (_ventesMenuExpanded) ...[
                _buildDrawerItem(
                    Icons.shopping_cart_outlined, "Point de vente", 3,
                    iconBgColor: Colors.teal),
                _buildDrawerItem(
                    Icons.library_books_sharp, "Historique de ventes", 4,
                    iconBgColor: Colors.cyan),
                _buildDrawerItem(Icons.credit_card_off, "Clients impayés", 5,
                    iconBgColor: Colors.orangeAccent),
                _buildDrawerItem(
                    FontAwesomeIcons.handshake, "Historique règlements", 6,
                    iconBgColor: Colors.deepOrange),
              ],

              _buildExpandableSectionHeader(
                'STOCKS',
                  Icons.inventory,
                expanded: _stockMenuExpanded,
                onTap: () => setState(() => _stockMenuExpanded = !_stockMenuExpanded),
              ),
              if (_stockMenuExpanded) ...[
                _buildDrawerItem(Icons.assured_workload_rounded, "Entrepots", 7,
                    iconBgColor: Colors.blue),
                if (role == "admin")
                  _buildDrawerItem(Icons.add, "Ajouter produits", 8,
                      iconBgColor: Colors.blue.shade300),
                _buildDrawerItem(Icons.inventory_2_rounded, "Inventaires", 9,
                    iconBgColor: Colors.deepPurple),
                _buildDrawerItem(Icons.assignment_add, "Mouvement inventaires", 10,
                    iconBgColor: Colors.deepOrange),
               
              ],

              _buildExpandableSectionHeader(
                'CATALOGUE',
                 Icons.category,
                expanded: _catalogueMenuExpanded,
                onTap: () => setState(() => _catalogueMenuExpanded = !_catalogueMenuExpanded),
              ),
              if (_catalogueMenuExpanded) ...[
                _buildDrawerItem(Icons.category, "Catégories", 11,
                    iconBgColor: Colors.green),
              ],

              _buildExpandableSectionHeader(
                'RELATIONS',
                Icons.people,
                expanded: _relationsMenuExpanded,
                onTap: () => setState(() => _relationsMenuExpanded = !_relationsMenuExpanded),
              ),
              if (_relationsMenuExpanded) ...[
                _buildDrawerItem(Icons.people_alt, "Mes clients", 12,
                    iconBgColor: Colors.teal),
                _buildDrawerItem(Icons.contact_phone_rounded, "Fournisseurs", 13,
                    iconBgColor: Colors.grey),
              ],

              _buildExpandableSectionHeader(
                'FINANCES',
                  Icons.attach_money,
                expanded: _financesMenuExpanded,
                onTap: () => setState(() => _financesMenuExpanded = !_financesMenuExpanded),
              ),
              if (_financesMenuExpanded) ...[
                _buildDrawerItem(Icons.balance_sharp, "Dépenses", 14,
                    iconBgColor: Colors.redAccent),
              ],
             if (role == "admin")
              _buildExpandableSectionHeader(
                'ADMINISTRATION',
                 Icons.admin_panel_settings,
                expanded: _adminMenuExpanded,
                onTap: () => setState(() => _adminMenuExpanded = !_adminMenuExpanded),
              ),
              if (_adminMenuExpanded) ...[
                if (role == "admin")
                  _buildDrawerItem(
                      FontAwesomeIcons.userGroup, "Suivis employés", 15,
                      iconBgColor: Colors.blueAccent),
              ],

              const Divider(color: Colors.grey),
                if (role == "admin")
              _customSidebarAction(
                  icon: Icons.settings,
                  label: "Paramètres",
                  color: const Color.fromARGB(255, 10, 165, 226),
                  onTap: () {
                    // Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ParametresPage()),
                    );
                  }),
             
              Consumer<AuthProvider>(
                builder: (context, provider, child) => _customSidebarAction(
                  icon: LineIcons.alternateSignOut,
                  label: "Se déconnecter",
                  color: const Color.fromARGB(255, 165, 10, 226),
                  onTap: () {
                    // Navigator.pop(context);
                    provider.logoutButton();
                  },
                ),
              ),
               if (role == "admin")
            _customSidebarAction(
              icon: Icons.receipt_long, 
              label: "Abonnement", 
              color: Colors.deepOrange, 
              onTap:  () {
                  // Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AbonnementHistoriquePage()),
                  );
                }
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    final store = Provider.of<AuthProvider>(context, listen: false).societeName;
    final number = Provider.of<AuthProvider>(context, listen: false).societeNumber;
    final role = Provider.of<AuthProvider>(context, listen: false).role;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001C30), Color(0xFF001C40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xff001c30),
                border: Border(bottom: BorderSide(width: 2, color: Colors.orange)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PikedPhoto(),
                  const SizedBox(height: 10),
                  Text(
                    store,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      number,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 231, 231, 231),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _buildExpandableSectionHeader(
              'ANALYSE',
              Icons.analytics,
              expanded: _analyseMenuExpanded,
              onTap: () => setState(() => _analyseMenuExpanded = !_analyseMenuExpanded),
            ),
            if (_analyseMenuExpanded) ...[
              if (role == "admin")
                _buildDrawerItem(
                    Icons.stacked_bar_chart_rounded, "Tableau de bord", 0,
                    iconBgColor: Colors.blueGrey),
             
                if (role == "admin")
                _buildDrawerItem(Icons.stacked_line_chart_outlined, "Rapports généraux", 1,
                    iconBgColor: Colors.green),
                 _buildDrawerItem(
                  Icons.workspace_premium, "Tendance des produits", 2,
                  iconBgColor: Colors.orange),
            ],

            _buildExpandableSectionHeader(
              'VENTES',
                Icons.shopping_cart,
              expanded: _ventesMenuExpanded,
              onTap: () => setState(() => _ventesMenuExpanded = !_ventesMenuExpanded),
            ),
            if (_ventesMenuExpanded) ...[
              _buildDrawerItem(
                  Icons.shopping_cart_outlined, "Point de vente", 3,
                  iconBgColor: Colors.teal),
              _buildDrawerItem(
                  Icons.library_books_sharp, "Historique de ventes", 4,
                  iconBgColor: Colors.cyan),
              _buildDrawerItem(Icons.credit_card_off, "Clients impayés", 5,
                  iconBgColor: Colors.orangeAccent),
              _buildDrawerItem(
                  FontAwesomeIcons.handshake, "Historique règlements", 6,
                  iconBgColor: Colors.deepOrange),
            ],

            _buildExpandableSectionHeader(
              'STOCKS',
              Icons.inventory,
              expanded: _stockMenuExpanded,
              onTap: () => setState(() => _stockMenuExpanded = !_stockMenuExpanded),
            ),
            if (_stockMenuExpanded) ...[
              _buildDrawerItem(Icons.assured_workload_rounded, "Entrepots", 7,
                  iconBgColor: Colors.blue),
              if (role == "admin")
                _buildDrawerItem(Icons.add, "Ajouter produits", 8,
                    iconBgColor: Colors.blue.shade300),
              _buildDrawerItem(Icons.inventory_2_rounded, "Inventaires", 9,
                  iconBgColor: Colors.deepPurple),
              _buildDrawerItem(Icons.assignment_add, "Mouvement inventaires", 10,
                  iconBgColor: Colors.deepOrange),
            
            ],

            _buildExpandableSectionHeader(
              'CATALOGUE',
               Icons.category,
              expanded: _catalogueMenuExpanded,
              onTap: () => setState(() => _catalogueMenuExpanded = !_catalogueMenuExpanded),
            ),
            if (_catalogueMenuExpanded) ...[
              _buildDrawerItem(Icons.category, "Catégories", 11,
                  iconBgColor: Colors.green),
            ],

            _buildExpandableSectionHeader(
              'RELATIONS',
               Icons.people,
              expanded: _relationsMenuExpanded,
              onTap: () => setState(() => _relationsMenuExpanded = !_relationsMenuExpanded),
            ),
            if (_relationsMenuExpanded) ...[
              _buildDrawerItem(Icons.people_alt, "Mes clients", 12,
                  iconBgColor: Colors.teal),
              _buildDrawerItem(Icons.contact_phone_rounded, "Fournisseurs", 13,
                  iconBgColor: Colors.grey),
            ],

            _buildExpandableSectionHeader(
              'FINANCES',
               Icons.attach_money,
              expanded: _financesMenuExpanded,
              onTap: () => setState(() => _financesMenuExpanded = !_financesMenuExpanded),
            ),
            if (_financesMenuExpanded) ...[
              _buildDrawerItem(Icons.balance_sharp, "Dépenses", 14,
                  iconBgColor: Colors.redAccent),
            ],
             if (role == "admin")
            _buildExpandableSectionHeader(
              'ADMINISTRATION',
               Icons.admin_panel_settings,
              expanded: _adminMenuExpanded,
              onTap: () => setState(() => _adminMenuExpanded = !_adminMenuExpanded),
            ),
            if (_adminMenuExpanded) ...[
              if (role == "admin")
                _buildDrawerItem(
                    FontAwesomeIcons.userGroup, "Suivis employés", 15,
                    iconBgColor: Colors.blueAccent),
            
            ],

            const Divider(color: Colors.grey),
              if (role == "admin")
            _customSidebarAction(
                icon: Icons.settings,
                label: "Paramètres",
                color: const Color.fromARGB(255, 10, 165, 226),
                onTap: () {
                  // Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ParametresPage()),
                  );
                }),
            Consumer<AuthProvider>(
              builder: (context, provider, child) => _customSidebarAction(
                icon: LineIcons.alternateSignOut,
                label: "Se déconnecter",
                color: const Color.fromARGB(255, 165, 10, 226),
                onTap: () {
                  // Navigator.pop(context);
                  provider.logoutButton();
                },
              ),
            ),
              if (role == "admin")
            _customSidebarAction(
              icon: Icons.receipt_long, 
              label: "Abonnement", 
              color: Colors.deepOrange, 
              onTap:  () {
                  // Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AbonnementHistoriquePage()),
                  );
                }
              )
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSectionHeader(String title,IconData icon, {
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 10, right: 10),
       leading: Icon(
        icon,
        size: 20,
        color: Colors.grey[400],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 12,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Icon(
        expanded ? Icons.expand_less : Icons.expand_more,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildPage() {
    final auth = Provider.of<AuthProvider>(context);
    final role = auth.role;

    final allPages = [
      const StatistiquesScreen(), 
      const RapportGeneralScreen(), 
      const StatistiquesProduitsPage(),
      const AddVenteScreen(),
      const HistoriqueVentesScreen(),
      const ClientsEnRetardScreen(),
      const HistoriqueReglementsScreen(),
      const StocksView(),
      const AddProduitPage(),
      const InventaireProPage(),
      const HistoriqueMouvementsScreen(),
      const CategoriesView(),
      const ClientsView(),
      const FournisseurView(),
      const DepenseScreen(),
      const UserManagementScreen(),
      // const AbonnementHistoriquePage()
    ];

    final allowedIndexes = [
       2, 3,4, 5, 6, 7,8, 9,10, 11, 12, 13,
      if (role == "admin") ...[0, 1, 14, 15]
    ];

    if (!allowedIndexes.contains(_currentIndex)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _currentIndex = allowedIndexes.first;
        });
      });
      return allPages[allowedIndexes.first];
    }

    return allPages[_currentIndex];
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    int index, {
    Widget? trailing,
    Color iconBgColor = Colors.orange,
  }) {
    final isSelected = _currentIndex == index;

    return ListTile(
      leading: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 5,
                  )
                ]
              : [],
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      trailing: trailing,
      selected: isSelected,
      selectedTileColor: Colors.white24,
      onTap: () {
        setState(() => _currentIndex = index);
        if (MediaQuery.of(context).size.width < 768) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _customSidebarAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        height: 27,
        width: 27,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  
}
