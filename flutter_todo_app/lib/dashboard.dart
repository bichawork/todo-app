import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_slidable/flutter_slidable.dart';

// Assuming config.dart contains API endpoints: addtodo, getToDoList, deleteTodo, updateTodo
import 'config.dart';

class Todo {
  final String id;
  final String title;
  final String description;
  Todo({required this.id, required this.title, required this.description});
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? 'No description',
    );
  }

  @override
  String toString() => 'Todo(id: $id, title: $title, description: $description)';
}

class Dashboard extends StatefulWidget {
  final String token;
  const Dashboard({required this.token, Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? userId;
  final _todoTitle = TextEditingController();
  final _todoDesc = TextEditingController();
  List<Todo>? items;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _todoTitle.dispose();
    _todoDesc.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
      if (JwtDecoder.isExpired(widget.token)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        // TODO: Navigate to login screen
        return;
      }
      userId = jwtDecodedToken['_id'];
      print('User ID: $userId');
      if (userId != null) {
        await getTodoList(userId!);
      }
    } catch (e) {
      print('JWT decode error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid token: $e')),
      );
    }
  }

  Future<void> addTodo() async {
    if (_todoTitle.text.trim().isEmpty || _todoDesc.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    var regBody = {
      "userId": userId,
      "title": _todoTitle.text.trim(),
      "description": _todoDesc.text.trim(),
    };

    print('addTodo request body: $regBody');

    try {
      var response = await http.post(
        Uri.parse(addtodo),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(regBody),
      ).timeout(const Duration(seconds: 10));

      print('addTodo status: ${response.statusCode}');
      print('addTodo body: ${response.body}');

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
        return;
      }

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == true) {
        _todoDesc.clear();
        _todoTitle.clear();
        Navigator.pop(context);
        await getTodoList(userId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add todo: ${jsonResponse['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('addTodo error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> editTodo(String id) async {
    if (_todoTitle.text.trim().isEmpty || _todoDesc.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    var regBody = {
      "id": id,
      "title": _todoTitle.text.trim(),
      "description": _todoDesc.text.trim(),
    };

    print('editTodo request body: $regBody');

    try {
      var response = await http.post(
        Uri.parse(updateTodo),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(regBody),
      ).timeout(const Duration(seconds: 10));

      print('editTodo status: ${response.statusCode}');
      print('editTodo body: ${response.body}');

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
        return;
      }

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == true) {
        _todoDesc.clear();
        _todoTitle.clear();
        Navigator.pop(context);
        await getTodoList(userId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update todo: ${jsonResponse['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('editTodo error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> getTodoList(String userId) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      var response = await http.get(
        Uri.parse('$getToDoList?userId=$userId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      ).timeout(const Duration(seconds: 10));

      print('getTodoList status: ${response.statusCode}');
      print('getTodoList body: ${response.body}');

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
        return;
      }

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['success'] == null || jsonResponse['success'] is! List) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid response format')),
        );
        return;
      }

      items = (jsonResponse['success'] as List)
          .map((item) => Todo.fromJson(item))
          .toList();
      print('Items length: ${items?.length}');
      print('Items: $items');
      setState(() {});
    } catch (e) {
      print('getTodoList error: $e');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch todos: $e')),
      );
    } finally {
      print('getTodoList completed');
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteItem(String id) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    var regBody = {"id": id};
    try {
      var response = await http.post(
        Uri.parse(deleteTodo),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode(regBody),
      ).timeout(const Duration(seconds: 10));

      print('deleteItem status: ${response.statusCode}');
      print('deleteItem body: ${response.body}');

      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
        return;
      }

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == true) {
        await getTodoList(userId!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete todo: ${jsonResponse['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      print('deleteItem error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 20.0,
                left: 30.0,
                right: 30.0,
                bottom: 30.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10.0),
                  const Text(
                    'ToDo with NodeJS + MongoDB',
                    style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${items?.length ?? 0} Task${items?.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : items == null
                          ? const Center(child: Text('Failed to load tasks'))
                          : items!.isEmpty
                              ? const Center(child: Text('No tasks available'))
                              : RefreshIndicator(
                                  onRefresh: () => userId != null ? getTodoList(userId!) : Future.value(),
                                  child: ListView.builder(
                                    itemCount: items!.length,
                                    itemBuilder: (context, index) {
                                      final todo = items![index];
                                      return Slidable(
                                        key: ValueKey(todo.id),
                                        endActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          children: [
                                            SlidableAction(
                                              backgroundColor: const Color(0xFF0392CF),
                                              foregroundColor: Colors.white,
                                              icon: Icons.edit,
                                              label: 'Edit',
                                              onPressed: (context) => _displayEditDialog(context, todo),
                                            ),
                                            SlidableAction(
                                              backgroundColor: const Color(0xFFFE4A49),
                                              foregroundColor: Colors.white,
                                              icon: Icons.delete,
                                              label: 'Delete',
                                              onPressed: (context) => deleteItem(todo.id),
                                            ),
                                          ],
                                        ),
                                        child: Card(
                                          child: ListTile(
                                            leading: const Icon(Icons.task),
                                            title: Text(todo.title),
                                            subtitle: Text(todo.description),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _displayTextInputDialog(context),
        child: const Icon(Icons.add),
        tooltip: 'Add To-Do',
      ),
    );
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    _todoTitle.clear();
    _todoDesc.clear();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add To-Do'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _todoTitle,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ).p4().px8(),
              TextField(
                controller: _todoDesc,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ).p4().px8(),
              ElevatedButton(
                onPressed: addTodo,
                child: const Text("Add"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _displayEditDialog(BuildContext context, Todo todo) async {
    _todoTitle.text = todo.title;
    _todoDesc.text = todo.description;
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit To-Do'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _todoTitle,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ).p4().px8(),
              TextField(
                controller: _todoDesc,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Description",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                ),
              ).p4().px8(),
              ElevatedButton(
                onPressed: () => editTodo(todo.id),
                child: const Text("Update"),
              ),
            ],
          ),
        );
      },
    );
  }
}