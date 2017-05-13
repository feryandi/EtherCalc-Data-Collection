var Table;
Table = (function(){
  Table.displayName = 'Table';
  var prototype = Table.prototype, constructor = Table;
  function Table(sheetdict, data){
    this.sheet = sheetdict;
    this.sheetname = 'Sheet1';
    // Table Specifics
    this.rows = [];
    this.range = "";
    // Spreadsheet Data
    this.dataval = {};
    this.title = [];
    this.footnote = [];
    this.header = [];
    this.data = [];
    this.startcol = 1;
    this.endcol = 1;
    if (sheetdict !== undefined && sheetdict !== null) {
      this.endcol = this.sheet[this.sheetname]['maxcolnum'];
    }
    if (data !== undefined && data !== null) {
      this.ParseData(data);
    }
  }
  Table.prototype.ParseData = function(data){
    var jdata, i$, len$, row;
    //jdata = JSON.parse(data);
    jdata = data; 
    if (jdata !== null) {
      for (i$ = 0, len$ = jdata.length; i$ < len$; ++i$) {
        row = jdata[i$];
        if (row.type === "Title") {
          this.title.push(parseInt(row.row) + 1);
        } else if (row.type === "Footnote") {
          this.footnote.push(parseInt(row.row) + 1);
        } else if (row.type === "Header") {
          this.header.push(parseInt(row.row) + 1);
        } else if (row.type === "Data") {
          this.data.push(parseInt(row.row) + 1);
        }
      }
    }
    return this.MapHeaderData();
  };
  Table.prototype.TupleSerializeWithChecker = function(){    
    ///////////////////////////////////////////////////////////////////
    // Tuples for databases
    // Sekarang 1 Tabel dulu yah :(
    table = {};
    table['name'] = 'table_1';
    table['headers'] = [];
    table['data'] = [];

    // Yang simpel dulu ya :((((
    datarow = {};

    datarange = this.RangeComponent(this.range)

    // Getting all the data CELLS that used
    colnum = 0;
    for (row of this.rows) {
      var header = {};
      header['name'] = row['header'];
      header['type'] = 'VARCHAR'; // TO-DO CHANGE THIS
      table['headers'].push(header);

      rownum = 0;
      for (i$ = datarange[1]; i$ <= datarange[3]; ++i$) {
        if (!(table['data'][rownum] instanceof Array)){
          table['data'][rownum] = []
        }
        cellname = '' + row['data'] + i$
        cell = this.sheet[this.sheetname]['sheetdict'][cellname]

        error = {};
        error['coordinate'] = cellname;

        // DATA TYPE CHECKER
        error['error'] = "type";
        console.log(cellname + " <~ " + row['vtype'] + " <<>> " + cell.mtype);

        if (row['vtype'] == "str" && cell.mtype != "str") {
          return error;
        } else if (row['vtype'] == "int") {
          if (!(cell.mtype == "int" || !isNaN(cell.cstr))) {
            return error;
          }
        } else if (row['vtype'] == "dbl" && cell.mtype != "str") {
          if (!((!isNaN(cell.cstr) && (cell.cstr).toString().indexOf('.') != -1))) {
            return error;
          }
        } else if (row['vtype'] == "txt" && cell.mtype != "str") {
          return error;
        } else if (row['vtype'] == "bln" && cell.mtype != "str") {
          text = cell.cstr.toString().toLowerCase();
          if (!(text == "true" || text == "false")) {
            return error;
          }
        }

        // DATA RANGE CHECKER
        // Check if the vrange is an JSONArray
        error['error'] = "range";
        console.log(cellname + " <~ r: " + row['vrange']);
        if (row['vrange'].charAt(0) == "[" && row['vrange'].slice(-1) == "]") {
          console.log("ARRAY");
        // EX: ["text01","text02"] (JSONArray)
          if (!(row['vrange'].includes(cell.cstr.toString()))) {
            error['description'] = "Not in array of accepted string";
            console.log(error);
            return error;
          }
        } else if (row['vrange'].includes("-")) {
          console.log("BETWEEN");
        // EX: 100-2100 OR 10.5-1000
          values = row['vrange'].split("-");
          if (values[0] > values[1]) {
            // INVALID: ERROR
          } else {
            num = parseInt(cell.cstr.toString());
            // TO-DO: Check NaN
            if (num < values[0] || num > values[1]) {
              error['description'] = "Values not in between";
              console.log(error);
              return error;
            }
          }
        } else if (row['vrange'].charAt(0) == "<") {
          console.log("LESS");
        // EX: <200 OR <=200
          num = parseInt(cell.cstr.toString());
          // TO-DO: Check NaN
          if (row['vrange'].charAt(1) == "=") {
            val = parseInt(row['vrange'].substr(2));
            if (!(num <= val)) {
              error['description'] = "Values not in less equals than";
              console.log(error);
              return error;
            }
          } else {
            val = parseInt(row['vrange'].substr(1));
            if (!(num < val)) {
              error['description'] = "Values not in less than";
              console.log(error);
              return error;
            }
          }
        } else if (row['vrange'].charAt(0) == ">") {
          console.log("GREATER");
        // EX: >200 OR >=200
          num = parseInt(cell.cstr.toString());
          // TO-DO: Check NaN
          if (row['vrange'].charAt(1) == "=") {
            val = parseInt(row['vrange'].substr(2));
            if (!(num >= val)) {
              error['description'] = "Values not in greater equals than";
              console.log(error);
              return error;
            }
          } else {
            val = parseInt(row['vrange'].substr(1));
            if (!(num > val)) {
              error['description'] = "Values not in greater than";
              console.log(error);
              return error;
            }            
          }
        } else if (row['vrange'].charAt(0) == "=") {
          console.log("EQUAL");
        // EX: =200
          val = parseInt(row['vrange'].substr(1));
          if (num != val) {
            error['description'] = "Values not in equals";
            console.log(error);
            return error;
          }
        } else {
          console.log("ELSE");
          // KOSONG
        }

        // DATA RELATION CHECKER, kayanya bukan disini sih harusnya soalnya ngecek antar tabel        

        table['data'][rownum][colnum] = cell.cstr
        rownum += 1;
      }
      colnum += 1
    }

    console.log(table);
    //
    //////////////////////////////////////////////////////////////////////
    return JSON.stringify(table);
  };
  Table.prototype.TupleDeserialize = function(sdata){
    return JSON.parse(sdata);
  };
  Table.prototype.IsHasData = function(){
    return this.data.length > 0;
  };
  Table.prototype.Serialize = function(){
    var data, table, datarow;
    data = {};
    data['title'] = this.title;
    data['footnote'] = this.footnote;
    data['header'] = this.header;
    data['data'] = this.data;
    data['startcol'] = this.startcol;
    data['endcol'] = this.endcol;
    data['rows'] = this.rows;
    data['range'] = this.range;

    return JSON.stringify(data);
  };
  Table.prototype.Deserialize = function(sdata){
    var data;
    data = JSON.parse(sdata);
    this.title = data['title'];
    this.footnote = data['footnote'];
    this.header = data['header'];
    this.data = data['data'];
    this.range = data['range'];
    this.startcol = data['startcol'];
    this.endcol = data['endcol'];
    this.rows = data['rows'];
  };
  Table.prototype.GetCellCol = function(colname){
    var res = colname.match(/[a-zA-Z]+/g);
    var s = res[0];
    var ret = 0;
    var iter = 0;
    while (s.length > iter) {
      var d = s.charCodeAt(iter) - 65 + 1;
      ret = 26 * ret + d;
      iter++;
    }
    return ret;
  };
  Table.prototype.GetCellRow = function(colname){
    var res = colname.match(/[0-9]+/g);
    return parseInt(res[0]);
  };
  Table.prototype.RangeComponent = function(range){
    var cells, c, r;
    var startend = range.split(":");
    cells = [];
    c = 1; r = 1;
    return [this.GetCellCol(startend[0]), this.GetCellRow(startend[0]), this.GetCellCol(startend[1]), this.GetCellRow(startend[1])];
  };
  Table.prototype.GetCells = function(range){
    var cells, c, r;
    var startend = range.split(":");
    cells = [];
    c = 1; r = 1;
    for (r = this.GetCellRow(startend[0]); r <= this.GetCellRow(startend[1]); r++) {
      for (c = this.GetCellCol(startend[0]); c <= this.GetCellCol(startend[1]); c++) {
        cells.push("" + SocialCalc.rcColname(c) + r);
      } 
    }
    return cells;
  };
  Table.prototype.GetDataRange = function(mincol, maxcol){
    var minval, maxval;
    minval = Math.min.apply(Math, this.data);
    maxval = Math.max.apply(Math, this.data);
    // Super simple.... for now :'(
    return SocialCalc.rcColname(mincol) + minval + ":" + SocialCalc.rcColname(maxcol) + maxval;
  };
  Table.prototype.MapHeaderData = function(){
    var i$, to$, col, tempobj, j$, ref$, len$, h, results$ = [];
    this.rows = [];
    // Yang di for itu kolom karena dengan asumsi bahwa tabelnya headernya horizontal
    for (i$ = this.startcol, to$ = this.endcol; i$ <= to$; ++i$) {
      col = i$;
      tempobj = {};
      tempobj['header'] = "";
      for (j$ = 0, len$ = (ref$ = this.header).length; j$ < len$; ++j$) {
        h = ref$[j$];
        tempobj['header'] += this.sheet[this.sheetname]['sheetdict'][SocialCalc.rcColname(col) + h].cstr + " ";
      }
      tempobj['data'] = SocialCalc.rcColname(col);
      tempobj['vtype'] = 'non';
      tempobj['vrange'] = '';
      tempobj['vrel'] = '';
      results$.push(this.rows.push(tempobj));
    }
    this.range = this.GetDataRange(this.startcol, this.endcol)
    return results$;
  };
  Table.prototype.GetHTMLForm = function(){
    var i, hdata, whole_table, title_div, begin_table, n, i$, len$, hd, table_start, table_label, table_data, table_validations, is_int, is_dbl, is_str, is_txt, is_bln, table_datatype, table_end, table_per_data, end_table;
    i = 1; // Used when there are multiple tables
    hdata = this.rows;
    whole_table = "";
    title_div = "<div style=\"margin-left:8px;border:1px solid rgb(192,192,192);display:inline-block;\"><div><table style=\"padding-top: 15px;padding-bottom: 15px;\"><tr><td width=\"55%\" style=\"padding-left:20px;\">" + "<strong>Table " + i + "</strong></td>";
    title_div += "<td width=\"35%\" style=\"text-align: right;\">Data Range <input id=\"t1.databaseRange\" class=\"btn btn-default btn-xs\" style=\"max-width: 105px\" value=\"" + this.range + "\"></td>";
    title_div += "<td width=\"10%\" style=\"text-align: right;\"><input type=\"button\" value=\"Save\" onclick=\"window.SaveConfiguration(" + i + ");\" style=\"font-size:x-small;\"></td></tr></table>";
    whole_table += title_div;
    begin_table = "<table style=\"border-top:1px solid rgb(192,192,192);padding-top:16px;\"><thead><tr><th>Label Name</th><th>Data Column</th><th>Type</th><th>Permitted Values</th><!--<th>Relation</th>--></tr></thead>";
    whole_table += begin_table;
    n = 1;
    for (i$ = 0, len$ = hdata.length; i$ < len$; ++i$) {
      hd = hdata[i$];
      table_start = "<tr>";
      table_label = "<td><input id=\"t1.databaseLabel." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + hd['header'] + "\" /></td>";
      table_data = "<td><input id=\"t1.databaseData." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" style=\"max-width: 85px\" value=\"" + hd['data'] + "\" /></td>";
      table_validations = "<td><select id=\"t1.databaseType." + n + "\" size=\"1\" class=\"btn btn-default btn-xs\"><option selected>None</option><option>String</option><option>Integer</option></select></td><td><input id=\"t1.databaseRangeV1\" onchange=\"\" class=\"btn btn-default btn-xs\"/></td><td><input id=\"t1.databaseRelationV1\" onchange=\"\" class=\"btn btn-default btn-xs\"/></td>";
      is_int = '';
      is_dbl = '';
      is_str = '';
      is_txt = '';
      is_bln = '';
      is_non = '';
      switch (hd['vtype']) {
      case 'non':
        is_non = 'selected';
        break;
      case 'int':
        is_int = 'selected';
        break;
      case 'dbl':
        is_dbl = 'selected';
        break;
      case 'str':
        is_str = 'selected';
        break;
      case 'txt':
        is_txt = 'selected';
        break;
      case 'bln':
        is_bln = 'selected';
      }
      table_datatype = "<td><select id=\"t1.databaseType." + n + "\" size=\"1\" class=\"btn btn-default btn-xs\"><option " + is_non + " value=\"non\">None</option><option " + is_int + " value=\"int\">Integer</option><option " + is_dbl + " value=\"dbl\">Double</option><option " + is_str + " value=\"str\">String</option><option " + is_txt + " value=\"txt\">Text</option><option " + is_bln + " value=\"bln\">Boolean</option></select></td>";
      table_permitted = "<td><input id=\"t1.databasePermitted." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + hd['vrange'] + "\" ></td>";
      table_validations = table_datatype + table_permitted;
      table_end = "</tr>";
      table_per_data = table_start + table_label + table_data + table_validations + table_end;
      whole_table += table_per_data;
      n += 1;
    }
    end_table = "</table></div></div>";
    whole_table += end_table;
    return whole_table;
  };
  return Table;
}());

if (typeof module !== 'undefined' && module.exports) {
  module.exports = Table;
}