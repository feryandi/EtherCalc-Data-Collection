@include = ->
  @use \json, @app.router, @express.static __dirname
  @app.use \/edit @express.static __dirname
  @app.use \/view @express.static __dirname
  @app.use \/app @express.static __dirname

  ## Helpers
  Table = require('./static/table')
  FrameFinder = require('./static/framefinder')

  @include \dotcloud
  @include \player-broadcast
  @include \player-graph
  @include \player-database
  @include \player

  clusterfck = require \clusterfck
  fs = require \fs

  J = require \j
  csv-parse = require \csv-parse

  DB = @include \db
  SC = @include \sc

  ## added by feryandi ##
  MYSQL = @include \mysql

  KEY = @KEY
  BASEPATH = @BASEPATH
  EXPIRE = @EXPIRE

  HMAC_CACHE = {}
  hmac = if !KEY then -> it else -> HMAC_CACHE[it] ||= do
    encoder = require \crypto .createHmac \sha256 (new Buffer KEY)
    encoder.update it.toString!
    encoder.digest \hex

  [   Text,    Html,   Csv,   Json       ] = <[
    text/plain text/html text/csv application/json
  ]>.map (+ "; charset=utf-8")

  require! <[ fs ]>
  const RealBin = require \path .dirname do
    fs.realpathSync __filename
  const DevMode = fs.existsSync "#RealBin/.git"
  #Time Triggered Email - contains next send time 
  dataDir = process.env.OPENSHIFT_DATA_DIR   
  #dataDir = ".."  
  
  sendFile = (file) -> ->
    @response.type Html
    @response.sendfile "#RealBin/#file"

  if @CORS
    console.log "Cross-Origin Resource Sharing (CORS) enabled."
    @all \* (req, res, next) ->
      @response.header \Access-Control-Allow-Origin  \*
      @response.header \Access-Control-Allow-Headers 'X-Requested-With,Content-Type,If-Modified-Since'
      @response.header \Access-Control-Allow-Methods 'GET,POST,PUT'
      return res.send(204) if req?method is \OPTIONS
      next!

  new-room = -> require \uuid-pure .newId 12 36 .toLowerCase!

  @get '/': sendFile \index.html
  #@get '/favicon.ico': -> @response.send 404 ''
  #return site icons
  @get '/favicon.ico': sendFile \favicon.ico
  @get '/android-chrome-192x192.png': sendFile \android-chrome-192x192.png
  @get '/apple-touch-icon.png': sendFile \apple-touch-icon.png
  @get '/browserconfig.xml': sendFile \browserconfig.xml
  @get '/favicon-16x16.png': sendFile \favicon-16x16.png
  @get '/favicon-32x32.png': sendFile \favicon-32x32.png
  @get '/favicon-32x32.png': sendFile \favicon-32x32.png
  @get '/mstile-150x150.png': sendFile \mstile-150x150.png
  @get '/mstile-310x310.png': sendFile \mstile-310x310.png
  @get '/safari-pinned-tab.svg': sendFile \safari-pinned-tab.svg
  @get '/manifest.appcache': ->
    @response.type \text/cache-manifest
    if DevMode
      @response.send 200 "CACHE MANIFEST\n\n##{Date!}\n\nNETWORK:\n*\n"
    else
      @response.sendfile "#RealBin/manifest.appcache"
  @get '/static/socialcalc.js': ->
    @response.type \application/javascript
    @response.sendfile "#RealBin/node_modules/socialcalc/SocialCalc.js"
  @get '/static/form:part.js': ->
    part = @params.part
    @response.type \application/javascript
    @response.sendfile "#RealBin/form#part.js"
  @get '/=_new': ->
    room = new-room!
    @response.redirect if KEY then "#BASEPATH/=#room/edit" else "#BASEPATH/=#room"
  @get '/_new': ->
    room = new-room!
    @response.redirect if KEY then "#BASEPATH/#room/edit" else "#BASEPATH/#room"
  @get '/_start': sendFile \start.html

  IO = @io
  api = (cb, cb-multiple) -> ->
    room = encodeURIComponent(@params.room).replace(/%3A/g \:)
    if room is /^%3D/ and cb-multiple
      room.=slice 3
      {snapshot} <~ SC._get room, IO
      unless snapshot
        _, default-snapshot <~ DB.get "snapshot-#room.1"
        unless default-snapshot
          @response.type Text
          @response.send 404 ''
          return
        [type, content] = cb-multiple.call @params, <[ Sheet1 ]>, [ default-snapshot ]
        @response.type type
        @response.set \Content-Disposition """
          attachment; filename="#room.xlsx"
        """
        @response.send 200 content
        return
      csv <~ SC[room].exportCSV
      _, body <~ csv-parse(csv, delimiter: \,)
      body.shift! # header
      todo = DB.multi!
      names = []
      for [link, title], idx in body | link and title and link is /^\//
        names ++= title
        todo.=get "snapshot-#{ link.slice(1) }"
      _, saves <~ todo.exec!
      [type, content] = cb-multiple.call @params, names, saves
      @response.type type
      @response.set \Content-Disposition """
        attachment; filename="#room.xlsx"
      """
      @response.send 200 content
    else
      {snapshot} <~ SC._get room, IO
      if snapshot
        [type, content] = cb.call @params, snapshot
        if type is Csv
          @response.set \Content-Disposition """
            attachment; filename="#{ @params.room }.csv"
          """
        if content instanceof Function
          rv <~ content SC[room]
          @response.type type
          @response.send 200 rv
        else
          @response.type type
          @response.send 200 content
      else
        @response.type Text
        @response.send 404 ''

  ExportCSV-JSON = api -> [Json, (sc, cb) ->
    csv <- sc.exportCSV
    _, body <- csv-parse(csv, delimiter: \,)
    cb body
  ]
  ExportCSV = api -> [Csv, (sc, cb) -> sc.exportCSV cb ]
  ExportHTML = api -> [Html, (sc, cb) -> sc.exportHTML cb ]

  J-TypeMap =
    md: \text/x-markdown
    xlsx: \application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ods: \application/vnd.oasis.opendocument.spreadsheet
  Export-J = (type) -> api (-> # single
    rv = J.utils["to_#type"](J.read it)
    rv = rv.Sheet1 if rv?Sheet1?
    [J-TypeMap[type], rv]
  ), ((names, saves) -> # multi
    input = [ null, { SheetNames: names, Sheets: {} } ]
    for save, idx in saves
      [harb, { Sheets: { Sheet1 } }] = J.read save
      input.0 ||= harb
      input.1.Sheets[names[idx]] = Sheet1
    rv = J.utils["to_#type"](input)
    [J-TypeMap[type], rv]
  )
      
  # Send time triggered email. Send due emails and schedule time of next send. Called from bash file:timetrigger in cron
  @get '/_timetrigger': -> 
      (, allTimeTriggers) <~ DB.hgetall "cron-list"
      console.log "allTimeTriggers "  {...allTimeTriggers}
      timeNowMins = Math.floor(new Date().getTime() / (1000 * 60))
      nextTriggerTime = 2147483647   # set to max seconds possible (31^2)      
      for cellID, timeList of allTimeTriggers
        timeList = for triggerTimeMins in timeList.split(',')
          if triggerTimeMins <= timeNowMins
            [room, cell] = cellID.split('!')        
            console.log "cellID #cellID triggerTimeMins #triggerTimeMins" 
            do
              {snapshot} <~ SC._get room, IO
              SC[room].triggerActionCell cell, ->                
            continue
          else
            if nextTriggerTime > triggerTimeMins 
              nextTriggerTime = triggerTimeMins
            triggerTimeMins
        console.log "timeList #timeList"
        if timeList.length == 0 
          DB.hdel "cron-list", cellID
        else
          DB.hset "cron-list", cellID, timeList.toString()      
      <~ DB.multi!
        .set "cron-nextTriggerTime" nextTriggerTime
        .bgsave!exec!
      fs.writeFileSync do
        "#dataDir/nextTriggerTime.txt"
        nextTriggerTime
        \utf8                       
      console.log "--- cron email sent ---"
      @response.type Json
      @response.send 200 allTimeTriggers

  ExportExcelXML = api ->

  @post '/_database/connect': ->
    this$ = this
    mysqlSetting =
      * host: @body.host,
        port: @body.port,
        user: @body.user,
        password: @body.password,
        database: @body.database

    console.log(mysqlSetting)

    MYSQL.createConnection mysqlSetting, (ret) ->
      data =
        * status: ret
      this$.response.type \application/json
      this$.response.json 200 data    

  @post '/_database/clean': ->
    this$ = this
    mysqlSetting = @body.setting
    db = @body.db
    id = @body.id

    dbProcessed = 0

    db.forEach (item, index, array) ->
      MYSQL.deleteData item, "_spreadsheet_id", id, mysqlSetting, (err, res) ->
        dbProcessed += 1
        if dbProcessed == array.length
          data =
            * code: 0
              status: "Clean up finished"
          this$.response.type \application/json
          this$.response.json 200 data

  @post '/_database/create': ->
    this$ = this
    mysqlSetting = @body.setting

    tablec = new Table null, null
    table = tablec.TupleDeserialize @body.table

    this$.message = "OK"
    this$.is_need_col_check = true

    this$.is_there_other = false
    this$.is_column_same = true

    # If there exists such table, delete HAHAHA
    MYSQL.isExistTable table.name, mysqlSetting, (err, results) ->
      if results.length > 0
        console.log("Exist. Emptying Table.")
        ## TO-DO KALO TABELNYA DIDN'T EXISTS ANYMORE GIMANA?, HARUS BISA NGEHAPUS DONG AAAA

        ### Bukan DROP-ing table lagi sekarang,
        #MYSQL.dropTable table.name, mysqlSetting, (err, res) ->
        #  console.log(res)
        ## Kalo kolom ga sama denied intinya mah, tipe validasi????

        ## Cek apakah ada data dari spreadsheet lain?
        MYSQL.selectNEData table.name, "_spreadsheet_id", table.spreadsheet_id, mysqlSetting, (err, res) ->
          if res.length > 0
            this$.is_there_other = true
          MYSQL.getColumns table.name, mysqlSetting, (err, res) ->
            # Cek Kecocokan Kolom
            checked = true
            i = 0
            if this$.is_need_col_check
              console.log("xoxo Checking Column Eq oxox")
              console.log(res)
              for header in table.headers
                ## Check by nama
                if i >= res.length
                  checked = false                  
                else
                  if (header.name.trim! != res[i]["Field"].trim!)
                    checked = false
                  ## Check by type
                  if header.type == "VARCHAR"
                    if (res[i]["Type"].toLowerCase() != (header.type + "(160)").toLowerCase())
                      checked = false
                  else if header.type == "INT"
                    if (res[i]["Type"].toLowerCase() != (header.type + "(11)").toLowerCase())
                      checked = false
                  else
                    if (res[i]["Type"].toLowerCase() != (header.type).toLowerCase())
                      checked = false
                i += 1
            this$.is_column_same = checked

            ## Kalo kolom sama
            if this$.is_column_same
              #### OK, DELETE ID YANG SAMA
              #### Insert
              ## Delete isi semua tabel WHERE id_spreadsheet, isi ulang
              MYSQL.deleteData table.name, "_spreadsheet_id", table.spreadsheet_id, mysqlSetting, (err, res) ->
                MYSQL.insertData table.name, table.headers, table.data, mysqlSetting, (err, res) ->
                  console.log(res)
                  data =
                    * code: 0
                      status: this$.message
                  this$.response.type \application/json
                  this$.response.json 200 data

            else if not this$.is_column_same and not this$.is_there_other
              ## Kalo kolom beda dan ga ada yang lain
              #### DROP
              #### CREATE BARU ....
              MYSQL.dropTable table.name, mysqlSetting, (err, res) ->
                MYSQL.createTable table.name, table.headers, mysqlSetting, (err, res) ->
                  MYSQL.insertData table.name, table.headers, table.data, mysqlSetting, (err, res) ->
                    console.log(res)
                    data =
                      * code: 0
                        status: this$.message
                    this$.response.type \application/json
                    this$.response.json 200 data            

            else
              ## Kalo kolom beda dan ada yang lain
              #### ERROR
              this$.message = "Error validating column equality, table contains data from other spreadsheet"
              data =
                * code: 1
                  status: this$.message
                  table: table.name
              this$.response.type \application/json
              this$.response.json 200 data
      else
        # Create the Table first, if no table before
        MYSQL.createTable table.name, table.headers, mysqlSetting, (err, res) ->
          MYSQL.insertData table.name, table.headers, table.data, mysqlSetting, (err, res) ->
            console.log(res)
            data =
              * code: 0
                status: this$.message
            this$.response.type \application/json
            this$.response.json 200 data 

  @post '/_database/state/:room': ->
    this$ = this
    mysqlSetting = @body.setting

    code_id = @params.room
    name = "s_database_state"
    MYSQL.isExistTable name, mysqlSetting, (err, results) ->
      if results.length > 0
        MYSQL.selectData name, "code_id", code_id, mysqlSetting, (err, results) ->
          console.log(results)
          this$.response.type \application/json
          this$.response.json 200 results
      else
        result =
          * code_id: code_id
            table_json: ""
        results = []
        results.push(result)
        this$.response.type \application/json
        this$.response.json 200 results

  @post '/_database/state': ->
    mysqlSetting = @body.setting
    code_id = @body.id
    table_json = @body.tables
    last_db_json = @body.last_db

    name = "s_database_state"
    MYSQL.isExistTable name, mysqlSetting, (err, results) ->
      console.log(results)
      columns = []

      columnA = []
      columnA["name"] = "code_id"
      columnA["type"] = "VARCHAR"
      columns.push(columnA)
      
      columnB = []
      columnB["name"] = "table_json"
      columnB["type"] = "TEXT"
      columns.push(columnB)

      columnC = []
      columnC["name"] = "last_db_json"
      columnC["type"] = "TEXT"
      columns.push(columnC)

      if results.length <= 0
        # Create the Table first
        MYSQL.createTable name, columns, mysqlSetting, (err, res) ->
          console.log(res)

      data = [code_id, table_json, last_db_json]

      MYSQL.selectData name, columnA["name"], code_id, mysqlSetting, (err, results) ->
        if results != void
          if results.length > 0
            MYSQL.updateData name, columns, data, columnA["name"], code_id, mysqlSetting, (err, res) ->
              console.log(res)
          else
            ndata = [data]
            MYSQL.insertData name, columns, ndata, mysqlSetting, (err, res) ->
              console.log(res)
        else
          ndata = [data]
          MYSQL.insertData name, columns, ndata, mysqlSetting, (err, res) ->
            console.log(res)

    data =
      * status: "OK"
    @response.type \application/json
    @response.json 200 data

  @get '/_/:room/test': ->
    room = @params.room
    {snapshot} <~ SC._get room, IO
    if snapshot
      rv <~ SC[room].exportControlObject
      
  @get '/_hierachical/:room/:ths': -> 
    this$ = this
    room = @params.room
    thres = @params.ths

    ## Getting the Spreadsheet data, now calculation ALL IN BACKEND
    {snapshot} <~ SC._get room, IO
    if snapshot
      sheet <~ SC[room].exportControlObject

      loadsheet = new FrameFinder.LoadSheet sheet
      sheetdict = loadsheet.LoadSheetDict!

      firstkey = Object.keys(sheetdict)[0]
      cellData = sheetdict[firstkey].GetCellsArray!

      cellDistance = (v1, v2) ->
        t = new Table null, null
        colD = t.GetCellCol(v1[0]) - t.GetCellCol(v2[0])
        rowD = t.GetCellRow(v1[0]) - t.GetCellRow(v2[0])

        # If the cell is neighboring but not diagonally neighbor
        if colD == 0
          if rowD == 1 or rowD == -1
            return 0
        if rowD == 0
          if colD == 1 or colD == -1
            return 0

        # Else, calculate neighboring cell
        leftTop = [[v1[1], v1[2]], [v2[1], v2[2]]]
        leftBot = [[v1[1], (v1[2] + v1[4])], [v2[1], (v2[2] + v2[4])]]
        righTop = [[(v1[1] + v1[3]), v1[2]], [(v2[1] + v2[3]), v2[2]]]
        righBot = [[(v1[1] + v1[3]), (v1[2] + v1[4])], [(v2[1] + v2[3]), (v2[2] + v2[4])]]

        if (leftTop[0][0] == righTop[1][0] and leftTop[0][1] == righTop[1][1])
          return 0
        if (leftBot[0][0] == righBot[1][0] and leftBot[0][1] == righBot[1][1])
          return 0

        if (leftTop[1][0] == righTop[0][0] and leftTop[1][1] == righTop[0][1])
          return 0
        if (leftBot[1][0] == righBot[0][0] and leftBot[1][1] == righBot[0][1])
          return 0

        if (leftTop[0][0] == leftBot[1][0] and leftTop[0][1] == leftBot[1][1])
          return 0
        if (righTop[0][0] == righBot[1][0] and righTop[0][1] == righBot[1][1])
          return 0

        if (leftTop[1][0] == leftBot[0][0] and leftTop[1][1] == leftBot[0][1])
          return 0
        if (righTop[1][0] == righBot[0][0] and righTop[1][1] == righBot[0][1])
          return 0

        # Else, calculate the distance
        dist = Math.sqrt(Math.pow((v2[1] + (v2[3]/2)) - (v1[1] + (v1[3]/2)), 2) + Math.pow((v2[2] + (v2[4]/2)) - (v1[2] + (v1[4]/2)), 2));
        return dist

      clusters = clusterfck.hcluster(cellData, cellDistance, "single", thres)

      leaves = (hCluster) ->
        if !hCluster.left
          return [hCluster]
        else
          return leaves(hCluster.left).concat(leaves(hCluster.right))

      flatcluster = clusters.map((hcluster) -> leaves(hcluster).map((leaf) -> return leaf.value))

      tablec = new Table null, null
      rangecluster = []
      for cluster in flatcluster
        cl = {}
        cl.sc = 9999 #HAHA
        cl.ec = 0
        cl.sr = 9999 #hahahaha
        cl.er = 0
        for cell in cluster
          col = tablec.GetCellCol(cell[0])
          row = tablec.GetCellRow(cell[0])
          if cl.sc >= col
            cl.sc = col
          if cl.ec <= col
            cl.ec = col
          if cl.sr >= row
            cl.sr = row
          if cl.er <= row
            cl.er = row
        rangecluster.push(cl)

      this$.response.type \text
      this$.response.json 200 rangecluster

  @get '/_framefinder/:room/:sc/:ec/:sr/:er': ->
    this$ = this
    room = @params.room

    sc = @params.sc
    ec = @params.ec
    sr = @params.sr
    er = @params.er

    thres = 20 ### FOR NOW THIS WORKS

    ## Getting the Spreadsheet data, now calculation ALL IN BACKEND
    {snapshot} <~ SC._get room, IO
    if snapshot
      sheet <~ SC[room].exportControlObject

      loadsheet = new FrameFinder.LoadSheet sheet
      sheetdict = loadsheet.LoadSheetDict!

      pr = new FrameFinder.PredictSheetRows
      features = pr.GenerateFromSheetFile sheetdict, sc, ec, sr, er

      content = features

      basePath = '/home/ethercalc/public/'
      filePath = basePath + room + sc + ec + sr + er
      featurePath = basePath + room + sc + ec + sr + er + '_feature'

      feature = (filePath, content, cb) ->
        fs.writeFile filePath, content, (err) ->
          if err 
            return console.log(err);
          cb!

      crf = (filePath, featurePath, cb) ->
        CPE = (require \child_process).exec
        cmd = 'crf_test -m /home/ethercalc/ethercalc/crf/example/model ' + featurePath + ' > ' + filePath
        CPE cmd, (error, stdout, stderr) ->
          fs.readFile filePath, 'utf8', (err,data) ->
            if err 
              return console.log(err);
            result = []
            lines = data.split "\n"
            console.log(lines)
            for line in lines
              obj = {}
              elemt = line.split "\t"
              if elemt[0] != ''
                obj.row = elemt[0]
                obj.type = elemt[elemt.length - 1]
                result.push obj
            cb result

      feature featurePath, content, ->
        crf filePath, featurePath, (data) ->
          console.log(data)
          this$.response.type \application/json
          this$.response.json 200 data

  @get '/:room.csv': ExportCSV
  @get '/:room.csv.json': ExportCSV-JSON
  @get '/:room.html': ExportHTML
  #@get '/:room.ods': Export-J \ods
  @get '/:room.xlsx': Export-J \xlsx
  @get '/:room.md': Export-J \md
  if @CORS
     @get '/_rooms' : ->
        @response.type Text
        return @response.send 403 '_rooms not available with CORS'
  else
     @get '/_rooms' : ->
        rooms <~ SC._rooms 
        @response.type \application/json
        @response.json 200 rooms
  if @CORS
     @get '/_roomlinks' : ->
        @response.type Text
        return @response.send 403 '_roomlinks not available with CORS'
  else
     @get '/_roomlinks' : ->
        rooms <~ SC._rooms 
        roomlinks = for room in rooms
          "<a href=#BASEPATH/#room>#room</a>"
        @response.type Html
        @response.json 200 roomlinks

  @get '/_from/:template': ->
    room = new-room!
    template = @params.template
    delete SC[room]
    {snapshot} <~ SC._get template, IO
    <~ SC._put room, snapshot
    @response.redirect if KEY then "#BASEPATH/#room/edit" else "#BASEPATH/#room"
  @get '/_exists/:room' : ->
    exists <~ SC._exists @params.room
    @response.type \application/json
    @response.json (exists === 1)

  @get '/:room': ->
    ui-file = if @params.room is /^=/ then \multi/index.html else \index.html
    if KEY then
      if @query.auth?length
        sendFile(ui-file).call @
      else @response.redirect "#BASEPATH/#{ @params.room }?auth=0"
    else sendFile(ui-file).call @
    
  # Form/App - auto duplicate sheet for new user to input data 
  @get '/:template/form': ->
    template = @params.template
    room = template + \_ + new-room!
    delete SC[room]
    {snapshot} <~ SC._get template, IO
    <~ SC._put room, snapshot
    @response.redirect "#BASEPATH/#room/app" 
  @get '/:template/appeditor': sendFile \panels.html    

  @get '/:room/edit': ->
    room = @params.room
    @response.redirect "#BASEPATH/#room?auth=#{ hmac room }"
  @get '/:room/view': ->
    room = @params.room
    #@response.redirect "#BASEPATH/#room?auth=0"
    @response.redirect "#BASEPATH/#room?auth=#{ hmac room }&view=1"
  @get '/:room/app': ->
    room = @params.room
    @response.redirect "#BASEPATH/#room?auth=#{ hmac room }&app=1"
  @get '/_/:room/cells/:cell': api -> [Json
    (sc, cb) ~> sc.exportCell @cell, cb
  ]
  @get '/_/:room/cells': api -> [Json
    (sc, cb) -> sc.exportCells cb
  ]
  @get '/_/:room/html': ExportHTML
  @get '/_/:room/csv': ExportCSV
  @get '/_/:room/csv.json': ExportCSV-JSON
  #@get '/_/:room/ods': Export-J \ods
  @get '/_/:room/xlsx': Export-J \xlsx
  @get '/_/:room/md': Export-J \md
  @get '/_/:room': api -> [Text, it]

  request-to-command = (request, cb) ->
    console.log "request-to-command"
    if request.is \application/json
      command = request.body?command
      return cb command if command
    cs = []; request.on \data (chunk) ~> cs ++= chunk
    <~ request.on \end
    buf = Buffer.concat cs
    return cb buf.toString(\utf8) if request.is \text/x-socialcalc
    return cb buf.toString(\utf8) if request.is \text/plain
    # TODO: Move to thread
    for k, save of (J.utils.to_socialcalc(J.read buf) || {'': ''})
      save.=replace /[\d\D]*?\ncell:/ 'cell:'
      save.=replace /\s--SocialCalcSpreadsheetControlSave--[\d\D]*/ '\n'
      save.=replace /\\/g "\\b" if ~save.index-of "\\"
      save.=replace /:/g  "\\c" if ~save.index-of ":"
      save.=replace /\n/g "\\n" if ~save.index-of "\n"
      return cb "loadclipboard #save"

  request-to-save = (request, cb) ->
    console.log "request-to-save"
    if request.is \application/json
      snapshot = request.body?snapshot
      return cb snapshot if snapshot
    cs = []; request.on \data (chunk) ~> cs ++= chunk
    <~ request.on \end
    buf = Buffer.concat cs
    return cb buf.toString(\utf8) if request.is \text/x-socialcalc
    if request.is \text/x-ethercalc-csv-double-encoded
      iconv = require \iconv-lite
      buf = iconv.decode buf, \utf8
      buf = iconv.encode buf, \latin1
      buf = iconv.decode buf, \utf8
    # TODO: Move to thread
    for k, save of (J.utils.to_socialcalc(J.read buf) || {'': ''})
      return cb save

  for route in <[ /=:room.xlsx /_/=:room/xlsx ]> => @put "#route": ->
    room = encodeURIComponent(@params.room).replace(/%3A/g \:)
    cs = []; @request.on \data (chunk) ~> cs ++= chunk
    <~ @request.on \end
    buf = Buffer.concat cs
    idx = 0
    toc = '#url,#title\n'
    parsed = J.utils.to_socialcalc J.read buf
    sheets-to-idx = {}
    res = []
    for k of parsed
      idx++
      sheets-to-idx[k] = idx
      toc += "\"/#{ @params.room.replace(/"/g, '""') }.#idx\","
      toc += "\"#{ k.replace(/"/g, '""') }\"\n"
      res.push k.replace(/'/g, "''").replace(/(\W)/g, '\\$1')
    { Sheet1 } = J.utils.to_socialcalc J.read toc
    todo = DB.multi!set("snapshot-#room", Sheet1)
    for k, save of parsed
      idx = sheets-to-idx[k]
      save.=replace //('?)\b(#{ res.join('|') })\1!//g, (,, ref) ~>
        "'#{ @params.room.replace(/'/g, "''") }.#{
          sheets-to-idx[ref.replace(/''/g, "'")] }'!"
      todo.=set("snapshot-#room.#idx", save)
    todo.bgsave!.exec!
    @response.send 201 \OK

  @put '/_/:room': ->
    console.log "put /_/:room"
    @response.type Text
    {room} = @params
    snapshot <~ request-to-save @request
    SC[room]?terminate!
    delete SC[room]
    <~ SC._put room, snapshot
    <~ DB.del "log-#room"
    IO.sockets.in "log-#room" .emit \data { snapshot, type: \snapshot }
    @response.send 201 \OK

  @post '/_/:room': ->
    console.log "post /_/:room"
    {room} = @params
    command <~ request-to-command @request
    unless command
      @response.type Text
      return @response.send 400 'Please send command'
    {log, snapshot} <~ SC._get room, IO
    if not (@request.is \application/json) and command is /^loadclipboard\s*/
      row = 1
      if snapshot is /\nsheet:c:\d+:r:(\d+):/
        row += Number(RegExp.$1)
      if parseInt(@query.row)
        row = parseInt(@query.row)
        command := [command, "insertrow A#row", "paste A#row all"]
      else
        command := [command, "paste A#row all"]
    if command is /^set\s+(A\d+):B\d+\s+empty\s+multi-cascade/
      _, [snapshot] <~ DB.multi!get("snapshot-#room").exec
      if snapshot
        sheetId = RegExp.$1
        matches = snapshot.match(new RegExp("cell:#sheetId:t:\/(.+)\n", "i"));
        if matches
            removeKey = matches[1]
            backupKey = "#{matches[1]}.bak"
            _ <~ DB.multi!
              .del("snapshot-#backupKey").rename("snapshot-#removeKey", "snapshot-#backupKey")
              .del("log-#backupKey").rename("log-#removeKey", "log-#backupKey")
              .del("audit-#backupKey").rename("audit-#removeKey", "audit-#backupKey")
              .bgsave!.exec
    command := [command] unless Array.isArray command
    cmdstr = command * \\n
    <~ DB.multi!
      .rpush "log-#room" cmdstr
      .rpush "audit-#room" cmdstr
      .bgsave!.exec!
    SC[room]?ExecuteCommand cmdstr
    IO.sockets.in "log-#room" .emit \data { cmdstr, room, type: \execute }
    @response.json 202 {command}

  @post '/_': ->
    console.log "post /_/:room"
    snapshot <~ request-to-save @request
    room = @body?room || new-room!
    <~ SC._put room, snapshot
    @response.type Text
    @response.location "/_/#room"
    @response.send 201 "/#room"

  @delete '/_/:room': ->
    @response.type Text
    {room} = @params
    SC[room]?terminate!
    delete SC[room]
    <~ SC._del room
    @response.send 201 \OK

  @on disconnect: !->
    console.log "on disconnect"
    { id } = @socket
    if IO.sockets.manager?roomClients?
      # socket.io 0.9.x
      :CleanRoomLegacy for key of IO.sockets.manager.roomClients[id] when key is // ^/log- //
        for client in IO.sockets.clients(key.substr(1))
        | client.id isnt id => continue CleanRoomLegacy
        room = key.substr(5)
        SC[room]?terminate!
        delete SC[room]
      return
    :CleanRoom for key, val of IO.sockets.adapter.rooms when key is // ^log- //
      for client, isConnected of val | isConnected and client isnt id
        continue CleanRoom
      room = key.substr(4)
      SC[room]?terminate!
      delete SC[room]

  @on data: !->
    {room, msg, user, ecell, cmdstr, type, auth} = @data
    # eddy
    console.log "on data: " {...@data} 
    room = "#room" - /^_+/ # preceding underscore is reserved
    DB.expire "snapshot-#room", EXPIRE if EXPIRE
    reply = (data) ~> @emit {data}
    broadcast = (data) ~>
      @socket.broadcast.to do
        if @data.to then "user-#{@data.to}" else "log-#{data.room}"
      .emit \data data
      if data.include_self? == true then @emit \data data   #message from server, so send to self as well
    switch type
    | \chat
      <~ DB.rpush "chat-#room" msg
      broadcast @data
    | \ask.ecells
      _, values <~ DB.hgetall "ecell-#room"
      broadcast { type: \ecells, ecells: values, room }
    | \my.ecell
      DB.hset "ecell-#room", user, ecell
    | \execute
      return if cmdstr is /^set sheet defaulttextvalueformat text-wiki\s*$/
      <~ DB.multi!
        .rpush "log-#room" cmdstr
        .rpush "audit-#room" cmdstr
        .bgsave!.exec!
      commandParameters = cmdstr.split("\r")       
      unless SC[room]?
        console.log "SC[#room] went away. Reloading..."
        _, [snapshot, log] <~ DB.multi!get("snapshot-#room").lrange("log-#room", 0, -1).exec
        SC[room] = SC._init snapshot, log, DB, room, @io
      # eddy @on data {
      if commandParameters[0].trim() is \submitform
        room_data = if room.indexOf('_') == -1  # store data in <templatesheet>_formdata
          then room + "_formdata"
          else room.replace(/_[.=_a-zA-Z0-9]*$/i,"_formdata") # get formdata sheet of cloned template
        console.log "test SC[#{room_data}] submitform..."      
        unless SC["#{room_data}"]?
          console.log "Submitform. loading... SC[#{room_data}]"
          _, [snapshot, log] <~ DB.multi!get("snapshot-#{room_data}").lrange("log-#{room_data}", 0, -1).exec
          SC["#{room_data}"] = SC._init snapshot, log, DB, "#{room_data}", @io   
        # add form values to last row of formdata sheet
        attribs <-! SC["#{room_data}"]?exportAttribs
        console.log "sheet attribs:" { ...attribs }       
        formrow = for let datavalue, formDataIndex in commandParameters when formDataIndex != 0
          "set #{String.fromCharCode(64 + formDataIndex)+(attribs.lastrow+1)} text t #datavalue" 
          #SocialCalc.crToCoord(formDataIndex, attribs.lastrow+1)}                   
        #cmdstrformdata = "set A3 text t abc"   
        cmdstrformdata = formrow.join("\n")
        console.log "cmdstrformdata:"+cmdstrformdata        
        <~ DB.multi!
          .rpush "log-#{room_data}" cmdstrformdata
          .rpush "audit-#{room_data}" cmdstrformdata
          .bgsave!.exec!
        SC["#{room_data}"]?ExecuteCommand cmdstrformdata
        broadcast { room:"#{room_data}", user, type, auth, cmdstr: cmdstrformdata, +include_self }
      # }eddy @on data 
      SC[room]?ExecuteCommand cmdstr
      broadcast @data
    | \ask.log
      # eddy @on data {
      #ignore requests for log if startup up database
      if typeof DB.DB == 'undefined'
        console.log "ignore connection request, no database yet!"      
        reply { type: \ignore }
        return
      # } eddy @on data         
      console.log "join [log-#{room}] [user-#user]"
      @socket.join "log-#room"
      @socket.join "user-#user"
      _, [snapshot, log, chat] <~ DB.multi!
        .get "snapshot-#room"
        .lrange "log-#room" 0 -1
        .lrange "chat-#room" 0 -1
        .exec!
      SC[room] = SC._init snapshot, log, DB, room, @io
      reply { type: \log, room, log, chat, snapshot }
    | \ask.recalc
      @socket.join "recalc.#room"
      SC[room]?terminate!
      delete SC[room]
      {log, snapshot} <~ SC._get room, @io
      reply { type: \recalc, room, log, snapshot }
    | \stopHuddle
      return if @KEY and KEY isnt @KEY
      <~ DB.del <[ audit log chat ecell snapshot ]>.map -> "#it-#room"
      SC[room]?terminate!
      delete SC[room]
      broadcast @data
    | \ecell
      return if auth is \0 or KEY and auth isnt hmac room
      broadcast @data
    | otherwise
      broadcast @data
