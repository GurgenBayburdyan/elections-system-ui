import 'package:elections_system_ui/vote_screen_state.dart';
import 'package:flutter/material.dart';


void main() {
  runApp(MaterialApp(
    title: 'Election System',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: const VoteScreen(title: "Vote for Election"),
    debugShowCheckedModeBanner: false,
  ));
}
