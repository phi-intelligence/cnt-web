import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/section_container.dart';
import 'event_create_screen_web.dart';

class LocationPickerScreenWeb extends StatefulWidget {
  final LocationResult? initialLocation;

  const LocationPickerScreenWeb({super.key, this.initialLocation});

  @override
  State<LocationPickerScreenWeb> createState() => _LocationPickerScreenWebState();
}

class _LocationPickerScreenWebState extends State<LocationPickerScreenWeb> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showManualEntry = false;
  
  LocationResult? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _addressController.text = widget.initialLocation!.address;
      _latController.text = widget.initialLocation!.latitude.toString();
      _lngController.text = widget.initialLocation!.longitude.toString();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Use Nominatim (OpenStreetMap) for geocoding - free and no API key required
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
        ),
        headers: {
          'User-Agent': 'CNTMediaPlatform/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Location search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat']?.toString() ?? '') ?? 0.0;
    final lng = double.tryParse(result['lon']?.toString() ?? '') ?? 0.0;
    final address = result['display_name'] as String? ?? '';

    setState(() {
      _selectedLocation = LocationResult(
        latitude: lat,
        longitude: lng,
        address: address,
      );
      _addressController.text = address;
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _confirmManualEntry() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    final address = _addressController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter an address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = LocationResult(
        latitude: lat ?? 0.0,
        longitude: lng ?? 0.0,
        address: address,
      );
    });
  }

  void _confirmSelection() {
    if (_selectedLocation == null) {
      // Try to use manual entry
      _confirmManualEntry();
    }

    if (_selectedLocation != null) {
      Navigator.pop(context, _selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select or enter a location'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Location',
          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        actions: [
          if (_selectedLocation != null)
            TextButton.icon(
              onPressed: _confirmSelection,
              icon: Icon(Icons.check, color: AppColors.warmBrown),
              label: Text(
                'Confirm',
                style: TextStyle(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 64 : (isMediumScreen ? 32 : 16),
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Section
                SectionContainer(
                  showShadow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Search Location',
                        style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 16),
                      
                      // Search field
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search for a place...',
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.backgroundSecondary,
                          prefixIcon: Icon(Icons.search, color: AppColors.warmBrown),
                          suffixIcon: _isSearching
                              ? Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.warmBrown,
                                    ),
                                  ),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length >= 3) {
                            _searchLocation(value);
                          } else {
                            setState(() {
                              _searchResults = [];
                            });
                          }
                        },
                      ),
                      
                      // Search results
                      if (_searchResults.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderPrimary),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) => Divider(height: 1),
                            itemBuilder: (context, index) {
                              final result = _searchResults[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: AppColors.warmBrown,
                                ),
                                title: Text(
                                  result['display_name'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14),
                                ),
                                onTap: () => _selectSearchResult(result),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Selected location display
                if (_selectedLocation != null)
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Selected Location',
                              style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warmBrown.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.warmBrown,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedLocation!.address,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_selectedLocation!.latitude != 0.0 || _selectedLocation!.longitude != 0.0)
                                      Padding(
                                        padding: EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.clear, color: AppColors.textSecondary),
                                onPressed: () {
                                  setState(() {
                                    _selectedLocation = null;
                                    _addressController.clear();
                                    _latController.clear();
                                    _lngController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(height: 24),
                
                // Manual entry toggle
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showManualEntry = !_showManualEntry;
                    });
                  },
                  icon: Icon(
                    _showManualEntry ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.warmBrown,
                  ),
                  label: Text(
                    _showManualEntry ? 'Hide manual entry' : 'Enter manually',
                    style: TextStyle(
                      color: AppColors.warmBrown,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Manual entry section
                if (_showManualEntry) ...[
                  SizedBox(height: 16),
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Entry',
                          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 16),
                        
                        // Address field
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address *',
                          hint: 'Enter the full address',
                          icon: Icons.home,
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Coordinates row
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _latController,
                                label: 'Latitude (optional)',
                                hint: 'e.g., 51.5074',
                                icon: Icons.gps_fixed,
                                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                controller: _lngController,
                                label: 'Longitude (optional)',
                                hint: 'e.g., -0.1278',
                                icon: Icons.gps_fixed,
                                keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 16),
                        
                        Text(
                          'Tip: You can find coordinates by right-clicking on Google Maps',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _confirmManualEntry,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warmBrown,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text('Use This Location'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 32),
                
                // Confirm button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown,
                        AppColors.accentMain,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _selectedLocation != null ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: AppColors.warmBrown, size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ],
    );
  }
}

