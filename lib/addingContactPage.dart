import 'dart:convert';

import 'package:chat_redis/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:redis/redis.dart';

class AddingContactPage extends StatelessWidget {
  final snackBarError = const SnackBar(
      content: Text('Error'),
      backgroundColor: Colors.redAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
        side: BorderSide(
          color: Colors.red,
        ),
      ));
  final snackBarSuccess = const SnackBar(
      content: Text('Contact added'),
      backgroundColor: Colors.greenAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), topLeft: Radius.circular(10)),
        side: BorderSide(
          color: Colors.green,
        ),
      ));

  TextEditingController nameCon = TextEditingController();
  TextEditingController numberCon = TextEditingController();
  TextEditingController disCon = TextEditingController();

  void makingNameList() {
    final conn = RedisConnection();
    for (int x = 0; x <= nameCon.text.length; x++) {
      conn.connect('10.0.2.2', 6379).then((Command command) {
        command.send_object([
          "rpush",
          "${MyApp.userPhone}:${nameCon.text.substring(0, x)}",
          numberCon.text
        ]).then((var response) {});
      });
    }
    for (int x = 1; x <= numberCon.text.length; x++) {
      conn.connect('10.0.2.2', 6379).then((Command command) {
        command.send_object([
          "rpush",
          "${MyApp.userPhone}:${numberCon.text.substring(0, x)}",
          numberCon.text
        ]).then((var response) {});
      });
    }
  }

  void makingChat() {
    final conn = RedisConnection();
    conn.connect('10.0.2.2', 6379).then((Command command) {
      command.send_object([
        "EXISTS",
        "${MyApp.userPhone}chat${numberCon.text}"
      ]).then((var value) {
        if (value == 0) {
          command.send_object([
            "rpush",
            "${MyApp.userPhone}chat${numberCon.text}",
            jsonEncode({
              "sender": 'none',
              "massage": 'start of chat',
              "date": 'none',
            })
          ]).then((var response) {});
          command.send_object([
            "rpush",
            "${numberCon.text}chat${MyApp.userPhone}",
            jsonEncode({
              "sender": 'none',
              "massage": 'start of chat',
              "date": 'none',
            })
          ]).then((var response) {});
        }
      });
    });
  }

  Future<void> setContact(BuildContext context) async {
    final conn = RedisConnection();
    await conn.connect('10.0.2.2', 6379).then((Command command) {
      command
          .send_object(["EXISTS", "${MyApp.userPhone}:${numberCon.text}"]).then(
              (var response) {
        if (response == 0) {
          makingNameList();
          makingChat();
          command.send_object([
            "Hmset",
            numberCon.text,
            "name",
            nameCon.text,
            "phoneNumber",
            numberCon.text,
            "dis",
            disCon.text
          ]).then((var response) {});
          command.send_object([
            "rpush",
            "${MyApp.userPhone}contacts",
            numberCon.text
          ]).then((var response) {
            print(response);
            ScaffoldMessenger.of(context).showSnackBar(snackBarSuccess);
            Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(snackBarError);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('adding Contact'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: nameCon,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0), //<-- SEE HERE
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0), //<-- SEE HERE
                ),
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(),
                labelText: 'contact name',
                hintText: 'name',
                contentPadding: EdgeInsets.all(20),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            TextField(
              controller: numberCon,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0), //<-- SEE HERE
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0), //<-- SEE HERE
                ),
                prefixIcon: const Icon(Icons.phone_android),
                border: OutlineInputBorder(),
                labelText: 'phone number',
                hintText: 'phone number',
                contentPadding: EdgeInsets.all(20),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            TextField(
              controller: disCon,
              maxLines: 2,
              maxLength: 100,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0), //<-- SEE HERE
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50.0), //<-- SEE HERE
                ),
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(),
                labelText: 'discription',
                hintText: 'discription',
                contentPadding: EdgeInsets.all(20),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            ElevatedButton(
                onPressed: () {
                  setContact(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text('Done'),
                    Icon(Icons.done),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
