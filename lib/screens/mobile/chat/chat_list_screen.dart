import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gpcs_hostel_portal/screens/mobile/chat/chat_room_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Get the role: 'Admin', 'Warden', or 'Student'
        String userRole = snapshot.data!.getString('user_role') ?? "Student";
        bool isStaff = userRole == 'Admin' || userRole == 'Warden';

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF0077C2),
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              isStaff ? "Staff Chat Management" : "Hostel Chat",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Public Chats"),
                _buildFirestoreSection('public', userRole),

                const SizedBox(height: 25),

                // ONLY show Roommate Chats if the user is a Student
                if (!isStaff) ...[
                  _buildSectionHeader("Roommate Chats"),
                  _buildRoommateSection(userRole),
                  const SizedBox(height: 25),
                ],

                _buildSectionHeader("Official Notices"),
                _buildFirestoreSection('notice', userRole),
              ],
            ),
          ),
          floatingActionButton: isStaff
              ? FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: const Color(0xFF438A7F),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildRoommateSection(String userRole) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        String? myRoom = snapshot.data!.getString('user_room');

        if (myRoom == null) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Text("No room assigned", style: TextStyle(color: Colors.grey)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .where('type', isEqualTo: 'room')
              .where(FieldPath.documentId, isEqualTo: 'room_$myRoom')
              .snapshots(),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData) return const SizedBox();
            if (chatSnapshot.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Your room chat is not active.",
                    style: TextStyle(color: Colors.grey)),
              );
            }

            return Column(
              children: chatSnapshot.data!.docs.map((chat) {
                return _buildChatCard(context, chat, 'room', userRole);
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF438A7F)),
      ),
    );
  }

  Widget _buildFirestoreSection(String type, String userRole) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        if (snapshot.data!.docs.isEmpty) return const Text("No chats found.");

        return Column(
          children: snapshot.data!.docs.map((chat) {
            return _buildChatCard(context, chat, type, userRole);
          }).toList(),
        );
      },
    );
  }

  Widget _buildChatCard(BuildContext context, DocumentSnapshot chat,
      String type, String userRole) {
    final data = chat.data() as Map<String, dynamic>;

    IconData iconData = Icons.public;
    Color iconColor = const Color(0xFF438A7F);
    if (type == 'room') {
      iconData = Icons.bed_rounded;
      iconColor = const Color(0xFFE67E22);
    } else if (type == 'notice') {
      iconData = Icons.campaign_rounded;
      iconColor = const Color(0xFF2980B9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(iconData, color: iconColor, size: 28),
        ),
        title: Text(
          data['name'] ?? "Unnamed Chat",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            data.containsKey('lastMessage')
                ? data['lastMessage']
                : "No messages yet",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
        trailing: _buildTrailingWidget(chat),
        onTap: () => _handleNavigation(context, chat, userRole),
      ),
    );
  }

  Widget _buildTrailingWidget(DocumentSnapshot chat) {
    final data = chat.data() as Map<String, dynamic>;
    String time = "";

    if (data.containsKey('lastTimestamp') && data['lastTimestamp'] != null) {
      DateTime dt = (data['lastTimestamp'] as Timestamp).toDate();
      time = DateFormat('hh:mm a').format(dt);
    }

    int unread = data.containsKey('unreadCount') ? data['unreadCount'] : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (unread > 0)
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
                color: Color(0xFFE74C3C), shape: BoxShape.circle),
            child: Text("$unread",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          )
        else
          const SizedBox(height: 25),
        Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // --- UPDATED NAVIGATION LOGIC ---
  void _handleNavigation(
      BuildContext context, DocumentSnapshot chat, String userRole) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get basic stored data
    String rollNo = prefs.getString('user_roll') ?? "STAFF";
    String storedName = prefs.getString('user_name') ?? "User";

    // 2. Fetch specific student name from Firestore if necessary
    String displayName = storedName;
    if (userRole == 'Student') {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(rollNo)
          .get();
      if (userDoc.exists) {
        displayName = userDoc['name'];
      }
    }

    if (!context.mounted) return;

    // 3. Navigate with the correct Role and Name
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatId: chat.id,
          chatName: chat['name'] ?? "Chat Room",
          userRollNo: rollNo,
          userName: displayName,
          userRole: userRole, // Ensures Warden/Admin identity is passed
        ),
      ),
    );
  }
}
