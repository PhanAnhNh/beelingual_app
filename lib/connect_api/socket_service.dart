// lib/connect_api/socket_service.dart
import 'package:beelingual_app/connect_api/url.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late IO.Socket socket;
  bool _isConnected = false;

  // --- 1. KHỞI TẠO KẾT NỐI ---
  void initSocket() {
    if (_isConnected) return; // Nếu đã kết nối rồi thì không connect lại

    String baseUrl = urlAPI.replaceAll('/api', '');

    socket = IO.io(baseUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .enableForceNew() // Thêm dòng này để đảm bảo session mới sạch sẽ
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

  // --- 2. CÁC HÀM GỬI DATA (EMIT) ---

  // Tìm trận
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

  // [MỚI] Hủy tìm trận (Khi đang tìm mà muốn dừng lại)
  void cancelMatching() {
    print('🚫 Canceling matching...');
    socket.emit('leave_queue');
  }

  // [MỚI] Rời phòng / Đầu hàng (Dùng khi người dùng ấn Back lúc đang thi đấu)
  // Hàm này chỉ báo server là user bỏ cuộc, CHỨ KHÔNG ngắt kết nối socket
  void leaveRoom(String roomId) {
    print('🏳️ User leaving room (Surrender): $roomId');
    socket.emit('leave_room', {'roomId': roomId});
  }

  // Gửi đáp án
  void submitAnswer(String roomId, String answer) {
    socket.emit('submit_answer', {
      'roomId': roomId,
      'answer': answer,
    });
  }



  void onGameFinished(Function(dynamic data) callback) {
    socket.off('game_finished');
    socket.on('game_finished', (data) => callback(data));
  }


  // --- 3. QUẢN LÝ KẾT NỐI (Cẩn thận khi dùng) ---

  // Hàm này CHỈ GỌI khi người dùng Đăng Xuất (Logout) khỏi App
  // Tuyệt đối không gọi hàm này khi thoát màn hình Game
  void disconnect() {
    if (_isConnected) {
      socket.disconnect();
      _isConnected = false;
    }
  }

  // --- 4. CÁC HÀM LẮNG NGHE (LISTENERS) ---

  void onMatchFound(Function(dynamic data) callback) {
    // Xóa listener cũ trước khi thêm mới để tránh bị gọi đúp (duplicate events)
    socket.off('match_found');
    socket.on('match_found', (data) => callback(data));
  }

  void onOpponentProgress(Function(dynamic data) callback) {
    socket.on('opponent_progress', (data) => callback(data));
  }

  void onOpponentDisconnected(Function(dynamic data) callback) {
    socket.on('opponent_disconnected', (data) => callback(data));
  }

  void requestBotMatch() {
    // Gửi sự kiện lên server.
    // Server cần bắt sự kiện 'request_bot' và gọi hàm joinWithBot(matchId)
    // Lưu ý: Client cần gửi kèm matchId hoặc userId để server biết ai đang đợi.
    socket.emit('join_with_bot', {});
  }

  void onNextQuestion(Function(dynamic data) callback) {
    socket.off('next_question');
    socket.on('next_question', (data) => callback(data));
  }

  // Xóa các sự kiện lắng nghe khi rời màn hình game
  // Chỉ tắt tai nghe, không tắt kết nối
  void offGameEvents() {
    print('🔇 Removing Game Listeners');
    socket.off('match_found');
    socket.off('next_question');
    socket.off('opponent_progress');
    socket.off('opponent_disconnected');
  }
}