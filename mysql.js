// Generated by LiveScript 1.5.0
(function(){
  this.__MYSQL__ = null;
  this.include = function(){
    var db, env, ref$, mysqlPort, mysqlHost, mysqlPass, mysqlDb, dataDir, mysqlUser, mysqlDB, mysqlSetting, mysql, client;
    if (this.__MYSQL__) {
      return this.__MYSQL__;
    }
    db = {};
    env = process.env;
    ref$ = [env['MYSQL_PORT'], env['MYSQL_HOST'], env['MYSQL_PASS'], env['MYSQL_DB'], env['OPENSHIFT_DATA_DIR']], mysqlPort = ref$[0], mysqlHost = ref$[1], mysqlPass = ref$[2], mysqlDb = ref$[3], dataDir = ref$[4];
    mysqlHost == null && (mysqlHost = 'localhost');
    mysqlPort == null && (mysqlPort = 3306);
    mysqlUser == null && (mysqlUser = 'root');
    mysqlPass == null && (mysqlPass = 'root');
    mysqlDB == null && (mysqlDB = 'TA');
    mysqlSetting = {
      host: mysqlHost,
      user: mysqlUser,
      password: mysqlPass,
      database: mysqlDB
    };
    mysql = require('mysql');
    client = mysql.createConnection(mysqlSetting);
    client.connect(function(err){
      if (err) {
        console.log("MySQL error connecting: " + err + ".stack");
        return;
      }
      console.log("MySQL connected as id " + client + ".threadId");
    });
    dataDir == null && (dataDir = process.cwd());
    db.createTable = function(table_name, columns){
      var colstring, i, i$, len$, col;
      colstring = '(';
      i = 0;
      for (i$ = 0, len$ = columns.length; i$ < len$; ++i$) {
        col = columns[i$];
        if (i > 0) {
          colstring += ', ';
        }
        if (col.type === "VARCHAR") {
          colstring += '`' + col.name.trim() + '` ' + col.type + '(160)';
        } else if (col.type === "INT") {
          colstring += '`' + col.name.trim() + '` ' + col.type + '(11)';
        } else {
          colstring += '`' + col.name.trim() + '` ' + col.type;
        }
        i += 1;
      }
      colstring += ')';
      return client.query("CREATE TABLE " + table_name + " " + colstring, function(error, results, fields){
        return console.log("ERROR CREATE: " + error);
      });
    };
    db.isExistTable = function(table_name, cb){
      console.log(table_name);
      return client.query("SHOW TABLES LIKE '" + table_name + "'", function(error, results, fields){
        return cb(error, results.length);
      });
    };
    db.isExistData = function(table_name, col, val, cb){
      console.log(table_name + " | " + col + " | " + val + " | ");
      return client.query("SELECT * FROM " + table_name + " WHERE " + col + " = '" + val + "'", function(error, results, fields){
        return cb(error, results.length);
      });
    };
    db.dropTable = function(table_name){
      return client.query("DROP TABLE " + table_name, function(error, results, fields){});
    };
    db.insertData = function(table_name, columns, data){
      var colstring, i, i$, len$, col, datastring, d;
      colstring = '(';
      i = 0;
      for (i$ = 0, len$ = columns.length; i$ < len$; ++i$) {
        col = columns[i$];
        if (i > 0) {
          colstring += ', ';
        }
        colstring += '`' + col.name.trim() + '`';
        i += 1;
      }
      colstring += ')';
      datastring = '(';
      i = 0;
      for (i$ = 0, len$ = data.length; i$ < len$; ++i$) {
        d = data[i$];
        console.log(d);
        if (i > 0) {
          datastring += ', ';
        }
        datastring += '"' + db.escapeString(d) + '"';
        i += 1;
      }
      datastring += ')';
      return client.query("INSERT INTO " + table_name + " " + colstring + " VALUES " + datastring, function(error, results, fields){
        return console.log(error);
      });
    };
    db.updateData = function(table_name, columns, data, con_col, con_val){
      var colstring, i, i$, len$, col;
      colstring = '';
      i = 0;
      for (i$ = 0, len$ = columns.length; i$ < len$; ++i$) {
        col = columns[i$];
        if (i > 0) {
          colstring += ", ";
        }
        colstring += "`" + col.name.trim() + "`='" + data[i] + "'";
        i += 1;
      }
      return client.query("UPDATE " + table_name + " SET " + colstring + " WHERE " + con_col + " = '" + con_val + "'", function(error, results, fields){
        return console.log(error);
      });
    };
    db.escapeString = function(str){
      return str.replace(/[\0\x08\x09\x1a\n\r"'\\\%]/g, function(char){
        switch (char) {
        case "\0":
          return "\\0";
        case "\x08":
          return "\\b";
        case "\x09":
          return "\\t";
        case "\x1a":
          return "\\z";
        case "\n":
          return "\\n";
        case "\r":
          return "\\r";
        case "\"":
        case "'":
        case "\\":
        case "%":
          return "\\" + char;
        }
      });
    };
    db.log = function(){
      console.log("MySQL OK");
      return "Some shitty strings";
    };
    db.test = function(){
      return client.query("CREATE TABLE pet (name VARCHAR(20), sex CHAR(1), birth DATE, death DATE)", function(error, results, fields){});
    };
    return this.__MYSQL__ = db;
  };
}).call(this);
