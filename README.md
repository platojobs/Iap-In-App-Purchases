# Iap-In-App-Purchases
Iap-In-App Purchases    IOS应用内支付IAP

+ [产品提交苹果审核之：苹果IAP内购规则](http://coffee.pmcaff.com/article/499746885393536/pmcaff?utm_source=forum&from=related&pmc_param%5Bentry_id%5D=209796516725824)

-------------

****流程****

一般有以下几种内购流程 
1. 直接使用Apple的服务器进行购买和验证 
2. 就是自己假设服务器进行验证 
网上有几张图，不过是英文版的，看着流程也很复杂，其实很简单，我简单说一下

第一种流程就是用户在买你app里面的道具A的时候，点击了购买按钮
这时候你的app会发送一个请求给苹果服务器，告诉它，我要买A
由于苹果服务器那边你已经配置好了有哪些东西(后面会叫你怎么在那边配置你要卖的商品ABCD)，苹果找出商品A，然后itunes store会向你确认是否真的要买A（只要用过苹果支付的基本都知道）
用户确定了以后，苹果服务器会给你返回一个购买凭证，app再把东西下发给用户，ok了
但是，一般的app都有自己的服务器，道具之类的物品也都是存在服务器的，所以，往往我们会采取第二种方式—把这个购买凭证发给我们自己的服务器，然后我们服务器通过给苹果服务器发送这个凭证来校验是不是真的，是真的，就下发道具，不是，则不下发！

--------------------- 

+ [iOS内购Iap-In-App Purchases那些事](https://www.jianshu.com/p/d1905a3e5920)
+ [关于IAP内购详细流程](https://www.jianshu.com/p/d6c678900a34)
+ [RMStore第三方简化内购](https://github.com/robotmedia/RMStore)
+ [RMStores实例应用](https://www.aliyun.com/jiaocheng/367377.html)

------------------------


```objective-c

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //设置购买的观察者，处理购买的
    [[SKPaymentQueue defaultQueue]addTransactionObserver:self];
    // Do any additional setup after loading the view, typically from a nib.
}
//用户点击了一个IAP项目，我们事先需要查询用户是否允许应用内购买，如果不允许则不用进行以下步骤了
- (IBAction)pochaseAC:(UIButton *)sender {
    if ([SKPaymentQueue canMakePayments]) {
        //
    }else{
        NSLog(@"失败，用户禁止应用内付费购买");
    }
    
}
/*先通过该IAP的ProductID 向APP store查询，获得SKPayment实例，通过SKPaymentQueue 的addPayment方法发起一个购买的操作*/
- (void)getProductInfo{
    NSSet *set=[NSSet setWithArray:@[@"ProductId"]];
    SKProductsRequest* request = [[SKProductsRequest alloc]initWithProductIdentifiers:set];
    request.delegate=self;
    [request start];
}
/*以上查询的回调函数*/
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray * myProduct = response.products;
    if (myProduct.count==0) {
        NSLog(@"无法获取产品信息，购买失败");
        return;
    }
    SKPayment *payment = [SKPayment paymentWithProduct:myProduct[0]];
    [[SKPaymentQueue defaultQueue]addPayment:payment];
    
    
}

#pragma mark处理观察者的回调
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"transactionIdentifier= %@",transaction.transactionIdentifier);
                //交易完成
                [self transactionsSuccess:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self transactionsFailed:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self transactionsRestored:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"事务在队列中，但它的最终状态是等待外部操作");
                break;
                
            default:
                break;
        }
    }
    
    
}
#pragma mark==交易完成的操作
-(void)transactionsSuccess:(SKPaymentTransaction*)transaction{
    
    //your app should implement these two methods
    
    NSString * productIdentifer = transaction.payment.productIdentifier;
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    NSURLSession *session = [NSURLSession sharedSession];
    // 创建任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:urlRequest  completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
        NSString * receipt = [data base64EncodedStringWithOptions:0];
        if (productIdentifer.length>0) {
            //向自己的服务器验证购买凭证  receipt 给服务器验证
            /*这里是可选的。也可以不验证。如果购买成功，如果购买成功，我们需要将凭证发送到服务器上进行验证。
            老点到网络异常情况，iOS 端的发送凭证操作应该可以持久化，如果程序退出、崩溃或
            网络异常，可以恢复重试。*/
        }
        // remove the paymentQueue
        [self removePaymentQueue:transaction];
    }];
    // 启动任务（必须的）
    [task resume];
    
}
#pragma mark cancel or fail
-(void)transactionsFailed:(SKPaymentTransaction*)transaction{
    
    if (transaction.error.code!=SKErrorPaymentCancelled) {
        NSLog(@"购买失败");
    }else{
        NSLog(@"购买取消");
    }
    [self removePaymentQueue:transaction];
}
#pragma mark Restored
-(void)transactionsRestored:(SKPaymentTransaction*)transaction{
    
    //对于已经购买过的商品，处理恢复购买的逻辑
    // insert your code here
    [self removePaymentQueue:transaction];
    
}
#pragma mark==remove the paymentQueue
-(void)removePaymentQueue:(SKPaymentTransaction*)transaction{
     [[SKPaymentQueue defaultQueue ]finishTransaction:transaction];
}
//移除观察者
-(void)dealloc{
    [[SKPaymentQueue defaultQueue]removeTransactionObserver:self];
}

/*
服务端的开发：
 
 服务端后台的工作比较简单，分为4步:
 1.接收iOS端发过来的购买凭证。
 2.判断凭证是否已经存在，是否验证过，然后存储该凭证。
 3.将该凭证发送到苹果的服务器验证，并将验证结果返回给客户端。
 4.如果需要，修改用户相应的会员权限。
 考虑到网络异常情况，服务器的验证应该是一一个可恢复的队列，如果失败了，应该进行重
 试。
 与苹果的验证接口文档在http://developer.com/library/ios/#documentation/NeworkinInternet/Conceptual/StoreKitGuide/Verifyingstoreceipts/VerifingStoreReceipts.html#//apple_ref/doc/uid/TP40008267-CH104-SW3。简单来说就是将该购买凭证用Base64编码，然后POST给苹果的验证服务器，苹果将验证结果以jSON形式返回。
 苹果App Store线上的购买凭证验证地址是https://buy.itunes.apple.com/verifyRceipt
 ，测试的验证地址是https://sandbox.itunes.apple.com/verifyRceipt
 
 */

```
