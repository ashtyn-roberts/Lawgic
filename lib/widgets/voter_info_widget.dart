// voter_info_widget.dart

import 'package:flutter/material.dart';
import '../services/voter_service.dart';

class VoterInfoWidget extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const VoterInfoWidget({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  State<VoterInfoWidget> createState() => _VoterInfoWidgetState();
}

class _VoterInfoWidgetState extends State<VoterInfoWidget> {
  final VoterService _voterService = VoterService(
    // Replace with your actual API URL
    baseUrl: 'http://localhost:5000',
  );

  bool _isLoading = false;
  VoterInfo? _voterInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVoterInfo();
  }

  Future<void> _fetchVoterInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _voterService.getVoterInfoFromUser(widget.userData);

      setState(() {
        _isLoading = false;
        if (response.success && response.data != null) {
          _voterInfo = response.data;
        } else {
          _error = response.error ?? 'Failed to fetch voter information';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voter Registration Info',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!_isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchVoterInfo,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _buildErrorWidget()
            else if (_voterInfo != null)
              _buildVoterInfoContent()
            else
              const Center(
                child: Text('No voter information available'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoterInfoContent() {
    return Column(
      children: [
        if (_voterInfo!.name != null)
          _buildInfoRow('Name', _voterInfo!.name!, Icons.person),
        if (_voterInfo!.status != null)
          _buildInfoRow(
            'Status',
            _voterInfo!.status!,
            Icons.check_circle,
            statusColor: _voterInfo!.status!.toLowerCase() == 'active'
                ? Colors.green
                : Colors.orange,
          ),
        if (_voterInfo!.parish != null)
          _buildInfoRow('Parish', _voterInfo!.parish!, Icons.location_city),
        if (_voterInfo!.wardPrecinct != null)
          _buildInfoRow('Ward/Precinct', _voterInfo!.wardPrecinct!, Icons.map),
        if (_voterInfo!.party != null)
          _buildInfoRow('Party', _voterInfo!.party!, Icons.how_to_vote),
        if (_voterInfo!.congressionalDistrict != null)
          _buildInfoRow(
            'Congressional District',
            _voterInfo!.congressionalDistrict!,
            Icons.account_balance,
          ),
        if (_voterInfo!.senateDistrict != null)
          _buildInfoRow(
            'Senate District',
            _voterInfo!.senateDistrict!,
            Icons.gavel,
          ),
        if (_voterInfo!.houseDistrict != null)
          _buildInfoRow(
            'House District',
            _voterInfo!.houseDistrict!,
            Icons.home_work,
          ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: statusColor ?? Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

