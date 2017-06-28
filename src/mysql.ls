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
        client.end()
        cb "error"
        return
      console.log "MySQL connected as id #client.threadId"
      client.end()
      cb "success"
      return

  db.executeSQL = (sql, mysqlSetting, cb) ->
    client = mysql.createConnection mysqlSetting
    client.connect (err) -> 
      if err 
        console.log "MySQL error connecting: #err.stack" 
        client.end()
        return false
      console.log "MySQL connected as id #client.threadId"
      console.log "SQL: " + sql
      client.query sql, (error, results, fields) ->
        client.end()
        cb error, results
      return true

  db.createTable = (table_name, columns, mysqlSetting, cb) ->
    colstring = '('
    i = 0
    ## The primary key SQL only works in MySQL!
    ## Giving id column
    colstring += '`_id` int NOT NULL AUTO_INCREMENT,'
    for col in columns
      if i > 0
        colstring += ', '
      #if col.type == "VARCHAR"
      #  colstring += '`' + col.name.trim! + '` ' + col.type + '(160)'
      #else if col.type == "INT" 
      #  colstring += '`' + col.name.trim! + '` ' + col.type + '(11)'
      if col.type == "CPKEY"
        colstring += 'PRIMARY KEY (' + col.name.trim! + ') '
      else if col.type == "CUNIQ"
        colstring += 'UNIQUE KEY `muniq` (' + col.name.trim! + ') '
      else if col.type == "STATE"
        colstring += '`' + col.name.trim! + '` TEXT'
      else
        colstring += '`' + col.name.trim! + '` VARCHAR(160)'
      i += 1
    ## Set id as primary key
    colstring += ', PRIMARY KEY (_id)'
    colstring += ')'

    sql = "CREATE TABLE " + table_name + " " + colstring
    db.executeSQL sql, mysqlSetting, (error, results) ->
      db.alterUnique table_name, columns, mysqlSetting, (error, results) ->
        cb error, results

  db.isExistTable = (table_name, mysqlSetting, cb) ->
    sql = "SHOW TABLES LIKE '" + table_name + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.getRowCount = (table_name, mysqlSetting, cb) ->
    sql = "SELECT COUNT(*) FROM " + table_name
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.getColumns = (table_name, mysqlSetting, cb) ->
    sql = "SHOW COLUMNS FROM " + table_name
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results  

  db.getUniqueColumns = (table_name, mysqlSetting, cb) ->
    sql = "SHOW COLUMNS FROM " + table_name + " WHERE `Key` = 'UNI'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.getColumnsByName = (table_name, column, mysqlSetting, cb) ->
    sql = "SHOW COLUMNS FROM " + table_name + " WHERE `Field` = '" + column + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results  

  db.selectData = (table_name, col, val, mysqlSetting, cb) ->
    sql = "SELECT * FROM " + table_name + " WHERE " + col + " = '" + val + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.selectNEData = (table_name, col, val, mysqlSetting, cb) ->
    sql = "SELECT * FROM " + table_name + " WHERE " + col + " != '" + val + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.selectWhereData = (table_name, sel_col, where_cond, mysqlSetting, cb) ->
    sql = "SELECT " + sel_col + " FROM " + table_name + " WHERE " + where_cond
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.deleteData = (table_name, con_col, con_val, mysqlSetting, cb) ->
    sql = "DELETE FROM " + table_name + " WHERE `" + con_col + "` = '" + con_val + "'"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.deleteWhereData = (table_name, where_cond, mysqlSetting, cb) ->
    sql = "DELETE FROM " + table_name + " WHERE " + where_cond
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
    console.log(data)
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

  db.insertDupData = (table_name, columns, data, bkey, mysqlSetting, cb) ->
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

    sql = "INSERT INTO " + table_name + " " + colstring + " VALUES " + datastring + " ON DUPLICATE KEY UPDATE " + bkey + " = VALUES(" + bkey + ")"
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.insertDupMultiData = (table_name, columns, data, mysqlSetting, cb) ->
    assignstring = ""
    colstring = '('
    i = 0
    a = 0
    for col in columns
      if i > 0
        colstring += ', '
      if a > 0 and !(col.unique)
        assignstring += ', '
      colstring += '`' + col.name.trim! + '`'
      if !(col.unique)
        assignstring += '`' + col.name.trim! + '` = VALUES(`' + col.name.trim! + '`)'
        a += 1
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

    sql = "INSERT INTO " + table_name + " " + colstring + " VALUES " + datastring + " ON DUPLICATE KEY UPDATE " + assignstring
    db.executeSQL sql, mysqlSetting, (error, results) ->
      console.log(results)
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

  db.updateWhereData = (table_name, columns, data, wcon, mysqlSetting, cb) ->
    # WARNING, THIS INTENTED FOR NULL VALUE
    colstring = ''
    i = 0
    for col in columns
      if i > 0
        colstring += ", "
      colstring += "`" + col.name.trim! + "`= " + data[i]
      i += 1

    sql = "UPDATE " + table_name + " SET " + colstring + " WHERE " + wcon
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.alterUnique = (table_name, columns, mysqlSetting, cb) ->
    colstring = ''
    i = 0
    for col in columns
      if col.unique
        if i > 0
          colstring += ", "
        colstring += "`" + col.name.trim! + "`"
        i += 1

    if colstring != ''
      sql = "ALTER TABLE `" + table_name + "` ADD UNIQUE INDEX `uidx` (" + colstring + ")"
      db.executeSQL sql, mysqlSetting, (error, results) ->
        cb error, results
    else
      cb "OK", "No unique column found"

  db.countColumns = (table_name, columns, mysqlSetting, cb) ->
    colstring = ''
    i = 0
    for col in columns
      if !(col["Key"].toLowerCase! == "uni")
        if i > 0
          colstring += ", "
        colstring += "COUNT(`" + col["Field"].trim! + "`) AS `" + col["Field"].trim! + "`"
        i += 1

    sql = "SELECT " + colstring + " FROM " + table_name
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.getNullColumns = (table_name, mysqlSetting, cb) ->
    db.getColumns table_name, mysqlSetting, (err, colres) ->
      db.countColumns table_name, colres, mysqlSetting, (err, res) ->
        nullColumns = []
        result = res[0]
        for col in colres
          if result[col["Field"].trim!] == 0
            nullColumns.push(col["Field"].trim!)
        cb "", nullColumns

  db.addColumns = (table_name, columns, mysqlSetting, cb) ->
    colstring = ''
    i = 0
    for col in columns
      if i > 0
        colstring += ", "
      colstring += " ADD COLUMN `" + col.name.trim! + "` "
      #if col.type == "VARCHAR"
      #  colstring += col.type + '(160)'
      #else if col.type == "INT" 
      #  colstring += col.type + '(11)'
      #else
      colstring += col.type + '(160)'
      i += 1

    sql = "ALTER TABLE `" + table_name + "` " + colstring
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.dropColumns = (table_name, columns, mysqlSetting, cb) ->
    colstring = ''
    i = 0
    for col in columns
      if i > 0
        colstring += ", "
      colstring += " DROP COLUMN `" + col.trim! + "`"
      i += 1

    sql = "ALTER TABLE `" + table_name + "` " + colstring
    db.executeSQL sql, mysqlSetting, (error, results) ->
      cb error, results

  db.checkRelation = (table_name, column, data, mysqlSetting, cb) ->
    datastring = ''
    i = 0
    for d in data
      if i > 0
        datastring += " OR "
      datastring += "`" + column + "`='" + d + "'"
      i += 1

    info = "No info"
    valid = false
    db.getColumnsByName table_name, column, mysqlSetting, (err, res) ->
      if res.length != 0
        if res[0]["Key"].toLowerCase() == "uni" or res[0]["Key"].toLowerCase() == "pri"
          valid = true
          sql = "SELECT COUNT(`_id`) AS COUNT FROM `" + table_name + "` WHERE " + datastring
          db.executeSQL sql, mysqlSetting, (error, results) ->
            cb error, results, valid, "No info"
        else
          info = "Column must pkey or unique"
          cb err, res, valid, info
      else
        info = "Column not found"
        cb err, res, valid, info

  db.cleanNullRow = (table_name, with_delete, mysqlSetting, cb) ->
    db.getColumns table_name, mysqlSetting, (err, res) ->
      where_cond = ""
      i = 0
      for r in res
        i += 1
        if r["Field"] != "_id" and r["Key"].toLowerCase! != "uni"
          where_cond += "`" + r["Field"] + "` is NULL"
          if i != res.length 
            where_cond += " AND "
      db.deleteWhereData table_name, where_cond, mysqlSetting, (error, results) ->
        db.getRowCount table_name, mysqlSetting, (error, results) ->
          if (with_delete)
            if (results[0]['COUNT(*)'] == 0)
              db.dropTable table_name, mysqlSetting, (error, results) ->
                cb error, results
            else
              db.getNullColumns table_name, mysqlSetting, (error, results) ->
                db.dropColumns table_name, results, mysqlSetting, (error, results) ->
                  cb error, results
          else
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


