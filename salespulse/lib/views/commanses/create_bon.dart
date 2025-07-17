// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/fournisseurs_model.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/commande_api.dart';
import 'package:salespulse/services/fournisseur_api.dart';
import 'package:salespulse/services/stocks_api.dart';

class OrderItem {
  final String productId;
  final String? image;
  final String? nom;
  final String productName;
  final int prixAchat;
  int quantity;

  OrderItem({
    required this.productId,
    required this.image,
    required this.nom,
    required this.productName,
    required this.prixAchat,
    this.quantity = 1,
  });
}

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final ServicesStocks api = ServicesStocks();
  final ServicesCommande commandeApi = ServicesCommande();
  final ServicesFournisseurs fournisseursApi = ServicesFournisseurs();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<OrderItem> _items = [];
  List<ProductModel> _products = [];
  List<FournisseurModel> _fournisseurs = [];
  FournisseurModel? _selectedFournisseur;
  String _searchQuery = "";
 
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadFournisseurs();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await api.getAllProducts(token);
      if (res.statusCode == 200) {
        final body = res.data;
        setState(() {
          _products = (body["produits"] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement produits: $e");
    }
  }

  Future<void> _loadFournisseurs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await fournisseursApi.getFournisseurs(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          _fournisseurs = (body["fournisseurs"] as List)
              .map((json) => FournisseurModel.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      Exception(e);
    }
  }

  Future<void> _submitOrder(BuildContext context,total) async{
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
    if (_formKey.currentState!.validate() && _items.isNotEmpty && _selectedFournisseur != null) {
       if (_selectedFournisseur == null || _items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Veuillez ajouter un fournisseur et au moins un produit.")),
    );
    return;
  }

  final commandeData = {
    "adminId":adminId,
    "fournisseurId": _selectedFournisseur!.id,
    "fournisseurName":"${_selectedFournisseur!.prenom} ${_selectedFournisseur!.nom}",
    "fournisseurContact":_selectedFournisseur!.numero,
    "fournisseurAddress":_selectedFournisseur!.address,
    "produits": _items.map((item) => {
      "productId": item.productId,
      "image":item.image,
      "nom":item.nom,
      "quantite": item.quantity,
      "prixAchat": item.prixAchat,
    }).toList(),
    "total":total,
    "statut":"en attente",
    "date": DateTime.now().toIso8601String(), // ✅ encodable en JSON
    "notes":_noteController.text
    // Tu peux ajouter d'autres champs si nécessaire (date, notes, etc.)
  };

 final res = await commandeApi.postCommande(commandeData, token);
 if(res.statusCode == 201){
  if(!context.mounted) return ;
  ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.data['message'])),
      );
      Navigator.pop(context,true);
 }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires.")),
      );
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _openProductSelector() {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = _products
              .where((product) => product.nom.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();

          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text("Sélectionner un produit",
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      decoration: const InputDecoration(hintText: "Rechercher un produit..."),
                      onChanged: (value) => setModalState(() => _searchQuery = value),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                          
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final product = filtered[index];
                              return ListTile(
                                leading:ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      product.image ?? '',
                                      fit: BoxFit.cover,
                                      width: 80,
                                      height: 50,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ) ,
                                title: Text(product.nom ,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),),
                                subtitle: Text("Stock: ${product.stocks} • ${product.prixVente} FCFA",style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),),
                                onTap: () {
                                  setState(() {
                                    _items.add(OrderItem(
                                      image:product.image ?? "",
                                      nom:product.nom,
                                      productId: product.id,
                                      productName: product.nom,
                                      prixAchat: product.prixAchat,
                                    ));
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<FournisseurModel>(
            decoration: InputDecoration(
              labelText: "Fournisseur",
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600 ,fontSize: 16 ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(width: 0.1, color: Colors.grey[200]!)
              )
              ),
            items: _fournisseurs
                .map((f) => DropdownMenuItem(value: f, child: Text("${f.nom} ${f.prenom}",style: GoogleFonts.poppins(fontWeight: FontWeight.w600 ,fontSize: 14 ))))
                .toList(),
            value: _selectedFournisseur,
            onChanged: (value) => setState(() => _selectedFournisseur = value),
            validator: (value) => value == null ? 'Sélectionnez un fournisseur' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                  labelText: "Date",
                  labelStyle:GoogleFonts.poppins(fontWeight: FontWeight.w600 ,fontSize: 16 ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(width: 0.1, color: Colors.grey[200]!)
                  )
                  ),
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 12),
            
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
  final isSmallScreen = MediaQuery.of(context).size.width < 799;

  return Container(
     padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16)
      ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Produits ajoutés",
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _items.isEmpty
            ? Center(
              child: Text(
                  "Aucun produit ajouté.",
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
                ),
            )
            : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                    children: _items.map((item) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        color: Colors.white,
                        elevation: 0.2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item.image ?? '',
                                  fit: BoxFit.cover,
                                  width: 80,
                                  height: 50,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Quantité: ${item.quantity}",
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 4),
                                    if (isSmallScreen)
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove),
                                            onPressed: () {
                                              setState(() {
                                                if (item.quantity > 1) item.quantity--;
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () => setState(() => item.quantity++),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => setState(() => _items.remove(item)),
                                          ),
                                        ],
                                      )
                                  ],
                                ),
                              ),
                              if (!isSmallScreen)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        setState(() {
                                          if (item.quantity > 1) item.quantity--;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => setState(() => item.quantity++),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => setState(() => _items.remove(item)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ),
            ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: _openProductSelector,
            icon: const Icon(Icons.add),
            label: Text(
              "Ajouter un produit",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildFooterSection(BuildContext context) {
    final total = _items.fold(0, (sum, item) => sum + (item.prixAchat * item.quantity));
    return Container(
       padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [   
          Text("Total : ${NumberFormat("#,##0", "fr_FR").format(total)} FCFA",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(),
          Text("Notes (optionnel)",style: GoogleFonts.poppins(fontWeight: FontWeight.w600 ,fontSize: 16 )),
          const SizedBox(height: 8),
          TextFormField(
                  maxLines: 5,
                  controller: _noteController,
                  decoration: InputDecoration(
                  hint: const Text("Ex: ") ,
                  filled: true,
                  fillColor: Colors.grey[100],
                  hintStyle:GoogleFonts.poppins(fontWeight: FontWeight.w600 ,fontSize: 16 ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(width: 1, color: Colors.grey[100]!)
                  )
                  ),
                ),
                  const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700 , foregroundColor: Colors.white),
              onPressed:()=> _submitOrder(context,total),
              child: Text("Enregistrer la commande", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon:const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white)),
        title: Text('Nouveau Bon de Commande',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600 ,fontSize: 16 ,color:Colors.white))),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal:16.0 , vertical: 25),
          child: Form(
            key: _formKey,
            child: isSmallScreen
                ? SafeArea(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderSection(),
                          const SizedBox(height: 24),
                          _buildItemsSection(),
                          const SizedBox(height: 24),
                          _buildFooterSection(context),
                        ],
                      ),
                    ),
                )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(
                        children: [
                          _buildHeaderSection(),
                          const SizedBox(height: 24),
                          _buildItemsSection(),                      
                        ],
                      )),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              
                              _buildFooterSection(context),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
