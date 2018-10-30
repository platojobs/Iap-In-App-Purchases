//
//  ViewController.m
//  InpchaseAPP
//
//  Created by MOON FLOWER on 2018/7/28.
//  Copyright © 2018年 David. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>
@interface ViewController ()<SKProductsRequestDelegate,SKPaymentTransactionObserver>

@end

@implementation ViewController

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



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
