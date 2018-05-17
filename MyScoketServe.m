//
//  MyScoketServe.m
//  WarmHome
//
//  Created by huafangT on 16/11/2.
//
//

#import "MyScoketServe.h"
#import "Tools.h"
//设置连接超时
#define TIME_OUT 20

//设置读取超时 -1 表示不会使用超时
#define READ_TIME_OUT -1

//设置写入超时 -1 表示不会使用超时
#define WRITE_TIME_OUT -1

//每次最多读取多少
#define MAX_BUFFER 10240

@implementation MyScoketServe

static MyScoketServe *socketServe = nil;

+ (MyScoketServe *)sharedSocketServe {
    @synchronized(self) {
        if(socketServe == nil) {
            socketServe = [[[self class] alloc] init];
        }
    }
    return socketServe;
}


+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (socketServe == nil)
        {
            socketServe = [super allocWithZone:zone];
            return socketServe;
        }
    }
    return nil;
}


- (void)startConnectSocketWithHost:(NSString *)host port:(NSInteger)port
{
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    //   [self SocketOpen:host port:port];
    [self.socket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    if ( ![self SocketOpen:host port:port] )
    {
        
    }
}

- (NSInteger)SocketOpen:(NSString*)addr port:(NSInteger)port
{
    
    if (![self.socket isConnected])
    {
        NSError *error = nil;
        [self.socket connectToHost:addr onPort:port withTimeout:TIME_OUT error:&error];
    }
    
    return 0;
}


-(void)cutOffSocket
{
    self.socket.userData = SocketOfflineByUser;
    [self.socket disconnect];
}


- (void)sendMessage:(id)message
{
    //像服务器发送数据
    NSString * jsons= [Tools toJsonModelStr:message] ;
    NSData * cmdData = [jsons dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:cmdData withTimeout:10.0f tag:0];
}

#pragma mark - Delegate

//接受消息成功之后回调
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString * msg;
    msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (_receiveData == nil) {
        _receiveData = [[NSMutableData alloc] init];
    }
    [_receiveData appendData:data];//把接收到的数据添加上
    NSRange endRange = [msg rangeOfString:@"\r"];
    if (endRange.location != NSNotFound) {
     NSString * resultJson =[[NSString alloc] initWithData:_receiveData encoding:NSUTF8StringEncoding];
        NSLog(@"didReadData-----%@",resultJson);
        _resultBlock([resultJson mj_JSONObject]);
        _receiveData = nil;//用于接受数据的对象置空
    }
    
    [self.socket readDataWithTimeout:READ_TIME_OUT buffer:nil bufferOffset:0 maxLength:MAX_BUFFER tag:0];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@" sorry the connect is failure %ld",sock.userData);
  //    [Tools showMessage:@"服务器无响应，请稍后再试"];
    
    if (sock.userData == SocketOfflineByServer) {
        // 服务器掉线，重连
        [self startConnectSocketWithHost:[Tools getObjForKey:IP] port:[[Tools getObjForKey:PORT]integerValue]];
    }
    else if (sock.userData == SocketOfflineByUser) {
        
        // 如果由用户断开，不进行重连
        return;
    }else if (sock.userData == SocketOfflineByWifiCut) {
        
        // wifi断开，不进行重连
        return;
    }
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSData * unreadData = [sock unreadData]; // ** This gets the current buffer
    if(unreadData.length > 0) {
        [self onSocket:sock didReadData:unreadData withTag:0]; // ** Return as much data that could be collected
    } else {
        
        NSLog(@" willDisconnectWithError %ld   err = %@",sock.userData,[err description]);
        if (err.code == 57) {
            self.socket.userData = SocketOfflineByWifiCut;
        }
    }
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"didAcceptNewSocket");
}

// 心跳连接
-(void)checkLongConnectByServe{
    
    // 向服务器发送固定可是的消息，来检测长连接
    NSString *longConnect = @"connect is here";
    NSData   *data  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:1 tag:0];
}


//发送消息成功之后回调
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    //读取消息
    [self.socket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:MAX_BUFFER tag:0];
}

-(void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"Received bytes: %lu",(unsigned long)partialLength);
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    //这是异步返回的连接成功，
    NSLog(@"MySocketServe didConnectToHost");
    
    [self.socket readDataWithTimeout:-1 tag:0];
    
    //    通过定时器不断发送消息，来检测长连接
    //    self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(checkLongConnectByServe) userInfo:nil repeats:YES];
    //    [self.heartTimer fire];
}

@end
