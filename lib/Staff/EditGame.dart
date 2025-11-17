// lib/Staff_screens/EditGame.dart
import 'dart:convert'; // เพิ่มสำหรับ jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // เพิ่มสำหรับเรียก API
import 'package:boardgame_app/Staff/game_input_form.dart';
import 'package:boardgame_app/Staff/staff_main.dart'
    show colour_available, colour_main; // ตัดตัวซ้ำออกให้แล้วครับ
import 'game_data.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// ⚠️ ตรวจสอบ URL ให้ตรงกับของเพื่อน (ถ้าแยกไฟล์ constants.dart ให้ import มาใช้)
const String baseUrl = '10.0.2.2:3000';

class EditGame extends StatefulWidget {
  final GameItem game;
  final int groupCount;
  final Function(int newCount) onCountChanged;

  const EditGame({
    super.key,
    required this.game,
    required this.groupCount,
    required this.onCountChanged,
  });

  @override
  State<EditGame> createState() => _EditGameState();
}

class _EditGameState extends State<EditGame> {
  final formKey = GlobalKey<GameInputFormState>();
  bool _isUpdating = false; // ตัวแปรเช็คสถานะกำลังบันทึก

  // ฟังก์ชันสำหรับเรียก API แก้ไขข้อมูล
  Future<void> _handleUpdate(Map<String, dynamic> formData) async {
    setState(() {
      _isUpdating = true; // เริ่มหมุนติ้วๆ
    });

    try {
      // 1. เตรียม URL (ตรวจสอบ Endpoint กับทีม: /game/update หรือ /game/:id)
      final url = Uri.parse('http://$baseUrl/game/${widget.game.gameId}');

      // 2. เตรียมข้อมูลที่จะส่ง (ตรงกับ SQL Database)
      final body = jsonEncode({
        'game_name': formData['game_name'],
        // 'style_id': ... (ถ้า Backend ต้องการ ID แทนชื่อ ต้องแก้ตรงนี้เพิ่ม)
        'game_style': formData['game_style'],
        'game_time': int.parse(formData['game_time']),
        'game_min_player': int.parse(formData['min_P']),
        'game_max_player': int.parse(formData['max_P']),
        'game_link_howto': formData['game_how2'],
        // 'game_pic_path': widget.game.picPath (ถ้าไม่ได้แก้รูป)
      });

      // 3. ยิง Request
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // 4. ถ้าสำเร็จ ให้แสดง Dialog เดิมของคุณ
        if (mounted) {
          _showSuccessDialog(formData['game_name']);
        }
      } else {
        // ถ้า Server ตอบ Error กลับมา
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Update Failed: ${response.body}')),
          );
        }
      }
    } catch (e) {
      print('Error updating game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network Error: Could not connect to server'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false; // หยุดหมุน
        });
      }
    }
  }

  Future<void> _showSuccessDialog(String gameName) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          FontAwesomeIcons.circleCheck,
          color: colour_available,
          size: 60,
        ),
        title: const Text(
          'Edit Successful!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Game "$gameName" has been updated.',
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pop(
                  context,
                  true,
                ); // Return true to refresh previous page
              },
              style: TextButton.styleFrom(
                backgroundColor: colour_available,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: colour_main, size: 30),
        title: const Text(
          'Edit Board Game',
          style: TextStyle(color: colour_main, fontSize: 30),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 175,
                    height: 190,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        widget.game.picPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name : ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.game.gameName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Game Style : ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          widget.game.gameStyle,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Player : ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${widget.game.minP} - ${widget.game.maxP} peoples",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Time : ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "${widget.game.gTime} min",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ฟอร์มกรอกข้อมูล
            GameInputForm(
              key: formKey,
              isEditing: true,
              initialData: {
                'game_name': widget.game.gameName,
                'game_style': widget.game.gameStyle,
                'game_time': widget.game.gTime.toString(),
                'min_P': widget.game.minP.toString(),
                'max_P': widget.game.maxP.toString(),
                'game_how2': widget.game.g_link,
                'game_count': widget.groupCount.toString(),
              },
              onCountChanged: widget.onCountChanged,
            ),

            const SizedBox(height: 30),

            // ปุ่ม Confirm (แก้ไขให้รองรับการโหลดและเรียก API)
            SizedBox(
              width: double.infinity, // ทำให้ปุ่มกว้างเต็มจอ
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colour_main,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // ปรับความมนของปุ่ม
                  ),
                ),
                onPressed: _isUpdating
                    ? null // ถ้ากำลังโหลด ห้ามกดปุ่มซ้ำ
                    : () async {
                        // 1. ดึงข้อมูลจากฟอร์ม
                        final data = formKey.currentState?.getFormData();
                        if (data == null)
                          return; // ถ้า validate ไม่ผ่าน ให้หยุด

                        // 2. เรียกฟังก์ชันอัปเดตข้อมูล
                        await _handleUpdate(data);
                      },
                child: _isUpdating
                    ? const SizedBox(
                        height: 25,
                        width: 25,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
