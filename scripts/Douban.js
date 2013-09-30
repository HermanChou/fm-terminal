// Generated by CoffeeScript 1.6.3
(function() {
  var Channel, DoubanFM, JsonObject, Player, Service, Song, User, proxy_domain, _ref, _ref1, _ref2,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  JsonObject = (function() {
    function JsonObject(json) {
      var key, value;
      this.json = json;
      for (key in json) {
        value = json[key];
        this[key] = value;
      }
    }

    return JsonObject;

  })();

  Channel = (function(_super) {
    __extends(Channel, _super);

    function Channel() {
      _ref = Channel.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Channel.prototype.update = function(succ, err) {
      var _ref1,
        _this = this;
      return (_ref1 = window.DoubanFM) != null ? _ref1.doGetSongs(this, (function(json) {
        var s;
        _this.songs = (function() {
          var _i, _len, _ref2, _results;
          _ref2 = json != null ? json.song : void 0;
          _results = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            s = _ref2[_i];
            _results.push(new Song(s));
          }
          return _results;
        })();
        return succ(_this.songs);
      }), err) : void 0;
    };

    return Channel;

  })(JsonObject);

  Song = (function(_super) {
    __extends(Song, _super);

    function Song() {
      _ref1 = Song.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    Song.prototype.like = function() {
      var _ref2;
      return (_ref2 = window.DoubanFM) != null ? _ref2.doLike(this) : void 0;
    };

    Song.prototype.unlike = function() {
      var _ref2;
      return (_ref2 = window.DoubanFM) != null ? _ref2.doUnlike(this) : void 0;
    };

    Song.prototype.boo = function() {
      var _ref2;
      return (_ref2 = window.DoubanFM) != null ? _ref2.doBoo(this) : void 0;
    };

    Song.prototype.skip = function() {
      var _ref2;
      return (_ref2 = window.DoubanFM) != null ? _ref2.doSkip(this) : void 0;
    };

    return Song;

  })(JsonObject);

  User = (function(_super) {
    __extends(User, _super);

    function User() {
      _ref2 = User.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    User.prototype.attachAuth = function(data) {
      if (this.user_id != null) {
        data["user_id"] = this.user_id;
      }
      if (this.token != null) {
        data["token"] = this.token;
      }
      if (this.expire != null) {
        return data["expire"] = this.expire;
      }
    };

    return User;

  })(JsonObject);

  Service = (function() {
    function Service(proxy) {
      this.proxy = proxy;
    }

    Service.prototype.query = function(type, url, data, succ, err) {
      data['url'] = url;
      console.log("" + type + " " + url);
      console.log("Data: ");
      console.log(data);
      return $.jsonp({
        type: type,
        data: data,
        url: this.proxy + "?callback=?",
        xhrFields: {
          withCredentials: false
        },
        success: function(data) {
          return succ(data);
        },
        error: function(j, status, error) {
          return err(status, error);
        }
      });
    };

    Service.prototype.get = function(url, data, succ, err) {
      return this.query("GET", url, data, succ, err);
    };

    Service.prototype.post = function(url, data, succ, err) {
      return this.query("POST", url, data, succ, err);
    };

    return Service;

  })();

  proxy_domain = "https://jsonpwrapper.appspot.com";

  if (window.Service == null) {
    window.Service = new Service(proxy_domain);
  }

  Player = (function() {
    function Player() {
      soundManager.setup({
        url: "SoundManager2/swf/",
        preferFlash: false,
        onready: function() {
          var _ref3;
          return (_ref3 = window.T) != null ? _ref3.echo("Player initialized") : void 0;
        },
        ontimeout: function() {
          var _ref3;
          return (_ref3 = window.T) != null ? _ref3.error("Failed to intialize player. Check your brower's flash setting.") : void 0;
        }
      });
    }

    return Player;

  })();

  DoubanFM = (function() {
    var app_name, channel_url, domain, login_url, song_url, version;

    app_name = "radio_desktop_win";

    version = 100;

    domain = "http://www.douban.com";

    login_url = "/j/app/login";

    channel_url = "/j/app/radio/channels";

    song_url = "/j/app/radio/people";

    DoubanFM.prototype.attachVersion = function(data) {
      data["app_name"] = app_name;
      return data["version"] = version;
    };

    function DoubanFM(service) {
      var _this = this;
      this.service = service;
      if (window.DoubanFM == null) {
        window.DoubanFM = this;
      }
      this.player = new Player();
      $(document).ready(function() {
        window.T.echo("DoubanFM initialized...");
        return _this.resume();
      });
    }

    DoubanFM.prototype.resume = function() {};

    DoubanFM.prototype.remember = function() {};

    DoubanFM.prototype.forget = function() {};

    DoubanFM.prototype.post_login = function(data, remember, succ, err) {
      this.user = new User(data);
      if (this.user.r === 1) {
        err(this.user);
        return;
      }
      if (remember) {
        this.remember;
      }
      return succ(this.user);
    };

    DoubanFM.prototype.login = function(email, password, remember, succ, err) {
      var payload,
        _this = this;
      payload = {
        "email": email,
        "password": password
      };
      this.attachVersion(payload);
      this.service.get(domain + login_url, payload, (function(data) {
        return _this.post_login(data, remember, succ, err);
      }), (function(status, error) {
        var data;
        data = {
          r: 1,
          err: "Internal Error: " + error
        };
        return _this.post_login(data, remember, succ, err);
      }));
    };

    DoubanFM.prototype.logout = function() {
      this.User = new User();
      return this.forget();
    };

    DoubanFM.prototype.update = function(succ, err) {
      var _this = this;
      return this.doGetChannels((function(json) {
        var j;
        _this.channels = (function() {
          var _i, _len, _ref3, _results;
          _ref3 = json != null ? json.channels : void 0;
          _results = [];
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            j = _ref3[_i];
            _results.push(new Channel(j));
          }
          return _results;
        })();
        return succ(_this.channels);
      }), err);
    };

    DoubanFM.prototype.doGetChannels = function(succ, err) {
      return this.service.get(domain + channel_url, {}, succ, err);
    };

    DoubanFM.prototype.doGetSongs = function(channel, succ, err) {
      var payload, _ref3, _ref4;
      payload = {
        "sid": "",
        "channel": (_ref3 = channel.channel_id) != null ? _ref3 : 0,
        "type": "n"
      };
      this.attachVersion(payload);
      if ((_ref4 = this.user) != null) {
        _ref4.attachAuth(payload);
      }
      return this.service.get(domain + song_url, payload, succ, err);
    };

    DoubanFM.prototype.doLike = function(song) {};

    DoubanFM.prototype.doUnlike = function(song) {};

    DoubanFM.prototype.doBoo = function(song) {};

    DoubanFM.prototype.doSkip = function(song) {};

    return DoubanFM;

  })();

  new DoubanFM(window.Service);

}).call(this);

/*
//@ sourceMappingURL=Douban.map
*/
