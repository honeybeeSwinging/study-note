#SCLAlertView

https://github.com/dogo/SCLAlertView

SCLAlertView: Beautiful animated Alert View.  [Swift version](https://github.com/vikmeup/SCLAlertView-Swift). 它是继承自 UIViewController，而不是UIView。

##逻辑整理

上面的圆圈图标由 circleViewBackground -> circleView -> circleIconImageView 层级构成，由 layer.cornerRadius 指定它们的圆圈角度。

最下层全屏幕显示的背景 backgroundView 有三种样式，阴影、模糊（由苹果 UIImage+ImageEffects 文件处理）、透明。

alertView 需要展示内容添加到 contentView 上，用一个数组 customViews 来装这些自定义的 view，目的是为了调整 alertview 的 frame。

而 textfield 则是用 inputs 数组来装，要让不是最后一个的 textfield.returnKeyType 为 UIReturnKeyNext，这样用户点击键盘上的完成后，焦点自动定位到下一个 textfield。 并且在 textFieldShouldReturn: 代理里面 becomeFirstResponder 弹出键盘。

它的显示方式有两种，一种是显示在某个 parentViewController 上(addChildViewController:)，另外一种就是添加到自定义的 Window 上(设置 windowLevel、rootViewController)。


##知识点

 * 链式语法；
 * UIView 动画的使用；
 * tintColor 知识点；
 * UIWindow 简易知识点；
 * UIControl sendAction: ；
 * UIBezierPath 画图；


###链式语法
block 要玩的比较溜，

```
@property(copy, nonatomic) SCLAlertViewBuilder *(^cornerRadius) (CGFloat cornerRadius);

- (SCLAlertViewBuilder *(^) (CGFloat cornerRadius))cornerRadius {
    if (!_cornerRadius) {
        __weak typeof(self) weakSelf = self;
        _cornerRadius = ^(CGFloat cornerRadius) {
            weakSelf.alertView.cornerRadius = cornerRadius;
            return weakSelf;
        };
    }
    return _cornerRadius;
}

// 由于上面的属性名和入参名一样 所以我把入参名改为 value 了。
@property(copy, nonatomic) SCLAlertViewBuilder *(^cornerRadius) (CGFloat value);

- (SCLAlertViewBuilder *(^) (CGFloat value))cornerRadius {
    if (!_cornerRadius) {
        __weak typeof(self) weakSelf = self;
        _cornerRadius = ^(CGFloat value) {
            weakSelf.alertView.cornerRadius = value;
            return weakSelf;
        };
    }
    return _cornerRadius;
}
```

该 block 的返回值类型就是自己，入参就是你要设置的属性。本来想写个 UIView 的相关设置来练下手的，结果发现已经有人写了。

 * [LinkBlock](https://github.com/qddnovo/LinkBlock/)
 * [ChainableKit](https://github.com/Draveness/ChainableKit/)


###UIView 动画的使用
根据 SCLAlertViewShowAnimation 和 SCLAlertViewHideAnimation 来调用不同的动画，而这个动画都是由 UIView 的类方法完成的。


###tintColor 知识点
tintColor 永远会返回一个 color 值(默认为 UIDeviceRGBColorSpace 0 0.478431 1 1)。当父视图的 tintColor 发生改变时，它所有的子视图的 tintColor 也会跟着发生改变。我们可以重载 tintColorDidChange 发生来监听 color 的改变，来调整自身的颜色。

[详解 UIView 的 Tint Color 属性](http://www.cocoachina.com/ios/20150703/12363.html)


###UIWindow 简易知识点
windowLevel、rootViewController、makeKeyAndVisible 等。


###UIControl sendAction:
事件的传递。


###UIBezierPath 画图
在 SCLAlertViewStyleKit 类里面，用 UIBezierPath 画 SCLAlertViewStyle 各种类型所代码的图片。













