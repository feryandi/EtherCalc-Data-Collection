var Table;
Table = (function(){
  Table.displayName = 'Table';
  var prototype = Table.prototype, constructor = Table;
  function Table(sheetdict, data){
    this.sheet = sheetdict;
    this.sheetname = 'Sheet1';
    // Table Specifics
    this.rows = [];
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
  Table.prototype.TupleSerialize = function(){    
    ///////////////////////////////////////////////////////////////////
    // Tuples for databases
    // Sekarang 1 Tabel dulu yah :(
    table = {};
    table['name'] = 'table_1';
    table['headers'] = [];
    table['data'] = [];

    // Yang simpel dulu ya :((((
    datarow = {};

    // Getting all the data CELLS that used
    for (row of this.rows) {
      var header = {}
      header['name'] = row['header'];
      header['type'] = 'VARCHAR'; // TO-DO CHANGE THIS
      table['headers'].push(header)

      for (cells of this.GetCells(row['data'])) {
        if (!(datarow[this.GetCellRow(cells)] instanceof Array)) {
          datarow[this.GetCellRow(cells)] = [];
        }
        datarow[this.GetCellRow(cells)].push(cells);
      }
    }

    // Datarow is held the corenspondent DATA CELLS per ROWS
    // For now, consider this as the absoulte ROWS for database
    // Further development of so many different use cases needed
    // console.log(datarow);
    for (var rownum in datarow) {
      if (!datarow.hasOwnProperty(rownum)) continue;

      var obj = datarow[rownum];
      var temprow = [];
      for (cell of obj) {
        temprow.push(this.sheet[this.sheetname]['sheetdict'][cell].cstr);
      }
      table['data'].push(temprow);
    }

    //console.log(table);
    //
    //////////////////////////////////////////////////////////////////////
    return JSON.stringify(table);
  };
  Table.prototype.TupleDeserialize = function(sdata){
    return JSON.parse(sdata);
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

    return JSON.stringify(data);
  };
  Table.prototype.Deserialize = function(sdata){
    var data;
    data = JSON.parse(sdata);
    this.title = data['title'];
    this.footnote = data['footnote'];
    this.header = data['header'];
    this.data = data['data'];
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
  Table.prototype.GetDataRange = function(col){
    var minval, maxval;
    minval = Math.min.apply(Math, this.data);
    maxval = Math.max.apply(Math, this.data);
    // Super simple.... for now :'(
    return SocialCalc.rcColname(col) + minval + ":" + SocialCalc.rcColname(col) + maxval;
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
      tempobj['data'] = this.GetDataRange(col);
      tempobj['vtype'] = 'str';
      tempobj['vrange'] = '';
      tempobj['vrel'] = '';
      results$.push(this.rows.push(tempobj));
    }
    return results$;
  };
  Table.prototype.GetHTMLForm = function(){
    var i, hdata, whole_table, title_div, begin_table, n, i$, len$, hd, table_start, table_label, table_data, table_validations, is_int, is_dbl, is_str, is_txt, is_bln, table_datatype, table_end, table_per_data, end_table;
    i = 1;
    hdata = this.rows;
    whole_table = "";
    title_div = "<div style=\"margin-left:8px;border:1px solid rgb(192,192,192);display:inline-block;\"><div><center>" + "<h4>Table " + i + "</h4>" + "</center>";
    whole_table += title_div;
    begin_table = "<table style=\"border-top:1px solid rgb(192,192,192);padding-top:16px;\"><thead><tr><th>Label Name</th><th>Data Range</th><th>Type Validation</th><th>Range Validation</th><th>Relation Validation</th></tr></thead>";
    whole_table += begin_table;
    n = 1;
    for (i$ = 0, len$ = hdata.length; i$ < len$; ++i$) {
      hd = hdata[i$];
      table_start = "<tr>";
      table_label = "<td><input id=\"%id.t1.databaseLabel" + n + "\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\" value=\"" + hd['header'] + "\" /></td>";
      table_data = "<td><input id=\"%id.t1.databaseData" + n + "\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\" value=\"" + hd['data'] + "\" /></td>";
      table_validations = "<td><select id=\"%id.t1.databaseType" + n + "\" size=\"1\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"><option selected>None</option><option>String</option><option>Integer</option></select></td><td><input id=\"%id.t1.databaseRangeV1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><input id=\"%id.t1.databaseRelationV1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td>";
      is_int = '';
      is_dbl = '';
      is_str = '';
      is_txt = '';
      is_bln = '';
      switch (hd['vtype']) {
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
      table_datatype = "<td><select id=\"%id.t1.databaseType" + n + "\" size=\"1\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"><option " + is_int + ">Integer</option><option " + is_dbl + ">Double</option><option " + is_str + ">String</option><option " + is_txt + ">Text</option><option " + is_bln + ">Boolean</option></select></td>";
      table_validations = table_datatype;
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