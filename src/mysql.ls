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

  db.log = -> 
    console.log "MySQL OK" 
    return

  db.test = ->
    client.query 'CREATE TABLE pet (name VARCHAR(20), sex CHAR(1), birth DATE, death DATE)', (error, results, fields) -> return

  @__MYSQL__ = db


