import 'dart:convert';

import 'package:chat_redis/Contact.dart';
import 'package:chat_redis/addingContactPage.dart';
import 'package:chat_redis/chatPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:redis/redis.dart';
import 'package:flutter/material.dart';
import 'package:substring_highlight/substring_highlight.dart';
import 'package:random_avatar/random_avatar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static bool isLogin = false;
  static String userPhone = '';
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ContactList(),
    );
  }
}

class ContactList extends StatefulWidget {
  const ContactList({Key? key}) : super(key: key);

  @override
  State<ContactList> createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  List<Contact> contacts = [];
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

  Future<void> getContacts() async {
    List cons = [];

    final conn = RedisConnection();
    await conn.connect('10.0.2.2', 6379).then((Command command) {
      command.send_object(["EXISTS", "${MyApp.userPhone}contacts"]).then(
          (var value) {
        if (value == 1) {
          command.send_object([
            "lrange",
            "${MyApp.userPhone}contacts",
            "0",
            "-1"
          ]).then((var response) {
            cons = response;

            for (var con in response) {
              command.send_object(["hvals", con]).then((var response) {
                contacts.add(Contact(response[2], response[0], response[1]));
                setState(() {});
              });
            }
          });
        } else {
          print('no contacts');
        }
      });
    });
  }

  TextEditingController phoneController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: MyApp.isLogin
              ? [
                  Text('Contacts'),
                  TextButton.icon(
                    onPressed: () {
                      contacts = [];
                      MyApp.isLogin = false;
                      setState(() {});
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white70,
                    ),
                    label: Text(
                      'exit',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ]
              : [
                  Text('Login'),
                ],
        ),
      ),
      floatingActionButton: MyApp.isLogin
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return AddingContactPage();
                    },
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: !MyApp.isLogin
          ? SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 100, left: 10, right: 10, bottom: 20),
                      child: TextField(
                        style: TextStyle(fontSize: 20),
                        controller: phoneController,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(50.0), //<-- SEE HERE
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(50.0), //<-- SEE HERE
                          ),
                          prefixIcon: const Icon(Icons.phone_android),
                          prefix: Text('+98'),
                          border: OutlineInputBorder(),
                          labelText: 'phone number',
                          contentPadding: EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    Text(
                      'example : +989101051122',
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (phoneController.text.length == 10 &&
                            phoneController.text.substring(0, 1) == '9') {
                          MyApp.userPhone = "0${phoneController.text}";
                          MyApp.isLogin = true;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(snackBarSuccess);
                          getContacts();
                          setState(() {});
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(snackBarError);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'enter     ',
                            style: TextStyle(fontSize: 20),
                          ),
                          Icon(Icons.login),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () {
                contacts = [];
                return Future.delayed(const Duration(seconds: 1), () async {
                  await getContacts();
                });
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (text) async {
                          contacts = [];
                          final conn = RedisConnection();
                          await conn
                              .connect('10.0.2.2', 6379)
                              .then((Command command) {
                            command.send_object([
                              "lrange",
                              "${MyApp.userPhone}:$text",
                              "0",
                              "-1"
                            ]).then((var response) {
                              for (var con in response) {
                                command.send_object(["hvals", con]).then(
                                    (var response) {
                                  contacts.add(Contact(
                                      response[2], response[0], response[1]));
                                  setState(() {});
                                });
                              }
                            });
                          });
                          setState(() {});
                        },
                        controller: searchController,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(50.0), //<-- SEE HERE
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(50.0), //<-- SEE HERE
                          ),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(),
                          labelText: 'Search',
                          hintText: 'Search',
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      List.generate(
                        contacts.length,
                        (index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                                top: 10, left: 10, right: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30)),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.deepPurple[400],
                                ),
                                onPressed: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        return ChatPage(
                                          contact: contacts[index],
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          child: randomAvatar(
                                              contacts[index].phoneNumber,
                                              height: 50,
                                              width: 50)
                                          // Image.asset(
                                          //   'assets/profile.png',
                                          //   width: 50,
                                          //   height: 50,
                                          // ),
                                          ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SubstringHighlight(
                                          text: contacts[index].name,
                                          term: searchController
                                              .text, //searchController.text,
                                          textStyle: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        SubstringHighlight(
                                          text: contacts[index].phoneNumber,
                                          term: searchController.text,
                                          textStyle:
                                              TextStyle(color: Colors.white),
                                        ),
                                        SizedBox(
                                          height: 5,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
