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


final firestoreInstance = FirebaseFirestore.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LandingPage(),
  ));
}


class LandingPage extends StatefulWidget {

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  var userProfile;

  @override
  void initState() {
    User? user = FirebaseAuth.instance.currentUser;
    firestoreInstance.collection("users").doc(user!.uid).get().then((value){
      print(value.data());
      setState(() {
        userProfile = value.data();
      });
    });
  }

  /// Get from gallery
  PickedFile? _image;
  Future getImageFromGallery() async {
    var image = await ImagePicker.platform.getImage(source: ImageSource.gallery);
    setState(() {
      _image = image as PickedFile?;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text((userProfile == null ? 'Login' : 'Hola ' + userProfile['Name'] + '!' )),
            Expanded(child: Container()),
            GestureDetector(
              child: Icon((userProfile == null) ?  Icons.person  : Icons.logout),
              onTap: () async {
                (user == null)
                    ? {Navigator.of(context).push(MaterialPageRoute(builder: (context)=>SignInPage()))}
                    : {await FirebaseAuth.instance.signOut(), setState(() {userProfile = null;}), };
              },
            )
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage((userProfile == null ? 'assets/bkg_08_august.jpg' : 'assets/bkg_12_december.jpg')),
            fit: BoxFit.cover,
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text((userProfile == null ? '' : '' ) ,style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.bold),),
                              ],
                            ),
                          ),
                          Image.memory(base64Decode('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')),
                          Container(
                            child: Center(
                              child: _image == null
                              ? Text('No image')
                              : Image.file(File(_image!.path)),
                            ),
                          ),
                          SizedBox(height: 30.0,),
                          (userProfile != null)
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
                              getImageFromGallery();

                              /*
                              firestoreInstance.collection("users").doc(userProfile['UID']).collection("collections").add(
                                  {
                                    "ArtName": "Sunny Beach",
                                    "ArtPrice": 700,
                                    "Category": "Scenery"
                                  }
                              ).then((value) {
                                print('data storage success!');
                              }
                              );
                              */
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