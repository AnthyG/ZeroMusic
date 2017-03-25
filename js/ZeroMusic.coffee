class ZeroMusic extends ZeroFrame
  selectUser: =>
    @cmd "certSelect", {accepted_domains: ["zeroid.bit"]}
    false

  onOpenWebsocket: =>
    @player = document.getElementById "player"
    @songList = document.getElementById "song_list"
    @cmd "site_info", {}, (site_info) =>
      @siteInfo = site_info
      if @siteInfo.cert_user_id
        document.getElementById("select_user").innerText = @siteInfo.cert_user_id
    @cmd "dbQuery", ["SELECT * FROM songs"], (res) =>
      @addSong file for file in res

  onRequest: (cmd, message) =>
    if cmd == "setSiteInfo"
      @siteInfo = message.params
      if message.params.cert_user_id
        document.getElementById("select_user").innerHTML = @siteInfo.cert_user_id
        @cmd "fileGet", ["data/users/" + @siteInfo.auth_address + "/content.json", false], (data) =>
          data = if data then JSON.parse(data) else {}
          data.optional = ".+mp3"
          data.modified = Date.now() / 1000;
          jsonRaw = unescape(encodeURIComponent(JSON.stringify(data, undefined, 1)));
          @cmd "fileWrite", ["data/users/" + @siteInfo.auth_address + "/content.json", btoa(jsonRaw)], (res) =>
            console.log(res)
      else
        document.getElementById("select_user").innerHTML = "Select user"

  playSong: (file) =>
    @player.innerHTML = '<source src="' + file + '" />'
    @player.load();
    @player.play();

  addSong: (song) =>
    @songList.innerHTML += '<li onclick="page.playSong(\'' + song.path + '\')"><strong>' + song.artist + '</strong> - ' + song.title + '</li>'

  getMetadata: (filename) =>
    filename = filename.replace(/(_|\.mp3$)/g, ' ').trim()
    metadata = {}
    if filename.match /^\d+/
      metadata.track = parseInt filename
      filename = filename.split(/^\d+\s*([-.]\s*)?/)[2]
    else
      metadata.track = "unknown"
    if filename.match /-/
      metadata.artist = filename.split('-')[0].trim()
      metadata.title = filename.split('-').slice(1).join('-').trim()
    else
      metadata.artist = "unknown"
      metadata.title = filename.trim()
    return metadata

  uploadSong: (e) =>
    if not @siteInfo.cert_user_id
      return @selectUser()

    name = e.files[0].name
    if !name.match /\.mp3$/
      return @cmd "wrapperNotification", ["error", "Only mp3 files are allowed for now.", 5000]
    @cmd "dbQuery", ["SELECT MAX(id) + 1 as next_id FROM songs"], (res) =>
      path = "data/users/" + @siteInfo.auth_address + '/' + res[0].next_id + '.mp3'
      reader = new FileReader()
      reader.onload = (e) =>
        @cmd "fileWrite", [path, btoa reader.result], (res) =>
          if res == "ok"
            @cmd "fileGet", ["data/users/" + @siteInfo.auth_address + "/data.json", false], (data) =>
              data = if data then JSON.parse(data) else {songs:[]}
              metadata = @getMetadata name
              metadata.path = path
              metadata.id = res[0].next_id
              data.songs.push metadata
              json_raw = unescape encodeURIComponent JSON.stringify data, undefined, 1
              @cmd "fileWrite", ["data/users/" + @siteInfo.auth_address + "/data.json", btoa(json_raw)], (res) =>
                @cmd "sitePublish", {inner_path: "data/users/" + @siteInfo.auth_address + "/content.json", sign: true}, (res) =>
                  console.log res
                  @addSong metadata
                  @playSong path
          else
            console.error res
      reader.readAsBinaryString(e.files[0]);

window.page = new ZeroMusic
