# cordova-plugin-irc

A cordova plugin, a JS version of [libircclient](http://www.ulduzsoft.com/libircclient/)

# Install

1. ```cordova plugin add https://github.com/hkizuna/cordova-plugin-irc```
2. ```cordova build ios``` or ```cordova build android```

# Usage
## Connect to IRC server
```Javascript
var options = {
  server: 'irc.dal.net',
  password: '',
  port: '6667',
  nickname: 'hkizuna',
  username: 'hkizuna',
  realname: 'hkizuna'
};
IRC.connect(options, function (res) {
  console.log(res);
}, function (err) {
  console.log(err);
});
```

## Join channel
```Javascript
var channel = '#hkizuna';
// should be called after connect
IRC.join(channel, function (res) {
  console.log(res);
}, function (err) {
  console.log(err);
});
```

## Listen on channel
```Javascript
// should be called after join
IRC.channel(function (res) {
  console.log(res);
});
```

## Message
```Javascript
// should be called after join
IRC.message('hello irc');
```

# TODO

1. ~~Add android version~~

2. Other APIs

# LICENSE

[MIT LICENSE](http://opensource.org/licenses/MIT)
