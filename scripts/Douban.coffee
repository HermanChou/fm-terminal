class JsonObject
        constructor: (@json) ->
                for key, value of json
                        @[key] = value
                

class Channel extends JsonObject
        appendSongs: (newSongs) ->
                if not newSongs?
                        return
                @songs ?= []
                # TODO: check max size and release
                @songs = @songs.concat(newSongs)
                return
                
        update: (succ, err, action, sid, history) ->
                window.DoubanFM?.doGetSongs(
                        @,
                        action, sid, history,
                        ((json) =>
                                # TODO: append song list instead of replacing
                                @appendSongs(new Song(s) for s in json?.song)
                                succ?(@songs)
                        )
                                ,
                        err
                )

        
class Song extends JsonObject
        # not so logic, it get liked/unliked/booed/skipped
        like: () ->
                window.DoubanFM?.doLike(@)

        unlike: () ->
                window.DoubanFM?.doUnlike(@)
                
        boo: () ->
                window.DoubanFM?.doBoo(@)
                
        skip: () ->
                window.DoubanFM?.doSkip(@)

class User extends JsonObject
        attachAuth: (data) ->
                data["user_id"] = @user_id if @user_id?
                data["token"] = @token if @token?
                data["expire"] = @expire if @expire?


class Player
        constructor: () ->
                @sounds = {}
                # Actions
                @action = {}
                @action.END = "e"
                @action.NONE = "n"
                @action.BOO = "b"
                @action.LIKE = "r"
                @action.UNLIKE = "u"
                @action.SKIP = "s"
                
                @maxHistoryCount = 15
                
                @currentSongIndex = -1

                @looping = false
                                
                soundManager.setup({
                        url: "SoundManager2/swf/",
                        preferFlash: false,

                        onready: () ->
                                window.T?.echo("Player initialized");
                        ontimeout: () ->
                                window.T?.error("Failed to intialize player. Check your brower's flash setting.")
                });

        currentSoundInfo: () ->
                sound = {}
                sound.song = @currentSong
                
                sound.paused = @currentSound.paused
                sound.isBuffering = @currentSound.isBuffering
                
                sound.position = @currentSound.position
                sound.duration = @currentSound.duration
                sound.bytesLoaded = @currentSound.bytesLoaded
                sound.bytesTotal = @currentSound.bytesTotal

                sound.looping = @looping
                return sound
                
        play: (channel) ->
                # if playing then stop
                @stop()
                @startPlay(channel)

        stop: () ->
                @currentSound?.unload()
                @currentSound?.stop()

        pause: () ->
                @currentSound?.pause()
                window.T.update_ui(@currentSoundInfo())


        resume: () ->
                @currentSound?.resume()        

        loops: () ->
                console.log("Should loop")
                @looping = not @looping
                        

        startPlay: (channel) ->
                @currentChannel = channel

                # initialize
                @currentSongIndex = -1
                @currentSong = null
                @history = []

                @nextSong(@action.NONE)
        
        getHistory: () ->
                str = "|"
                H = $(@history).map (i, h) ->
                        h.join(":")
                str += H.get().join("|")
                return str
                
        nextSong: (action) ->
                @stop()

                sid = ""
                if @currentSong
                        sid = @currentSong.sid
                        h = [sid, action]
                        # slice to make sure the size 
                        if @history.length > @maxHistoryCount
                                @history = @history[1..]
                        @history.push(h)
                        console.log @getHistory()
                        
                # TODO: record history
                # if not in cache, update
                if (@currentSongIndex + 1 >= @currentChannel.songs.length)
                        # TODO: prompt user that we are updating
                        @currentChannel.update(
                                (songs) => @nextSong(action),
                                () -> #TODO:,
                                action,
                                sid,
                                @getHistory())
                        return # block operation here
                # handle action of previous song
                # action could be booo, finish, skip, null
                if (@currentSongIndex > -1)
                        @currentChannel.update(null, null, action, sid, @getHistory())
                # get next song
                @currentSongIndex++

                # do simple indexing, since when channel is updated, song list is appended
                @doPlay(@currentChannel.songs[@currentSongIndex])
                
        doPlay: (song) ->
                id = song.sid
                url = song.url
                
                @currentSong = song
                @currentSound = @sounds[id]
                window.T.init_ui(song)

                if @onPlayCallback?
                        @onPlayCallback(song)
                @currentSound ?= soundManager.createSound({
                        url: url,
                        autoLoad: true,
                        whileloading: () => window.T.update_ui(@currentSoundInfo()),
                        whileplaying: () => window.T.update_ui(@currentSoundInfo()),
                        onload: () -> @.play()
                        onfinish: () =>
                                if @looping
                                        @doPlay(@currentSong)
                                else
                                        @nextSong(@action.END)
                        # TODO: invoke nextSong when complete
                })
                


        
