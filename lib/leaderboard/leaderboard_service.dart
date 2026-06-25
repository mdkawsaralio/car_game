import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayerStats {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final int bestScore;
  final int totalCoins;
  final int gamesPlayed;
  final DateTime lastPlayed;

  PlayerStats({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.bestScore,
    required this.totalCoins,
    required this.gamesPlayed,
    required this.lastPlayed,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map, String uid) {
    return PlayerStats(
      uid: uid,
      username: map['username'] ?? 'Unknown',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      bestScore: map['bestScore'] ?? 0,
      totalCoins: map['totalCoins'] ?? 0,
      gamesPlayed: map['gamesPlayed'] ?? 0,
      lastPlayed: (map['lastPlayed'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'bestScore': bestScore,
      'totalCoins': totalCoins,
      'gamesPlayed': gamesPlayed,
      'lastPlayed': FieldValue.serverTimestamp(),
    };
  }
}

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._internal();
  factory LeaderboardService() => _instance;
  LeaderboardService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update or create player stats
  Future<void> updatePlayerStats({
    required int bestScore,
    required int totalCoins,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('No user logged in - skipping leaderboard update');
      return;
    }

    final String uid = user.uid;
    final String username =
        user.displayName ?? user.email?.split('@').first ?? 'Player';
    final String email = user.email ?? '';
    final String? photoUrl = user.photoURL;

    try {
      final docRef = _firestore.collection('players').doc(uid);
      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing player
        final data = doc.data()!;
        final currentBestScore = data['bestScore'] ?? 0;

        await docRef.update({
          'bestScore': bestScore > currentBestScore
              ? bestScore
              : currentBestScore,
          'totalCoins': totalCoins,
          'gamesPlayed': FieldValue.increment(1),
          'lastPlayed': FieldValue.serverTimestamp(),
          'username': username,
          'email': email,
          'photoUrl': photoUrl ?? data['photoUrl'],
        });
        print('✅ Player stats updated for: $username');
      } else {
        // Create new player
        await docRef.set({
          'username': username,
          'email': email,
          'photoUrl': photoUrl,
          'bestScore': bestScore,
          'totalCoins': totalCoins,
          'gamesPlayed': 1,
          'lastPlayed': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ New player created: $username');
      }
    } catch (e) {
      print('❌ Error updating player stats: $e');
      // Don't rethrow - let the game continue even if leaderboard fails
    }
  }

  // Get current player's stats
  Future<PlayerStats?> getCurrentPlayerStats() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('players').doc(user.uid).get();
      if (doc.exists) {
        return PlayerStats.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting player stats: $e');
      return null;
    }
  }

  // Get top players (limited)
  Future<List<PlayerStats>> getTopPlayers({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('players')
          .orderBy('bestScore', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) {
        return PlayerStats.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error getting top players: $e');
      return [];
    }
  }

  // Stream for real-time leaderboard updates
  Stream<List<PlayerStats>> getLeaderboardStream({int limit = 10}) {
    try {
      return _firestore
          .collection('players')
          .orderBy('bestScore', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return PlayerStats.fromMap(doc.data(), doc.id);
            }).toList();
          });
    } catch (e) {
      print('❌ Error getting leaderboard stream: $e');
      return Stream.value([]);
    }
  }
}
