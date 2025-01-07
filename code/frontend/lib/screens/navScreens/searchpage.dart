import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hanini_frontend/models/colors.dart';
import 'package:hanini_frontend/screens/services/service.dart';
import 'package:hanini_frontend/localization/app_localization.dart';
import 'package:hanini_frontend/services/data_manager.dart'; // Import

class SearchPage extends StatefulWidget {
  final String? preSelectedWorkDomain;

  const SearchPage({
    Key? key,
    this.preSelectedWorkDomain,
  }) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> filteredServices = [];
  List<String> likedServiceIds = [];
  final TextEditingController _searchController = TextEditingController();
  double _minRating = 0.0;
  bool _isRatingFilterApplied = false;
  RangeValues _priceRange = const RangeValues(0, 19999);
  bool _isPriceFilterApplied = false;
  List<String> _selectedWorkChoices = [];
  Map<String, Map<String, String>> _workChoicesMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterServices);
    _loadWorkChoices().then((_) => _initializeData());
  }

  Future<void> _loadWorkChoices() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Metadata')
          .doc('WorkChoices')
          .get();

      if (doc.exists) {
        final choices = doc.data()?['choices'] as List<dynamic>;
        _workChoicesMap = {};

        for (var choice in choices) {
          final id = choice['id'] as String;
          _workChoicesMap[id] = {
            'en': choice['en'],
            'fr': choice['fr'],
            'ar': choice['ar'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error loading work choices: $e');
    }
  }

  String getLocalizedWorkChoice(String id) {
    final locale = Localizations.localeOf(context).languageCode;
    return _workChoicesMap[id]?[locale] ?? _workChoicesMap[id]?['en'] ?? id;
  }

  List<String> get _allWorkChoiceIds => _workChoicesMap.keys.toList();

  void _showFilterDialog() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.filterServices,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    ClipOval(
                      child: Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                          hoverColor: Colors.grey.shade100,
                          splashColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating Section with enhanced visuals
                            _buildEnhancedFilterSection(
                              title: localizations.minimumRating,
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber,
                              content: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildRatingBadge('0.0'),
                                      _buildRatingBadge(
                                          '${_minRating.toStringAsFixed(1)} ★'),
                                      _buildRatingBadge('5.0'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: Colors.amber.shade400,
                                      inactiveTrackColor: Colors.grey.shade200,
                                      thumbColor: Colors.amber.shade500,
                                      overlayColor:
                                          Colors.amber.withOpacity(0.12),
                                      valueIndicatorColor:
                                          Colors.amber.shade500,
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _minRating,
                                      min: 0,
                                      max: 5,
                                      divisions: 10,
                                      label: _minRating.toStringAsFixed(1),
                                      onChanged: (value) {
                                        setState(() {
                                          _minRating = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Price Range Section with enhanced visuals
                            _buildEnhancedFilterSection(
                              title: localizations.priceRange,
                              icon: Icons.payments_rounded,
                              iconColor: Colors.green.shade500,
                              content: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildPriceBadge(
                                        '${_priceRange.start.toInt()} ${localizations.dzd}',
                                        Colors.green.shade50,
                                        Colors.green.shade700,
                                      ),
                                      _buildPriceBadge(
                                        _priceRange.end == 19999
                                            ? '∞'
                                            : '${_priceRange.end.toInt()} ${localizations.dzd}',
                                        Colors.green.shade50,
                                        Colors.green.shade700,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: Colors.green.shade400,
                                      inactiveTrackColor: Colors.grey.shade200,
                                      thumbColor: Colors.green.shade500,
                                      overlayColor:
                                          Colors.green.withOpacity(0.12),
                                      valueIndicatorColor:
                                          Colors.green.shade500,
                                      trackHeight: 4,
                                    ),
                                    child: RangeSlider(
                                      values: _priceRange,
                                      min: 0,
                                      max: 19999,
                                      divisions: 1000,
                                      labels: RangeLabels(
                                        _priceRange.start.toStringAsFixed(0),
                                        _priceRange.end == 19999
                                            ? '∞'
                                            : _priceRange.end
                                                .toStringAsFixed(0),
                                      ),
                                      onChanged: (values) {
                                        setState(() {
                                          _priceRange = values;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Work Domain Section with enhanced visuals
                            _buildEnhancedFilterSection(
                              title: localizations.workDomain,
                              icon: Icons.work_rounded,
                              iconColor: Colors.indigo.shade400,
                              content: Container(
                                height: 160,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.all(12),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _allWorkChoiceIds.map((choiceId) {
                                      final isSelected = _selectedWorkChoices
                                          .contains(choiceId);
                                      return FilterChip(
                                        label: Text(
                                          getLocalizedWorkChoice(choiceId),
                                          style: GoogleFonts.poppins(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: Colors.indigo.shade400,
                                        checkmarkColor: Colors.white,
                                        backgroundColor: Colors.white,
                                        elevation: 0,
                                        pressElevation: 0,
                                        showCheckmark: true,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          side: BorderSide(
                                            color: isSelected
                                                ? Colors.indigo.shade400
                                                : Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedWorkChoices
                                                  .add(choiceId);
                                            } else {
                                              _selectedWorkChoices
                                                  .remove(choiceId);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Enhanced Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _minRating = 0.0;
                            _priceRange = const RangeValues(0, 19999);
                            _selectedWorkChoices.clear();
                            _isRatingFilterApplied = false;
                            _isPriceFilterApplied = false;
                            _filterServices();
                          });
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          localizations.clearFilters,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isRatingFilterApplied = _minRating > 0.0;
                            _isPriceFilterApplied = _priceRange.start > 0 ||
                                _priceRange.end < 19999;
                            _filterServices();
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          localizations.applyFilters,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedFilterSection({
    required String title,
    required IconData icon,
    required Widget content,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildRatingBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.amber.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriceBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Set<String> favoriteServices = {};
  String? currentUserId;

  Future<void> _fetchUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint('No user logged in');
        return;
      }

      currentUserId = user.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userDoc.exists) {
        setState(() {
          favoriteServices = Set<String>.from(
            userDoc.data()?['favorites'] ?? [],
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      final dataManager = DataManager();
      final providers = dataManager.getCachedProviders();
      
      if (providers.isEmpty) {
        debugPrint('⚠️ No cached providers found, attempting to reload cache');
        await dataManager.reloadCache();
        final refreshedProviders = dataManager.getCachedProviders();
        setState(() {
          services = refreshedProviders;
          filteredServices = refreshedProviders;
        });
      } else {
        debugPrint('📦 Loaded ${providers.length} providers from cache');
        setState(() {
          services = providers;
          filteredServices = providers;
        });
      }

      // Apply initial work domain filter if provided
      if (widget.preSelectedWorkDomain != null) {
        _selectedWorkChoices = [widget.preSelectedWorkDomain!];
        _filterServices();
      }
      
    } catch (e) {
      debugPrint('❌ Error loading cached providers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadLikedServices() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          likedServiceIds =
              List<String>.from(userDoc.data()?['favorites'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading liked services: $e');
    }
  }

  void _filterServices() {
    if (services.isEmpty) return;

    List<Map<String, dynamic>> results = List.from(services);

    // Apply text search filter with null checks
    final searchTerm = _searchController.text.toLowerCase();
    if (searchTerm.isNotEmpty) {
      results = results.where((service) {
        final profession = (service['basicInfo'] as Map<String, dynamic>?)?['profession']?.toString().toLowerCase() ?? '';
        final name = service['name']?.toString().toLowerCase() ?? '';
        return profession.contains(searchTerm) || name.contains(searchTerm);
      }).toList();
    }

    // Apply rating filter with null check
    if (_isRatingFilterApplied && _minRating > 0.0) {
      results = results.where((service) {
        final rating = (service['rating'] as num?)?.toDouble() ?? 0.0;
        return rating >= _minRating;
      }).toList();
    }

    // Apply price filter with null check
    if (_isPriceFilterApplied) {
      results = results.where((service) {
        final price = (service['basicInfo']?['hourlyRate'] as num?)?.toDouble() ?? 0.0;
        return price >= _priceRange.start && price <= _priceRange.end;
      }).toList();
    }

    // Apply work domain filter with null check
    if (_selectedWorkChoices.isNotEmpty) {
      results = results.where((service) {
        final workChoice = service['selectedWorkChoice']?.toString() ?? '';
        return _selectedWorkChoices.contains(workChoice);
      }).toList();
    }

    setState(() {
      filteredServices = results;
    });
  }

  int _calculateLevenshteinDistance(String s1, String s2) {
    List<List<int>> distances = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) distances[i][0] = i;
    for (int j = 0; j <= s2.length; j++) distances[0][j] = j;

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        distances[i][j] = min(
          min(distances[i - 1][j] + 1, distances[i][j - 1] + 1),
          distances[i - 1][j - 1] + cost,
        );
      }
    }

    return distances[s1.length][s2.length];
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    int halfStars = (rating % 1 >= 0.5) ? 1 : 0;
    int emptyStars = 5 - fullStars - halfStars;

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star, color: Colors.amber, size: 20),
        for (int i = 0; i < halfStars; i++)
          const Icon(Icons.star_half, color: Colors.amber, size: 20),
        for (int i = 0; i < emptyStars; i++)
          const Icon(Icons.star_border, color: Colors.grey, size: 20),
      ],
    );
  }

  String get searchHint {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') {
      return "ابحث عن خدمات...";
    } else if (locale == 'fr') {
      return "Recherchez des services...";
    } else {
      return "Search for services...";
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return Text("Nothing");

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(localizations),
            const SizedBox(height: 10),
            _buildAppliedFilters(),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: filteredServices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  final service = filteredServices[index];
                  final serviceId = service['uid'];
                  return _buildServiceItem(service, false, serviceId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations localizations) {
    return Container(
      margin: EdgeInsets.only(top: 10, left: 18, right: 18),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xff1d1617).withOpacity(0.11),
            blurRadius: 40,
            spreadRadius: 0,
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.all(15),
          hintText: localizations.searchHint,
          hintStyle: TextStyle(
            color: const Color.fromARGB(153, 170, 71, 188),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
                'assets/search_icons/Search.svg'), // Replace with your own asset
          ),
          suffixIcon: Container(
            width: 100,
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  VerticalDivider(
                    color: Colors.black,
                    indent: 10,
                    endIndent: 10,
                    thickness: 0.1,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: GestureDetector(
                      onTap:
                          _showFilterDialog, // Trigger filter dialog on press
                      child: SvgPicture.asset(
                        'assets/search_icons/Filter.svg', // Replace with your own asset
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildAppliedFilters() {
    List<Widget> filters = [];
    if (_isRatingFilterApplied && _minRating > 0.0) {
      filters.add(
          _buildFilterChip('Min Rating: ${_minRating.toStringAsFixed(1)}', () {
        setState(() {
          _minRating = 0.0;
          _isRatingFilterApplied = false;
          _filterServices();
        });
      }));
    }
    if (_isPriceFilterApplied &&
        (_priceRange.start > 0 || _priceRange.end < 19999)) {
      filters.add(_buildFilterChip(
          'Price: ${_priceRange.start.toStringAsFixed(0)} - ${_priceRange.end == 19999 ? '∞' : _priceRange.end.toStringAsFixed(0)} DZD',
          () {
        setState(() {
          _priceRange = const RangeValues(0, 19999);
          _isPriceFilterApplied = false;
          _filterServices();
        });
      }));
    }
    if (_selectedWorkChoices.isNotEmpty) {
      filters.addAll(_selectedWorkChoices
          .map((choiceId) =>
              _buildFilterChip(getLocalizedWorkChoice(choiceId), () {
                setState(() {
                  _selectedWorkChoices.remove(choiceId);
                  _filterServices();
                });
              }))
          .toList());
    }

    // Return empty container if no filters
    if (filters.isEmpty) {
      return Container();
    }

    // Return scrollable container with filters
    return Container(
      height: 50, // Fixed height for the filter area
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Horizontal scrolling
        child: Row(
          children: filters
              .map((filter) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: filter,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    // Determine filter type and colors based on label content
    List<Color> gradientColors;
    Color shadowColor;

    if (label.contains('Rating')) {
      gradientColors = [Colors.amber.shade300, Colors.amber.shade400];
      shadowColor = Colors.amber.shade100;
    } else if (label.contains('Price')) {
      gradientColors = [Colors.green.shade300, Colors.green.shade400];
      shadowColor = Colors.green.shade100;
    } else {
      // Work Domain filters
      gradientColors = [Colors.indigo.shade300, Colors.indigo.shade400];
      shadowColor = Colors.indigo.shade100;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 200),
        child: Tooltip(
          message: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  GestureDetector(
                    onTap: onDeleted,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(
      Map<String, dynamic> service, bool isFavorite, String serviceId) {
    // Add null checks for nested data
    final profession = (service['basicInfo'] as Map<String, dynamic>?)?['profession']?.toString() ?? 'N/A';
    final name = service['name']?.toString() ?? 'Unknown';
    final photoUrl = service['photoURL']?.toString() ?? '';
    final rating = (service['rating'] as num?)?.toDouble() ?? 0.0;
    final price = (service['basicInfo']?['hourlyRate'] as num?)?.toDouble() ?? 0.0;

    // Use favoriteServices instead of isFavorite parameter
    final isServiceFavorite = favoriteServices.contains(serviceId);

    return GestureDetector(
      onTap: () async {
        // Print message in terminal
        debugPrint('Navigating to FullProfilePage with providerId: $serviceId');

        // Increment the provider's click_count in the database
        try {
          final providerDoc =
              FirebaseFirestore.instance.collection('users').doc(serviceId);
          await providerDoc.update({
            'click_count': FieldValue.increment(1),
          });

          // Increment the click count for the provider in the user's document
          if (currentUserId != null) {
            final userDoc = FirebaseFirestore.instance
                .collection('users')
                .doc(currentUserId);
            await userDoc.update({
              'click_count_per_service.$serviceId': FieldValue.increment(1),
            });
          }
        } catch (e) {
          debugPrint('Error incrementing click_count: $e');
        }

        // Navigate to FullProfilePage with the selected service's ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceProviderFullProfile(
              providerId: serviceId,
            ),
          ),
        );
      },
      child: Card(
        color: AppColors.tempColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) {
                          debugPrint('Error loading image: $error');
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.tempColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profession,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.mainColor,
                          ),
                          maxLines: 1,
                        ),
                        _buildStarRating(rating),
                        const SizedBox(height: 2),
                        Text(
                          'DZD ${price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  isServiceFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isServiceFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: () => toggleFavorite(service),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleFavorite(Map<String, dynamic> service) async {
    if (currentUserId == null) {
      // Show a dialog or snackbar to prompt login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add favorites')),
      );
      return;
    }

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);

      final serviceId = service['docId'] ?? service['uid'];

      if (favoriteServices.contains(serviceId)) {
        // Remove from favorites
        await userDoc.update({
          'favorites': FieldValue.arrayRemove([serviceId]),
        });
        setState(() {
          favoriteServices.remove(serviceId);
        });
      } else {
        // Add to favorites
        await userDoc.update({
          'favorites': FieldValue.arrayUnion([serviceId]),
        });
        setState(() {
          favoriteServices.add(serviceId);
        });
      }
    } catch (e) {
      debugPrint('Error updating favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorites')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
