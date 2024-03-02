import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stacked_carousel_slider/stacked_carousel_slider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: double.maxFinite,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: StackedCarouselSlider(
                  items: [
                    getDummyItem(color: Colors.green),
                    getDummyItem(color: Colors.red),
                    getDummyItem(color: Colors.blue),
                  ],
                  onPageChanged: (page) {
                    if (kDebugMode) {
                      print("onPageChanged($page)");
                    }
                  },
                  onTap: (page) {
                    if (kDebugMode) {
                      print("onTap($page)");
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getDummyItem({required Color color}) {
    return Container(
      color: color,
      child: Center(
        child: ElevatedButton(
          child: const Text("Button"),
          onPressed: () {
            print("Tapped");
          },
        ),
      ),
    );
  }
}
