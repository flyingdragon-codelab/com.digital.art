import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LandingPage(),
  ));
}

final firestoreInstance = FirebaseFirestore.instance;

class LandingPage extends StatefulWidget {

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  var userProfile;
  List collections = [];

  getAllCollections() async {
    firestoreInstance.collection("users").get().then((value) {
      value.docs.forEach((value) {
        firestoreInstance.collection("users").doc(value.id).collection("collections").get().then((value) {
          value.docs.forEach((element) {
            setState(() {
              collections.add(element.data());
            });
            //  print(element.data()['Name']);
            //   print(element.data()['Filedata']);
            //    print(collections);
            //  print(collections.length);
          });
        });
      });
    });
  }

  getUserProfile () async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if(firebaseUser != null)  {
      var result = await FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).get();
      setState((){
        userProfile = result.data();
      });
    }
  //  print(collections);
  }

  @override
  void initState() {
    getAllCollections();
  //  getUserProfile();
  }

  /// Get from gallery
  XFile? _image;
  Future getImageFromGallery(name, category, price) async {
    var image = await ImagePicker.platform.getImage(source: ImageSource.gallery);
    var finalImage = image as XFile?;
    var base64Image = File(finalImage!.path).readAsBytesSync();
    print(base64Encode(base64Image));
    firestoreInstance.collection("users").doc(userProfile['UID']).collection("collections").add(
        {
          "Name": name,
          "Price": price,
          "Category": category,
          "Filedata": base64Encode(base64Image),
          "UpdatedOn": DateTime.now()
         // "Media": base64Encode(base64Image)
        }
    ).then((value) {
      print('data storage success!');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Alert!!"),
            content: new Text('Success!'),
            actions: <Widget>[
              new FlatButton(
                child: new Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    );
    setState(() {
      _image = image as XFile?;
    });
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Text((userProfile == null ? 'Login' : 'Hola ' + userProfile["Name"] + '!' )),
            Expanded(child: Container()),
            GestureDetector(
              child: Icon((user == null) ?  Icons.person  : Icons.logout),
              onTap: () async {
                (user == null)
                    ? {Navigator.of(context).push(MaterialPageRoute(builder: (context)=>SignInPage()))}
                    : {await FirebaseAuth.instance.signOut(), setState(() {user = null; _image = null; userProfile = null; getUserProfile();}), };
              },
            )
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
          height: height,
          width: width,
          child: SingleChildScrollView(
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                    width: width * 0.8,
                    child: Column(
                        children: [
                          OutlinedButton(
                            child: Container(
                              width: width * 0.4,
                              height: 60,
                              child: Center(
                                  child: Text('Add Data')
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.teal,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                            onPressed: () async {
                              getImageFromGallery(nameController.text, categoryController.text, int.parse(priceController.text));
                            },
                          ),
                          /*TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Name',
                              suffixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              hintText: 'Category',
                              suffixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              hintText: 'Price',
                              suffixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          (user != null)
                          ? OutlinedButton(
                            child: Container(
                              width: width * 0.4,
                              height: 60,
                              child: Center(
                                  child: Text('Add Data')
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.teal,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                            onPressed: () async {
                              getImageFromGallery(nameController.text, categoryController.text, int.parse(priceController.text));
                            },
                          )
                              : Container(),
                          SizedBox(height: 30.0,),
                          Container(child: Text((collections.length != 0) ? 'Nbr of Collections - ' + collections.length.toString() : 'No Collections',)),*/
                          SizedBox(height: 30.0,),
                          (collections.length != 0) ? SizedBox(
                            height: 500,
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: collections.length,
                              itemBuilder: (context, index) => Image.memory(
                                base64Decode(collections[index]['Filedata']),
                                  fit: BoxFit.cover,
                              )
                            ),
                          )  : Text('nothing here - ' + collections.length.toString()),
                          SizedBox(height: 30.0,),
                        ]
                    )
                ),
              ],
            ),
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}



class SignInPage extends StatefulWidget {

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool validUser = true;

  @override
  Widget build(BuildContext context) {
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Demo Login UI'),
      //  automaticallyImplyLeading: false,
      ),
      body: Container(
          height: height,
          width: width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: width,
                  height: height*0.45,
                  child: Image.asset('assets/yoga.png',fit: BoxFit.fill,),
                ),
                Container(
                    width: width * 0.8,
                    child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text('Login',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              suffixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              suffixIcon: Icon(Icons.visibility_off),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgetPasswordPage()));
                                  },
                                  child: Text.rich(
                                    TextSpan(
                                        text: 'Forget password?',
                                    ),
                                  ),
                                ),
                                RaisedButton(
                                  child: Text('Login'),
                                  color: Color(0xffEE7B23),
                                  onPressed: () async {
                                    try {
                                      dynamic result = (await FirebaseAuth.instance.signInWithEmailAndPassword(
                                        email: emailController.text,
                                        password: passwordController.text,
                                      )).user;
                                      if (result != null) {
                                        Navigator.push(context, MaterialPageRoute(builder: (context)=>LandingPage()));
                                      }
                                    } catch (e) {
                                      print(e.toString());
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: new Text("Alert!!"),
                                            content: new Text(e.toString()),
                                            actions: <Widget>[
                                              new FlatButton(
                                                child: new Text("OK"),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height:20.0),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpPage()));
                            },
                            child: Text.rich(
                              TextSpan(
                                  text: 'Don\'t have an account ',
                                  children: [
                                    TextSpan(
                                      text: 'Signup',
                                      style: TextStyle(
                                          color: Color(0xffEE7B23)
                                      ),
                                    ),
                                  ]
                              ),
                            ),
                          ),
                          Container(
                            height: 50,
                          ),
                        ]
                    )
                ),
              ],
            ),
          )
      ),
    );
  }
}



