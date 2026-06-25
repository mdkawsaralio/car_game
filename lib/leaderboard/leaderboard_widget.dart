import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../leaderboard/leaderboard_service.dart';

class LeaderboardWidget extends StatefulWidget {
  final int currentScore;
  final int currentCoins;

  const LeaderboardWidget({
    super.key,
    required this.currentScore,
    required this.currentCoins,
  });

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  List<PlayerStats> _players = [];
  bool _isLoading = true;
  String? _error;
  PlayerStats? _currentPlayer;
  Stream<List<PlayerStats>>? _leaderboardStream;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _listenToLeaderboardStream();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _listenToLeaderboardStream() {
    _leaderboardStream = _leaderboardService.getLeaderboardStream(limit: 10);
    _isListening = true;
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _currentPlayer = await _leaderboardService.getCurrentPlayerStats();
      final players = await _leaderboardService.getTopPlayers(limit: 10);

      setState(() {
        _players = players;
        _isLoading = false;
        if (players.isEmpty) {
          _error = 'No players yet. Be the first!';
        }
      });

      _leaderboardStream?.listen(
        (updatedPlayers) {
          if (mounted) {
            setState(() {
              _players = updatedPlayers;
              _isLoading = false;
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                final currentPlayerData = updatedPlayers.firstWhere(
                  (p) => p.uid == currentUser.uid,
                  orElse: () => _currentPlayer!,
                );
                if (currentPlayerData != _currentPlayer) {
                  _currentPlayer = currentPlayerData;
                }
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _error = 'Real-time updates failed, but data is available';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Unable to load leaderboard. Play a game to start!';
        _isLoading = false;
      });
    }
  }

  int _getPlayerRank(String uid) {
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].uid == uid) {
        return i + 1;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - Simplified
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              const Text(
                'TOP 10',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isListening ? 'Live' : 'Offline',
                    style: TextStyle(
                      color: _isListening ? Colors.green : Colors.red,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (!_isLoading && _players.isNotEmpty)
                    Text(
                      '${_players.length}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 9),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white12, height: 0.5),

          // Current Player Stats - More compact
          if (_currentPlayer != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _currentPlayer!.photoUrl != null
                        ? NetworkImage(_currentPlayer!.photoUrl!)
                        : null,
                    child: _currentPlayer!.photoUrl == null
                        ? Text(
                            _currentPlayer!.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPlayer!.username,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          '🏆${_currentPlayer!.bestScore} 🪙${_currentPlayer!.totalCoins}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${_getPlayerRank(_currentPlayer!.uid) > 0 ? _getPlayerRank(_currentPlayer!.uid) : '--'}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Loading State
          if (_isLoading) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.amber,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ] else if (_error != null) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 12),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.grey[400], fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_players.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.grey, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'No players yet',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Player List - Compact
            const SizedBox(height: 2),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _players.length > 10 ? 10 : _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                final bool isCurrentUser = player.uid == currentUser?.uid;
                final int rank = index + 1;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: isCurrentUser
                        ? Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 0.5,
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      // Rank
                      SizedBox(width: 18, child: _getRankIcon(rank)),
                      const SizedBox(width: 4),
                      // Photo
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: player.photoUrl != null
                            ? NetworkImage(player.photoUrl!)
                            : null,
                        child: player.photoUrl == null
                            ? Text(
                                player.username[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      // Name and stats - Expanded with proper constraints
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    player.username,
                                    style: TextStyle(
                                      color: isCurrentUser
                                          ? Colors.blue
                                          : Colors.white,
                                      fontWeight: isCurrentUser
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 9,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: const Text(
                                      'YOU',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 6,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '🏆${player.bestScore} 🪙${player.totalCoins}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 7,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      // Score - Fixed width
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '${player.bestScore}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Refresh button
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: _loadLeaderboard,
                icon: const Icon(Icons.refresh, color: Colors.grey, size: 12),
                label: Text(
                  'Sync',
                  style: TextStyle(color: Colors.grey[400], fontSize: 9),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _getRankIcon(int rank) {
    if (rank == 1) {
      return const Icon(Icons.emoji_events, color: Colors.amber, size: 14);
    } else if (rank == 2) {
      return const Icon(Icons.emoji_events, color: Colors.grey, size: 14);
    } else if (rank == 3) {
      return const Icon(Icons.emoji_events, color: Colors.brown, size: 14);
    } else {
      return Text(
        '#$rank',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}
