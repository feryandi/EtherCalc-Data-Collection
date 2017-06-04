@__MYSQL__ = null
@include = ->
  return @__MYSQL__ if @__MYSQL__

  db = {}

  env = process.env
  [mysqlPort, mysqlHost, mysqlPass, mysqlDb, dataDir] = env<[ MYSQL_PORT MYSQL_HOST MYSQL_PASS MYSQL_DB OPENSHIFT_DATA_DIR ]>

  mysqlHost ?= \localhost
  mysqlPort ?= 3306
  mysqlUser ?= \root
  mysqlPass ?= \root
  mysqlDB ?= \TA

  mysqlSetting =
    * host: mysqlHost,
      user: mysqlUser,
      password: mysqlPass,
      database: mysqlDB 

  require! \mysql
  client = mysql.createConnection mysqlSetting
  client.connect (err) -> 
    if err 
      console.log "MySQL error connecting: #err.stack" 
      return
    
    console.log "MySQL connected as id #client.threadId"
    return

  dataDir ?= process.cwd!

  db.createTable = (table_name, columns) ->
    colstring = '('
    i = 0
    for col in columns
      if i > 0
        colstring += ', '
      ## DISINI HARUSNYA DITANGANIN JUGA JENIS2 VARCHAR, TEXT BERAPA LENGTHNYA DLL 
      ## YANG INI BARU DEFAULT: VARCHAR

      if col.type == "VARCHAR"
        colstring += '`' + col.name.trim! + '` ' + col.type + '(160)'
      else if col.type == "INT" 
        colstring += '`' + col.name.trim! + '` ' + col.type + '(11)'
      else
        colstring += '`' + col.name.trim! + '` ' + col.type

      i += 1
    colstring += ')'

    client.query "CREATE TABLE " + table_name + " " + colstring, (error, results, fields) -> 
      console.log ("ERROR CREATE: " + error)

  db.isExistTable = (table_name, cb) ->
    console.log(table_name)
    client.query "SHOW TABLES LIKE '" + table_name + "'", (error, results, fields) ->
      cb error, results.length

  db.isExistData = (table_name, col, val, cb) ->
    console.log(table_name + " | " + col + " | " + val + " | ")
    client.query "SELECT * FROM " + table_name + " WHERE " + col + " = '" + val + "'", (error, results, fields) ->
      cb error, results.length

  db.dropTable = (table_name) ->
    client.query "DROP TABLE " + table_name, (error, results, fields) -> return

  db.insertData = (table_name, columns, data) ->
    colstring = '('
    i = 0
    for col in columns
      if i > 0
        colstring += ', '
      colstring += '`' + col.name.trim! + '`'
      i += 1
    colstring += ')'

    datastring = '('
    i = 0
    for d in data
      console.log(d)
      if i > 0
        datastring += ', '
      datastring += '"' + db.escapeString(d) + '"'
      i += 1
    datastring += ')'

    client.query "INSERT INTO " + table_name + " " + colstring + " VALUES " + datastring, (error, results, fields) -> 
      console.log(error)

  db.updateData = (table_name, columns, data, con_col, con_val) ->
    colstring = ''
    i = 0
    for col in columns
      if i > 0
        colstring += ", "
      colstring += "`" + col.name.trim! + "`='" + data[i] + "'"
      i += 1

    client.query "UPDATE " + table_name + " SET " + colstring + " WHERE " + con_col + " = '" + con_val + "'", (error, results, fields) -> 
      console.log(error)

  db.escapeString = (str) ->
    return str.replace /[\0\x08\x09\x1a\n\r"'\\\%]/g, (char) ->
        switch (char) 
        case "\0"
          return "\\0"
        case "\x08"
          return "\\b"
        case "\x09"
          return "\\t"
        case "\x1a"
          return "\\z"
        case "\n"
          return "\\n"
        case "\r"
          return "\\r"
        case "\"", "'", "\\", "%"
          return "\\"+char

  db.log = -> 
    console.log "MySQL OK" 
    return "Some shitty strings"

  db.test = ->
    client.query "CREATE TABLE pet (name VARCHAR(20), sex CHAR(1), birth DATE, death DATE)", (error, results, fields) -> return

  @__MYSQL__ = db


