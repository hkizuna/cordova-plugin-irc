package xwang.cordova.irc;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

public class IRC extends CordovaPlugin {
    public static final String ERROR_INVALID_PARAMETERS = "参数错误";

    public static final String TAG = "Cordova.Plugin.IRC";

    protected IRCClient ircClient;
    String joinedChannel;

    @Override
    protected void pluginInitialize() {
      super.pluginInitialize();
      ircClient = IRCClient.getInstance();
    }

    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
      if (action.equals("connect")) {
        return connect(args, callbackContext);
      }
      else if (action.equals("disconnect")) {
        return disconnect(args, callbackContext);
      }
      else if (action.equals("isConnected")) {
        return isConnected(args, callbackContext);
      }
      else if (action.equals("join")) {
        return join(args, callbackContext);
      }
      else if (action.equals("message")) {
        return message(args, callbackContext);
      }
      else if (action.equals("channel")) {
        return channel(args, callbackContext);
      }

      return false;
    }

    protected boolean connect(CordovaArgs args, final CallbackContext callbackContext) {
      final JSONObject options;
      final String server;
      final int port;
      final String password;
      final String nickname;
      final String username;
      final String realname;
      try {
        options = args.getJSONObject(0);
        server = options.getString("server");
        port = Integer.parseInt(options.getString("port"));
        password = options.getString("password");
        nickname = options.getString("nickname");
        username = options.getString("username");
        realname = options.getString("realname");
      } catch (JSONException e) {
          callbackContext.error(ERROR_INVALID_PARAMETERS);
          return true;
      }

      ircClient.setOnConnectListener(new IRCClient.OnConnectListener() {
        @Override
        public void onConnect() {
          callbackContext.success("ok");
        }
      });

      cordova.getThreadPool().execute(new Runnable() {
        @Override
        public void run() {
          try {
            ircClient.connect(server, port, password, nickname, username, realname);
          } catch (Exception e) {
            callbackContext.error(e.getMessage());
          }
        }
      });

      return true;
    }

    protected boolean disconnect(CordovaArgs args, final CallbackContext callbackContext) {
      cordova.getThreadPool().execute(new Runnable() {
        @Override
        public void run() {
          try {
            ircClient.disconnect();
          } catch (Exception e) {
            callbackContext.error(e.getMessage());
          }
        }
      });

      PluginResult result = new PluginResult(PluginResult.Status.OK, true);
      callbackContext.sendPluginResult(result);
      return true;
    }

    protected boolean isConnected(CordovaArgs args, final CallbackContext callbackContext) {
      cordova.getThreadPool().execute(new Runnable() {
        @Override
        public void run() {
          try {
            boolean connected = ircClient.isConnected();
            PluginResult result = new PluginResult(PluginResult.Status.OK, connected);
            callbackContext.sendPluginResult(result);
          } catch (Exception e) {
            callbackContext.error(e.getMessage());
          }
        }
      });

      return true;
    }

    protected boolean join(CordovaArgs args, final CallbackContext callbackContext) {
      final String channel;
      try {
        channel = args.getString(0);
        joinedChannel = channel;
      } catch (JSONException e) {
        callbackContext.error(ERROR_INVALID_PARAMETERS);
        return true;
      }

      cordova.getThreadPool().execute(new Runnable() {
        @Override
        public void run() {
          try {
            ircClient.join(channel);
          } catch (Exception e) {
            callbackContext.error(e.getMessage());
          }
        }
      });

      sendNoResultPluginResult(callbackContext, false);
      return true;
    }

    protected boolean message(CordovaArgs args, final CallbackContext callbackContext) {
      final String channel;
      final String content;
      try {
        content = args.getString(0);
        channel = joinedChannel;
      } catch (JSONException e) {
        callbackContext.error(ERROR_INVALID_PARAMETERS);
        return true;
      }

      cordova.getThreadPool().execute(new Runnable() {
        @Override
        public void run() {
          try {
            int errorCode = ircClient.message(channel, content);
            PluginResult result = null;
            if (errorCode == 0) {
              result = new PluginResult(PluginResult.Status.OK);
            }
            else {
              result = new PluginResult(PluginResult.Status.ERROR);
            }
            callbackContext.sendPluginResult(result);
          } catch (Exception e) {
            callbackContext.error(e.getMessage());
          }
        }
      });

      return true;
    }

    protected boolean channel(CordovaArgs args, final CallbackContext callbackContext) {
      cordova.getThreadPool().execute(new Runnable() {
        @Override
        public void run() {
          try {
            ircClient.setOnChannelListener(new IRCClient.OnChannelListener() {
              @Override
              public void onChannel(String fromPerson, String toChannel, String message) {
                String json = "{nickname: '" + fromPerson + "', channelName: '" + toChannel + "', message: '" + message + "'}";
                try {
                  PluginResult result = new PluginResult(PluginResult.Status.OK, new JSONObject(json));
                  result.setKeepCallback(true);
                  callbackContext.sendPluginResult(result);
                } catch (JSONException e) {
                  callbackContext.error(e.getMessage());
                }
              }
            });
          } catch (Exception e) {
            callbackContext.error(e.getMessage());
          }
        }
      });

      return true;
    }

    private void sendNoResultPluginResult(CallbackContext callbackContext, boolean keep) {
      PluginResult result = new PluginResult(PluginResult.Status.OK);
      result.setKeepCallback(keep);
      callbackContext.sendPluginResult(result);
    }
}