class SignUpPage extends StatefulWidget {
  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final firestoreInstance = FirebaseFirestore.instance;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        height: height,
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: width,
                height: height*0.45,
                child: Image.asset('assets/play.png',fit: BoxFit.fill,),
              ),
              Container(
                  width: width * 0.8,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Signup',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.0,),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Name',
                          suffixIcon: Icon(Icons.person_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.0,),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          suffixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0,),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          suffixIcon: Icon(Icons.visibility_off),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.0,),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Forget password?',style: TextStyle(fontSize: 12.0),),
                            ElevatedButton(
                              child: Text('Signup'),
                              onPressed: () async {
                                try{
                                  dynamic result = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                      email: emailController.text,
                                      password: passwordController.text
                                  )).user;
                                  if (result != null) {
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>LandingPage()));
                                    firestoreInstance.collection("users").doc(result.uid).set(
                                      {
                                        "Name": nameController.text,
                                        "Email": emailController.text,
                                        "UID": result.uid
                                      }
                                    ).then((value) {
                                      print('data storage success!');
                                    }
                                    );
                                  }
                                } catch (e) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: new Text("Alert!!"),
                                        content: new Text(e.toString()),
                                        actions: <Widget>[
                                          new FlatButton(
                                            child: new Text("OK"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height:20.0),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInPage()));
                        },
                        child: Text.rich(
                          TextSpan(
                              text: 'Already have an account ',
                              children: [
                                TextSpan(
                                  text: 'Signin',
                                  style: TextStyle(
                                      color: Color(0xffEE7B23)
                                  ),
                                ),
                              ]
                          ),
                        ),
                      ),
                    ],
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}



class ForgetPasswordPage extends StatefulWidget {
  @override
  ForgetPasswordPageState createState() => ForgetPasswordPageState();
}

