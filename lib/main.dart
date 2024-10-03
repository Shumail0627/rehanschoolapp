import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'drawer_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyTask {
  final String title;
  bool isCompleted;

  DailyTask({required this.title, this.isCompleted = false});
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rehan School',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboard(),
        // Add other routes here if needed
      },
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      final userRole = prefs.getString('user_role');
      final userCampus = prefs.getString('user_campus');
      if (userRole != null && userCampus != null) {
        _navigateToAppropriateScreen(userId, userRole, userCampus);
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        final response = await http.post(
          Uri.parse('http://school.superteclabs.com/login_api.php'),
          body: {
            'email': _email,
            'password': _password,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            // Store user data in SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', data['user_id'].toString());
            await prefs.setString('user_role', data['role']);
            await prefs.setString(
                'user_campus', data['campus'] ?? 'Default Campus');

            _navigateToAppropriateScreen(
              data['user_id'].toString(),
              data['role'],
              data['campus'] ?? 'Default Campus',
            );
          } else {
            setState(() {
              _errorMessage = data['message'];
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to connect to the server';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAppropriateScreen(String userId, String role, String campus) {
    switch (role) {
      case 'Admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboard()),
        );
        break;
      case 'Student':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(studentId: userId),
          ),
        );
        break;
      case 'Principal':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PrincipalDashboard(
              principalId: userId,
              campus: campus,
            ),
          ),
        );
        break;
      default:
        setState(() {
          _errorMessage = 'Unknown user role: $role';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: Column(
            children: [
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  color: Color(0xFF0047AB),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(80),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 60,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Rehan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'School',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your email' : null,
                          onChanged: (value) => _email = value,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          obscureText: true,
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your password'
                              : null,
                          onChanged: (value) => _password = value,
                        ),
                        const SizedBox(height: 20),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0047AB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> dashboardData = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://school.superteclabs.com/admin_dashboard_api.php'),
      );

      if (response.statusCode == 200) {
        // Print the raw response for debugging
        print('Raw API Response: ${response.body}');

        final decodedData = json.decode(response.body);

        if (decodedData is Map<String, dynamic>) {
          setState(() {
            dashboardData = decodedData;
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected data format: ${response.body}');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchDashboardData: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 120.0,
                        floating: false,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: const Text('Admin Dashboard'),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue[400]!, Colors.blue[800]!],
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AddUserScreen(
                                        campus: '', isStudent: false)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: _logout,
                          ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildTotalOverviewCard(),
                              const SizedBox(height: 20),
                              const Text(
                                'Campus Overview',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => buildCampusCard(index),
                            childCount: dashboardData.keys
                                .where((key) => key.endsWith('_campus'))
                                .length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: buildTotalFeesSection(),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget buildTotalOverviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Overview',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                buildOverviewItem(
                    'Students', dashboardData['total_students'], Icons.school,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllUsersScreen(userType: 'Student'),
                    ),
                  );
                }),
                buildOverviewItem(
                    'Teachers', dashboardData['total_teachers'], Icons.person,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllUsersScreen(userType: 'Teacher'),
                    ),
                  );
                }),
                buildOverviewItem(
                    'Principals',
                    dashboardData['total_principals'],
                    Icons.person_outline, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AllUsersScreen(userType: 'Principal'),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOverviewItem(
      String label, dynamic value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AllUsersScreen(userType: label.replaceAll('s', '')),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 30, color: Colors.blue[700]),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700])),
        ],
      ),
    );
  }

  Widget buildCampusCard(int index) {
    String campusKey = dashboardData.keys
        .where((key) => key.endsWith('_campus'))
        .elementAt(index);
    Map<String, dynamic> campusData = dashboardData[campusKey];
    String campusName =
        campusKey.replaceAll('_campus', '').replaceAll('_', ' ');

    return GestureDetector(
      onTap: () => navigateToCampusDetails(campusName),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                campusName.toUpperCase(),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildCampusItem(
                      'Students', campusData['student_count'], Icons.school),
                  buildCampusItem(
                      'Teachers', campusData['teacher_count'], Icons.person),
                ],
              ),
              const SizedBox(height: 8),
              buildCampusItem('Principals', campusData['principal_count'],
                  Icons.person_outline),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCampusItem(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue[700]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value.toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget buildTotalFeesSection() {
    print("Building Total Fees Section. Data: $dashboardData");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total Fees Received',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount:
              dashboardData.keys.where((key) => key.endsWith('_campus')).length,
          itemBuilder: (context, index) {
            String campusKey = dashboardData.keys
                .where((key) => key.endsWith('_campus'))
                .elementAt(index);
            Map<String, dynamic> campusData = dashboardData[campusKey];
            String campusName =
                campusKey.replaceAll('_campus', '').replaceAll('_', ' ');

            print("Campus: $campusName, Data: $campusData");

            double totalFees =
                double.tryParse(campusData['total_fees']?.toString() ?? '0') ??
                    0.0;
            print(
                "Campus: $campusName, Raw Total Fees: ${campusData['total_fees']}, Parsed Total Fees: $totalFees");

            return Card(
              color: Colors.green,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      campusName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PKR ${totalFees.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void navigateToCampusDetails(String campus) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampusDetailsScreen(campus: campus),
      ),
    );
  }

  void _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
}

class AllUsersScreen extends StatefulWidget {
  final String userType;

  const AllUsersScreen({Key? key, required this.userType}) : super(key: key);

  @override
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> displayedUsers = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/get_all_users_api.php?type=${widget.userType}'),
      );

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        print('Decoded data: $decodedData');

        if (decodedData.containsKey('students') &&
            decodedData['students'] is List) {
          setState(() {
            users = List<Map<String, dynamic>>.from(decodedData['students']);
            displayedUsers = List.from(users);
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected data format: $decodedData');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  void filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedUsers = List.from(users);
      } else {
        displayedUsers = users
            .where((user) =>
                user['name'].toLowerCase().contains(query.toLowerCase()) ||
                (user['roll_no'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
                (user['email'] ?? '').toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'All ${widget.userType}s',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        onChanged: filterUsers,
                        decoration: InputDecoration(
                          hintText: 'Search ${widget.userType}s',
                          prefixIcon: Icon(Icons.search, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: displayedUsers.length,
                        itemBuilder: (context, index) {
                          final user = displayedUsers[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: user['picture_path'] != null
                                    ? NetworkImage(
                                        'http://school.superteclabs.com/${user['picture_path']}')
                                    : null,
                                child: user['picture_path'] == null
                                    ? Text(
                                        user['name'][0].toUpperCase(),
                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user['name'] ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['roll_no'] ?? user['email'] ?? 'N/A',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user['campus'] ?? 'N/A',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue),
                              onTap: () {
                                // Handle user tap, e.g., navigate to user details
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailsScreen(userId: user['id'], userType: user['user_type']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

class UserDetailsScreen extends StatefulWidget {
  final String userId;
  final String userType;

  const UserDetailsScreen({
    Key? key,
    required this.userId,
    required this.userType,
  }) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/user_details_api.php?id=${widget.userId}&type=${widget.userType}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        setState(() {
          userData = decodedData['user'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> updateUserField(String field, String value) async {
    try {
      final response = await http.post(
        Uri.parse('http://school.superteclabs.com/update_user_field_api.php'),
        body: {
          'user_id': widget.userId,
          'user_type': widget.userType,
          'field': field,
          'value': value,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            userData[field] = value;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated successfully')),
          );
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update field');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, {bool editable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          editable
              ? GestureDetector(
                  onTap: () => _showEditDialog(label, value),
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(color: Colors.blue),
                  ),
                )
              : Text(value),
        ],
      ),
    );
  }

  void _showEditDialog(String field, String currentValue) {
    String newValue = currentValue;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $field'),
        content: TextField(
          onChanged: (value) => newValue = value,
          controller: TextEditingController(text: currentValue),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              updateUserField(field.toLowerCase().replaceAll(' ', '_'), newValue);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userType} Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserScreen(
                    userId: widget.userId,
                    userType: widget.userType,
                    userData: userData,
                  ),
                ),
              ).then((_) => fetchUserData());
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: userData['picture_path'] != null
                              ? NetworkImage(
                                  'http://school.superteclabs.com/${userData['picture_path']}')
                              : null,
                          child: userData['picture_path'] == null
                              ? Text(
                                  userData['name'][0].toUpperCase(),
                                  style: const TextStyle(fontSize: 40),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildDetailRow('Name', userData['name'] ?? 'N/A'),
                      _buildDetailRow('Email', userData['email'] ?? 'N/A'),
                      _buildDetailRow('Phone', userData['phone'] ?? 'N/A'),
                      _buildDetailRow('Campus', userData['campus'] ?? 'N/A'),
                      if (widget.userType == 'Student') ...[
                        _buildDetailRow('Roll Number', userData['roll_no'] ?? 'N/A'),
                        _buildDetailRow('Class', userData['class'] ?? 'N/A'),
                        _buildDetailRow('Father\'s Name', userData['father_name'] ?? 'N/A'),
                        _buildDetailRow('Mother\'s Name', userData['mother_name'] ?? 'N/A'),
                      ],
                      if (widget.userType == 'Teacher') ...[
                        _buildDetailRow('Subject', userData['subject'] ?? 'N/A'),
                      ],
                      _buildDetailRow('Date of Birth', userData['dob'] ?? 'N/A'),
                      _buildDetailRow('Date of Joining', userData['doj'] ?? 'N/A'),
                      _buildDetailRow('WhatsApp Number', userData['whatsapp'] ?? 'N/A'),
                      _buildDetailRow('City', userData['city'] ?? 'N/A'),
                      _buildDetailRow('Country', userData['country'] ?? 'N/A'),
                      if (widget.userType == 'Student') ...[
                        _buildDetailRow('Reason for Joining', userData['reason_for_joining'] ?? 'N/A'),
                        _buildDetailRow('Favorite Food', userData['favorite_food'] ?? 'N/A'),
                        _buildDetailRow('Biggest Wish', userData['biggest_wish'] ?? 'N/A'),
                        _buildDetailRow('Vision for 10 Years', userData['vision_10_years'] ?? 'N/A'),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class EditUserScreen extends StatefulWidget {
  final String userId;
  final String userType;
  final Map<String, dynamic> userData;

  const EditUserScreen({
    Key? key,
    required this.userId,
    required this.userType,
    required this.userData,
  }) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _editedUserData;

  @override
  void initState() {
    super.initState();
    _editedUserData = Map.from(widget.userData);
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final response = await http.post(
          Uri.parse('http://school.superteclabs.com/update_user_api.php'),
          body: {
            'user_id': widget.userId,
            'user_type': widget.userType,
            ..._editedUserData,
          },
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User updated successfully')),
            );
            Navigator.pop(context, true);
          } else {
            throw Exception(result['message']);
          }
        } else {
          throw Exception('Failed to update user');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update user: $e')),
        );
      }
    }
  }

  Widget _buildTextField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: _editedUserData[key],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        onSaved: (value) => _editedUserData[key] = value!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.userType}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField('Name', 'name'),
              _buildTextField('Email', 'email'),
              _buildTextField('Phone', 'phone'),
              _buildTextField('Campus', 'campus'),
              if (widget.userType == 'Student') ...[
                _buildTextField('Roll Number', 'roll_no'),
                _buildTextField('Class', 'class'),
                _buildTextField('Father\'s Name', 'father_name'),
                _buildTextField('Mother\'s Name', 'mother_name'),
              ],
              if (widget.userType == 'Teacher') ...[
                _buildTextField('Subject', 'subject'),
              ],
              _buildTextField('Date of Birth', 'dob'),
              _buildTextField('Date of Joining', 'doj'),
              _buildTextField('WhatsApp Number', 'whatsapp'),
              _buildTextField('City', 'city'),
              _buildTextField('Country', 'country'),
              if (widget.userType == 'Student') ...[
                _buildTextField('Reason for Joining', 'reason_for_joining'),
                _buildTextField('Favorite Food', 'favorite_food'),
                _buildTextField('Biggest Wish', 'biggest_wish'),
                _buildTextField('Vision for 10 Years', 'vision_10_years'),
              ],
              ElevatedButton(
                onPressed: _updateUser,
                child: Text('Update ${widget.userType}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



enum AssignmentStatus { Pending, Completed, Submitted }

class DailyAssignment {
  final String id;
  final String name;
  final AssignmentStatus status;
  final String remarks;

  DailyAssignment({
    required this.id,
    required this.name,
    required this.status,
    this.remarks = '',
  });

  factory DailyAssignment.fromJson(Map<String, dynamic> json) {
    return DailyAssignment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString() ?? ''),
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  static AssignmentStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AssignmentStatus.Completed;
      case 'submitted':
        return AssignmentStatus.Submitted;
      default:
        return AssignmentStatus.Pending;
    }
  }
}

class AssignmentsScreen extends StatefulWidget {
  final String studentId;

  const AssignmentsScreen({Key? key, required this.studentId})
      : super(key: key);

  @override
  _AssignmentsScreenState createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<DailyAssignment> assignments = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('Student ID in AssignmentsScreen: ${widget.studentId}');
    fetchAssignments();
  }

  Future<void> fetchAssignments() async {
    if (widget.studentId.isEmpty) {
      setState(() {
        errorMessage = 'Error: Student ID is missing';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/get_daily_assignments_api.php?student_id=${widget.studentId}&date=${selectedDate.toIso8601String().split('T')[0]}'),
      );

      print('Assignments API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            assignments = (data['data']['assignments'] as List?)
                    ?.map((assignment) => DailyAssignment.fromJson(assignment))
                    .toList() ??
                [];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
      print('Error fetching assignments: $e');
    }
  }

  Future<void> submitAssignment(String assignmentId, String link) async {
    if (widget.studentId.isEmpty || assignmentId.isEmpty) {
      setState(() {
        errorMessage = 'Error: Student ID or Assignment ID is missing';
      });
      print(
          'Missing fields: studentId=${widget.studentId}, assignmentId=$assignmentId');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://school.superteclabs.com/submit_assignment_api.php'),
        body: {
          'student_id': widget.studentId,
          'assignment_id': assignmentId,
          'link': link,
          'date': selectedDate.toIso8601String().split('T')[0],
        },
      );

      print('API Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignment submitted successfully')),
          );
          await fetchAssignments();
        } else {
          throw Exception(data['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to submit assignment');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
      print('Error submitting assignment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Assignments'),
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: _buildAssignmentsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                });
                fetchAssignments();
              }
            },
            child: Text('Select Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }
    if (assignments.isEmpty) {
      return Center(child: Text('No assignments for this date'));
    }
    return ListView.builder(
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        return _buildAssignmentCard(assignments[index]);
      },
    );
  }

  Widget _buildAssignmentCard(DailyAssignment assignment) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text(assignment.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${assignment.status.toString().split('.').last}'),
            if (assignment.remarks.isNotEmpty)
              Text('Remarks: ${assignment.remarks}'),
          ],
        ),
        trailing: _buildAssignmentAction(assignment),
      ),
    );
  }

  Widget _buildAssignmentAction(DailyAssignment assignment) {
    if (assignment.status == AssignmentStatus.Completed) {
      return Icon(Icons.check_circle, color: Colors.green);
    }
    if (assignment.name.toLowerCase() == 'yoga' ||
        assignment.name.toLowerCase() == 'meditation') {
      return ElevatedButton(
        onPressed: () => _markAsCompleted(assignment),
        child: Text('Mark Complete'),
      );
    }
    return ElevatedButton(
      onPressed: () => _showSubmitDialog(assignment),
      child: Text('Submit'),
    );
  }

  void _markAsCompleted(DailyAssignment assignment) {
    // Implement the logic to mark the assignment as completed without a link
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Activity Completed'),
          content:
              Text('Great job completing your ${assignment.name} activity!'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                fetchAssignments();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSubmitDialog(DailyAssignment assignment) {
    String link = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Submit Assignment'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Submission Link'),
            onChanged: (value) => link = value,
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                if (link.isNotEmpty) {
                  submitAssignment(assignment.id, link);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a submission link')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class StudentDashboard extends StatefulWidget {
  final String studentId;

  const StudentDashboard({Key? key, required this.studentId}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  Map<String, dynamic> studentData = {};
  bool isLoading = true;
  String errorMessage = '';
  bool showFeeReminder = false;

  @override
  void initState() {
    super.initState();
    fetchStudentData();
    checkFeeReminder();
  }

  Future<void> checkFeeReminder() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final lastReminderDate = prefs.getString('lastFeeReminderDate');

    if (lastReminderDate == null ||
        DateTime.parse(lastReminderDate).month != now.month) {
      setState(() {
        showFeeReminder = true;
      });
      prefs.setString('lastFeeReminderDate', now.toIso8601String());
    }
  }

  Future<void> fetchStudentData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/student_details_api.php?id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedData = json.decode(response.body);
        if (parsedData.containsKey('student') &&
            parsedData['student'] is Map<String, dynamic>) {
          setState(() {
            studentData = parsedData['student'];
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format or no student data available');
        }
      } else {
        throw Exception('Failed to load student data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Home',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // Handle notification action
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Open drawer
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchStudentData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        if (showFeeReminder) _buildFeeReminder(),
                        _buildStudentInfo(),
                        _buildDashboardCards(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildFeeReminder() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade200, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange[800], size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Kindly pay your fees for this month. If you have already paid, please ignore this reminder.',
              style: GoogleFonts.poppins(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.orange[800]),
            onPressed: () {
              setState(() {
                showFeeReminder = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundImage: studentData['picture_path'] != null
                    ? NetworkImage(
                        'http://school.superteclabs.com/${studentData['picture_path']}')
                    : const AssetImage('assets/default_profile.png')
                        as ImageProvider,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentData['name'] ?? 'Student Name',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Roll Number: ${studentData['roll_no'] ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Class: ${studentData['class'] ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text('More Details',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            children: [
              _buildDetailRow('Age', studentData['age']),
              _buildDetailRow('Date of Birth', studentData['dob']),
              _buildDetailRow('Date of Joining', studentData['doj']),
              _buildDetailRow(
                  'WhatsApp Number', studentData['student_whatsapp']),
              _buildDetailRow('City', studentData['city']),
              _buildDetailRow('Country', studentData['country']),
              _buildDetailRow('Father\'s Name', studentData['father_name']),
              _buildDetailRow('Mother\'s Name', studentData['mother_name']),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentDetailsScreen(
                      studentId: widget.studentId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                elevation: 5,
              ),
              child: Text(
                'View Full Profile',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          Text(value?.toString() ?? 'N/A', style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  Widget _buildDashboardCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _buildDashboardItem(Icons.school, 'My Attendance', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AttendanceScreen(studentId: widget.studentId),
              ),
            );
          }),
          _buildDashboardItem(Icons.payment, 'My Fees', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FeesScreen(studentId: widget.studentId),
              ),
            );
          }),
          _buildDashboardItem(Icons.assignment, 'Assignment', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AssignmentsScreen(studentId: widget.studentId),
              ),
            );
          }),
          _buildDashboardItem(Icons.assessment, 'Result', () {
            // Navigate to Result screen when implemented
          }),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(IconData icon, String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Logout"),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      );
    },
  );
}

class StudentDetailsScreen extends StatefulWidget {
  final String studentId;
  final bool isPrincipal;

  const StudentDetailsScreen({
    Key? key,
    required this.studentId,
    this.isPrincipal = false,
  }) : super(key: key);

  @override
  _StudentDetailsScreenState createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Map<String, dynamic> studentData = {};
  bool isLoading = true;
  String errorMessage = '';
  double profileCompletion = 0.0;

  Map<String, String?> socialLinks = {
    'facebook': null,
    'linkedin': null,
    'youtube': null,
    'instagram': null,
  };

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/student_details_api.php?id=${widget.studentId}'),
      );

      print("API Response Status Code: ${response.statusCode}");
      print("API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsedData = json.decode(response.body);
        if (parsedData.containsKey('student') &&
            parsedData['student'] is Map<String, dynamic>) {
          setState(() {
            studentData = parsedData['student'];
            isLoading = false;
          });
          print("Parsed Student Data: $studentData"); // For debugging
        } else {
          throw Exception('Invalid data format or no student data available');
        }
      } else {
        throw Exception('Failed to load student data: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching student data: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  void calculateProfileCompletion() {
    int totalFields = studentData.length;
    int filledFields = studentData.values
        .where((v) => v != null && v.toString().isNotEmpty)
        .length;
    profileCompletion = (filledFields / totalFields) * 100;
    setState(() {});
  }

  Future<void> updateField(String field, String value) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://school.superteclabs.com/update_student_field_api.php'),
        body: {
          'student_id': widget.studentId,
          'field': field,
          'value': value,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            studentData[field] = value;
          });
          calculateProfileCompletion();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Updated successfully')),
          );
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update field');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  Future<void> updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://school.superteclabs.com/update_profile_picture_api.php'),
        );

        request.fields['student_id'] = widget.studentId;
        request.files
            .add(await http.MultipartFile.fromPath('image', image.path));

        var response = await request.send();

        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final result = json.decode(responseData);
          if (result['status'] == 'success') {
            setState(() {
              studentData['picture_path'] = result['picture_path'];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile picture updated successfully')),
            );
          } else {
            throw Exception(result['message']);
          }
        } else {
          throw Exception('Failed to update profile picture');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  bool canEdit(String field) {
    List<String> editableFields = [
      'student_whatsapp',
      'introduction',
      'favorite_food_dishes',
      'biggest_wish',
      'vision_10_years',
      'ideal_personalities'
    ];
    return editableFields.contains(field.toLowerCase().replaceAll(' ', '_'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(child: _buildProfileHeader()),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildInfoSection('Personal Information', [
                          _buildInfoItem('Age', studentData['age']),
                          _buildInfoItem('Date of Birth', studentData['dob']),
                          _buildInfoItem('Date of Joining', studentData['doj']),
                          _buildInfoItem('Class', studentData['class']),
                          _buildInfoItem('Roll No', studentData['roll_no']),
                          _buildInfoItem('City', studentData['city']),
                          _buildInfoItem('Country', studentData['country']),
                          _buildInfoItem('Reason of Joining',
                              studentData['reason_for_joining']),
                          _buildInfoItem(
                              'WhatsApp', studentData['student_whatsapp']),
                        ]),
                        _buildInfoSection('Family Information', [
                          _buildInfoItem(
                              "Father's Name", studentData['father_name']),
                          _buildInfoItem(
                              "Father's Age", studentData['father_age']),
                          _buildInfoItem(
                              "Father's Occupation", studentData['father_job']),
                          _buildInfoItem("Father's Contact",
                              studentData['father_whatsapp']),
                          _buildInfoItem(
                              "Mother's Name", studentData['mother_name']),
                          _buildInfoItem(
                              "Mother's Age", studentData['mother_age']),
                          _buildInfoItem("Mother's Contact",
                              studentData['mother_whatsapp']),
                          _buildInfoItem(
                              "Mother's Occupation", studentData['mother_job']),
                          _buildInfoItem("Number of Siblings",
                              studentData['number_of_siblings']),
                        ]),
                        _buildInfoSection('Additional Information', [
                          _buildInfoItem('Favorite Food',
                              studentData['favorite_food_dishes']),
                          _buildInfoItem('Plan for 1 Crore Rupees',
                              studentData['plan_for_crore_rupees']),
                          _buildInfoItem(
                              'Biggest Wish', studentData['biggest_wish']),
                          _buildInfoItem('Vision in 10 Years',
                              studentData['vision_10_years']),
                          _buildInfoItem('Ideal Personalities',
                              studentData['ideal_personalities']),
                        ]),
                        _buildSocialLinks(),
                      ]),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          studentData['name'] ?? 'Student Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'http://school.superteclabs.com/${studentData['picture_path']}',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 58,
                  backgroundImage: studentData['picture_path'] != null
                      ? NetworkImage(
                          'http://school.superteclabs.com/${studentData['picture_path']}')
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
                ),
              ),
              if (widget.isPrincipal)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: updateProfilePicture,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            studentData['name'] ?? 'N/A',
            style:
                GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            studentData['campus'] ?? 'N/A',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Text(
            'Profile Completion',
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: profileCompletion / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${profileCompletion.toStringAsFixed(1)}% Complete',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value?.toString() ?? 'N/A',
              style: GoogleFonts.poppins(),
            ),
          ),
          if (widget.isPrincipal && canEdit(label))
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
              onPressed: () => _showEditDialog(label, value?.toString()),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(String label, String? currentValue) {
    String newValue = currentValue ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: TextEditingController(text: currentValue),
          onChanged: (value) => newValue = value,
          decoration: const InputDecoration(hintText: 'Enter new value'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              updateField(label.toLowerCase().replaceAll(' ', '_'), newValue);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social Links',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialIcon(
                    'Facebook', Icons.facebook, studentData['facebook_link']),
                _buildSocialIcon(
                    'LinkedIn', Icons.link, studentData['linkedin_link']),
                _buildSocialIcon('YouTube', Icons.play_circle_filled,
                    studentData['youtube_link']),
                _buildSocialIcon('Instagram', Icons.camera_alt,
                    studentData['instagram_link']),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showEditSocialLinksDialog,
              child: Text('Update Social Links'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialLinkItem(String platform, IconData icon, String? link) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              link ?? 'Not provided',
              style: TextStyle(color: link != null ? Colors.blue : Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(String platform, IconData icon, String? link) {
    return InkWell(
      onTap: () => _launchSocialLink(platform),
      child: Icon(
        icon,
        color: link != null && link.isNotEmpty ? Colors.blue : Colors.grey,
        size: 30,
      ),
    );
  }

  void _launchSocialLink(String platform) async {
    String? link = studentData['${platform.toLowerCase()}_link'];
    if (link != null && link.isNotEmpty) {
      final Uri url = Uri.parse(link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $link')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No $platform link provided')),
      );
    }
  }

  void _showEditSocialLinksDialog() {
    Map<String, TextEditingController> controllers = {
      'facebook': TextEditingController(text: studentData['facebook_link']),
      'linkedin': TextEditingController(text: studentData['linkedin_link']),
      'youtube': TextEditingController(text: studentData['youtube_link']),
      'instagram': TextEditingController(text: studentData['instagram_link']),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Social Links'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: controllers.entries.map((entry) {
              return TextField(
                controller: entry.value,
                decoration: InputDecoration(labelText: entry.key.capitalize()),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Save'),
            onPressed: () {
              _updateSocialLinks(controllers);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateSocialLinks(
      Map<String, TextEditingController> controllers) async {
    try {
      final response = await http.post(
        Uri.parse('http://school.superteclabs.com/update_social_links_api.php'),
        body: {
          'student_id': widget.studentId,
          'facebook_link': controllers['facebook']!.text,
          'linkedin_link': controllers['linkedin']!.text,
          'youtube_link': controllers['youtube']!.text,
          'instagram_link': controllers['instagram']!.text,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            studentData['facebook_link'] = controllers['facebook']!.text;
            studentData['linkedin_link'] = controllers['linkedin']!.text;
            studentData['youtube_link'] = controllers['youtube']!.text;
            studentData['instagram_link'] = controllers['instagram']!.text;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Social links updated successfully')),
          );
        } else {
          throw Exception(result['message']);
        }
      } else {
        throw Exception('Failed to update social links');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update social links: $e')),
      );
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AttendanceScreen extends StatefulWidget {
  final String studentId;

  const AttendanceScreen({super.key, required this.studentId});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> attendanceData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/student_attendance_api.php?id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          attendanceData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: const Text('My Attendance'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Column(
                  children: [
                    buildAttendanceSummary(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: attendanceData.length,
                        itemBuilder: (context, index) {
                          final attendance = attendanceData[index];
                          return buildAttendanceCard(attendance);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget buildAttendanceSummary() {
    int totalDays = attendanceData.length;
    int presentDays = attendanceData.where((a) => a['attended'] == '1').length;
    double attendancePercentage = (presentDays / totalDays) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue,
      child: Column(
        children: [
          const Text(
            'Attendance Summary',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              buildSummaryItem('Total Days', totalDays.toString()),
              buildSummaryItem('Present', presentDays.toString()),
              buildSummaryItem(
                  'Percentage', '${attendancePercentage.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryItem(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value ?? 'N/A', // Safely handle null values
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget buildAttendanceCard(Map<String, dynamic> attendance) {
    bool isPresent = attendance['attended'] == '1';

    // Handling null for 'date'
    String attendanceDate = attendance['date'] ?? 'Unknown Date';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          isPresent ? Icons.check_circle : Icons.cancel,
          color: isPresent ? Colors.green : Colors.red,
          size: 36,
        ),
        title: Text(
          // Use a fallback value for the date
          attendanceDate != 'Unknown Date'
              ? DateFormat('MMMM d, yyyy')
                  .format(DateTime.parse(attendanceDate))
              : 'Date Not Available',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          isPresent ? 'Present' : 'Absent',
          style: TextStyle(
            color: isPresent ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class FeesScreen extends StatefulWidget {
  final String studentId;

  const FeesScreen({super.key, required this.studentId});

  @override
  _FeesScreenState createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  Map<String, dynamic> feesData = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchFeesData();
  }

  Future<void> fetchFeesData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/student_fees_api.php?id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          feesData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load fees data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: const Text('My Fees'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildFeeSummary(),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Fee Records',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      buildFeeRecordsList(),
                    ],
                  ),
                ),
    );
  }

  Widget buildFeeSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Summary',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildSummaryItem('Total Paid', 'PKR ${feesData['total_paid']}'),
              buildSummaryItem(
                  'Outstanding', 'PKR ${feesData['outstanding_fee']}'),
              buildSummaryItem('Monthly Fee', 'PKR ${feesData['monthly_fee']}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget buildFeeRecordsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: feesData['fee_records'].length,
      itemBuilder: (context, index) {
        final record = feesData['fee_records'][index];
        final paymentDate =
            record['payment_date'] ?? '1970-01-01'; // Default date if null
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.receipt, color: Colors.blue),
            title: Text(
              DateFormat('MMMM d, yyyy').format(DateTime.parse(paymentDate)),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'PKR ${record['amount'] ?? '0'}', // Default amount if null
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CampusDetailsScreen extends StatefulWidget {
  final String campus;

  const CampusDetailsScreen({super.key, required this.campus});

  @override
  _CampusDetailsScreenState createState() => _CampusDetailsScreenState();
}

class _CampusDetailsScreenState extends State<CampusDetailsScreen> {
  List<dynamic> campusData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchCampusData();
  }

  Future<void> fetchCampusData() async {
    try {
      final response = await http.get(Uri.parse(
          'http://school.superteclabs.com/campus_details_api.php?campus=${widget.campus}'));

      if (response.statusCode == 200) {
        String cleanedResponse = response.body.trim();
        while (cleanedResponse.isNotEmpty && !cleanedResponse.startsWith('[')) {
          cleanedResponse = cleanedResponse.substring(1);
        }
        print('Cleaned response: $cleanedResponse');

        final decodedData = json.decode(cleanedResponse);

        if (decodedData is List) {
          setState(() {
            campusData = decodedData;
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected data format: $decodedData');
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error details: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerMenu(),
      appBar: AppBar(
        title: Text('${widget.campus} Campus',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : campusData.isEmpty
                    ? const Center(child: Text('No data available'))
                    : ListView.builder(
                        itemCount: campusData.length,
                        itemBuilder: (context, index) {
                          final student = campusData[index];
                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: CircleAvatar(
                                radius: 30,
                                backgroundImage: student['picture_path'] !=
                                            null &&
                                        student['picture_path'].isNotEmpty
                                    ? NetworkImage(
                                        'http://school.superteclabs.com/${student['picture_path']}')
                                    : AssetImage('assets/default_profile.png')
                                        as ImageProvider,
                                onBackgroundImageError:
                                    (exception, stackTrace) {
                                  print('Error loading image: $exception');
                                },
                              ),
                              title: Text(
                                student['name'] ?? 'No name',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(
                                    student['gmail'] ?? 'No email',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: student['status'] == 'Active'
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      student['status'] ?? 'No status',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.arrow_forward_ios,
                                  color: Colors.blue),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailsScreen(
                                        studentId: student['id']),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

Widget buildAttendanceProgressBar(int attendedDays, int totalDays) {
  double attendancePercentage = (attendedDays / totalDays) * 100;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Attendance: ${attendancePercentage.toStringAsFixed(2)}%'),
      const SizedBox(height: 5),
      LinearProgressIndicator(
        value: attendedDays / totalDays,
        backgroundColor: Colors.grey[300],
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    ],
  );
}

class Student {
  final String id;
  final String name;
  final String rollNo;
  final String campus;
  final String profilePicture; // Add this field

  Student({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.campus,
    required this.profilePicture, // Add this to the constructor
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      rollNo: json['roll_no'] ?? '',
      campus: json['campus'] ?? '',
      profilePicture: json['picture_path'] ?? '', // Parse from JSON
    );
  }
}

class PrincipalDashboard extends StatefulWidget {
  final String principalId;
  final String campus;

  const PrincipalDashboard({
    super.key,
    required this.principalId,
    required this.campus,
  });

  @override
  _PrincipalDashboardState createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  Map<String, dynamic> dashboardData = {};
  List<Student> allStudents = [];
  List<Student> displayedStudents = [];
  bool isLoading = true;
  String errorMessage = '';
  int _selectedIndex = 0;
  String principalName = '';
  String campusName = '';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  void refreshDashboard() {
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/principal_students_api.php?id=${widget.principalId}'),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body) as Map<String, dynamic>;

        if (decodedData.containsKey('principal') &&
            decodedData.containsKey('students')) {
          setState(() {
            dashboardData = decodedData;
            principalName = decodedData['principal']['name'];
            campusName = decodedData['principal']['campus'];
            allStudents = (decodedData['students'] as List)
                .map((data) => Student(
                      id: data['id'].toString(),
                      name: data['name'] ?? 'N/A',
                      rollNo: data['roll_no'] ?? 'N/A',
                      campus: data['campus'] ?? 'N/A',
                      profilePicture: data['picture_path'] ?? '',
                    ))
                .toList();
            displayedStudents = List.from(allStudents);
            isLoading = false;
          });
        } else {
          throw Exception('Unexpected data format: ${response.body}');
        }
      } else {
        throw Exception(
            'Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load dashboard data: $e';
        isLoading = false;
      });
    }
  }

  void filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        displayedStudents = List.from(allStudents);
      } else {
        displayedStudents = allStudents
            .where((student) =>
                student.name.toLowerCase().contains(query.toLowerCase()) ||
                student.rollNo.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Home - do nothing, already on home screen
        break;
      case 1:
        // View Students
        _showStudentsList();
        break;
      case 2:
        // Log out
        _showLogoutDialog();
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () async {
                // Clear SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Navigate to LoginScreen
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Principal Dashboard',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.black),
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : RefreshIndicator(
                  onRefresh: fetchDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildPrincipalInfo(),
                        _buildDashboardCards(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPrincipalInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _updateProfilePicture,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: dashboardData['principal']
                              ?['picture_path'] !=
                          null
                      ? NetworkImage(
                          'http://school.superteclabs.com/${dashboardData['principal']['picture_path']}')
                      : const AssetImage('assets/default_profile.png')
                          as ImageProvider,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            principalName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            campusName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://school.superteclabs.com/update_profile_picture_api.php'),
        );

        request.fields['user_id'] = widget.principalId;
        request.fields['user_type'] = 'principal';

        var pic =
            await http.MultipartFile.fromPath('profile_picture', image.path);
        request.files.add(pic);

        var response = await request.send();

        if (response.statusCode == 200) {
          String responseBody = await response.stream.bytesToString();
          var jsonResponse = json.decode(responseBody);
          if (jsonResponse['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile picture updated successfully')),
            );
            fetchDashboardData(); // Refresh data to show new picture
          } else {
            throw Exception(
                jsonResponse['message'] ?? 'Unknown error occurred');
          }
        } else {
          throw Exception('Failed to upload profile picture');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildDashboardItem(
            Icons.people, 'All Students', allStudents.length.toString(),
            onTap: _showStudentsList),
        _buildDashboardItem(Icons.date_range, 'Attendance', 'Mark', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MarkBulkAttendanceScreen(
                students: allStudents,
                campus: widget.campus,
                refreshDashboard: refreshDashboard,
              ),
            ),
          );
        }),
        _buildDashboardItem(Icons.person, 'All Teachers',
            dashboardData['total_teachers']?.toString() ?? '0', onTap: () {
          // Navigate to AllTeachersScreen when implemented
        }),
        _buildDashboardItem(Icons.payment, 'Fees Management', 'View',
            onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ManageFeesScreen(
                  students: allStudents, campus: widget.campus),
            ),
          );
        }),
        _buildDashboardItem(Icons.assignment, 'Assignments', 'View', onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AssignmentsOverviewScreen(campus: widget.campus),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDashboardItem(IconData icon, String label, String value,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                child: const Text("Add Student"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToAddUserScreen(isStudent: true);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                child: const Text("Add Teacher"),
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToAddUserScreen(isStudent: false);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAddUserScreen({required bool isStudent}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddUserScreen(
          campus: widget.campus,
          isStudent: isStudent,
        ),
      ),
    ).then((_) => fetchDashboardData()); // Refresh data after adding a user
  }

  void _showStudentsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Text(
                            'All Students',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: filterStudents,
                      decoration: InputDecoration(
                        hintText: 'Search students',
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: displayedStudents.length,
                      itemBuilder: (context, index) {
                        final student = displayedStudents[index];
                        return Card(
                          elevation: 2,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: student.profilePicture.isNotEmpty
                                  ? NetworkImage(
                                      'http://school.superteclabs.com/${student.profilePicture}')
                                  : AssetImage('assets/default_profile.png')
                                      as ImageProvider,
                              radius: 25,
                            ),
                            title: Text(
                              student.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              'Roll No: ${student.rollNo}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: Colors.blue),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailsScreen(
                                    studentId: student.id,
                                    isPrincipal: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStudentActions(BuildContext context, Student student) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentDetailsScreen(studentId: student.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditStudentScreen(studentId: student.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text('View Attendance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AttendanceScreen(studentId: student.id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('View Fees Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        StudentFeeDetailsScreen(studentId: student.id),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class AddUserScreen extends StatefulWidget {
  final String campus;
  final bool isStudent;

  const AddUserScreen({
    Key? key,
    required this.campus,
    required this.isStudent,
  }) : super(key: key);

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _userData = {};
  File? _image;
  final picker = ImagePicker();
  String _selectedRole = 'Student';
  String _selectedCampus = 'Korangi';

  List<String> _roles = ['Teacher', 'Student', 'Principal', 'Admin'];
  List<String> _campuses = ['Korangi', 'Munawwar', 'Islamabad', 'Online'];

  @override
  void initState() {
    super.initState();
    // Ensure that the initial values are in the respective lists
    _selectedRole = _roles.contains(widget.isStudent ? 'Student' : 'Teacher')
        ? (widget.isStudent ? 'Student' : 'Teacher')
        : _roles.first;
    _selectedCampus =
        _campuses.contains(widget.campus) ? widget.campus : _campuses.first;
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://school.superteclabs.com/add_user_api.php'),
        );

        request.fields.addAll({
          ..._userData,
          'campus': _selectedCampus,
          'role': _selectedRole,
        });

        if (_image != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'picture',
            _image!.path,
          ));
        }

        var response = await request.send();
        if (response.statusCode == 200) {
          String responseBody = await response.stream.bytesToString();
          var result = json.decode(responseBody);
          if (result['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$_selectedRole added successfully')),
            );
            Navigator.pop(context);
          } else {
            throw Exception(result['message']);
          }
        } else {
          throw Exception('Failed to add user');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding user: $e')),
        );
      }
    }
  }

  Widget _buildTextField(String label, String key, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: isMultiline ? 3 : 1,
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
        onSaved: (value) => _userData[key] = value!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add $_selectedRole'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _getImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _image != null ? FileImage(_image!) : null,
                    child: _image == null
                        ? Icon(Icons.add_a_photo, size: 40)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Name', 'name'),
              _buildTextField('Email', 'email'),
              _buildTextField('Password', 'password'),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles.map((String role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRole = newValue;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCampus,
                items: _campuses.map((String campus) {
                  return DropdownMenuItem<String>(
                    value: campus,
                    child: Text(campus),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCampus = newValue;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Campus',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedRole == 'Student') ...[
                _buildTextField('Roll Number', 'roll_no'),
                _buildTextField('Class', 'class'),
                _buildTextField('Father\'s Name', 'father_name'),
                _buildTextField('Mother\'s Name', 'mother_name'),
              ] else if (_selectedRole == 'Teacher') ...[
                _buildTextField('Subject', 'subject'),
              ],
              _buildTextField('Date of Birth', 'dob'),
              _buildTextField('Date of Joining', 'doj'),
              _buildTextField('WhatsApp Number', 'whatsapp'),
              _buildTextField('City', 'city'),
              _buildTextField('Country', 'country'),
              if (_selectedRole == 'Student') ...[
                _buildTextField('Reason for Joining', 'reason_for_joining',
                    isMultiline: true),
                _buildTextField('Favorite Food', 'favorite_food',
                    isMultiline: true),
                _buildTextField('Biggest Wish', 'biggest_wish',
                    isMultiline: true),
                _buildTextField('Vision for 10 Years', 'vision_10_years',
                    isMultiline: true),
              ],
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Add $_selectedRole'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditStudentScreen extends StatefulWidget {
  final String studentId;

  const EditStudentScreen({super.key, required this.studentId});

  @override
  _EditStudentScreenState createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  bool isLoading = true;
  Map<String, dynamic> studentData = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchStudentData();
  }

  Future<void> fetchStudentData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/student_details_api.php?id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          studentData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load student data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading student data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateStudentData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final response = await http.post(
          Uri.parse('http://school.superteclabs.com/update_student_api.php'),
          body: studentData,
        );

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Student data updated successfully')),
            );
            Navigator.pop(context);
          } else {
            throw Exception(result['message']);
          }
        } else {
          throw Exception('Failed to update student data');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating student data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Name', 'name'),
                    _buildTextField('Roll Number', 'roll_no'),
                    _buildTextField('Class', 'class'),
                    _buildTextField('Campus', 'campus'),
                    _buildTextField('Age', 'age'),
                    _buildTextField('Date of Birth', 'dob'),
                    _buildTextField('Date of Joining', 'doj'),
                    _buildTextField('WhatsApp Number', 'student_whatsapp'),
                    _buildTextField('City', 'city'),
                    _buildTextField('Country', 'country'),
                    _buildTextField('Father\'s Name', 'father_name'),
                    _buildTextField('Mother\'s Name', 'mother_name'),
                    _buildTextField('Father\'s Occupation', 'father_job'),
                    _buildTextField('Mother\'s Occupation', 'mother_job'),
                    _buildTextField('Favorite Food', 'favorite_food_dishes'),
                    _buildTextField('Biggest Wish', 'biggest_wish'),
                    _buildTextField('Vision in 10 Years', 'vision_10_years'),
                    _buildTextField(
                        'Ideal Personalities', 'ideal_personalities'),
                    _buildTextField('Facebook Link', 'facebook_link'),
                    _buildTextField('LinkedIn Link', 'linkedin_link'),
                    _buildTextField('YouTube Link', 'youtube_link'),
                    _buildTextField('Instagram Link', 'instagram_link'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: updateStudentData,
                      child: const Text('Update Student Details'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, String field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        initialValue: studentData[field]?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onSaved: (value) {
          studentData[field] = value;
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}

class MarkBulkAttendanceScreen extends StatefulWidget {
  final List<Student> students;
  final String campus;
  final Function refreshDashboard; // Add this line

  const MarkBulkAttendanceScreen({
    Key? key,
    required this.students,
    required this.campus,
    required this.refreshDashboard, // Add this line
  }) : super(key: key);

  @override
  _MarkBulkAttendanceScreenState createState() =>
      _MarkBulkAttendanceScreenState();
}

class _MarkBulkAttendanceScreenState extends State<MarkBulkAttendanceScreen> {
  late DateTime selectedDate;
  Map<String, bool> attendance = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    for (var student in widget.students) {
      attendance[student.id] = true;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _submitAttendance() async {
    try {
      print("Submitting attendance data: ${json.encode(attendance)}");
      final response = await http.post(
        Uri.parse(
            'http://school.superteclabs.com/mark_bulk_attendance_api.php'),
        body: {
          'date': selectedDate.toIso8601String().split('T')[0],
          'campus': widget.campus,
          'attendance': json.encode(attendance),
        },
      );

      print("Server response: ${response.body}");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          widget.refreshDashboard(); // Add this line
          Navigator.pop(context);
        } else {
          throw Exception(result['message'] ?? 'Unknown error occurred');
        }
      } else {
        throw Exception('Failed to mark attendance: ${response.statusCode}');
      }
    } catch (e) {
      print("Error details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Bulk Attendance',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Icon(Icons.calendar_today, color: Colors.blue),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.students.length,
                itemBuilder: (context, index) {
                  final student = widget.students[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: CheckboxListTile(
                      title: Text(student.name,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('Roll No: ${student.rollNo}',
                          style: GoogleFonts.poppins(fontSize: 14)),
                      value: attendance[student.id],
                      onChanged: (bool? value) {
                        setState(() {
                          attendance[student.id] = value!;
                        });
                      },
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          student.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      activeColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _submitAttendance,
                child: Text('Submit Attendance',
                    style: GoogleFonts.poppins(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  elevation: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageFeesScreen extends StatelessWidget {
  final List<Student> students;
  final String campus;

  const ManageFeesScreen(
      {super.key, required this.students, required this.campus});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Fees - $campus',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon: Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: Colors.blue.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          student.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        student.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        'Roll No: ${student.rollNo}',
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.grey[600]),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentFeeDetailsScreen(
                                  studentId: student.id),
                            ),
                          );
                        },
                        child: Text('View Fees'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentFeeDetailsScreen extends StatefulWidget {
  final String studentId;

  const StudentFeeDetailsScreen({super.key, required this.studentId});

  @override
  _StudentFeeDetailsScreenState createState() =>
      _StudentFeeDetailsScreenState();
}

class _StudentFeeDetailsScreenState extends State<StudentFeeDetailsScreen> {
  Map<String, dynamic> feeDetails = {};
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchFeeDetails();
  }

  Future<void> fetchFeeDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/student_fees_api.php?id=${widget.studentId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          feeDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load fee details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Paid: ${feeDetails['total_paid'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                          'Outstanding Fee: ${feeDetails['outstanding_fee'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('Monthly Fee: ${feeDetails['monthly_fee'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Text('Fee Records:',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (feeDetails['fee_records'] != null)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: feeDetails['fee_records'].length,
                          itemBuilder: (context, index) {
                            final record = feeDetails['fee_records'][index];
                            return Card(
                              child: ListTile(
                                title: Text(
                                    'Date: ${record['payment_date'] ?? 'N/A'}'),
                                subtitle: Text(
                                    'Amount: ${record['amount'] ?? 'N/A'}'),
                              ),
                            );
                          },
                        )
                      else
                        const Text('No fee records available'),
                    ],
                  ),
                ),
    );
  }
}

class AssignmentsOverviewScreen extends StatefulWidget {
  final String campus;

  const AssignmentsOverviewScreen({Key? key, required this.campus})
      : super(key: key);

  @override
  _AssignmentsOverviewScreenState createState() =>
      _AssignmentsOverviewScreenState();
}

class _AssignmentsOverviewScreenState extends State<AssignmentsOverviewScreen> {
  List<Student> students = [];
  List<Assignment> assignments = [];
  Student? selectedStudent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://school.superteclabs.com/get_students_api.php'),
      );

      print('API Response: ${response.body}'); // Add this line

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded Data: $data'); // Add this line
        setState(() {
          students = data.map((student) => Student.fromJson(student)).toList();
          isLoading = false;
        });
        print('Students List: $students'); // Add this line
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      print('Error fetching students: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAssignments(String studentId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            'http://school.superteclabs.com/get_student_assignments_api.php?student_id=$studentId'),
      );

      print('Assignments API Response: ${response.body}'); // Add this line

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Decoded Assignments Data: $data'); // Add this line
        setState(() {
          assignments = data
              .map((assignment) => Assignment.fromJson(assignment))
              .toList();
          isLoading = false;
        });
        print('Assignments List: $assignments'); // Add this line
      } else {
        throw Exception('Failed to load assignments');
      }
    } catch (e) {
      print('Error fetching assignments: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateAssignment(String assignmentId, String remarks) async {
    try {
      final response = await http.post(
        Uri.parse('http://school.superteclabs.com/update_assignment_api.php'),
        body: {
          'assignment_id': assignmentId,
          'remarks': remarks,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assignment updated successfully')),
          );
          fetchAssignments(selectedStudent!.id);
        } else {
          throw Exception(data['error']);
        }
      } else {
        throw Exception('Failed to update assignment');
      }
    } catch (e) {
      print('Error updating assignment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update assignment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Building UI. IsLoading: $isLoading, Students: ${students.length}, Assignments: ${assignments.length}');
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments Overview'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text('Campus: ${widget.campus}',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(students[index].name),
                        subtitle: Text(students[index].rollNo),
                        onTap: () {
                          setState(() {
                            selectedStudent = students[index];
                          });
                          fetchAssignments(students[index].id);
                        },
                      );
                    },
                  ),
                ),
                if (selectedStudent != null) ...[
                  Text('Assignments for ${selectedStudent!.name}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(assignments[index].name),
                          subtitle: Text('Date: ${assignments[index].date}'),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showUpdateDialog(assignments[index]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _showUpdateDialog(Assignment assignment) {
    String remarks = assignment.remarks;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Assignment'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Remarks'),
            onChanged: (value) {
              remarks = value;
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                updateAssignment(assignment.id, remarks);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class StudentModel {
  final String id;
  final String name;
  final String rollNo;

  StudentModel({required this.id, required this.name, required this.rollNo});

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'],
      name: json['name'],
      rollNo: json['roll_no'],
    );
  }
}

class Assignment {
  final String id;
  final String name;
  final String date;
  final String link;
  final String remarks;

  Assignment(
      {required this.id,
      required this.name,
      required this.date,
      required this.link,
      required this.remarks});

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      name: json['assignment_name'],
      date: json['date'],
      link: json['link'],
      remarks: json['remarks'],
    );
  }
}
