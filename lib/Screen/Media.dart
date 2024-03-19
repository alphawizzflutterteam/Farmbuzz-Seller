import 'dart:async';
import 'dart:convert';
import 'package:eshopmultivendor/Helper/AppBtn.dart';
import 'package:eshopmultivendor/Helper/Color.dart';
import 'package:eshopmultivendor/Helper/Constant.dart';
import 'package:eshopmultivendor/Helper/Session.dart';
import 'package:eshopmultivendor/Helper/String.dart';
import 'package:eshopmultivendor/Model/Media_Model.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';

import 'Add_Product.dart';

class Media extends StatefulWidget {
  final from, pos;

  const Media({Key? key, this.from, this.pos}) : super(key: key);

  @override
  _MediaState createState() => _MediaState();
}

class _MediaState extends State<Media> with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool scrollLoadmore = true, scrollGettingData = false, scrollNodata = false;
  int scrollOffset = 0;
  List<MediaModel> mediaList = [];
  List<MediaModel> tempList = [];
  List<MediaModel> selectedList = [];

  ScrollController? scrollController;
  late List<String> variantImgList = [];
  late List<String> variantImgUrlList = [];

  late List<String> otherImgList = [];
  late List<String> otherImgUrlList = [];
  XFile? image;
  Future<String> selectMedia(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    image = await picker.pickImage(source: source);
    print(image?.path);
    return image?.path == null ? "" : image!.path;
  }

  @override
  void initState() {
    super.initState();
    scrollOffset = 0;
    getMedia();

    buttonController = new AnimationController(
        duration: new Duration(milliseconds: 2000), vsync: this);
    scrollController = ScrollController(keepScrollOffset: true);
    scrollController!.addListener(_transactionscrollListener);

    buttonSqueezeanimation = new Tween(
      begin: width * 0.7,
      end: 50.0,
    ).animate(
      new CurvedAnimation(
        parent: buttonController!,
        curve: new Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  _transactionscrollListener() {
    if (scrollController!.offset >=
            scrollController!.position.maxScrollExtent &&
        !scrollController!.position.outOfRange) {
      if (mounted)
        setState(
          () {
            scrollLoadmore = true;
            getMedia();
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(getTranslated(context, 'Media')!, context),
      body: _isNetworkAvail ? _showContent() : noInternet(context),
    );
  }

  _showContent() {
    return scrollNodata
        ? getNoItem(context)
        : NotificationListener<ScrollNotification>(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    shrinkWrap: true,
                    padding: EdgeInsetsDirectional.only(
                        bottom: 5, start: 10, end: 10),
                    itemCount: mediaList.length,
                    itemBuilder: (context, index) {
                      MediaModel? item;

                      item = mediaList.isEmpty ? null : mediaList[index];

                      return item == null ? Container() : getMediaItem(index);
                    },
                  ),
                ),
                scrollGettingData
                    ? Padding(
                        padding: EdgeInsetsDirectional.only(top: 5, bottom: 5),
                        child: CircularProgressIndicator(),
                      )
                    : Container(),
              ],
            ),
          );
  }

  getAppBar(String title, BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: white,
      leading: Builder(
        builder: (BuildContext context) {
          return Container(
            margin: EdgeInsets.all(10),
            decoration: shadow(),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_left,
                  color: primary,
                  size: 30,
                ),
              ),
            ),
          );
        },
      ),
      title: Text(
        title,
        style: TextStyle(
          color: grad2Color,
        ),
      ),
      actions: [
        (widget.from == "other" || widget.from == 'variant')
            ? TextButton(
                onPressed: () {
                  if (widget.from == "other") {
                    otherPhotos.addAll(otherImgList);
                    otherImageUrl.addAll(otherImgUrlList);
                  } else if (widget.from == 'variant') {
                    variationList[widget.pos].images = variantImgList;
                    variationList[widget.pos].imagesUrl = variantImgUrlList;
                  }
                  Navigator.pop(context);
                },
                child: Text('Done'))
            : Container(),
        TextButton(
            onPressed: () {
              showModalBottomSheet(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15))),
                context: context,
                builder: (btmctx) => Container(
                  padding: const EdgeInsets.all(12),
                  height: MediaQuery.of(context).size.height * .2,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          String iPath = await selectMedia(ImageSource.gallery);
                          if (iPath != '') {
                            uploadMedia(iPath);
                            Navigator.pop(btmctx);
                            print(iPath);
                          } else {
                            Navigator.pop(btmctx);
                            Fluttertoast.showToast(msg: 'No media selected');
                          }
                        },
                        child: ListTile(
                          title: Text(
                            'Select from Gallery',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(Icons.collections),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          String iPath = await selectMedia(ImageSource.camera);
                          if (iPath != '') {
                            uploadMedia(iPath);
                            Navigator.pop(btmctx);
                            print(iPath);
                          } else {
                            Navigator.pop(btmctx);
                            Fluttertoast.showToast(msg: 'No media selected');
                          }
                        },
                        child: ListTile(
                          title: Text(
                            'Take a Photo',
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(Icons.camera_alt_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Row(
              children: [
                Text('Upload'),
                Icon(
                  Icons.upload_file_outlined,
                  size: 15,
                )
              ],
            ))
      ],
    );
  }

  Future<void> uploadMedia(String file) async {
    try {
      var request = MultipartRequest(
          'POST',
          Uri.parse(
              'https://developmentalphawizz.com/farmbuz/seller/app/v1/api/add_media'));
      request.files.add(await MultipartFile.fromPath('image[]', file));
      var response = await request.send();
      var json = jsonDecode(await response.stream.bytesToString());
      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: json['message'].toString());
      } else {
        Fluttertoast.showToast(msg: json['message'].toString());
      }
    } catch (e, stackTrace) {
      print(stackTrace);
      throw Exception(e);
    }
  }

  Widget noInternet(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            noIntImage(),
            noIntText(context),
            noIntDec(context),
            AppBtn(
              title: getTranslated(context, "NO_INTERNET")!,
              btnAnim: buttonSqueezeanimation,
              btnCntrl: buttonController,
              onBtnSelected: () async {
                _playAnimation();

                Future.delayed(Duration(seconds: 2)).then(
                  (_) async {
                    _isNetworkAvail = await isNetworkAvailable();
                    if (_isNetworkAvail) {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  super.widget)).then((value) {
                        setState(() {});
                      });
                    } else {
                      await buttonController!.reverse();
                      if (mounted) setState(() {});
                    }
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Future<Null> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getMedia() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      if (scrollLoadmore) {
        if (mounted)
          setState(() {
            scrollLoadmore = false;
            scrollGettingData = true;
            if (scrollOffset == 0) {
              mediaList = [];
            }
          });

        try {
          var parameter = {
            //  SellerId: CUR_USERID,
            LIMIT: perPage.toString(),
            OFFSET: scrollOffset.toString(),

            // SEARCH: _searchText.trim(),
          };

          if (widget.from == "video") {
            parameter["type"] = "video";
          }

          Response response =
              await post(getMediaApi, body: parameter, headers: headers)
                  .timeout(Duration(seconds: timeOut));

          var getdata = json.decode(response.body);
          bool error = getdata["error"];
          String? msg = getdata["message"];
          // total = int.parse(getdata["total"]);
          scrollGettingData = false;
          if (scrollOffset == 0) scrollNodata = error;

          if (!error) {
            tempList.clear();
            var data = getdata["data"];
            if (data.length != 0) {
              tempList = (data as List)
                  .map((data) => new MediaModel.fromJson(data))
                  .toList();

              mediaList.addAll(tempList);
              scrollLoadmore = true;
              scrollOffset = scrollOffset + perPage;
            } else {
              scrollLoadmore = false;
            }
          } else {
            scrollLoadmore = false;
          }
          if (mounted)
            setState(() {
              scrollLoadmore = false;
            });
        } on TimeoutException catch (_) {
          setSnackbar(getTranslated(context, "somethingMSg")!);
          setState(() {
            scrollLoadmore = false;
          });
        }
      }
    } else {
      if (mounted)
        setState(() {
          _isNetworkAvail = false;
          scrollLoadmore = false;
        });
    }
  }

  setSnackbar(String msg) {
    Fluttertoast.showToast(
        msg: "$msg",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: primary,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  getMediaItem(int index) {
    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            mediaList[index].isSelected = !mediaList[index].isSelected;

            if (widget.from == "main") {
              productImage =
                  mediaList[index].subDic! + "" + mediaList[index].name!;
              productImageUrl = mediaList[index].image!;
              Navigator.pop(context);
            } else if (widget.from == "video") {
              uploadedVideoName =
                  mediaList[index].subDic! + "" + mediaList[index].name!;
              Navigator.pop(context);
            } else if (widget.from == "other") {
              if (mediaList[index].isSelected) {
                otherImgList.add(
                    mediaList[index].subDic! + "" + mediaList[index].name!);
                otherImgUrlList.add(mediaList[index].image!);
              } else {
                otherImgList.remove(
                    mediaList[index].subDic! + "" + mediaList[index].name!);
                otherImgUrlList.remove(mediaList[index].image!);
              }
            } else if (widget.from == 'variant') {
              if (mediaList[index].isSelected) {
                variantImgList.add(
                    mediaList[index].subDic! + "" + mediaList[index].name!);
                variantImgUrlList.add(mediaList[index].image!);
              } else {
                variantImgList.remove(
                    mediaList[index].subDic! + "" + mediaList[index].name!);
                variantImgUrlList.remove(mediaList[index].image!);
              }
            }
          });
        },
        child: Stack(
          children: [
            Row(
              children: [
                Image.network(
                  mediaList[index].image!,
                  height: 200,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) => erroWidget(200),
                  color: Colors.black
                      .withOpacity(mediaList[index].isSelected ? 1 : 0),
                  colorBlendMode: BlendMode.color,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name : ' + mediaList[index].name!),
                        Text('Sub Directory : ' + mediaList[index].subDic!),
                        Text('Size : ' + mediaList[index].size!),
                        Text('extension : ' + mediaList[index].extention!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.black
                  .withOpacity(mediaList[index].isSelected ? 0.1 : 0),
            ),
            mediaList[index].isSelected
                ? Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.check_circle,
                        color: primary,
                      ),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}