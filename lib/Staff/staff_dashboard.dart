// lib/Staff/staff_dashboard.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:boardgame_app/Staff/Add_New_Game.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'EditGame.dart'; // ตรวจสอบ path ให้ถูกต้อง
import 'staff_main.dart'
    show colour_available, colour_borrow, colour_disable, colour_main;

import 'game_data.dart';

// ⚠️ ตรวจสอบ URL ให้ตรงกับของเพื่อน (ถ้ามีไฟล์ constants.dart ให้ import มาใช้)
final String url = '10.0.2.2:3000';

class StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const StatusCard({
    super.key,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      height: 115,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 50,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final GameItem game;
  final VoidCallback? onStatusTap;
  final String authToken;
  const GameCard({
    super.key,
    required this.game,
    required this.onStatusTap,
    required this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    final isBorrowed = game.status == 'Borrowed' || game.status == 'Borrowing';
    final config = _getStatusConfig(game.status, isBorrowed);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                game.picPath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.broken_image,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    game.gameName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${game.gameId}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${game.status}',
                    style: TextStyle(
                      color: config.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isBorrowed
                  ? null
                  : () async {
                      final newStatus = game.status == 'Available'
                          ? 'Disabled'
                          : 'Available';
                      final success = await _updateGameStatus(
                        game.gameId,
                        newStatus,
                      );
                      if (success && context.mounted) {
                        _showStatusPopup(context, newStatus);
                      }
                      onStatusTap?.call();
                    },
              icon: Icon(config.icon, color: config.color, size: 40),
              tooltip: isBorrowed
                  ? 'Cannot change while borrowed'
                  : 'Toggle Available/Disabled',
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  void _showStatusPopup(BuildContext context, String status) {
    final isEnabled = status == 'Available';
    late BuildContext dialogContext;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        dialogContext = ctx;
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEnabled ? Icons.check_circle : Icons.cancel,
                    color: isEnabled ? Colors.green : Colors.red,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEnabled ? 'Enabled' : 'Disabled',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isEnabled ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    });
  }

  Future<bool> _updateGameStatus(int inventoryId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('http://$url/staff/game/status/$inventoryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'status': newStatus}),
      );

      print("Update: ${response.statusCode} ${response.body}");
      return response.statusCode == 200 &&
          jsonDecode(response.body)['success'] == true;
    } catch (e) {
      print("Update error: $e");
      return false;
    }
  }

  ({Color color, IconData icon}) _getStatusConfig(
    String status,
    bool isBorrowed,
  ) {
    if (isBorrowed || status == 'Borrowing') {
      return (color: Colors.grey.shade400, icon: Icons.lock_outline);
    }
    return switch (status) {
      'Available' => (color: colour_available, icon: Icons.play_disabled),
      'Disabled' => (color: colour_disable, icon: FontAwesomeIcons.play),
      _ => (color: Colors.grey, icon: Icons.help),
    };
  }
}

class GroupedGameList extends StatelessWidget {
  final List<GameItem> games;
  final Function(int gameId) onStatusToggle;
  final String authToken;
  final VoidCallback onRefresh; // ✅ เพิ่ม Callback สำหรับรีเฟรชข้อมูล

  const GroupedGameList({
    super.key,
    required this.games,
    required this.onStatusToggle,
    required this.authToken,
    required this.onRefresh, // ✅ รับค่าเข้ามา
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 30),
        child: Center(
          child: Text('No games found.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final List<Widget> children = [];
    String? lastGroup;

    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      final isNewGroup = lastGroup != game.gameGroup;

      final isLastInGroup =
          i == games.length - 1 || games[i + 1].gameGroup != game.gameGroup;

      if (isNewGroup) {
        final group = games
            .where((g) => g.gameGroup == game.gameGroup)
            .toList();
        final groupCount = group.length;

        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    game.gameGroup,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // --- ปุ่ม Edit (แก้ไข Logic การกดปุ่ม) ---
                ElevatedButton(
                  onPressed: () async {
                    // เปิดหน้า EditGame และรอรับค่า result (true/false/null)
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditGame(
                          game: game,
                          groupCount: groupCount,
                          onCountChanged: (val) {
                            // ไม่ต้องทำอะไร เพราะเราจะ reload จาก API แทน
                          },
                        ),
                      ),
                    );

                    // ถ้าแก้ไขสำเร็จ (result == true) ให้รีเฟรชข้อมูลใหม่จาก Server
                    if (result == true && context.mounted) {
                      onRefresh();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colour_borrow,
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                // -----------------------------------------
              ],
            ),
          ),
        );
      } else if (i > 0) {
        children.add(const SizedBox(height: 8));
      }

      children.add(
        GameCard(
          key: ValueKey(game.gameId),
          game: game,
          onStatusTap: () => onStatusToggle(game.gameId),
          authToken: authToken,
        ),
      );

      if (isLastInGroup) {
        children.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Divider(height: 1, thickness: 1, color: colour_main),
          ),
        );
      }
      lastGroup = game.gameGroup;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class StaffDashboard extends StatefulWidget {
  final String authToken;
  const StaffDashboard({super.key, required this.authToken});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  late List<GameItem> _filteredGames;
  int borrowedCount = 0, availableCount = 0, disabledCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _filteredGames = [];
    gameList.clear();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      print("Fetching dashboard...");
      final response = await http.get(
        Uri.parse('http://$url/staff/dashboard'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Dashboard response: $data");

        if (data['success'] == true) {
          final summary = data['summary'] ?? {};
          setState(() {
            borrowedCount = summary['pending_bookings'] ?? 0;
            availableCount = summary['approved_bookings'] ?? 0;
            disabledCount = summary['rejected_bookings'] ?? 0;
          });
        }
      }

      await fetchGames();
    } catch (e) {
      print("Dashboard ERROR: $e");
      await fetchGames();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> fetchGames() async {
    try {
      print("Fetching games from http://$url/staff/games...");
      final response = await http.get(
        Uri.parse('http://$url/staff/games'),
        headers: {'Authorization': 'Bearer ${widget.authToken}'},
      );

      print("Response status: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("API Error: ${response.body}");
        return;
      }

      final data = jsonDecode(response.body);
      if (!data['success']) {
        print("API not success: ${data['message']}");
        return;
      }

      final List<dynamic> gamesJson = data['games'];
      print("Found ${gamesJson.length} game groups");

      final List<GameItem> loadedGames = [];

      for (var json in gamesJson) {
        final List<String> ids =
            (json['itemIds'] as List?)?.cast<String>() ?? [];
        final List<String> statuses =
            (json['itemStatuses'] as List?)?.cast<String>() ?? [];

        if (ids.isEmpty) continue;

        for (int i = 0; i < ids.length; i++) {
          final status = i < statuses.length ? statuses[i] : 'Available';
          loadedGames.add(
            GameItem(
              gameId: int.tryParse(ids[i]) ?? 0,
              gameName: json['gameName']?.toString() ?? 'Unknown',
              gameGroup: json['gameName']?.toString() ?? 'Unknown',
              gameStyle: (json['styleId'] ?? 0).toString(),
              gTime: int.tryParse(json['gameTime'].toString()) ?? 60,
              minP: int.tryParse(json['minPlayers'].toString()) ?? 1,
              maxP: int.tryParse(json['maxPlayers'].toString()) ?? 1,
              g_link: json['howToLink']?.toString() ?? '',
              picPath: 'http://$url/${json['picPath']}',
              status: _mapStatus(status),
            ),
          );
        }
      }

      print("Loaded ${loadedGames.length} GameItems");

      setState(() {
        gameList
          ..clear()
          ..addAll(loadedGames)
          ..sort((a, b) => a.gameGroup.compareTo(b.gameGroup));
        _filteredGames = List.from(gameList);
        _updateStatusCounts();
      });
    } catch (e) {
      print("Load games ERROR: $e");
    }
  }

  String _mapStatus(String? s) {
    final status = (s ?? '').toLowerCase().trim();
    return switch (status) {
      'borrowing' => 'Borrowing',
      'available' => 'Available',
      'disabled' => 'Disabled',
      _ => s ?? 'Available',
    };
  }

  void _updateStatusCounts() {
    borrowedCount = gameList
        .where((g) => g.status == 'Borrowed' || g.status == 'Borrowing')
        .length;
    availableCount = gameList.where((g) => g.status == 'Available').length;
    disabledCount = gameList.where((g) => g.status == 'Disabled').length;
    if (mounted) setState(() {});
  }

  void _filterGames(String query) {
    setState(() {
      _filteredGames = query.isEmpty
          ? List.from(gameList)
          : gameList
                .where(
                  (g) => g.gameName.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
    });
  }

  void _toggleAvailableDisabled(int gameId) {
    final game = gameList.firstWhere((g) => g.gameId == gameId);
    if (game.status == 'Borrowed' || game.status == 'Borrowing') return;
    setState(() {
      game.status = game.status == 'Available' ? 'Disabled' : 'Available';
      _updateStatusCounts();
    });
  }

  // ฟังก์ชันเดิม (เก็บไว้เผื่อใช้ แต่ไม่ได้ถูกเรียกหลักใน flow ใหม่)
  void adjustGroupCount(String groupName, int newCount) {
    // ... logic เดิม ...
  }

  // ฟังก์ชันเดิม (เก็บไว้)
  void _addNewGames(Map newGameData) {
    // ... logic เดิม ...
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Status",
                    style: TextStyle(
                      color: colour_main,
                      fontSize: 30,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      StatusCard(
                        label: 'Borrowed',
                        count: borrowedCount,
                        color: colour_borrow,
                      ),
                      const Spacer(),
                      StatusCard(
                        label: 'Available',
                        count: availableCount,
                        color: colour_available,
                      ),
                      const Spacer(),
                      StatusCard(
                        label: 'Disabled',
                        count: disabledCount,
                        color: colour_disable,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Manage Board',
                    style: TextStyle(
                      color: colour_main,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: _filterGames,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colour_main),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colour_main),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colour_main, width: 2),
                      ),
                      hintText: 'Search game name . . .',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ✅ ส่ง onRefresh: fetchGames เข้าไป
                  GroupedGameList(
                    games: _filteredGames,
                    onStatusToggle: _toggleAvailableDisabled,
                    authToken: widget.authToken,
                    onRefresh: fetchGames, // ฟังก์ชันรีเฟรช
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                backgroundColor: colour_main,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddNewGame()),
                  );
                  if (result is Map &&
                      result['game_name']?.toString().isNotEmpty == true) {
                    await fetchGames(); // รีเฟรชหลังจากเพิ่มเกม
                  }
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