class ForgetPasswordPageState extends State<ForgetPasswordPage> {
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
              alignment: Alignment.bottomCenter,
              image: AssetImage(
                'assets/forget_password.jfif',
              ),
              fit: BoxFit.fitWidth,
            )
        ),
        height: height,
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100.00),
              Container(
                  width: width * 0.8,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('Forget Password',style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.0,),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          suffixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 30.0,),
                      Center(
                        child: ElevatedButton(
                          child: Text('Submit'),
                          onPressed: () async {
                            try{
                              await FirebaseAuth.instance.sendPasswordResetEmail(
                                  email: emailController.text
                              );
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: new Text("Email Sent!!"),
                                    content: new Text('Password Reset Email has been sent!'),
                                    actions: <Widget>[
                                      new FlatButton(
                                        child: new Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            } catch (e) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: new Text("Alert!!"),
                                    content: new Text(e.toString()),
                                    actions: <Widget>[
                                      new FlatButton(
                                        child: new Text("OK"),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height:20.0),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>SignInPage()));
                        },
                        child: Text.rich(
                          TextSpan(
                              text: 'Already have an account ',
                              children: [
                                TextSpan(
                                  text: 'Signin',
                                  style: TextStyle(
                                      color: Color(0xffEE7B23)
                                  ),
                                ),
                              ]
                          ),
                        ),
                      ),
                    ],
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}




class AddFilePage extends StatefulWidget {

  @override
  AddFilePageState createState() => AddFilePageState();
}

class AddFilePageState extends State<AddFilePage> {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  var userProfile;
  List collections = [];

  getUserProfile () async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    if(firebaseUser != null)  {
      var result = await FirebaseFirestore.instance.collection("users").doc(firebaseUser.uid).get();
      setState((){
        userProfile = result.data();
      });
    }
    //  print(collections);
  }

  @override
  void initState() {
    getUserProfile();
  }

  /// Get from gallery
  XFile? _image;
  Future getImageFromGallery(name, category, price) async {
    var image = await ImagePicker.platform.getImage(source: ImageSource.gallery);
    var finalImage = image as XFile?;
    var base64Image = File(finalImage!.path).readAsBytesSync();
    print(base64Encode(base64Image));
    firestoreInstance.collection("users").doc(userProfile['UID']).collection("collections").add(
        {
          "Name": name,
          "Price": price,
          "Category": category,
          "Filedata": base64Encode(base64Image),
          "UpdatedOn": DateTime.now()
          // "Media": base64Encode(base64Image)
        }
    ).then((value) {
      print('data storage success!');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: new Text("Alert!!"),
            content: new Text('Success!'),
            actions: <Widget>[
              new FlatButton(
                child: new Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
    );
    setState(() {
      _image = image as XFile?;
    });
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            Text((userProfile == null ? 'Login' : 'Hola ' + userProfile["Name"] + '!' )),
            Expanded(child: Container()),
            GestureDetector(
              child: Icon((user == null) ?  Icons.person  : Icons.logout),
              onTap: () async {
                (user == null)
                    ? {Navigator.of(context).push(MaterialPageRoute(builder: (context)=>SignInPage()))}
                    : {await FirebaseAuth.instance.signOut(), setState(() {user = null; _image = null; userProfile = null; getUserProfile();}), };
              },
            )
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                alignment: Alignment.bottomCenter,
                image: AssetImage(
                  (user == null ? 'assets/flat1.jfif' : 'assets/High Five.png'),
                ),
                fit: BoxFit.fitWidth,
              )
          ),
          height: height,
          width: width,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                    width: width * 0.8,
                    child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              hintText: 'Name',
                              suffixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          TextField(
                            controller: categoryController,
                            decoration: InputDecoration(
                              hintText: 'Category',
                              suffixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          TextField(
                            controller: priceController,
                            decoration: InputDecoration(
                              hintText: 'Price',
                              suffixIcon: Icon(Icons.person_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          (user != null)
                              ? OutlinedButton(
                            child: Container(
                              width: width * 0.4,
                              height: 60,
                              child: Center(
                                  child: Text('Add Data')
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.teal,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                            onPressed: () async {
                              getImageFromGallery(nameController.text, categoryController.text, int.parse(priceController.text));
                            },
                          )
                              : Container(),
                        ]
                    )
                ),
              ],
            ),
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'School',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
