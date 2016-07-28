//
//  CDVIRC.m
//
//  Created by xwang on 07/01/16.
//
//

#import "CDVIRC.h"
#import "libircclient.h"

static void onConnect(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onNick(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onQuit(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onJoinChannel(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onPartChannel(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onMode(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onUserMode(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onTopic(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onKick(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onChannelPrvmsg(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onPrivmsg(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onNotice(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onInvite(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onCtcpRequest(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onCtcpReply(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onCtcpAction(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onUnknownEvent(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count);
static void onNumericEvent(irc_session_t * session, unsigned int event, const char * origin, const char ** params, unsigned int count);

@implementation CDVIRC:CDVPlugin

CDVIRC *refToSelf;

- (void)pluginInitialize
{
  refToSelf = self;
}

- (irc_session_t *)initSession
{
  callbacks.event_connect = onConnect;
  callbacks.event_nick = onNick;
  callbacks.event_quit = onQuit;
  callbacks.event_join = onJoinChannel;
  callbacks.event_part = onPartChannel;
  callbacks.event_mode = onMode;
  callbacks.event_umode = onUserMode;
  callbacks.event_topic = onTopic;
  callbacks.event_kick = onKick;
  callbacks.event_channel = onChannelPrvmsg;
  callbacks.event_privmsg = onPrivmsg;
  callbacks.event_notice = onNotice;
  callbacks.event_invite = onInvite;
  callbacks.event_ctcp_req = onCtcpRequest;
  callbacks.event_ctcp_rep = onCtcpReply;
  callbacks.event_ctcp_action = onCtcpAction;
  callbacks.event_unknown = onUnknownEvent;
  callbacks.event_numeric = onNumericEvent;
  callbacks.event_dcc_chat_req = nil;
  callbacks.event_dcc_send_req = nil;

  encoding = NSASCIIStringEncoding;
  return irc_create_session(&callbacks);
}

- (void)connect:(CDVInvokedUrlCommand *)command
{
  NSArray *arguments = [command arguments];
  if ([arguments count] != 1)
  {
    [self failWithCallbackId:command.callbackId withMessage:@"invalid paramaters"];
    return;
  }
  session = [self initSession];
  if (!session) {
    [self failWithCallbackId:command.callbackId withMessage:@"fail to create irc_session"];
    return;
  }
  NSDictionary *options = [arguments objectAtIndex:0];
  server = [options objectForKey:@"server"];
  password = [options objectForKey:@"password"];
  port = [options objectForKey:@"port"];
  nickname = [options objectForKey:@"nickname"];
  username = [options objectForKey:@"username"];
  realname = [options objectForKey:@"realname"];

  const char *cc_server = [server cStringUsingEncoding:encoding];
  const char *cc_server_password = [password length] > 0 ? [password cStringUsingEncoding:encoding] : nil;
  unsigned short us_port = [port intValue];
  const char *cc_nick = [nickname cStringUsingEncoding:encoding];
  const char *cc_username = [username cStringUsingEncoding:encoding];
  const char *cc_realname = [realname cStringUsingEncoding:encoding];

  if (irc_connect(session, cc_server, us_port, cc_server_password, cc_nick, cc_username, cc_realname)) {
    [self failWithCallbackId:command.callbackId withMessage:@"fail to connect server"];
  }
  else {
    if (thread) {
      return;
    }
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [thread start];
    connectCallbackId = command.callbackId;
  }
}

- (void)run
{
  irc_run(session);
}

- (void)disconnect:(CDVInvokedUrlCommand *)command
{
  irc_disconnect(session);
  irc_destroy_session(session);
}

- (void)isConnected:(CDVInvokedUrlCommand *)command
{
  if (!session) {
    [self successWithCallbackId:command.callbackId withBoolean:NO];
  }
  else {
    BOOL connected = irc_is_connected(session) != 0;
    [self successWithCallbackId:command.callbackId withBoolean:connected];
  }
}

- (void)join:(CDVInvokedUrlCommand *)command
{
  NSArray *arguments = [command arguments];
  if ([arguments count] != 1)
  {
    [self failWithCallbackId:command.callbackId withMessage:@"invalid paramaters"];
    return;
  }
  channel = [arguments objectAtIndex:0];
  const char *cc_channel = [channel cStringUsingEncoding:encoding];
  if (irc_cmd_join(session, cc_channel, nil)) {
    [self failWithCallbackId:command.callbackId withMessage:@"fail to join channel"];
  }
  else {
    [self successWithCallbackId:command.callbackId withMessage:@"ok" andKeep:NO];
  }
}

- (void)message:(CDVInvokedUrlCommand *)command
{
  NSArray *arguments = [command arguments];
  if ([arguments count] != 1)
  {
    [self failWithCallbackId:command.callbackId withMessage:@"invalid paramaters"];
    return;
  }
  NSString *content = [arguments objectAtIndex:0];
  const char *cc_channel = [channel cStringUsingEncoding:encoding];
  const char *cc_message = [content cStringUsingEncoding:encoding];
  if (irc_cmd_msg(session, cc_channel, cc_message)) {
    [self failWithCallbackId:command.callbackId withMessage:@"fail to send message"];
  }
  else {
    [self successWithCallbackId:command.callbackId withMessage:@"ok" andKeep:NO];
  }
}

- (void)channel:(CDVInvokedUrlCommand *)command
{
  channelCallbackId = command.callbackId;
}

static void onConnect(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onConnect triggered");
  [refToSelf successWithCallbackId:refToSelf->connectCallbackId withMessage:@"ok" andKeep:NO];
}

static void onNick(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onNick triggered");
}

static void onQuit(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onQuit triggered");
}

static void onJoinChannel(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onJoinChannel triggered");
}

static void onPartChannel(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onPartChannel triggered");
}

static void onMode(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onMode triggered");
}

static void onUserMode(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onUserMode triggered");
}

static void onTopic(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onTopic triggered");
}

static void onKick(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onKick triggered");
}

static void onChannelPrvmsg(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onChannelPrvmsg triggered");
  NSString *fromPerson = [NSString stringWithCString:origin encoding:refToSelf->encoding];
  NSString *toChannel = [NSString stringWithCString:params[0] encoding:refToSelf->encoding];
  NSString *message = [NSString stringWithCString:params[1] encoding:refToSelf->encoding];
  NSDictionary *ret = @{@"nickname": fromPerson, @"channelName": toChannel, @"message": message};
  [refToSelf successWithCallbackId:refToSelf->channelCallbackId withDictionary:ret andKeep:YES];
}

static void onPrivmsg(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onPrivmsg triggered");
}

static void onNotice(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onNotice triggered");
}

static void onInvite(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onInvite triggered");
}

static void onCtcpRequest(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onCtcpRequest triggered");
}

static void onCtcpReply(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onCtcpReply triggered");
}

static void onCtcpAction(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onCtcpAction triggered");
}

static void onUnknownEvent(irc_session_t *session, const char *event, const char *origin, const char **params, unsigned int count)
{
  NSLog(@"onUnknownEvent triggered");
}

static void onNumericEvent(irc_session_t * session, unsigned int event, const char * origin, const char ** params, unsigned int count)
{
  NSLog(@"onNumericEvent triggered");
}

- (void)successWithCallbackId:(NSString *)callbackId withMessage:(NSString *)message andKeep:(BOOL)keep
{
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
  [pluginResult setKeepCallbackAsBool:keep];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)successWithCallbackId:(NSString *)callbackId withDictionary:(NSDictionary *)message andKeep:(BOOL)keep
{
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                messageAsDictionary:message];
  [pluginResult setKeepCallbackAsBool:keep];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)failWithCallbackId:(NSString *)callbackId withMessage:(NSString *)message
{
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)successWithCallbackId:(NSString *)callbackId withBoolean:(BOOL)boolVal
{
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:boolVal];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

@end
