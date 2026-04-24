import 'package:flutter/material.dart';
import './register_screen.dart';
import './login_screen.dart';
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: [
            Text('Welcome', style: TextStyle(
              color: Color(0xFF1B1B4E),
              fontWeight: FontWeight.w600,
              fontSize: 40,
              shadows: [
              Shadow(
                  blurRadius:3.0,  
                  // color: Color(0xFF1B1B4E), 
                  color: Colors.black,
                  offset: Offset(0.0,0.0), 
                  ),
              ],
            ),),
            Padding(padding: EdgeInsets.all(10),
            child: ElevatedButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
            }, child: const Text('Register')),
            ),
            Padding(padding: EdgeInsets.all(10),
            child: ElevatedButton(onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            }, child: const Text('Login')),
            )
          ],
          ),
      ),
    );
  }
}