import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/price_data.dart';
import '../../services/price_service.dart';

class PriceTrendsPage extends StatefulWidget {
  const PriceTrendsPage({super.key});

  @override
  State<PriceTrendsPage> createState() => _PriceTrendsPageState();
}

class _PriceTrendsPageState extends State<PriceTrendsPage> {
  final PriceService _priceService = PriceService();

  List<String> _farmerCrops = [];
  String? _selectedCrop;
  List<PriceData> _priceData = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Price statistics
  double _currentPrice = 0.0;
  double _highestPrice = 0.0;
  double _lowestPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFarmerCrops();
  }

  /// Load farmer's crops from Firestore
  Future<void> _loadFarmerCrops() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _hasError = true;
          _errorMessage = 'User not logged in';
          _isLoading = false;
        });
        return;
      }

      print('📊 Loading farmer crops for user: ${user.uid}');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();

        // Get crops array
        if (data != null && data.containsKey('crops')) {
          _farmerCrops = List<String>.from(data['crops'] ?? []);
        }

        // Fallback to single cropType for backward compatibility
        if (_farmerCrops.isEmpty &&
            data != null &&
            data.containsKey('cropType')) {
          _farmerCrops = [data['cropType']];
        }

        print('✅ Loaded ${_farmerCrops.length} crops: $_farmerCrops');

        // Auto-select first crop and fetch data
        if (_farmerCrops.isNotEmpty) {
          _selectedCrop = _farmerCrops.first;
          await _fetchPriceData(_selectedCrop!);
        } else {
          setState(() {
            _hasError = true;
            _errorMessage =
                'No crops found in your profile. Please update your profile.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'User profile not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading farmer crops: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load crops: $e';
        _isLoading = false;
      });
    }
  }

  /// Fetch price data for selected crop
  Future<void> _fetchPriceData(String cropName) async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      print('📈 Fetching price data for: $cropName');

      final data = await _priceService.fetchCropPrices(cropName);

      setState(() {
        _priceData = data;
        _isLoading = false;

        // Calculate statistics
        if (_priceData.isNotEmpty) {
          _calculateStatistics();
        } else {
          _currentPrice = 0.0;
          _highestPrice = 0.0;
          _lowestPrice = 0.0;
        }
      });

      print('✅ Loaded ${_priceData.length} price records');
    } catch (e) {
      print('❌ Error fetching price data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to fetch price data: $e';
        _isLoading = false;
      });
    }
  }

  /// Calculate price statistics from fetched data
  void _calculateStatistics() {
    if (_priceData.isEmpty) return;

    // Latest price (last item in sorted list)
    _currentPrice = _priceData.last.price;

    // Highest price
    _highestPrice = _priceData
        .map((e) => e.price)
        .reduce((a, b) => a > b ? a : b);

    // Lowest price
    _lowestPrice = _priceData
        .map((e) => e.price)
        .reduce((a, b) => a < b ? a : b);

    print(
      '📊 Statistics - Current: ₹$_currentPrice, High: ₹$_highestPrice, Low: ₹$_lowestPrice',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Price Trends'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? _buildErrorWidget()
          : _farmerCrops.isEmpty
          ? _buildEmptyState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Dropdown
          _buildCropDropdown(),
          const SizedBox(height: 20),

          // Price Summary Card
          if (_priceData.isNotEmpty) ...[
            _buildPriceSummaryCard(),
            const SizedBox(height: 20),
          ],

          // Line Chart Section
          _priceData.isEmpty ? _buildNoDataWidget() : _buildLineChart(),
        ],
      ),
    );
  }

  Widget _buildCropDropdown() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.grass, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedCrop,
                isExpanded: true,
                underline: const SizedBox(),
                items: _farmerCrops.map((crop) {
                  return DropdownMenuItem<String>(
                    value: crop,
                    child: Text(
                      crop,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newCrop) {
                  if (newCrop != null && newCrop != _selectedCrop) {
                    setState(() {
                      _selectedCrop = newCrop;
                    });
                    _fetchPriceData(newCrop);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    return Card(
      elevation: 3,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Current Price',
                  _currentPrice,
                  Colors.blue,
                  Icons.monetization_on,
                ),
                _buildStatItem(
                  'Highest',
                  _highestPrice,
                  Colors.green,
                  Icons.trending_up,
                ),
                _buildStatItem(
                  'Lowest',
                  _lowestPrice,
                  Colors.orange,
                  Icons.trending_down,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Trend (Last ${_priceData.length} Records)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (_highestPrice - _lowestPrice) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (_priceData.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _priceData.length) {
                            final date = _priceData[index].date;
                            return Text(
                              DateFormat('dd/MM').format(date),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  minX: 0,
                  maxX: (_priceData.length - 1).toDouble(),
                  minY: _lowestPrice * 0.95,
                  maxY: _highestPrice * 1.05,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _priceData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.price);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.withOpacity(0.3),
                            Colors.green.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.green.shade700,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final index = spot.x.toInt();
                          if (index >= 0 && index < _priceData.length) {
                            final priceData = _priceData[index];
                            final dateStr = DateFormat(
                              'dd MMM yyyy',
                            ).format(priceData.date);
                            return LineTooltipItem(
                              '$dateStr\n₹${priceData.price.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No market price data available',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different crop or check back later',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (_selectedCrop != null) {
                  _priceService.clearCache();
                  _fetchPriceData(_selectedCrop!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFarmerCrops,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grass, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Crops Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please update your profile with the crops you grow',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
