import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:barg_user_app/ipcon.dart';
import 'package:barg_user_app/screen/main_screen/home_screen/profile_screen/profile_screen.dart';
import 'package:barg_user_app/screen/main_screen/home_screen/store/menu_screen.dart';
import 'package:barg_user_app/screen/main_screen/home_screen/search_screen.dart';
import 'package:barg_user_app/widget/auto_size_text.dart';
import 'package:barg_user_app/widget/color.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List storeList = [];
  List rateList = [];
  List distanceList = [];
  Position? userLocation;
  double distance = 0;
  List delivery_feeList = [];

  get_store() async {
    final response = await http.get(Uri.parse("$ipcon/get_all_store"));
    var data = json.decode(response.body);
    if (this.mounted) {
      setState(() {
        storeList = data;
      });
    }
  }

  sum_rate_store(index, String? store_id) async {
    final response =
        await http.get(Uri.parse("$ipcon/sum_rate_store/$store_id"));
    var data = json.decode(response.body);

    if (this.mounted) {
      setState(() {
        if (rateList.length >= storeList.length) {
          if (data != null) {
            double rate = double.parse(data.toString());
            rateList[index] = rate.toStringAsFixed(1);
          } else {
            rateList[index] = '0';
          }
        } else {
          if (data != null) {
            double rate = double.parse(data.toString());
            rateList.add(rate.toStringAsFixed(1));
          } else {
            rateList.add('0');
          }
        }
      });
    }
  }

  Future<Position?> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    return userLocation;
  }

  calculateDistance(index, double lat, double long) async {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat - double.parse(userLocation!.latitude.toString())) * p) / 2 +
        c(double.parse(userLocation!.latitude.toString()) * p) *
            c(lat * p) *
            (1 -
                c((double.parse(userLocation!.longitude.toString()) - long) *
                    p)) /
            2;

    distance = double.parse((12742 * asin(sqrt(a))).toStringAsFixed(1));

    double delivery_fee = distance * 5;

    if (distanceList.length >= storeList.length) {
      distanceList[index] = distance;
    } else {
      distanceList.add(distance);
    }
    if (delivery_feeList.length >= storeList.length) {
      distanceList[index] = distance;
    } else {
      delivery_feeList.add(delivery_fee);
    }
  }

  @override
  void initState() {
    rateList = [];
    _getLocation();
    get_store();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 50,
              floating: true,
              title: Text("Barg Food"),
              centerTitle: false,
              backgroundColor: blue,
              actions: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (BuildContext context) {
                      return ProfileScreen();
                    }));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/user.png',
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            )
          ];
        },
        body: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03, vertical: height * 0.02),
                  width: width,
                  height: height * 0.08,
                  color: blue,
                ),
                Container(
                  child: buildList(),
                )
              ],
            ),
            buildSearch(),
          ],
        ),
      ),
    );
  }

  Widget buildSearch() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Positioned(
      top: height * 0.03,
      child: GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return SearchScreen();
          }));
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: height * 0.02),
          width: width * 0.85,
          height: height * 0.06,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AutoText(
                  text: "search",
                  fontSize: 16,
                  color: Colors.grey.shade400,
                  fontWeight: null,
                ),
                Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildList() {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return FutureBuilder(
      future: _getLocation(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return Expanded(
            child: GridView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                    vertical: height * 0.05, horizontal: width * 0.04),
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 0.76,
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemCount: storeList.length,
                itemBuilder: (BuildContext context, int index) {
                  calculateDistance(
                      index,
                      double.parse(storeList[index]['store_lat'].toString()),
                      double.parse(storeList[index]['store_long'].toString()));
                  sum_rate_store(
                      index, storeList[index]['store_id'].toString());
                  return GestureDetector(
                    onTap: () {
                      if (delivery_feeList.isNotEmpty &&
                          distanceList.isNotEmpty) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (BuildContext context) {
                          return MenuScreen(
                            store_id: '${storeList[index]['store_id']}',
                            store_image: '${storeList[index]['store_image']}',
                            store_name: '${storeList[index]['store_name']}',
                            delivery_fee: '${delivery_feeList[index]}',
                            distance: '${distanceList[index]}',
                            star: '${rateList[index]}',
                          );
                        }));
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: width * 0.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            spreadRadius: 3,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: double.infinity,
                            height: height * 0.19,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5),
                              ),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(
                                    '$path_img/store/${storeList[index]['store_image']}'),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: AutoText2(
                              text: "${storeList[index]['store_name']}",
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.asset(
                                  "assets/images/fast-delivery.png",
                                  width: width * 0.04,
                                  height: height * 0.025,
                                  color: Colors.grey.shade600,
                                ),
                                delivery_feeList.isEmpty
                                    ? AutoText(
                                        text: "...",
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: null,
                                      )
                                    : AutoText(
                                        text: "${delivery_feeList[index]} ฿",
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: null,
                                      ),
                                Container(
                                  width: 1,
                                  height: 15,
                                  color: Colors.grey.shade500,
                                ),
                                distanceList.isEmpty
                                    ? AutoText(
                                        text: "...",
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: null,
                                      )
                                    : distanceList[index] == null ||
                                            distanceList[index] == ''
                                        ? Text("")
                                        : AutoText(
                                            text: "${distanceList[index]} km",
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                            fontWeight: null,
                                          ),
                                Container(
                                  width: 1,
                                  height: 15,
                                  color: Colors.grey.shade500,
                                ),
                                Image.asset(
                                  "assets/images/star.png",
                                  width: width * 0.03,
                                  height: height * 0.02,
                                  color: Colors.yellow.shade800,
                                ),
                                rateList.isEmpty
                                    ? AutoText(
                                        text: "...",
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                        fontWeight: null,
                                      )
                                    : rateList[index] == null
                                        ? Text("...")
                                        : AutoText(
                                            text: "${rateList[index]}",
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                            fontWeight: null,
                                          ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }),
          );
        } else {
          return SizedBox(
            height: height * 0.5,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
