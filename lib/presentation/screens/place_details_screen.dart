import 'package:flutter/material.dart';
import 'package:movidapp/data/models/place.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({Key? key, required this.place}) : super(key: key);

  @override
  _PlaceDetailsScreenState createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  double _sliderValue = 0;

  void _showCrowdReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Slider(
                            value: _sliderValue,
                            min: 0,
                            max: 2,
                            divisions: 2,
                            onChanged: (value) {
                              setState(() {
                                _sliderValue = value;
                              });
                            },
                            activeColor: _getSliderColor(_sliderValue),
                            inactiveColor: Colors.grey[300],
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("High"),
                          Text("Medium"),
                          Text("Low"),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _confirmAndSendReport,
                    child: const Text('OK'),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndSendReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Report'),
        content: const Text('Are you sure you want to report the crowd level?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _sendReport();
    }
  }

  Future<void> _sendReport() async {
    // Close the modal immediately for better UX
    Navigator.of(context).pop();

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send a report.')),
      );
      return;
    }

    try {
      // Check if the place already exists.
      final existingPlace = await supabase
          .from('place')
          .select('id')
          .eq('id', widget.place.id)
          .maybeSingle();

      // If the place doesn't exist, create it.
      if (existingPlace == null) {
        await supabase.from('place').insert({
          'id': widget.place.id,
          'name': widget.place.name,
          'address': widget.place.address,
          'latitude': widget.place.latitude,
          'longitude': widget.place.longitude,
          // TODO: This needs to be dynamic based on user input or other logic.
          'event_type_id': 1,
        });
      }

      // Now, insert the signal.
      final affluenceId = _sliderValue.toInt() + 1; // 1: low, 2: medium, 3: high
      await supabase.from('signal').insert({
        'place_id': widget.place.id,
        'affluence_id': affluenceId,
        'user': user.id,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending report: $error')),
      );
    }
  }

  Color _getSliderColor(double value) {
    if (value == 0) {
      return Colors.yellow;
    } else if (value == 1) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.place.photoUrl != null)
              Center(
                child: Image.network(
                  widget.place.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 100),
                ),
              ),
            const SizedBox(height: 16),
            Text(widget.place.address),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _showCrowdReportModal(context),
                child: const Text("Report Crowd"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
