//
//  MyScoketServe.h
//  WarmHome
//
//  Created by huafangT on 16/11/2.
//

#import <Foundation/Foundation.h>
#import <AsyncSocket.h>

typedef void(^ResultBlock)(id resultJson);

enum{
    SocketOfflineByServer,      //服务器掉线
    SocketOfflineByUser,        //用户断开
    SocketOfflineByWifiCut,     //wifi 断开
};

@protocol MySocketDelegate <NSObject>
- (void)onSocketDidDisconnect:(AsyncSocket *)sock;
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag;
@end

@interface MyScoketServe : NSObject<AsyncSocketDelegate>
@property (nonatomic, copy)ResultBlock resultBlock;
@property (nonatomic, strong) AsyncSocket         *socket;       // socket
@property (nonatomic, retain) NSTimer             *heartTimer;   // 心跳计时器
@property (nonatomic, retain) NSMutableData *receiveData;

+ (MyScoketServe *)sharedSocketServe;

//  socket连接
- (void)startConnectSocketWithHost:(NSString *)host port:(NSInteger)port;

// 断开socket连接
-(void)cutOffSocket;

// 发送消息
- (void)sendMessage:(id)message;

@end
