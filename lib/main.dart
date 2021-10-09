import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(LandingPage());
}

class LandingPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      title: 'Welcome to Digital Art',
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Column(
          children: [
            Container(
              child: RaisedButton(
                child: Text('' + (user == null ? 'Already Login' : 'Must Login 123') ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>Second()));
                },
              ),
            ),
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context)=>Second()));
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
          ],
        ),
      )
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

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    double width=MediaQuery.of(context).size.width;
    double height=MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Demo Login UI'),
        automaticallyImplyLeading: false,
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
                                Text('Forget password?',style: TextStyle(fontSize: 12.0),),
                                RaisedButton(
                                  child: Text('Login'),
                                  color: Color(0xffEE7B23),
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                                        email: emailController.text,
                                        password: passwordController.text,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height:20.0),
                          GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>Second()));
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
                )
              ],
            ),
          )
      ),
    );
  }
}


class Second extends StatefulWidget {
  @override
  _SecondState createState() => _SecondState();
}

class _SecondState extends State<Second> {
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
                                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: emailController.text,
                                    password: passwordController.text
                                );
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