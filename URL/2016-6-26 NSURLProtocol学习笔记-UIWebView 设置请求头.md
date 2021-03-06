NSURLProtocol学习笔记-UIWebView 设置请求头
=============

前段时间写过[UIWebView 设置请求头](http://joakimliu.github.io/2016/05/15/UIWebView%E8%AE%BE%E7%BD%AE%E8%AF%B7%E6%B1%82%E5%A4%B4/)文章，后面发现那样做是有bug的，因为当我A到B回到A再进入B界面的时候，这是B已经加载过了，B的url已经存在那个数组里面，所以不会再塞请求头了，但是这样子就会请求失败，所以这个方法是不行的。好在[NSURLProtocol](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLProtocol_Class/)能解决这个问题。

> `An NSURLProtocol object handles the loading of protocol-specific URL data. The NSURLProtocol class itself is an abstract class that provides the infrastructure for processing URLs with a specific URL scheme. You create subclasses for any custom protocols or URL schemes that your app supports.`

> NSURLProtocol 对象处理加载特定的url。它是一个为处理特定scheme url提供基础解决方案的抽象类。我们可以创建App支持的解决特定协议或者url的子类。

下面是我处理请求头的代码，在`viewDidLoad`方法里面调用 `registerClass:` 方法，`dealloc`里面调用`unregisterClass:`方法
``` Objective-C
static NSString *const URLProtocolHandledKey = @"URLProtocolHandledKey";
@interface NSCustomHeaderURLProtocol () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation NSCustomHeaderURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (!([[[request URL] scheme] caseInsensitiveCompare:@"http"] == NSOrderedSame || [[[request URL] scheme] caseInsensitiveCompare:@"https"] == NSOrderedSame)) { // 不是http的不用处理
        return NO;
    }

    if (![request allHTTPHeaderFields][kKeyWebViewAuthorization]) {                   // 不包含请求头
        if ([NSURLProtocol propertyForKey:URLProtocolHandledKey inRequest:request]) { // 已经处理过了 不用处理
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mRequest = [request mutableCopy];
    NSString *fieldValue =@"xxx请求头内容";
    [mRequest addValue:fieldValue forHTTPHeaderField:kKeyWebViewAuthorization];
    return mRequest;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:URLProtocolHandledKey inRequest:mutableReqeust];
    self.connection = [[NSURLConnection alloc] initWithRequest:[[self class] canonicalRequestForRequest:self.request] delegate:self startImmediately:YES];
}

- (void)stopLoading {
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response != nil) {
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    return request;
}

@end

```
下面来说说它的处理流程以及相关方法。
`propertyForKey:inRequest:`和`setProperty:forKey:inRequest:`方法是用来处理`NSURLRequest`或者`NSMutableURLRequest`的，可以标志该request是否已做过处理。 上面的`URLProtocolHandledKey`就是用来标记该request是否处理过。并且还有一个最基本的功能，就是创建NSURLResponse来处理request请求成功的情况。


####Registering and Unregistering Protocol Classes
####`registerClass:`
注册一个NSURLProtocol的子类，让`URL loading system`知道它的存在。当它注册失败返回NO时，说明注册的类不是 NSURLProtocol 的子类。
当`URL loading system`开始加载一个request时，每一个注册的protocol都会去看自己是否能够被特定的request初始化。当第一个注册protocol，` canInitWithRequest: `方法返回YES时，它就去加载特定的url了，所以这里并不能保证所有注册的protocol都能处理。protocol处理的顺序和它们注册的顺序相反，即后注册的先处理。处理模式就是在`canonicalRequestForRequest:`里面创建一个权威的request去请求。
####`unregisterClass:`
取消注册。该方法调用后，该protocolClass不再被`URL loading system`处理。

####Determining If a Subclass Can Handle a Request
#####`canInitWithRequest：`
该protocolClass是否处理该request。子类必须实现该方法。

####Getting and Setting Request Properties
#####`propertyForKey:inRequest:`
#####`setProperty:forKey:inRequest:`
#####`removePropertyForKey:inRequest:`
顾名思义，这个三个方法就是根据某个key取出、设置、移除request的属性。

####Providing a Canonical Version of a Request
#####`canonicalRequestForRequest:`
权威的request（个人理解就是被处理过的request）。要保证该protocolClass处理过的request要有统一的形式（一个protocolClass 你不能即添加请求头，又改变url的query，这是错误的做法）。该方法子类必须实现，在实现的过程中得考虑`URL cache`缓存问题，因为`the canonical form of a request`习惯于从`URL cache`中查找对象用来检测两个`NSURLRequest`是否相等。

####Determining If Requests Are Cache Equivalent
#####`requestIsCacheEquivalent:toRequest:`
该方法用来检测两个request在缓存意义上是否相等。
该方法当且仅当request用相同的protocol来处理，并且当它们执行过特定的检测后protocol证明它们两个相等。

####Starting and Stopping Downloads
#####`startLoading`
执行特定的request请求。 子类必须实现该方法。
该方法执行后，子类需要加载该request并且通过`NSURLProtocolClient`协议来处理`URL loading system`的回调。 
#####`stopLoading`
取消特定的request请求。 子类必须实现该方法。
该方法能够取消一个正在进行中的请求，并且还要停止对该protocolClass的`client`属性发通知。

####Getting Protocol Attributes
#####`cachedResponse`
 缓存的响应数据。如果没有在子类里重载，则会返回在初始化时存储的值。
#####`client`
与`URL loading system`交互的接受者。
####`request`
请求对象request。


####NSURLProtocolClient
`NSURLProtocolClient`为`NSURLProtocol`提供于`URL loading system`交互的接口。App没有必要去实现该协议。从上面看到的代码看到，在`NSURLConnectionDelegate`的代理方法里面有`client`响应的处理方法。

####总结
* 当然了，这里的网络请求也可以用 `NSURLSession`，只要将请求返回的数据让`client`与`URL loading system`交互即可。
* 上面的代码处理是参考的[matt大神的NSEtcHosts](https://github.com/mattt/NSEtcHosts)
* [Apple Sample Code](https://developer.apple.com/library/ios/navigation/#section=Resource%20Types&topic=Sample%20Code)里面竟然没有`NSURLProtocol`的samplecode

####问题 NSURLProtocol不支持WKWebView ？
> It’s likely that this worked with UIWebView as an accident of the implementation.  WKWebView, OTOH, does all of its networking out of process, so such accidents are rare (everything that traverses the inter-process gap has to be explicitly coded to do so). from[https://forums.developer.apple.com/thread/18952](https://forums.developer.apple.com/thread/18952)

NSURLProtocol`这种处理对`WKWebView`是不起作用的，因为`WKWebView`的加载是在另外一个进程里。如果现有的项目中是用`WKWebView`的，那么怎么塞请求头呢？我目前想到的只有通过特定的协议采取js交互。

* `search keyword:wkwebview set header、 wkwebview custom header`
* [WKWebViewでNSURLRequestをPOSTするとヘッダーが消える問題（解決）](http://labs.torques.jp/2015/10/06/4045/)
* [Can't set headers on my WKWebView POST request](http://stackoverflow.com/questions/26253133/cant-set-headers-on-my-wkwebview-post-request)
* [How To add HttpHeader in request globally for ios swift](http://stackoverflow.com/questions/28984212/how-to-add-httpheader-in-request-globally-for-ios-swift/37474812#37474812)
* [WKWebView and NSURLProtocol not working](http://stackoverflow.com/questions/24208229/wkwebview-and-nsurlprotocol-not-working)）

####问题 重定向问题
最近在 load webPage 的时候，发现重定向的时候 (A->B->C) 有问题，不能 load C，只能到 B，或者到 A。现在假设 (A->B) 这个情况，通过调试发现，两个 URL 的 NSURLProtocol 方法如下：
A:
 * canInitWithRequest:
 * canonicalRequestForRequest:
 * startLoading

B:
 * canInitWithRequest:
 * canonicalRequestForRequest:

也就是说 startLoading 方法没有调用，webView 就不会加载 B。后面通过查找资料发现是网络请求的原因，于是将 NSURLConnection 换成了 NSURLSession，因为 NSURLSession 有个重定向的代理方法   URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:

调整后的实例代码如下(其他的代码逻辑处理还是一样的)，

``` Objective-C
- (void)startLoading {
    NSMutableURLRequest *mutableReqeust = [[self request] mutableCopy];
    //打标签，防止无限循环
    [NSURLProtocol setProperty:@(YES) forKey:URLProtocolHandledKey inRequest:mutableReqeust];

    NSURLSessionConfiguration *configure = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    self.session = [NSURLSession sessionWithConfiguration:configure delegate:self delegateQueue:queue];
    self.task = [self.session dataTaskWithRequest:mutableReqeust];
    [self.task resume];
}

- (void)stopLoading {
    [self.session invalidateAndCancel];
    self.session = nil;
}

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)newRequest completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    NSMutableURLRequest *redirectRequest = [newRequest mutableCopy];
    [[self class] removePropertyForKey:URLProtocolHandledKey inRequest:redirectRequest];
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    [self.task cancel];
    [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}
```

####参考链接
* https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLProtocol_Class/
* https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Protocols/NSURLProtocolClient_Protocol/
* https://github.com/mattt/NSEtcHosts
* http://stackoverflow.com/questions/25539837/how-to-add-customize-http-headers-in-uiwebview-request-my-uiwebview-is-based-on

####其他学习链接
* [NSURLProtocol Tutorial](https://www.raywenderlich.com/59982/nsurlprotocol-tutorial)
* [NSURLProtocol - nshipster](http://nshipster.com/nsurlprotocol/)
* [NSURLProtocol - xiongzenghuidegithub](http://xiongzenghuidegithub.github.io/blog/2015/01/07/nsurlprotocol/)
* [iOS开发之--- NSURLProtocol](http://www.jianshu.com/p/7c89b8c5482a)
* [研究笔记：iOS中使用WebViewProxy拦截URL请求](https://yq.aliyun.com/articles/7470?spm=5176.100239.blogrightarea55708.13.Tob8Rp)
* [NSURLProtocol和NSRunLoop的那些坑](http://xiangwangfeng.com/2014/11/29/NSURLProtocol%E5%92%8CNSRunLoop%E7%9A%84%E9%82%A3%E4%BA%9B%E5%9D%91/)
