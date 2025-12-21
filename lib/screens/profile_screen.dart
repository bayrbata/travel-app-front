import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:travelapp/services/auth_service.dart';
import 'package:travelapp/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, String?> _userInfo = {};
  bool _isLoading = true;
  int _snowflakesInCircle = 0;
  final List<_SnowflakePosition> _snowflakes = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    // Initialize 5 draggable snowflakes
    _initializeSnowflakes();
  }

  void _initializeSnowflakes() {
    _snowflakes.clear();
    for (int i = 0; i < 5; i++) {
      _snowflakes.add(_SnowflakePosition(
        id: i,
        offset: Offset.zero,
        isInCircle: false,
      ));
    }
  }
  
  void _handleSnowflakeDropped(int snowflakeId) {
    setState(() {
      final snowflake = _snowflakes.firstWhere((s) => s.id == snowflakeId);
      if (!snowflake.isInCircle) {
        snowflake.isInCircle = true;
        _snowflakesInCircle++;
      }
    });
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await _authService.getUserInfo();
    setState(() {
      _userInfo = userInfo;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Гарах'),
        content: const Text('Та системээс гарахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Болих'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Гарах', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Профайл',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Snowman Circle with Drop Zone
                  Center(
                    child: _SnowmanCircle(
                      snowflakesInCircle: _snowflakesInCircle,
                      onSnowflakeDropped: _handleSnowflakeDropped,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Instruction text
                  Text(
                    '5 цасан ширхэгийг дугуй руу чирж тавина уу',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Draggable Snowflakes
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: _snowflakes.map((snowflake) {
                      return _DraggableSnowflake(
                        key: ValueKey(snowflake.id),
                        snowflakeId: snowflake.id,
                        isInCircle: snowflake.isInCircle,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Хэрэглэгчийн нэр
                  Text(
                    _userInfo['username'] ?? 'Нэргүй',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Имэйл
                  Text(
                    _userInfo['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Мэдээлэл картууд
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: const Text('Нэвтрэх нэр'),
                          subtitle: Text(
                            _userInfo['username'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.email,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: const Text('Имэйл'),
                          subtitle: Text(
                            _userInfo['email'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.badge,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: const Text('Хэрэглэгчийн ID'),
                          subtitle: Text(
                            _userInfo['id'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  const SizedBox(height: 24),
                  // Гарах товч
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Гарах'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Snowflake Position Class
class _SnowflakePosition {
  int id;
  Offset offset;
  bool isInCircle;

  _SnowflakePosition({
    required this.id,
    required this.offset,
    this.isInCircle = false,
  });
}

// Snowman Circle Widget with Drop Zone
class _SnowmanCircle extends StatelessWidget {
  final int snowflakesInCircle;
  final Function(int) onSnowflakeDropped;

  const _SnowmanCircle({
    required this.snowflakesInCircle,
    required this.onSnowflakeDropped,
  });

  @override
  Widget build(BuildContext context) {
    final snowmanOpacity = (snowflakesInCircle / 5.0).clamp(0.0, 1.0);
    
    return DragTarget<int>(
      onWillAccept: (data) => data != null,
      onAccept: (snowflakeId) {
        onSnowflakeDropped(snowflakeId);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: candidateData.isNotEmpty
                    ? Colors.green.withOpacity(0.5)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white,
            child: Opacity(
              opacity: snowmanOpacity,
              child: CustomPaint(
                size: const Size(120, 120),
                painter: _SnowmanPainter(),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Snowman Painter
class _SnowmanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final bottomY = size.height - 10;

    // Bottom circle
    final bottomCircle = Offset(centerX, bottomY - 30);
    canvas.drawCircle(bottomCircle, 35, fillPaint);
    canvas.drawCircle(bottomCircle, 35, strokePaint);

    // Middle circle
    final middleCircle = Offset(centerX, bottomY - 75);
    canvas.drawCircle(middleCircle, 28, fillPaint);
    canvas.drawCircle(middleCircle, 28, strokePaint);

    // Top circle
    final topCircle = Offset(centerX, bottomY - 110);
    canvas.drawCircle(topCircle, 22, fillPaint);
    canvas.drawCircle(topCircle, 22, strokePaint);

    // Eyes
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX - 8, bottomY - 115), 3, eyePaint);
    canvas.drawCircle(Offset(centerX + 8, bottomY - 115), 3, eyePaint);

    // Nose
    final nosePaint = Paint()..color = Colors.orange;
    final nosePath = Path()
      ..moveTo(centerX, bottomY - 110)
      ..lineTo(centerX + 10, bottomY - 106)
      ..lineTo(centerX, bottomY - 103)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Buttons
    canvas.drawCircle(Offset(centerX, bottomY - 70), 2, eyePaint);
    canvas.drawCircle(Offset(centerX, bottomY - 55), 2, eyePaint);

    // Hat
    canvas.drawRect(
      Rect.fromLTWH(centerX - 20, bottomY - 135, 40, 8),
      eyePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(centerX - 15, bottomY - 145, 30, 10),
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Draggable Snowflake Widget
class _DraggableSnowflake extends StatelessWidget {
  final int snowflakeId;
  final bool isInCircle;

  const _DraggableSnowflake({
    super.key,
    required this.snowflakeId,
    required this.isInCircle,
  });

  @override
  Widget build(BuildContext context) {
    if (isInCircle) {
      // If already in circle, hide it
      return const SizedBox.shrink();
    }

    return Draggable<int>(
      data: snowflakeId,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.2,
          child: CustomPaint(
            size: const Size(50, 50),
            painter: _SnowflakeIconPainter(),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: CustomPaint(
          size: const Size(50, 50),
          painter: _SnowflakeIconPainter(),
        ),
      ),
      child: CustomPaint(
        size: const Size(50, 50),
        painter: _SnowflakeIconPainter(),
      ),
    );
  }
}

// Snowflake Icon Painter
class _SnowflakeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF87CEEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Draw 6-pointed snowflake
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 90) * math.pi / 180;
      
      // Main arm
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
      
      // Side branches
      final branchLength = radius * 0.3;
      final branchAngle1 = angle + math.pi / 3;
      final branchAngle2 = angle - math.pi / 3;
      
      final branchStartX = center.dx + radius * 0.6 * math.cos(angle);
      final branchStartY = center.dy + radius * 0.6 * math.sin(angle);
      
      final branch1EndX = branchStartX + branchLength * math.cos(branchAngle1);
      final branch1EndY = branchStartY + branchLength * math.sin(branchAngle1);
      canvas.drawLine(
        Offset(branchStartX, branchStartY),
        Offset(branch1EndX, branch1EndY),
        paint,
      );
      
      final branch2EndX = branchStartX + branchLength * math.cos(branchAngle2);
      final branch2EndY = branchStartY + branchLength * math.sin(branchAngle2);
      canvas.drawLine(
        Offset(branchStartX, branchStartY),
        Offset(branch2EndX, branch2EndY),
        paint,
      );
    }
    
    // Center circle
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.1, paint);
  }

  @override
  bool shouldRepaint(_SnowflakeIconPainter oldDelegate) => false;
}

