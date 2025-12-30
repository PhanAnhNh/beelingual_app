// lib/services/socket_service.dart
import 'package:beelingual_app/connect_api/url.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool _isConnected = false;

  // Khởi tạo kết nối
  void initSocket() {
    if (_isConnected) return;

    // Cắt bỏ phần '/api' nếu urlAPI của bạn có dạng 'http://IP:3000/api'
    // Socket cần kết nối vào root: 'http://IP:3000'
    String baseUrl = urlAPI.replaceAll('/api', '');

    socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket']) // Bắt buộc dùng websocket để ổn định
        .disableAutoConnect() // Tự chủ động connect
        .build());

    socket.connect();

    socket.onConnect((_) {
      print('✅ Socket Connected: ${socket.id}');
      _isConnected = true;
    });

    socket.onDisconnect((_) {
      print('❌ Socket Disconnected');
      _isConnected = false;
    });

    socket.onConnectError((err) => print('⚠️ Socket Error: $err'));
  }

  // --- CÁC HÀM GỬI DATA (EMIT) ---

  // 1. Tìm trận (Gửi kèm Level và số câu hỏi)
  void joinQueue({
    required String userId,
    required String username,
    required String avatarUrl,
    required String level,
    required int questionCount,
  }) {
    print('🔍 User $username joining queue: $level');
    socket.emit('join_queue', {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'level': level,
      'questionCount': questionCount,
    });
  }

  // 2. Gửi đáp án
  void submitAnswer(String roomId, bool isCorrect) {
    socket.emit('submit_answer', {
      'roomId': roomId,
      'isCorrect': isCorrect,
    });
  }

  // 3. Kết thúc game
  void finishGame(String roomId, int timeUsed) {
    socket.emit('finish_game', {
      'roomId': roomId,
      'timeUsed': timeUsed,
    });
  }

  // 4. Hủy tìm trận / Thoát game
  void disconnect() {
    socket.disconnect();
    _isConnected = false;
  }

  // --- CÁC HÀM LẮNG NGHE (LISTENERS) ---

  // Setup lắng nghe sự kiện tìm thấy trận
  void onMatchFound(Function(dynamic data) callback) {
    socket.on('match_found', (data) => callback(data));
  }

  // Lắng nghe tiến độ đối thủ
  void onOpponentProgress(Function(dynamic data) callback) {
    socket.on('opponent_progress', (data) => callback(data));
  }

  // Lắng nghe đối thủ thoát
  void onOpponentDisconnected(Function(dynamic data) callback) {
    socket.on('opponent_disconnected', (data) => callback(data));
  }

  // Xóa các sự kiện để tránh bị gọi nhiều lần (memory leak)
  void offGameEvents() {
    socket.off('match_found');
    socket.off('opponent_progress');
    socket.off('opponent_disconnected');
  }
}