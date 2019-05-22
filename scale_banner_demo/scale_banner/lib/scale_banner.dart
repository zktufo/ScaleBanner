library scale_banner;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'screen_util.dart';

const MAX_COUNT = 0x7fffffff;

/// Item的点击事件
typedef void OnBannerItemClick(int position, var data);

/// 用户自定义的Item绘制方法，外层缩放控件已包含在本类中
typedef Widget CustomBuild(int position, var data, var offset, var context);

var isRunning = false;

///容器内展示单个item所占width的比例
const viewPort = 4 / 6;

///最小缩放比例
const minScale = 0.8;

var current;

class ScaleBanner extends StatefulWidget {
  final height;
  final width;
  final List datas;

  //自动播放时间间隔
  final int duration;

  final Color selectedColor;
  final Color unSelectedColor;
  final double pointRadius;
  final OnBannerItemClick bannerItemClick;
  final CustomBuild build;

  const ScaleBanner(
      this.datas, {
        this.duration,
        this.width,
        this.height,
        this.selectedColor = Colors.blue,
        this.unSelectedColor = Colors.white,
        this.pointRadius = 3.0,
        this.bannerItemClick,
        this.build,
      }) : super();

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ScaleBannerState();
  }
}

class _ScaleBannerState extends State<ScaleBanner> {
  Timer timer;
  int selectedIndex = 0;
  PageController controller;
  var pageOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: widget.height,
      width: null != widget.width
          ? widget.width
          : ScreenUtil.getScreenSize(context).width,
      child: Stack(
        children: <Widget>[
          getViewPager(),
          new Align(
            alignment: Alignment.bottomCenter,
            child: IntrinsicHeight(
              child: Container(
                padding: EdgeInsets.all(6.0),
//                color: widget.textBackgroundColor,
//                child: getBannerTextInfoWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    current = widget.datas.length > 0
        ? (MAX_COUNT / 2) - ((MAX_COUNT / 2) % widget.datas.length)
        : 0.0;
    //初始化controller，并设置每个item所占宽度比例
    controller = PageController(
        initialPage: current.toInt(), viewportFraction: viewPort);
    controller.addListener(() {
      setState(() {
        //设置banner宽度，默认为屏幕宽度
        var width = null != widget.width
            ? widget.width
            : ScreenUtil.getScreenSize(context).width;

        //计算页面偏移量
        pageOffset = controller.offset / (width * viewPort);
//        print('Listener called and the controller offset is :${pageOffset}.the controler offset is ${controller.offset}');
      });
    });
    _initPageAutoScroll();
    super.initState();
  }

  _initPageAutoScroll() {
    start();
  }

  ///开启轮播
  start() {
    //若timer已存在，则关闭
    stop();
    timer = Timer.periodic(Duration(milliseconds: widget.duration), (timer) {
      if (widget.datas.length > 0 &&
          controller != null &&
          controller.page != null) {
        controller.animateToPage(controller.page.toInt() + 1,
            duration: Duration(milliseconds: 300), curve: Curves.linear);
      }
    });
    isRunning = true;
  }

  ///关闭轮播
  stop() {
    timer?.cancel();
    timer = null;
  }

  @override
  void dispose() {
    //控件销毁时，关闭轮播并销毁页面监听
    stop();
    controller.dispose();
    super.dispose();
  }

  Widget getViewPager() {
    return PageView.builder(
      itemCount: widget.datas.length > 0 ? MAX_COUNT : 0,
      controller: controller,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return InkWell(
            onTap: () {
              //添加回调回调
              if (null != widget.bannerItemClick)
                widget.bannerItemClick(
                    selectedIndex, _getItemWithRealIndex(index));
            },
            child: _buildItemContainer(index));
      },
    );
  }

  ///构造Item外部容器
  Widget _buildItemContainer(index) {
    //当前操作的item下标
    return Transform.scale(
      scale: _generateScale(index),
      //若为设置自定义构造方法，则读取data的imgUrl并加载网络图片
      child: widget.build == null
          ? FadeInImage.memoryNetwork(
        image: _getItemWithRealIndex(index).imgUrl,
        fit: BoxFit.cover,
        placeholder: null,
      )
          : widget.build(
          index, _getItemWithRealIndex(index), pageOffset, context),
    );
  }

  ///返回当前下标对应的真实数据
  _getItemWithRealIndex(index) {
    return widget.datas[index % widget.datas.length];
  }

  ///生成缩放逻辑
  _generateScale(index) {
    var currentLeftPageIndex = pageOffset.floor();
    var currentPageOffsetPercent = pageOffset - currentLeftPageIndex;
    double scale;

    //未开始滚动时，加载初始缩放比例
    if (pageOffset == 0) {
      if (current == index) {
        scale = 1;
      } else {
        scale = minScale;
      }
      return scale;
    }
    //往左滑动时，中间的item;往右滑动时，最左边的item
    if (index == currentLeftPageIndex) {
      scale = max(1 - currentPageOffsetPercent, minScale);
    }
    //往左滑动时，最右边的item;往右滑动时，中间的item
    else if (index == currentLeftPageIndex + 1) {
      scale = max(currentPageOffsetPercent, minScale);
    }
    //往左滑动时，最左边的item
    else if (index == currentLeftPageIndex - 1) {
      if (currentPageOffsetPercent < minScale) {
        scale = minScale;
      } else {
        scale = currentPageOffsetPercent;
      }
    }
    //往右滑动方式，最右边的item
    else if (index == currentLeftPageIndex + 2) {
      if (currentPageOffsetPercent > minScale) {
        scale = minScale;
      } else {
        scale = (1 - currentPageOffsetPercent);
      }
    }

    return scale;
  }


  onPageChanged(index) {
    selectedIndex = index % widget.datas.length;
    setState(() {});
  }
}

