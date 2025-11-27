import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MeditationScreen extends StatelessWidget {
  const MeditationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meditation'),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Your Meditation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildMeditationCard(
                    context,
                    'Sleep & Unwind',
                    'Guided sleep meditation for better rest',
                    Icons.nightlight_round,
                    Colors.indigo,
                    'g0jfhRcXtLQ?si=M--kU1H2jrg_MdYQ', // REAL YouTube video ID
                  ),
                  const SizedBox(height: 16),
                  _buildMeditationCard(
                    context,
                    'Relaxing',
                    'Calming meditation for stress relief',
                    Icons.self_improvement,
                    Colors.teal,
                    'tuiQxBB67wI?si=4u1umssqihSyThU0', // REAL YouTube video ID
                  ),
                  const SizedBox(height: 16),
                  _buildMeditationCard(
                    context,
                    'Nature',
                    'Sounds of nature for peace and focus',
                    Icons.park,
                    Colors.green,
                    'AImuCtIokl0?si=IfXVr4pedNz1psFo', // REAL YouTube video ID
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeditationCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    String videoId, // This is the YouTube video ID
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => YouTubeMeditationScreen(
                videoId: videoId, // Pass the YouTube video ID
                title: title,
                backgroundColor: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class YouTubeMeditationScreen extends StatefulWidget {
  final String videoId; // This stores the YouTube video ID
  final String title;
  final Color backgroundColor;

  const YouTubeMeditationScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.backgroundColor,
  });

  @override
  State<YouTubeMeditationScreen> createState() => _YouTubeMeditationScreenState();
}

class _YouTubeMeditationScreenState extends State<YouTubeMeditationScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  void _initializeWebViewController() {
    final WebViewController controller = WebViewController();
    
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.setBackgroundColor(const Color(0x00000000));
    
    controller.setNavigationDelegate(NavigationDelegate(
      onPageStarted: (String url) {
        setState(() {
          _isLoading = true;
        });
      },
      onPageFinished: (String url) {
        setState(() {
          _isLoading = false;
        });
      },
    ));

    // THIS IS WHERE YOUTUBE VIDEO LOADS
    controller.loadRequest(
      Uri.parse('https://www.youtube.com/embed/${widget.videoId}?autoplay=1&playsinline=1'),
    );

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: widget.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: widget.backgroundColor,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}