package xwang.cordova.irc;

public class IRCClient {
  // single irc_session
  private static IRCClient inst;
  public static synchronized IRCClient getInstance() {
    if (inst == null) {
      inst = new IRCClient();
      inst.initialize();
    }
    return inst;
  }

  private IRCClient() {
    initialize();
  }

  private native void initialize();

  // connection
  public native int connect(String server, int port, String password, String nickname, String username, String realname); 
  public native void disconnect();
  public native boolean isConnected();

  // join channel
  // should be used after connect
  public native int join(String channel);

  // send message
  // should be used after connect
  public native int message(String channel, String content);

  // event listeners
  public static class OnConnectListener {
    public void onConnect() {}
  }

  public static class OnChannelListener {
    public void onChannel(String fromPerson, String toChannel, String message) {}
  }

  private OnConnectListener mOnConnectListener;
  private OnChannelListener mOnChannelListener;

  public void setOnConnectListener(OnConnectListener listener) {
    mOnConnectListener = listener;
  }

  public void setOnChannelListener(OnChannelListener listener) {
    mOnChannelListener = listener;
  }

  // events
  public void onConnect() {
    if (mOnConnectListener != null) mOnConnectListener.onConnect();
  }

  public void onChannel(String fromPerson, String toChannel, String message) {
    if (mOnChannelListener != null) mOnChannelListener.onChannel(fromPerson, toChannel, message);
  }

  static {
    System.loadLibrary("ircclient-jni");
  }
}
