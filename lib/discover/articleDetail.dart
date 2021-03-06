import 'package:flutter/material.dart';
import 'package:flutter_fuqi/modal/articleData.dart';
import 'package:flutter_fuqi/constants.dart';
import 'package:flutter_fuqi/fuqi/indicator_viewpager.dart';
import 'package:flutter_fuqi/fuqi/user_detail.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_fuqi/dio/dio.dart';
import 'package:flutter_fuqi/tool/tool.dart';
import 'package:dio/dio.dart';

class articleDetail extends StatefulWidget{

  articleData mData;
  String tag;


  articleDetail({Key key,@required this.mData,@required this.tag}):super(key:key);

  @override
  _articleDetailState createState() {
    // TODO: implement createState
    return _articleDetailState();
  }

}

class _articleDetailState extends State<articleDetail> with TickerProviderStateMixin {
  List<String> _urls = [];
  List<Widget> _imagePages = [];
  TabController _controller;
  List<Tab> _tabs;
  Widget _articleTabContent;
  int _currentIndex = 0;
  articleData _localData;
  TextEditingController _textController = new TextEditingController();


  void _setImagePages(){
    _urls.add(widget.mData.head_img);
    if (widget.mData.head_img2.contains('media/uploads/couple.jpg') == false){
      _urls.add(widget.mData.head_img2);
    }
    if (widget.mData.head_img3.contains('media/uploads/couple.jpg') == false){
      _urls.add(widget.mData.head_img3);
    }

    _urls.forEach((String url) {

      Widget avator = tool.getCacheImage(url: url,height: Constants.bannerImageHeight,fit:BoxFit.contain );

      _imagePages.add(
          Container(
            color: Colors.black.withAlpha(900),
            child: ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: avator),
          ));
    });
  }

  _onChanged(){
    if(_currentIndex != _controller.index){
      setState(() {
        _currentIndex = _controller.index;
        _articleTabContent = _getArticleTabContent();
      });
    }
  }

  _getArticleTabContent(){
    Widget content;
    if (_tabs[_currentIndex].text == '文章详情'){
      if(tool.myUserData['profile'] == '普通会员' && widget.tag == 'qq' && tool.myUserData['is_free'] == false){
        content = Text("内容:权限不够,请升级为VIP后查看",style:TextStyle(color: Colors.red));
      }else{
        content = Text("内容:${_localData.content}");
      }
        return ListView(
          children: <Widget>[
            Container(
                padding: EdgeInsets.only(left: 10.0,top: 5.0),
                child: Row(
                  children: <Widget>[
                    Text("简介:${_localData.brief}"),
                  ],
                )
            ),
            Divider(),
            Container(
                padding: EdgeInsets.only(left: 10.0,top: 5.0),
                child: content
            ),
          ],
        );
    }else{
      return ListView.builder(
          itemCount: _localData.article_comment.length,
          itemBuilder: (BuildContext context, int index){
            return GestureDetector(
              onTap: (){
                Navigator.of(context).push(new MaterialPageRoute(builder: (_) {
                  return UserDetail(id: _localData.article_comment[index]['user']['id']);
                }));
              },
              child: Container(
                  child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 35.0,
                              height: 35.0,
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                image: new DecorationImage(
                                    image: new NetworkImage(_localData.article_comment[index]['user']['head_img']),
                                    fit: BoxFit.cover),
                                border: new Border.all(
                                  color: Colors.white,
                                  width: 2.0,),
                              ),),
                            Padding(
                                padding: const EdgeInsets.fromLTRB(6.0, 0.0, 0.0, 0.0),
                                child: new Text(
                                    _localData.article_comment[index]['user']['name'],
                                    style: new TextStyle(fontSize: 16.0))),],
                        ),
                        Container(
                          alignment: Alignment.bottomRight,
                          padding: EdgeInsets.only(right: 5.0),
                          child:Text(_localData.article_comment[index]['comment'], style: TextStyle(fontSize: 12.0),)
                        ),
                        Divider()]
                  )
              )
            );
          }
          );
    }
  }

  _sendComment() async {
    String comment = _textController.text;

    if (comment == null || comment.length == 0 || comment.trim().length == 0) {
      Scaffold.of(context).showSnackBar(new SnackBar(
        content: new Text("请填写留言内容！"),
      ));
      return;
    }

    try{
      var response = await dioTool.dio.post('${Constants.host}/app/writeComment/',
          data:{'comment':comment,'article_id':_localData.id});
      tool.showToast("发布成功");
      _getArticleInfo();
    }on DioError catch (e){
      if (e.response != null && e.response.statusCode == 401){
        tool.showToast("密码已过期,请重新登录");
        Navigator.of(context).pushNamed('/login');
      }else{
        tool.showToast("网络异常");
      }
    }
  }

  _writeComment(){
    Alert(
        context: context,
        title: "评论",
        content: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                hintText: '请输入评论内容',
              ),
              controller: _textController,
            ),
          ],
        ),
        buttons: [
          DialogButton(
            onPressed: () {
              _sendComment();
              Navigator.pop(context);
            },
            child: Text(
              "发布",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
        ]).show();
  }

  //获取文章详情,增加人气统计
  void _getArticleInfo() async {
    try{
      var response = await dioTool.dio.get("${Constants.host}/app/searchArticles/${_localData.id}/");
      //widget.mData.setNewData(_localData);//如果不更新它,重新进来时不会显示新的评论信息
      _localData = articleData.getArticleData(response.data);
      if(_localData.comment_count != widget.mData.comment_count){
        setState(() {
          widget.mData.setNewData(_localData);//如果不更新它,重新进来时不会显示新的评论信息
          _articleTabContent = _getArticleTabContent();
        });
      }
    }on DioError catch (e){
      if(e.response != null && e.response.statusCode == 401){
        tool.showToast("密码已过期,请重新登录");
        Navigator.of(context).pushNamed('/login');
      }else{
        tool.showToast("网络异常");
      }
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print("init");
    _setImagePages();
    _tabs = [
      Tab(text: '文章详情'),
      Tab(text: '评论'),
    ];
    _localData = widget.mData;//IOS版直接操作widget.mData有异常
    _controller = new TabController(length: _tabs.length, vsync: this);
    _currentIndex = _controller.index;
    _controller.addListener(_onChanged);
    _articleTabContent = _getArticleTabContent();
    _getArticleInfo();
  }
  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  _getFloatingActionButton() {
    if(_tabs[_currentIndex].text == '文章详情') {
      return null;
    }else {
      return Builder(builder: (BuildContext context) {
        return FloatingActionButton(
          child:Icon(Icons.add),
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          onPressed: (){
            _writeComment();
          },
        );
      });
    }
  }
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.mData.title),
          centerTitle: true,
        ),
        floatingActionButton: _getFloatingActionButton(),
        body: Container(
            child: Column(
              children: <Widget>[
                new SizedBox.fromSize(
                  size:  Size.fromHeight(Constants.bannerImageHeight),
                  child: new IndicatorViewPager(_imagePages),
                ),
                Divider(),
                TabBar(
                  indicatorWeight: 3.0,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: new TextStyle(fontSize: 16.0),
                  labelColor: Colors.black,
                  controller: _controller,
                  tabs: _tabs,
                  indicatorColor: Theme
                      .of(context)
                      .primaryColor,
                ),
                Expanded(
                  child: _articleTabContent,
                )

              ],)),
      );
    }
}