import 'dart:convert';
import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

const bgColor = const Color(0xff4A83FE);

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
  var greetingMessage = "";
  List allCollections = [];
  List collections = [];
  List categories = [];

  void filterCategory(String query)  {
    if(query.isNotEmpty)  {
      collections = [];
      allCollections.forEach((item) {
        if(item['Category'].contains(query)) {
          setState(() {
            collections.add(item);
          });
        }
      });
    }
  }

  void searchQuery(String query)  {
    if(query.isNotEmpty)  {
      collections = [];
      /*allCollections.forEach((item) {
        if((item['Category'].contains(query)) || (item['Name'].contains(query))) {
          setState(() {
            collections.add(item);
          });
        }
      });*/
      collections = allCollections.where((value) =>
      value["Name"].toLowerCase().contains(query.toLowerCase()) || value["Category"].toLowerCase().contains(query.toLowerCase())).toList();
    } else {
      collections = [];
      collections = allCollections;
    }
  }

  void showSlideupView(BuildContext context, collections) {
    showBottomSheet(
        context: context,
        builder: (context) {
          return new Container(
            decoration: new BoxDecoration(
                color: Colors.grey[50],
                borderRadius: new BorderRadius.only(
                  topLeft: const Radius.circular(30.0),
                  topRight: const Radius.circular(30.0),
                )
            ),
            width: MediaQuery.of(context).size.width,
            child: new GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Column(
                children: [
                  SizedBox(height: 20,),
                  Text('Name: ' + collections['Name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24,),),
                  SizedBox(height: 20,),
                  Image.memory(base64Decode(collections['Filedata']), width: MediaQuery.of(context).size.width * 0.6,),
                  SizedBox(height: 20,),
                  Text('Category: ' + collections['Category'], style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18,), ),
                  SizedBox(height: 20,),
                  Text('Price: ' + collections['Price'].toString(), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18,), ),
                  SizedBox(height: 20,),
                  Text('Updatedon: ' + DateFormat("dd MMM yyyy").format(collections['UpdatedOn'].toDate()), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18,), ),
                ],
              ),
            ),
          );
        });
  }

  getAllCollections() async {
    allCollections = [];
    collections = [];
    firestoreInstance.collection("users").get().then((value) {
      value.docs.forEach((value) {
        firestoreInstance.collection("users").doc(value.id).collection("collections").get().then((value) {
          value.docs.forEach((element) {
            setState(() {
            //  print(element.id);
              categories.add(element.data()['Category']);
              allCollections.add({"Id": element.id, "Name": element.data()['Name'], "Filedata": element.data()['Filedata'], "Price": element.data()['Price'], "Category": element.data()['Category'], "UpdatedOn": element.data()['UpdatedOn']  });
            //  collections.add(element.data());
              collections = allCollections.toSet().toList();
              categories = categories.toSet().toList();
            });
          });
        });
      });
    });
  }

  void sortLists() {
    setState(() {
      categories.sort();
      collections.sort((a, b) =>
          b["UpdatedOn"].compareTo(a["UpdatedOn"])
      );
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

  String greetingLogic() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      setState(() {
        greetingMessage = "Good morning";
      });
      return 'Morning';
    }
    if (hour < 17) {
      setState(() {
        greetingMessage = "Good afternoon";
      });
      return 'Afternoon';
    }
    setState(() {
      greetingMessage = "Good evening";
    });
    return 'Evening';
  }

  @override
  void initState() {
    greetingLogic();
    getAllCollections();
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
    sortLists();
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: bgColor,
        bottomOpacity: 0.0,
        elevation: 0.0,
        title: Center(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(10, 10, 0, 0),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      (userProfile != null) ? 'Hi' + ', ' + userProfile['Name'] + '!'  : 'Hi' + '!',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                ),
              ),
              Expanded(child: Container()),
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  child: Icon((userProfile != null) ?  Icons.cloud_upload  : null, size: 30,),
                ),
                onTap: () async {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>MyArtPage()));
                },
              ),
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  child: Icon((userProfile != null) ?  Icons.logout  : Icons.person, size: 30,),
                ),
                onTap: () async {
                  (user == null)
                      ? {Navigator.of(context).push(MaterialPageRoute(builder: (context)=>SignInPage()))}
                      : {await FirebaseAuth.instance.signOut(), setState(() {user = null; _image = null; userProfile = null; getUserProfile();}), };
                },
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Container(
      //  color: Colors.white,
          height: height,
          width: width,
          child: RefreshIndicator(
            onRefresh: () async {
              getAllCollections();
              return await Future.delayed(Duration(seconds: 3));
            },
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                  //  color: bgColor,
                    width: width * 0.8,
                    height: 50,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                    child: TextField(
                      onChanged: (queryText){
                        searchQuery(queryText);
                      },
                      controller: nameController,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(20, 2, 2, 2),
                        isDense: false,
                        fillColor: Colors.white,
                        filled: true,
                        hintText: 'Search',
                        suffixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: new BorderSide(color: Colors.transparent, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(color: Colors.transparent, width: 2.0),
                        ),
                      ),
                    ),
                    /*Row(
              children: [
                Text((userProfile == null ? 'Login' : 'Hola ' + userProfile["Name"] + '!' )),
                Expanded(child: Container()),
                GestureDetector(
                    child: Icon(Icons.person_pin_sharp),
                    onTap: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => MyArtPage()));
                    }
                ),
                Container(width: 50),
                GestureDetector(
                  child: Icon(Icons.refresh),
                  onTap: () async {
                    setState(() {
                      collections = [];
                      allCollections = [];
                    });
                    getAllCollections();
                  },
                ),
                Container(width: 50),
                GestureDetector(
                  child: Icon((user == null) ?  Icons.person  : Icons.logout),
                  onTap: () async {
                    (user == null)
                        ? {Navigator.of(context).push(MaterialPageRoute(builder: (context)=>SignInPage()))}
                        : {await FirebaseAuth.instance.signOut(), setState(() {user = null; _image = null; userProfile = null; getUserProfile();}), };
                  },
                )
              ],
            ),*/
                  ),
                  Container(
                      decoration: new BoxDecoration(
                          color: Colors.white,
                          borderRadius: new BorderRadius.only(
                            topLeft: const Radius.circular(30.0),
                            topRight: const Radius.circular(30.0),
                          )
                      ),
                      padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                      width: width,
                      height: height - 150,
                      child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 20),
                              width: width * 0.9,
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Featured',
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.normal, color: Colors.black),
                                  )
                              ),
                            ),
                            /*(categories.length != 0)  ? DropdownButtonFormField(
                              isDense: true,
                              items: categories.map((category) {
                                return new DropdownMenuItem(
                                  value: category,
                                  child: Text(category.toString(),),
                                );
                              }).toList(),
                              //  value: (ddlCountryValue == null)  ? null  : ddlCountryValue,
                              onChanged: (selectedValue) {
                              //  print(selectedValue);
                                filterCategory(selectedValue.toString());
                              },
                              decoration: InputDecoration(
                                //  labelText: 'Home Country',
                                // labelStyle: Theme.of(context).primaryTextTheme.caption.copyWith(color: fcmGreen),
                                //  labelStyle: TextStyle(fontSize: 12.0, color: fcmMidnightBlack, ),
                                //  filled: true,
                                //  fillColor: fcmGreyOne,
                                //  hintText: 'Select Country',
                                //  focusedBorder:UnderlineInputBorder(
                                //    borderSide: BorderSide(color: fcmMidnightBlack, style: BorderStyle.solid),
                                //  ),
                                //  border: OutlineInputBorder(borderSide: BorderSide(color: fcmMidnightBlack, style: BorderStyle.solid),),
                                //  prefixIcon: Icon(Icons.public, color: fcmMidnightBlack,),
                              ),
                            ) : Text(''),
                            SizedBox(height: 10,),
                            Text('Total items - ' + collections.length.toString()),*/
                            (collections.length != 0) ? SizedBox(height: 50, child: Container(
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                                width: width * 0.9,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categories.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        child: Container(
                                          margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
                                          child: Text(
                                            categories[index],
                                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: Colors.black),
                                          ),
                                        ),
                                        onTap: () {
                                      filterCategory(categories[index]);
                                        },
                                      );
                                    }
                                )
                            ),)  : Text('nothing here - ' + collections.length.toString()),
                            (collections.length != 0) ? SizedBox(
                              height: 250,
                              child: Container(
                                color: Colors.white,
                                padding: EdgeInsets.fromLTRB(10, 0, 10, 20),
                                width: width * 0.9,
                                child: Container(
                                  child: ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: collections.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          child: Container(
                                            decoration: BoxDecoration(
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey,
                                                    blurRadius: 2.0,
                                                    spreadRadius: 0.0,
                                                    offset: Offset(2.0, 2.0), // shadow direction: bottom right
                                                  )
                                                ],
                                                borderRadius: BorderRadius.circular(10),
                                                image: DecorationImage(
                                                  alignment: Alignment.bottomCenter,
                                                  image: MemoryImage(base64Decode(collections[index]['Filedata'])),
                                                  fit: BoxFit.cover,
                                                )
                                            ),
                                            alignment: Alignment.topLeft,
                                            width: 150,
                                            height: 250,
                                            margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
                                            child: Text(''),
                                          ),
                                          onTap: () {
                                            showSlideupView(context, collections[index]);
                                          },
                                        );
                                      }
                                  ),
                                ),
                            ),)  : Text('nothing here - ' + collections.length.toString()),

                          ]
                      )
                  ),
                ],
              ),
            ),
          ),
      ),
      /*bottomNavigationBar: BottomNavigationBar(
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
      ),*/
    );
  }
}


