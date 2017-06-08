@__MYSQL__ = null
@include = ->
  return @__MYSQL__ if @__MYSQL__

  db = {}

  env = process.env
  [mysqlPort, mysqlHost, mysqlPass, mysqlDb, dataDir] = env<[ MYSQL_PORT MYSQL_HOST MYSQL_PASS MYSQL_DB OPENSHIFT_DATA_DIR ]>

  require! \mysql
  client = client

  dataDir ?= process.cwd!

  db.createConnection = (mysqlSetting, cb) ->
    client = mysql.createConnection mysqlSetting
    client.connect (err) -> 
      if err 
        console.log "MySQL error connecting: #err.stack" 
        cb "Error"
      console.log "MySQL connected as id #client.threadId"
      cb "Success"

  db.executeSQL = (sql, mysqlSetting, cb) ->
    client = mysql.createConnection mysqlSetting
    client.connect (err) -> 
      if err 
        console.log "MySQL error connecting: #err.stack" 
        return false
      console.log "MySQL connected as id #client.threadId"
      console.log "SQL: " + sql
      client.query sql, (error, results, fields) -> 
        cb error, results
      return true

  db.createTable = (table_name, columns, mysqlSetting, cb) ->
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

    sql = "CREATE TABLE " + table_name + " " + colstring
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.isExistTable = (table_name, mysqlSetting, cb) ->
    sql = "SHOW TABLES LIKE '" + table_name + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.getColumns = (table_name, mysqlSetting, cb) ->
    sql = "SHOW COLUMNS FROM " + table_name
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results  

  db.selectData = (table_name, col, val, mysqlSetting, cb) ->
    sql = "SELECT * FROM " + table_name + " WHERE " + col + " = '" + val + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.deleteData = (table_name, con_col, con_val, mysqlSetting, cb) ->
    sql = "DELETE FROM " + table_name + " WHERE `" + con_col + "` = '" + con_val + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.dropTable = (table_name, mysqlSetting, cb) ->
    sql = "DROP TABLE " + table_name
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.insertData = (table_name, columns, data, mysqlSetting, cb) ->
    colstring = '('
    i = 0
    for col in columns
      if i > 0
        colstring += ', '
      colstring += '`' + col.name.trim! + '`'
      i += 1
    colstring += ')'

    datastring = '('
    jd = 1
    for d in data
      i = 0
      for dt in d
        if i > 0
          datastring += ', '
        datastring += '"' + db.escapeString(dt) + '"'
        i += 1
      datastring += ')'
      if jd < data.length
        datastring += ', ('
      jd += 1

    sql = "INSERT INTO " + table_name + " " + colstring + " VALUES " + datastring
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.updateData = (table_name, columns, data, con_col, con_val, mysqlSetting, cb) ->
    colstring = ''
    i = 0
    for col in columns
      if i > 0
        colstring += ", "
      colstring += "`" + col.name.trim! + "`='" + data[i] + "'"
      i += 1

    sql = "UPDATE " + table_name + " SET " + colstring + " WHERE " + con_col + " = '" + con_val + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.escapeString = (str) ->
    return ("" + str).replace /[\0\x08\x09\x1a\n\r"'\\\%]/g, (char) ->
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

  db.test = (mysqlSetting) ->
    sql = "CREATE TABLE pet (name VARCHAR(20), sex CHAR(1), birth DATE, death DATE)"
    db.executeSQL sql, mysqlSetting

  @__MYSQL__ = db