class DoubanFM
        app_name = "radio_desktop_win"
        version = 100
        domain = "http://www.douban.com"
        login_url = "/j/app/login"
        channel_url = "/j/app/radio/channels"
        song_url = "/j/app/radio/people"

        attachVersion: (data) ->
                data["app_name"] = app_name
                data["version"] = version
        
        constructor: (@service) ->
                window.DoubanFM ?= @
                @player = new Player()
                $(document).ready =>
                        window.T.echo("DoubanFM initialized...")
                        @resume_session()
                
        resume_session: () ->
                # Initialize cookie setting
                $.cookie.json = true
                # read cookie to @user
                cookie_user_json = $.cookie('user')
                @user = if cookie_user_json? then new User(cookie_user_json) else new User()
                # update terminal
                window.TERM.setUser(@user)


        remember: (always) ->
                # calculate expire day
                # see https://github.com/akfish/fm-terminal/edit/develop/douban-fm-api.md#notes-on-expire-field
                now = new Date()
                expire_day = (@user.expire - now.getTime() / 1000) / 3600 / 24
                console.log("Expire in #{expire_day} days")
                
                # session cookie or persistent cookie
                expire = { expires: expire_day }

                # write cookie from @user
                value = @user?.json
                if always
                        $.cookie('user', value, expire)
                else
                        $.cookie('user', value)
                
        forget: () ->
                #TODO: clear cookie
                $.removeCookie('user')

        clean_user_data: () ->
                # TODO: clean user specific data
                # like channels

        post_login: (data, remember, succ, err) ->
                @user = new User(data)
                if (@user.r == 1)
                        err?(@user)
                        return
                @remember(remember)
                @clean_user_data()
                succ?(@user)
                
        login: (email, password, remember, succ, err) ->
                payload =
                {
                        "email": email,
                        "password": password,
                }
                @attachVersion(payload)
                @service.post(
                        domain + login_url,
                        payload,
                        ((data) =>
                                @post_login(data, remember, succ, err)
                        ),
                        ((status, error) =>
                                data = { r: 1, err: "Internal Error: #{error}" }
                                @post_login(data, remember, succ, err)
                        ))
                return
                
        logout: () ->
                @user = new User()
                @forget()
                @clean_user_data()
                
        #######################################
        # Play Channel
        play: (channel) ->
                @currentChannel = channel
                @player?.play(channel)
        next: () ->
                @player?.nextSong(@player.action.SKIP)

        pause: () ->
                @player?.pause()

        resume: () ->
                @player?.resume()

        loops: () ->
                @player?.loops()

        stop: () ->
                @player?.stop()


        #######################################
        #
        update: (succ, err) ->
                @doGetChannels(
                        ((json) =>
                                @channels = (new Channel(j) for j in json?.channels)
                                succ(@channels)
                        )
                                ,
                        err
                )
                

        #######################################
        doGetChannels: (succ, err)->
                @service.get(
                        domain + channel_url,
                        {},
                        succ,
                        err)        
                
        doGetSongs: (channel, action, sid, history, succ, err)->
                payload = {
                        "sid": sid,
                        "channel": channel.channel_id ? 0,
                        "type": action ? "n",
                        "h": history ? ""
                }
                @attachVersion(payload)
                @user?.attachAuth(payload)

                @service.get(
                        domain + song_url,
                        payload,
                        succ,
                        err
                )

        #######################################
        doLike: (song) ->
                #TODO:

        doUnlike: (song) ->
                #TODO:
                
        doBoo: (song) ->
                #TODO:

        doSkip: (song) ->
                #TODO:

new DoubanFM(window.Service)