class ViewArtPage extends StatefulWidget {
  final artData;
  ViewArtPage(this.artData);

  @override
  ViewArtPageState createState() => ViewArtPageState(artData);
}

class ViewArtPageState extends State<ViewArtPage> {
  final artData;
  ViewArtPageState(this.artData);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Name: ' + artData['Name']),
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
                  padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                  width: width * 0.8,
                  child: Column(
                    children: [
                      Container(
                        child: Image.memory(base64Decode(artData['Filedata']),
                          fit: BoxFit.fill,
                        ),
                      ),
                      SizedBox(height: 30,),
                      Container(child: Text('Category: ' + artData['Category'])),
                      SizedBox(height: 30,),
                      Container(child: Text('Price: ' + artData['Price'].toString())),
                    ],
                  ),
              ),
            ],
          ),
        ),
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
      backgroundColor: Colors.blue,
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
      //  automaticallyImplyLeading: false,
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



class MyArtPage extends StatefulWidget {

  @override
  MyArtPageState createState() => MyArtPageState();
}

class MyArtPageState extends State<MyArtPage> {
  final nameController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  var userProfile;
  List collections = [];

  getAllCollections() async {
    var firebaseUser = FirebaseAuth.instance.currentUser;
    firestoreInstance.collection("users").doc(firebaseUser!.uid).collection("collections").get().then((value) {
      value.docs.forEach((element) {
        setState(() {
          //  print(element.id);
          collections.add({"Id": element.id, "Name": element.data()['Name'], "Filedata": element.data()['Filedata'], "Price": element.data()['Price'], "Category": element.data()['Category'], "UpdatedOn": element.data()['UpdatedOn']  });
          //  collections.add(element.data());
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

  void showSlideupView(BuildContext context, collections) {
    showBottomSheet(
        context: context,
        builder: (context) {
          return new Container(
            width: MediaQuery.of(context).size.width,
            child: new GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Column(
                children: [
                  SizedBox(height: 20,),
                  Text('Name: ' + collections['Name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24,),),
                  SizedBox(height: 20,),
                  Image.memory(base64Decode(collections['Filedata']), width: MediaQuery.of(context).size.width * 0.6,),
                  SizedBox(height: 20,),
                  Text('Category: ' + collections['Category'], style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18,), ),
                  SizedBox(height: 20,),
                  Text('Price: ' + collections['Price'].toString(), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18,), ),
                  SizedBox(height: 20,),
                  Text('Updatedon: ' + DateFormat("dd MMM yyyy").format(collections['UpdatedOn'].toDate()), style: TextStyle(fontWeight: FontWeight.normal, fontSize: 18,), ),
                ],
              ),
            ),
          );
        });
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
            Text('My Art'),
            Expanded(child: Container()),
            (user != null)
                ? GestureDetector(
                    child: Icon(Icons.upload_sharp),
                    onTap: () async {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AddFilePage()));
                    },
                  )
                : Container(),
            Container(width: 50),
            GestureDetector(
              child: Icon(Icons.refresh),
              onTap: () async {
                setState(() {
                  collections = [];
                });
                getAllCollections();
              },
            ),
            Container(width: 50),
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
                  padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  width: width * 0.8,
                  child: Column(
                      children: [
                        Text('Total Collections: ' + collections.length.toString()),
                        Container(height: 20,),
                        (collections.length != 0) ? SizedBox(
                          height: 600,
                          child: ListView.builder(
                              shrinkWrap: true,
                              //  scrollDirection: Axis.horizontal,
                              itemCount: collections.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                                  child: ListTile(
                                    leading: Image.memory(base64Decode(collections[index]['Filedata']),
                                      fit: BoxFit.contain,
                                    ),
                                    title: Align(alignment: Alignment.centerLeft, child: Text('Name: ' + collections[index]['Name']),),
                                    subtitle: Column(
                                      children: [
                                        SizedBox(height: 10.0,),
                                        Align(alignment: Alignment.centerLeft, child: Text('Category: ' + collections[index]['Category']),),
                                        Align(alignment: Alignment.centerLeft, child: Text('Category: ' + collections[index]['Price'].toString()),),
                                      ],
                                    ),
                                    trailing: GestureDetector(
                                      child: Icon(Icons.delete),
                                      onTap: () {
                                        FirebaseFirestore.instance.collection("users").doc(user!.uid).collection("collections").doc(collections[index]["Id"]).delete().then((value) {
                                          print("Delete Successed");
                                        });
                                        setState(() {
                                          collections = [];
                                        });
                                        getAllCollections();
                                      },
                                    ),
                                    onTap: (){
                                      showSlideupView(context, collections[index]);
                                      /*Navigator.of(context).push(
                                          MaterialPageRoute(builder: (context) => ViewArtPage(collections[index])));*/
                                    },
                                  ),
                                );
                              }
                          ),
                        )  : Text('nothing here - ' + collections.length.toString()),
                        SizedBox(height: 30.0,),
                      ]
                  )
              ),
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


/*GridView.builder(
itemCount:collections.length,
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: MediaQuery.of(context).orientation ==
Orientation.portrait ? 2: 2,
crossAxisSpacing: 8,
mainAxisSpacing: 8,
childAspectRatio: (2 / 3),
),
itemBuilder: (context,index,) {
return GestureDetector(
onTap:(){
showSlideupView(context, collections[index]);
*//*Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => ViewArtPage(collections[index])));*//*
},
child:Container(
child: Image.memory(base64Decode(collections[index]['Filedata']),
fit: BoxFit.fill,
),
),
);
},
)*/



