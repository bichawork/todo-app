import 'package:flutter/material.dart'; 
import 'package:velocity_x/velocity_x.dart'; 
class CommonLogo extends StatelessWidget { 
@override 
Widget build(BuildContext context) { 
  return Column( 
      mainAxisAlignment: MainAxisAlignment.center, 
      children: <Widget>[ 
        Image.network("https://static.vecteezy.com/system/resources/previews/012/782/675/original/avengers-logo-isolated-icon-free-vector.jpg",width: 100,), 
        "To-Do App".text.xl2.italic.make(), 
        "Make A List of your task".text.light.white.wider.lg.make(), 
      ], 
    ); 
  } 
} 