import 'package:flutter/material.dart';
import '../widgets/floating_nav_bar.dart';
import '../services/app_translations.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../models/animal_model.dart';

class MarketItem {
  final String id;
  final String title;
  final String categoryKey;
  final String price;
  final String location;
  final String imageAsset;
  final String sellerName;
  final String sellerPhone;
  final String details;
  final bool isMyListing;
  final String date;
  final String verificationStatus;
  final bool isGovVerified;

  MarketItem({
    required this.id,
    required this.title,
    required this.categoryKey,
    required this.price,
    required this.location,
    required this.imageAsset,
    required this.sellerName,
    required this.sellerPhone,
    required this.details,
    this.isMyListing = false,
    this.date = 'Just now',
    this.verificationStatus = 'VERIFIED',
    this.isGovVerified = true,
  });
}

class MarketplaceScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final ValueChanged<int>? onNavTap;
  final int initialTabIndex;

  const MarketplaceScreen({
    super.key,
    this.onBackToHome,
    this.onNavTap,
    this.initialTabIndex = 0,
  });

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  static const Color _orange = Color(0xFFFF6D00);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _bg = Color(0xFFFBF9F4);

  late int _selectedTab; // 0: Buy, 1: Sell
  String _selectedCategoryKey = ''; // '' means all
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favoriteIds = {};

  final List<Map<String, String>> _categories = [
    {
      'key': 'cow',
      'labelKey': 'cat_cow',
      'image': 'assets/images/market_cat_cow.png',
    },
    {
      'key': 'buffalo',
      'labelKey': 'cat_buffalo',
      'image': 'assets/images/market_cat_buffalo.png',
    },
    {
      'key': 'goat',
      'labelKey': 'cat_goat',
      'image': 'assets/images/market_cat_goat.png',
    },
    {
      'key': 'fodder',
      'labelKey': 'cat_fodder',
      'image': 'assets/images/market_cat_fodder.png',
    },
    {
      'key': 'medicine',
      'labelKey': 'cat_medicine',
      'image': 'assets/images/market_cat_medicine.png',
    },
    {
      'key': 'equipment',
      'labelKey': 'cat_equipment',
      'image': 'assets/images/market_cat_equipment.png',
    },
  ];

  late List<MarketItem> _buyItems;
  late List<MarketItem> _mySellItems;
  String? _lastLoadedLang;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _syncItemsForLanguage(SessionManager().language);
  }

  void _syncItemsForLanguage(String lang) {
    if (_lastLoadedLang == lang) return;
    _lastLoadedLang = lang;
    final List<MarketItem> userAdded = [];
    if (mounted) {
      try {
        userAdded.addAll(_mySellItems.where((i) => i.id != 'my_1' && i.isMyListing));
      } catch (_) {}
    }
    _buyItems = _getBuyItems(lang);
    _mySellItems = [...userAdded, ..._getSellItems(lang)];
  }

  static List<MarketItem> _getBuyItems(String lang) {
    if (lang == 'hi') {
      return [
        MarketItem(
          id: 'item_1',
          title: 'एचएफ गाय (दुधारू)',
          categoryKey: 'cow',
          price: '₹ 65,000',
          location: 'पुणे, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_hf_cow.png',
          sellerName: 'सुरेश पाटिल',
          sellerPhone: '9822012345',
          details: 'दूध क्षमता: 18 लीटर प्रतिदिन। उम्र: 4.5 वर्ष। सभी आवश्यक टीके पूर्ण, स्वस्थ व शांत।',
          date: '2 घंटे पहले',
        ),
        MarketItem(
          id: 'item_2',
          title: 'मुर्रा भैंस',
          categoryKey: 'buffalo',
          price: '₹ 85,000',
          location: 'नासिक, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_murrah_buffalo.png',
          sellerName: 'गणेश देशमुख',
          sellerPhone: '9822123456',
          details: 'पहले ब्यात की उच्च गुणवत्ता वाली मुर्रा भैंस। 12 लीटर दैनिक दूध, उत्तम फैट।',
          date: '5 घंटे पहले',
        ),
        MarketItem(
          id: 'item_3',
          title: 'उच्च गुणवत्ता हरा चारा',
          categoryKey: 'fodder',
          price: '₹ 450 / 50kg',
          location: 'औरंगाबाद, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_green_fodder.png',
          sellerName: 'रमेश शिंदे',
          sellerPhone: '9822234567',
          details: 'ताजा सुपर नेपियर और मक्का हरा चारा। 50 किग्रा बंडल, खेत से ताजी कटाई।',
          date: '1 दिन पहले',
        ),
        MarketItem(
          id: 'item_4',
          title: 'उस्मानाबादी बकरी (गाभिन)',
          categoryKey: 'goat',
          price: '₹ 14,000',
          location: 'सोलापुर, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_goat_osmanabadi.png',
          sellerName: 'बालू कदम',
          sellerPhone: '9822345678',
          details: '3 माह की गाभिन, स्वस्थ उस्मानाबादी बकरी। वजन 35 किग्रा, संपूर्ण टीकाकरण।',
          date: '1 दिन पहले',
        ),
        MarketItem(
          id: 'item_5',
          title: 'गीर गाय (शुद्ध देशी)',
          categoryKey: 'cow',
          price: '₹ 72,000',
          location: 'कोल्हापुर, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'तानाजी जाधव',
          sellerPhone: '9822456789',
          details: 'A2 दूध देने वाली शुद्ध काठियावाड़ी गीर गाय। 14 लीटर दूध क्षमता, शांत व स्वस्थ।',
          date: '2 दिन पहले',
        ),
      ];
    } else if (lang == 'mr') {
      return [
        MarketItem(
          id: 'item_1',
          title: 'HF गाय (दुधासाठी)',
          categoryKey: 'cow',
          price: '₹ 65,000',
          location: 'पुणे, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_hf_cow.png',
          sellerName: 'सुरेश पाटील',
          sellerPhone: '9822012345',
          details: 'दूध क्षमता: १८ लिटर प्रतिदिन. वय: ४.५ वर्षे. सर्व आवश्यक लसीकरण पूर्ण. निरोगी व शांत गाय.',
          date: '२ तास आधी',
        ),
        MarketItem(
          id: 'item_2',
          title: 'म्हैस (Murrah)',
          categoryKey: 'buffalo',
          price: '₹ 85,000',
          location: 'नाशिक, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_murrah_buffalo.png',
          sellerName: 'गणेश देशमुख',
          sellerPhone: '9822123456',
          details: 'पहिल्या वेताची उच्च प्रतीची मुर्रा म्हैस. १२ लिटर दूध क्षमता. उत्तम फॅट व घनता.',
          date: '५ तास आधी',
        ),
        MarketItem(
          id: 'item_3',
          title: 'हाय क्वालिटी चारा',
          categoryKey: 'fodder',
          price: '₹ 450 / 50kg',
          location: 'औरंगाबाद, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_green_fodder.png',
          sellerName: 'रमेश शिंदे',
          sellerPhone: '9822234567',
          details: 'ताजा सुपर नेपियर व संकरित मका हिरवा चारा. ५० किलो बंडल. थेट शेतातून ताजी कापणी.',
          date: '१ दिवस आधी',
        ),
        MarketItem(
          id: 'item_4',
          title: 'उस्मानाबादी शेळी (गाभण)',
          categoryKey: 'goat',
          price: '₹ 14,000',
          location: 'सोलापूर, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_goat_osmanabadi.png',
          sellerName: 'बाळू कदम',
          sellerPhone: '9822345678',
          details: '३ महिने गाभण, निरोगी उस्मानाबादी शेळी. वजन ३५ किलो. सर्व जंतनिर्मूलन व लसीकरण पूर्ण.',
          date: '१ दिवस आधी',
        ),
        MarketItem(
          id: 'item_5',
          title: 'गीर गाय (शुद्ध देशी)',
          categoryKey: 'cow',
          price: '₹ 72,000',
          location: 'कोल्हापूर, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'तानाजी जाधव',
          sellerPhone: '9822456789',
          details: 'A2 गुणधर्माचे दूध देणारी शुद्ध काठियावाडी गीर गाय. १४ लिटर दूध क्षमता. शांत व निरोगी.',
          date: '२ दिवस आधी',
        ),
      ];
    } else if (lang == 'te') {
      return [
        MarketItem(
          id: 'item_1',
          title: 'హెచ్‌ఎఫ్ ఆవు (పాల ఉత్పత్తి)',
          categoryKey: 'cow',
          price: '₹ 65,000',
          location: 'పూణే, మహారాష్ట్ర',
          imageAsset: 'assets/images/market_item_hf_cow.png',
          sellerName: 'సురేష్ పాటిల్',
          sellerPhone: '9822012345',
          details: 'పాల సామర్థ్యం: రోజుకు 18 లీటర్లు. వయస్సు: 4.5 సంవత్సరాలు. టీకాలు పూర్తయ్యాయి.',
          date: '2 గంటల క్రితం',
        ),
        MarketItem(
          id: 'item_2',
          title: 'ముర్రా గేదె',
          categoryKey: 'buffalo',
          price: '₹ 85,000',
          location: 'నాసిక్, మహారాష్ట్ర',
          imageAsset: 'assets/images/market_item_murrah_buffalo.png',
          sellerName: 'గణేష్ దేశ్‌ముఖ్',
          sellerPhone: '9822123456',
          details: 'మొదటి ఈత ముర్రా గేదె. రోజుకు 12 లీటర్ల పాలు, మంచి వెన్న శాతం.',
          date: '5 గంటల క్రితం',
        ),
        MarketItem(
          id: 'item_3',
          title: 'నాణ్యమైన పచ్చి మేత',
          categoryKey: 'fodder',
          price: '₹ 450 / 50kg',
          location: 'ఔరంగాబాద్, మహారాష్ట్ర',
          imageAsset: 'assets/images/market_item_green_fodder.png',
          sellerName: 'రమేష్ షిండే',
          sellerPhone: '9822234567',
          details: 'తాజా సూపర్ నేపియర్ & హైబ్రిడ్ మొక్కజొన్న మేత. 50 కేజీల బండిల్.',
          date: '1 రోజు క్రితం',
        ),
        MarketItem(
          id: 'item_4',
          title: 'ఉస్మానాబాది మేక (చూడి)',
          categoryKey: 'goat',
          price: '₹ 14,000',
          location: 'సోలాపూర్, మహారాష్ట్ర',
          imageAsset: 'assets/images/market_item_goat_osmanabadi.png',
          sellerName: 'బాలు కదమ్',
          sellerPhone: '9822345678',
          details: '3 నెలల చూడి, ఆరోగ్యకరమైన ఉస్మానాబాది మేక. బరువు 35 కేజీలు.',
          date: '1 రోజు క్రితం',
        ),
        MarketItem(
          id: 'item_5',
          title: 'గిర్ ఆవు (స్వచ్ఛమైన దేశీ)',
          categoryKey: 'cow',
          price: '₹ 72,000',
          location: 'కొల్హాపూర్, మహారాష్ట్ర',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'తానాజీ జాదవ్',
          sellerPhone: '9822456789',
          details: 'A2 పాలు ఇచ్చే స్వచ్ఛమైన గిర్ ఆవు. రోజుకు 14 లీటర్ల పాలు.',
          date: '2 రోజుల క్రితం',
        ),
      ];
    } else if (lang == 'ta') {
      return [
        MarketItem(
          id: 'item_1',
          title: 'எச்.எஃப் பசு (பால் உற்பத்தி)',
          categoryKey: 'cow',
          price: '₹ 65,000',
          location: 'புனே, மகாராஷ்டிரா',
          imageAsset: 'assets/images/market_item_hf_cow.png',
          sellerName: 'சுரேஷ் பாட்டீல்',
          sellerPhone: '9822012345',
          details: 'பால் திறன்: நாள் ஒன்றுக்கு 18 லிட்டர். வயது: 4.5 ஆண்டுகள். தடுப்பூசி போடப்பட்டது.',
          date: '2 மணி நேரத்திற்கு முன்',
        ),
        MarketItem(
          id: 'item_2',
          title: 'முர்ரா எருமை',
          categoryKey: 'buffalo',
          price: '₹ 85,000',
          location: 'நாசிக், மகாராஷ்டிரா',
          imageAsset: 'assets/images/market_item_murrah_buffalo.png',
          sellerName: 'கணேஷ் தேஷ்முக்',
          sellerPhone: '9822123456',
          details: 'முதல் ஈத்து உயர் ரக முர்ரா எருமை. நாள் ஒன்றுக்கு 12 லிட்டர் பால்.',
          date: '5 மணி நேரத்திற்கு முன்',
        ),
        MarketItem(
          id: 'item_3',
          title: 'உயர்தர பசுந்தீவனம்',
          categoryKey: 'fodder',
          price: '₹ 450 / 50kg',
          location: 'அவுரங்காபாத், மகாராஷ்டிரா',
          imageAsset: 'assets/images/market_item_green_fodder.png',
          sellerName: 'ரமேஷ் ஷிண்டே',
          sellerPhone: '9822234567',
          details: 'புதிய சூப்பர் நேப்பியர் மற்றும் சோள பசுந்தீவனம். 50 கிலோ கட்டு.',
          date: '1 நாள் முன்',
        ),
        MarketItem(
          id: 'item_4',
          title: 'உஸ்மானாபாதி ஆடு (சினை)',
          categoryKey: 'goat',
          price: '₹ 14,000',
          location: 'சோலாப்பூர், மகாராஷ்டிரா',
          imageAsset: 'assets/images/market_item_goat_osmanabadi.png',
          sellerName: 'பாலு கதம்',
          sellerPhone: '9822345678',
          details: '3 மாத சினை, ஆரோக்கியமான உஸ்மானாபாதி ஆடு. எடை 35 கிலோ.',
          date: '1 நாள் முன்',
        ),
        MarketItem(
          id: 'item_5',
          title: 'கிர் பசு (தூய நாட்டு ரகம்)',
          categoryKey: 'cow',
          price: '₹ 72,000',
          location: 'கோலாப்பூர், மகாராஷ்டிரா',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'தானாஜி ஜாதவ்',
          sellerPhone: '9822456789',
          details: 'A2 பால் தரும் தூய கிர் பசு. 14 லிட்டர் பால் திறன்.',
          date: '2 நாட்கள் முன்',
        ),
      ];
    }

    // Default 'en' (English)
    return [
      MarketItem(
        id: 'item_1',
        title: 'HF Cow (Milking)',
        categoryKey: 'cow',
        price: '₹ 65,000',
        location: 'Pune, Maharashtra',
        imageAsset: 'assets/images/market_item_hf_cow.png',
        sellerName: 'Suresh Patil',
        sellerPhone: '9822012345',
        details: 'Milk yield: 18 Liters/day. Age: 4.5 years. Fully vaccinated, healthy and calm.',
        date: '2 hours ago',
      ),
      MarketItem(
        id: 'item_2',
        title: 'Murrah Buffalo',
        categoryKey: 'buffalo',
        price: '₹ 85,000',
        location: 'Nashik, Maharashtra',
        imageAsset: 'assets/images/market_item_murrah_buffalo.png',
        sellerName: 'Ganesh Deshmukh',
        sellerPhone: '9822123456',
        details: 'First lactation high genetic merit Murrah buffalo. 12L daily yield, high fat content.',
        date: '5 hours ago',
      ),
      MarketItem(
        id: 'item_3',
        title: 'High Quality Green Fodder',
        categoryKey: 'fodder',
        price: '₹ 450 / 50kg',
        location: 'Aurangabad, Maharashtra',
        imageAsset: 'assets/images/market_item_green_fodder.png',
        sellerName: 'Ramesh Shinde',
        sellerPhone: '9822234567',
        details: 'Fresh Super Napier & hybrid maize green fodder. 50kg bundle, direct farm harvest.',
        date: '1 day ago',
      ),
      MarketItem(
        id: 'item_4',
        title: 'Osmanabadi Goat (Pregnant)',
        categoryKey: 'goat',
        price: '₹ 14,000',
        location: 'Solapur, Maharashtra',
        imageAsset: 'assets/images/market_item_goat_osmanabadi.png',
        sellerName: 'Balu Kadam',
        sellerPhone: '9822345678',
        details: '3 months pregnant, healthy Osmanabadi breed. Weight 35kg, dewormed & vaccinated.',
        date: '1 day ago',
      ),
      MarketItem(
        id: 'item_5',
        title: 'Gir Cow (Pure Breed)',
        categoryKey: 'cow',
        price: '₹ 72,000',
        location: 'Kolhapur, Maharashtra',
        imageAsset: 'assets/images/market_item_gir_cow.png',
        sellerName: 'Tanaji Jadhav',
        sellerPhone: '9822456789',
        details: 'Pure Kathiawadi Gir cow with A2 milk quality. 14L daily capacity, calm temperament.',
        date: '2 days ago',
      ),
    ];
  }

  static List<MarketItem> _getSellItems(String lang) {
    if (lang == 'hi') {
      return [
        MarketItem(
          id: 'my_1',
          title: 'गीर बछिया (1.5 वर्ष)',
          categoryKey: 'cow',
          price: '₹ 38,000',
          location: 'पुणे, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'मेरा खाता (किसान)',
          sellerPhone: '9876543210',
          details: 'उत्कृष्ट वंशावली, स्वस्थ बछिया। एफएमडी व ब्रुसेलोसिस टीकाकरण पूर्ण।',
          isMyListing: true,
          date: 'सक्रिय विज्ञापन',
        ),
      ];
    } else if (lang == 'mr') {
      return [
        MarketItem(
          id: 'my_1',
          title: 'गीर कालवड (1.5 वर्षे)',
          categoryKey: 'cow',
          price: '₹ 38,000',
          location: 'पुणे, महाराष्ट्र',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'माझे खाते (शेतकरी)',
          sellerPhone: '9876543210',
          details: 'उत्कृष्ट वंशावळ, निरोगी कालवड. एफएमडी व ब्रुसेलोसिस लसीकरण पूर्ण.',
          isMyListing: true,
          date: 'सक्रिय जाहिरात',
        ),
      ];
    } else if (lang == 'te') {
      return [
        MarketItem(
          id: 'my_1',
          title: 'గిర్ దూడ (1.5 సం.)',
          categoryKey: 'cow',
          price: '₹ 38,000',
          location: 'పూణే, మహారాష్ట్ర',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'నా ఖాతా (రైతు)',
          sellerPhone: '9876543210',
          details: 'మంచి వంశావళి, ఆరోగ్యకరమైన దూడ. టీకాలు పూర్తయ్యాయి.',
          isMyListing: true,
          date: 'యాక్టివ్ ప్రకటన',
        ),
      ];
    } else if (lang == 'ta') {
      return [
        MarketItem(
          id: 'my_1',
          title: 'கிர் கன்று (1.5 ஆண்டுகள்)',
          categoryKey: 'cow',
          price: '₹ 38,000',
          location: 'புனே, மகாராஷ்டிரா',
          imageAsset: 'assets/images/market_item_gir_cow.png',
          sellerName: 'எனது கணக்கு (விவசாயி)',
          sellerPhone: '9876543210',
          details: 'சிறந்த பரம்பரை, ஆரோக்கியமான கன்றுக்குட்டி. தடுப்பூசி போடப்பட்டது.',
          isMyListing: true,
          date: 'செயலில் உள்ள விளம்பரம்',
        ),
      ];
    }
    return [
      MarketItem(
        id: 'my_1',
        title: 'Gir Heifer (1.5 Years)',
        categoryKey: 'cow',
        price: '₹ 38,000',
        location: 'Pune, Maharashtra',
        imageAsset: 'assets/images/market_item_gir_cow.png',
        sellerName: 'My Account (Farmer)',
        sellerPhone: '9876543210',
        details: 'Excellent pedigree, healthy heifer. FMD & Brucellosis vaccinated.',
        isMyListing: true,
        date: 'Active Listing',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketItem> get _filteredBuyItems {
    final query = _searchController.text.trim().toLowerCase();
    return _buyItems.where((item) {
      final matchesCategory = _selectedCategoryKey.isEmpty || item.categoryKey == _selectedCategoryKey;
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.price.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  List<MarketItem> get _filteredSellItems {
    final query = _searchController.text.trim().toLowerCase();
    return _mySellItems.where((item) {
      final matchesCategory = _selectedCategoryKey.isEmpty || item.categoryKey == _selectedCategoryKey;
      final matchesQuery = query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _handleBack() {
    if (widget.onBackToHome != null) {
      widget.onBackToHome!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _handleNavTap(int index) {
    if (widget.onNavTap != null) {
      widget.onNavTap!(index);
    } else {
      if (index == 0) {
        _handleBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SessionManager(),
      builder: (context, _) {
        _syncItemsForLanguage(SessionManager().language);

        return Scaffold(
          backgroundColor: _bg,
          extendBody: true,
          bottomNavigationBar: widget.onNavTap != null
              ? null
              : FloatingNavBar(
                  currentIndex: 2,
                  onTap: _handleNavTap,
                ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                _buildTabSwitcher(),
                const SizedBox(height: 12),
                _buildCategoryRow(),
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 95),
                    physics: const BouncingScrollPhysics(),
                    child: _selectedTab == 0 ? _buildBuyContent() : _buildSellContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // APP BAR
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          InkWell(
            onTap: _handleBack,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF1B2A1E),
                size: 26,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'market_title'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A1E),
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance back button
        ],
      ),
    );
  }

  // TAB SWITCHER (खरेदी करा / विक्री करा)
  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? _orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _selectedTab == 0
                      ? [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'market_buy'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _selectedTab == 0 ? Colors.white : const Color(0xFF424242),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? _orange : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _selectedTab == 1
                      ? [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'market_sell'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _selectedTab == 1 ? Colors.white : const Color(0xFF424242),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CATEGORIES HORIZONTAL ROW
  Widget _buildCategoryRow() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final key = cat['key']!;
          final isSelected = _selectedCategoryKey == key;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryKey = isSelected ? '' : key;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? _orange : Colors.grey.shade200,
                  width: isSelected ? 1.8 : 1.1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _orange.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    cat['image']!,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets_rounded,
                      size: 26,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cat['labelKey']!.tr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? _orange : const Color(0xFF424242),
                      ),
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

  // SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B2A1E),
        ),
        decoration: InputDecoration(
          hintText: 'market_search_hint'.tr,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF1B2A1E),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // BUY CONTENT
  Widget _buildBuyContent() {
    final items = _filteredBuyItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'no_items_found'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((item) => _buildProductCard(item, isSellerView: false)).toList(),
    );
  }

  // SELL CONTENT
  Widget _buildSellContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CTA Banner to Sell
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFCC80)),
            boxShadow: [
              BoxShadow(
                color: _orange.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_business_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'sell_banner_title'.tr,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B2A1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'sell_banner_subtitle'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF616161),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _openPostAdSheet(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'market_post_ad'.tr,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section Title: My Listings
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'market_my_listings'.tr} (${_filteredSellItems.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B2A1E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (_filteredSellItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            alignment: Alignment.center,
            child: Text(
              'no_listings_yet'.tr,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          )
        else
          ..._filteredSellItems.map((item) => _buildProductCard(item, isSellerView: true)),
      ],
    );
  }

  // PRODUCT CARD MATCHING USER REFERENCE SCREENSHOT
  Widget _buildProductCard(MarketItem item, {required bool isSellerView}) {
    final isFav = _favoriteIds.contains(item.id);

    return InkWell(
      onTap: () => _showItemDetailsSheet(context, item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail Image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 82,
                height: 82,
                color: const Color(0xFFF1F8E9),
                child: Image.asset(
                  item.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.pets_rounded,
                    color: _green,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1B2A1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        item.price,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: _green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isGovVerified
                              ? const Color(0xFFDCFCE7)
                              : (item.verificationStatus == 'REJECTED'
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFFEF3C7)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: item.isGovVerified
                                ? const Color(0xFF86EFAC)
                                : (item.verificationStatus == 'REJECTED'
                                    ? const Color(0xFFFCA5A5)
                                    : const Color(0xFFFDE68A)),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          item.isGovVerified
                              ? '🛡️ Govt Verified'
                              : (item.verificationStatus == 'REJECTED'
                                  ? '❌ Rejected'
                                  : '⏳ Govt Review'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: item.isGovVerified
                                ? const Color(0xFF15803D)
                                : (item.verificationStatus == 'REJECTED'
                                    ? const Color(0xFFB91C1C)
                                    : const Color(0xFFB45309)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Action: Heart (Buy view) or Active Badge (Sell view)
            if (!isSellerView)
              IconButton(
                onPressed: () {
                  setState(() {
                    if (isFav) {
                      _favoriteIds.remove(item.id);
                    } else {
                      _favoriteIds.add(item.id);
                    }
                  });
                },
                icon: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? const Color(0xFFE53935) : Colors.grey.shade400,
                  size: 24,
                ),
              )
            else
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'delete') {
                    setState(() {
                      _mySellItems.removeWhere((x) => x.id == item.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('listing_deleted'.tr)),
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('edit'.tr),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text('delete'.tr, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ITEM DETAILS MODAL
  void _showItemDetailsSheet(BuildContext context, MarketItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Drag Bar
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        height: 210,
                        color: const Color(0xFFF1F8E9),
                        child: Image.asset(
                          item.imageAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.pets_rounded,
                            color: _green,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1B2A1E),
                            ),
                          ),
                        ),
                        Text(
                          item.price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Location Pin
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: _orange),
                        const SizedBox(width: 4),
                        Text(
                          item.location,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    // Details
                    Text(
                      'details_and_info'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.details,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seller Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF9F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded, color: _green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.sellerName,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1B2A1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, size: 14, color: _green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'verified_livestock_farmer'.tr,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Call & Contact Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${'seller_contact'.tr}: ${item.sellerPhone}'),
                              backgroundColor: _green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                        label: Text(
                          '${'market_contact_seller'.tr} (${item.sellerPhone})',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // POST NEW AD MODAL SHEET
  void _openPostAdSheet(BuildContext context) {
    final cached = FarmerApiService.getCachedAnimals();
    final titleController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCat = 'cow';
    AnimalModel? pickedAnimal = cached.isNotEmpty ? cached.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'market_post_ad'.tr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B2A1E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Option 1: Pick from My Livestock
                      if (cached.isNotEmpty) ...[
                        Text(
                          'pick_from_livestock'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B2A1E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cached.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final a = cached[i];
                              final isSel = pickedAnimal?.id == a.id;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    pickedAnimal = a;
                                    titleController.text = '${a.breed} ${a.species} (${a.name})';
                                    selectedCat = a.species.toLowerCase().contains('buffalo') ? 'buffalo' : 'cow';
                                  });
                                },
                                child: Container(
                                  width: 120,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFFE8F5E9) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSel ? _green : Colors.grey.shade200,
                                      width: isSel ? 1.8 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          a.assetImage,
                                          width: 34,
                                          height: 34,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.name,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                color: isSel ? _green : const Color(0xFF1B2A1E),
                                              ),
                                              maxLines: 1,
                                            ),
                                            Text(
                                              a.species,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Option 2: Category Selector
                      Text(
                        'select_category'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((c) {
                          final isSel = selectedCat == c['key'];
                          return InkWell(
                            onTap: () => setModalState(() => selectedCat = c['key']!),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFFFF3E0) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSel ? _orange : Colors.grey.shade300),
                              ),
                              child: Text(
                                c['labelKey']!.tr,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSel ? _orange : const Color(0xFF424242),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Title
                      Text(
                        'ad_title'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'ad_title_hint'.tr,
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Text(
                        '४. ${'market_price'.tr} (₹)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2A1E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'price_hint'.tr,
                          prefixText: '₹ ',
                          filled: true,
                          fillColor: const Color(0xFFF9F9F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Publish Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            final priceText = priceController.text.trim();
                            if (title.isEmpty || priceText.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('fill_all_fields'.tr)),
                              );
                              return;
                            }

                            final String priceStr = priceText.startsWith('₹') ? priceText : '₹ $priceText';
                            final String img = pickedAnimal != null
                                ? pickedAnimal!.assetImage
                                : selectedCat == 'buffalo'
                                    ? 'assets/images/market_item_murrah_buffalo.png'
                                    : selectedCat == 'fodder'
                                        ? 'assets/images/market_item_green_fodder.png'
                                        : 'assets/images/market_item_hf_cow.png';

                            final lang = SessionManager().language;
                            final defaultLoc = (lang == 'hi' || lang == 'mr') ? 'पुणे, महाराष्ट्र' : 'Pune, Maharashtra';
                            final defaultSeller = lang == 'hi'
                                ? 'मेरा खाता (किसान)'
                                : lang == 'mr'
                                    ? 'माझे खाते (शेतकरी)'
                                    : 'My Account (Farmer)';
                            final defaultDetails = lang == 'hi'
                                ? 'किसान द्वारा सीधे बिक्री के लिए उपलब्ध।'
                                : lang == 'mr'
                                    ? 'शेतकऱ्याने थेट विक्रीसाठी उपलब्ध केलेले उत्पादन.'
                                    : 'Direct farm product available for sale.';
                            final defaultDate = lang == 'hi'
                                ? 'अभी'
                                : lang == 'mr'
                                    ? 'आताच'
                                    : 'Just now';

                            final newItem = MarketItem(
                              id: 'my_${DateTime.now().millisecondsSinceEpoch}',
                              title: title,
                              categoryKey: selectedCat,
                              price: priceStr,
                              location: defaultLoc,
                              imageAsset: img,
                              sellerName: defaultSeller,
                              sellerPhone: SessionManager().currentUser?.phone ?? '9876543210',
                              details: defaultDetails,
                              isMyListing: true,
                              date: defaultDate,
                              verificationStatus: 'PENDING',
                              isGovVerified: false,
                            );

                            setState(() {
                              _mySellItems.insert(0, newItem);
                            });

                            Navigator.pop(sheetCtx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  (lang == 'hi')
                                      ? 'विज्ञापन सत्यापन के लिए सरकार को भेजा गया। अनुमोदन के बाद बाजार में दिखाई देगा।'
                                      : (lang == 'mr')
                                          ? 'जाहिरात शासकीय पडताळणीसाठी पाठवली आहे. मंजुरीनंतर बाजारात दिसेल.'
                                          : 'Ad submitted for Government Verification. It will be public once approved.',
                                ),
                                backgroundColor: _green,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'publish_ad'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
