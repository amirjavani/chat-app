import 'dart:convert';

import 'package:chat_redis/Contact.dart';
import 'package:chat_redis/Massage.dart';
import 'package:chat_redis/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:redis/redis.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  ChatPage({Key? key, required this.contact}) : super(key: key);
  final Contact contact;
  @override
  State<ChatPage> createState() => _ChatPageState(contact);
}

class _ChatPageState extends State<ChatPage> {
  List<Massage> massages = [];
  Contact contact;
  String chatKey = '';
  _ChatPageState(this.contact);

  Future<void> gettingChatKey() async {
    final conn = RedisConnection();
    await conn.connect('10.0.2.2', 6379).then((Command command) {
      command.send_object([
        "EXISTS",
        "${MyApp.userPhone}chat${contact.phoneNumber}"
      ]).then((var response) {
        if (response == 1) {
          chatKey = '${MyApp.userPhone}chat${contact.phoneNumber}';
        } else {
          command.send_object([
            "EXISTS",
            "${contact.phoneNumber}chat${MyApp.userPhone}"
          ]).then((var response) {
            if (response == 1) {
              chatKey = '${contact.phoneNumber}chat${MyApp.userPhone}';
            } else {}
          });
        }
      });
    });
  }

  Future<void> getMassage() async {
    final conn = RedisConnection();
    await conn.connect('10.0.2.2', 6379).then((Command command) {
      command.send_object([
        "lrange",
        "${MyApp.userPhone}chat${contact.phoneNumber}",
        "0",
        "-1"
      ]).then((var response) {
        for (var con in response) {
          var decoded = json.decode(con);
          massages.add(Massage.normal(
            decoded['massage'],
            decoded['sender'],
            decoded['date'],
          ));
          print(massages[0].massage);
        }
        setState(() {});
      });
    });
  }

  Future<void> sendMassage() async {
    final conn = RedisConnection();
    await conn.connect('10.0.2.2', 6379).then((Command command) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('kk:mm dd/MM/yy').format(now);
      command.send_object([
        "rpush",
        "${contact.phoneNumber}chat${MyApp.userPhone}",
        jsonEncode({
          "sender": MyApp.userPhone,
          "massage": textCon.text,
          "date": formattedDate,
        })
      ]).then((var response) {});
      command.send_object([
        "rpush",
        "${MyApp.userPhone}chat${contact.phoneNumber}",
        jsonEncode({
          "sender": MyApp.userPhone,
          "massage": textCon.text,
          "date": formattedDate,
        })
      ]).then((var response) {
        massages.add(Massage.normal(
          textCon.text,
          MyApp.userPhone,
          formattedDate,
        ));
        print(massages[0].massage);
        textCon.clear();
        setState(() {});
      });
    });
  }

  @override
  void initState() {
    getMassage();
    super.initState();
  }

  TextEditingController textCon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            randomAvatar(contact.phoneNumber,
                height: 50, width: 50, trBackground: true),
            SizedBox(
              width: 15,
            ),
            Text(contact.name),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: massages.length,
                itemBuilder: (context, index) => Column(
                  crossAxisAlignment:
                      massages[index].sender == contact.phoneNumber
                          ? CrossAxisAlignment.start
                          : massages[index].sender == "none"
                              ? CrossAxisAlignment.center
                              : CrossAxisAlignment.end,
                  children: massages[index].sender == "none"
                      ? [
                          Text(
                            massages[index].massage,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          )
                        ]
                      : [
                          massages[index].sender == MyApp.userPhone
                              ? Text('you')
                              : Text(contact.name),
                          Container(
                            padding: EdgeInsets.all(5),
                            child: Text(
                              massages[index].massage,
                              style: TextStyle(fontSize: 20),
                            ),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                color: massages[index].sender ==
                                        contact.phoneNumber
                                    ? Colors.deepPurple
                                    : Colors.deepPurpleAccent),
                          )
                        ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.deepPurple[100],
                    ),
                    child: TextField(
                      onSubmitted: (text) {
                        sendMassage();
                      },
                      controller: textCon,
                      decoration: InputDecoration(
                        hintText: 'Text',
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          onPressed: textCon.clear,
                          icon: Icon(Icons.clear),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    sendMassage();
                  },
                  icon: Icon(Icons.send),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
