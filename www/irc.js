var exec = require('cordova/exec');

module.exports = {
  // connect server
  connect: function (options, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "IRC", "connect", [options]);
  },

  // disconnect server
  disconnect: function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, "IRC", "disconnect", []);
  },

  isConnected: function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, "IRC", "isConnected", []);
  },

  // join channel
  // should be used after connect
  join: function (channel, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "IRC", "join", [channel]);
  },

  // send message
  // should be used after connect
  message: function (content, successCallback, errorCallback) {
    exec(successCallback, errorCallback, "IRC", "message", [content]);
  },

  // events
  // should be used after connect
  channel: function (successCallback, errorCallback) {
    exec(successCallback, errorCallback, "IRC", "channel", []);
  }
};