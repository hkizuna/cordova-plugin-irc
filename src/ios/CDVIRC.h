//
//  CDVIRC.h
//
//  Created by xwang on 07/01/16.
//
//

#import <Cordova/CDV.h>
#import "libircclient.h"

@interface CDVIRC:CDVPlugin {
  irc_callbacks_t callbacks;
  irc_session_t *session;

  NSStringEncoding encoding;
  NSThread *thread;

  NSString *server;
  NSString *port;
  NSString *password;
  NSString *nickname;
  NSString *username;
  NSString *realname;
  NSString *channel;

  NSString *connectCallbackId;
  NSString *channelCallbackId;
}

- (void)connect:(CDVInvokedUrlCommand *)command;
- (void)disconnect:(CDVInvokedUrlCommand *)command;
- (void)isConnected:(CDVInvokedUrlCommand *)command;
- (void)join:(CDVInvokedUrlCommand *)command;
- (void)message:(CDVInvokedUrlCommand *)command;
- (void)channel:(CDVInvokedUrlCommand *)command;

@end