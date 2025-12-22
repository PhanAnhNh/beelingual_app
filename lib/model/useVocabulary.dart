// model/model_user_vocab.dart (hoặc file model_Vocab.dart)

class UserVocabularyItem {
  final String id; // ID của từ vựng gốc (_id)
  final String word;
  final String meaning;
  final String type;
  final String pronunciation;
  final String imageUrl;
  final String status;
  final String userVocabId; // ID của bản ghi UserVocabulary (dùng cho Xóa/Cập nhật trạng thái)

  UserVocabularyItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.type,
    required this.pronunciation,
    required this.imageUrl,
    required this.status,
    required this.userVocabId,
  });

  factory UserVocabularyItem.fromJson(Map<String, dynamic> json) {
    return UserVocabularyItem(
      id: json['_id'] ?? '', // ID từ vựng gốc
      word: json['word'] ?? 'N/A',
      meaning: json['meaning'] ?? 'N/A',
      type: json['type'] ?? 'N/A',
      pronunciation: json['pronunciation'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'learning',
      userVocabId: json['userVocabId'] ?? '', // ID bản ghi UserVocabulary
    );
  }
}