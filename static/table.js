var Table;
Table = (function(){
  Table.displayName = 'Table';
  var prototype = Table.prototype, constructor = Table;
  function Table(sheetdict, data){
    // console.log(data);
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
    this.datarow = [];

    this.startcol = 1;
    this.endcol = 1;
    this.affectedcol = [];
    
    this.rawdata = data;
    this.name = "untitled"; 
    // This only works if only table is vertically aligned
    // if (sheetdict !== undefined && sheetdict !== null) {
    //   this.endcol = this.sheet[this.sheetname]['maxcolnum'];
    // }
    if (data !== undefined && data !== null) {
      this.ParseData(data);
    }
  }
  Table.prototype.ParseData = function(data){
    var jdata, i$, len$, row;
    this.title = [];
    this.footnote = [];
    this.header = [];
    this.data = [];
    this.datarow = [];
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
          //this.data.push(parseInt(row.row) + 1);
          this.datarow.push(parseInt(row.row) + 1);
          this.data = JSON.stringify(this.data);
        }
      }
    }
    return this.MapHeaderData();
  };
  Table.prototype.TupleSerializeWithChecker = function(spid){    
    ///////////////////////////////////////////////////////////////////
    // Tuples for databases
    table = {};
    table['name'] = this.name;
    table['headers'] = [];
    table['data'] = [];
    table['spreadsheet_id'] = spid;
    table['unique_vals'] = [];
    table['db_relations'] = [];

    error = {};
    reserved = ["s_database_state", "s_database_wlog"];

    if (reserved.includes(this.name)) {
      error['coordinate'] = this.name;
      error['error'] = "table";
      error['description'] = "Name is reserved";
      return error;
    }

    // Getting all the data CELLS that used
    colnum = 0;
    header_names = [];
    for (row of this.rows) {
      var header = {};
      header['name'] = row['header'];
      header_names.push(header['name']);
      header['type'] = 'VARCHAR';
      header['unique'] = row['vunique'];
      table['headers'].push(header);

      rownum = 0;
      datas = [];
      
      for (i$ = 0; i$ < this.datarow.length; ++i$) {
        if (!(table['data'][rownum] instanceof Array)){
          table['data'][rownum] = [];
        }
        // Tangani kalau cuma value aja
        if (row.hasOwnProperty("vvalue")) {
          table['data'][rownum][colnum] = row["value"];
        } else {
          cellname = '' + row['data'] + this.datarow[i$];
          cell = this.sheet[this.sheetname]['sheetdict'][cellname];

          if (typeof cell !== "undefined") {            
            // DATA MERGE AND DATA CONTENT
            mergemap = this.sheet[this.sheetname]['mergemap'];
            mergetarget = mergemap[cellname];
            if (mergetarget) {
              cell.cstr = this.sheet[this.sheetname]['sheetdict'][mergetarget].cstr;
              cell.mtype = this.sheet[this.sheetname]['sheetdict'][mergetarget].mtype;
              table['data'][rownum][colnum] = cell.cstr;
            } else {
              table['data'][rownum][colnum] = cell.cstr;
            }
            datas.push(table['data'][rownum][colnum]);

            error = {};
            error['coordinate'] = cellname;

            // DATA TYPE IN DATABASE
            if (row['vtype'] == "int") {
              header['type'] = 'INT';
            } else if (row['vtype'] == "dbl") {
              header['type'] = 'DOUBLE'; 
            } else if (row['vtype'] == "txt") {
              header['type'] = 'TEXT'; 
            }

            // DATA TYPE CHECKER
            error['error'] = "type";
            // console.log(cellname + " <~ " + row['vtype'] + " <<>> " + cell.mtype);
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
            therange = decodeURIComponent(row['vrange']);

            // console.log(cellname + " <~ r: " + row['vrange']);
            if (therange.charAt(0) == "[" && therange.slice(-1) == "]") {
              console.log("ARRAY");
            // EX: ["text01","text02"] (JSONArray)
              if (!(therange.includes(cell.cstr.toString()))) {
                error['description'] = "Not in array of accepted string";
                console.log(error);
                return error;
              }
            } else if (therange.includes("-")) {
              console.log("BETWEEN");
            // EX: 100-2100 OR 10.5-1000
              values = therange.split("-");
              if (values[0] > values[1]) {
                error['description'] = "The between rule is not right";
                console.log(error);
                return error;
              } else {
                num = parseInt(cell.cstr.toString());
                // TO-DO: Check NaN
                if (num < values[0] || num > values[1]) {
                  error['description'] = "Values not in between";
                  console.log(error);
                  return error;
                }
              }
            } else if (therange.charAt(0) == "<") {
              console.log("LESS");
            // EX: <200 OR <=200
              num = parseInt(cell.cstr.toString());
              // TO-DO: Check NaN
              if (therange.charAt(1) == "=") {
                val = parseInt(therange.substr(2));
                if (!(num <= val)) {
                  error['description'] = "Values not in less equals than";
                  console.log(error);
                  return error;
                }
              } else {
                val = parseInt(therange.substr(1));
                if (!(num < val)) {
                  error['description'] = "Values not in less than";
                  console.log(error);
                  return error;
                }
              }
            } else if (therange.charAt(0) == ">") {
              console.log("GREATER");
            // EX: >200 OR >=200
              num = parseInt(cell.cstr.toString());
              // TO-DO: Check NaN
              if (therange.charAt(1) == "=") {
                val = parseInt(therange.substr(2));
                if (!(num >= val)) {
                  error['description'] = "Values not in greater equals than";
                  console.log(error);
                  return error;
                }
              } else {
                val = parseInt(therange.substr(1));
                if (!(num > val)) {
                  error['description'] = "Values not in greater than";
                  console.log(error);
                  return error;
                }            
              }
            } else if (therange.charAt(0) == "=") {
              console.log("EQUAL");
            // EX: =200
              val = parseInt(therange.substr(1));
              if (num != val) {
                error['description'] = "Values not in equals";
                console.log(error);
                return error;
              }
            } else {
              // KOSONG
            }

            // DATA RELATION CHECKER, kayanya bukan disini sih harusnya soalnya ngecek antar tabel
            // row['vrel']
            relValid = false;
            therel = decodeURIComponent(row['vrel']);
            error['error'] = "relation";

            if ((therel.charAt(0) == "[") && (therel.charAt(therel.length - 1) == "]")) {
              relValid = true; // Do Nothing

            } else if (therel.split(":").length == 2) {
              content = table['data'][rownum][colnum];
              relRange = this.RangeComponent(therel);

              for (r = relRange[1]; r <= relRange[3]; r++) {
                for (c = relRange[0]; c <= relRange[2]; c++) {
                  checkCell = this.sheet[this.sheetname]['sheetdict'][SocialCalc.rcColname(c) + r];
                  if (checkCell.cstr == content) {
                    relValid = true;
                  }
                }
              }
            } else {
              relValid = true;
            }

            if (!relValid) {          
              error['description'] = "Unrelated value detected";
              return error;
            }
          } else {
            table['data'][rownum][colnum] = "";
            datas.push(table['data'][rownum][colnum]);
          }
        }
        rownum += 1;
      }

      // Check unique-ness of data
      if (row['vunique']) {
        if ((new Set(datas)).size !== datas.length) {
          error['error'] = "unique";
          error['coordinate'] = row['data'];
          error['description'] = "`" + row["header"].trim() + "` values is not unique (within sheet)";
          return error;          
        }
        table['unique_vals'] = datas
      }

      // Database based relation check
      therel = decodeURIComponent(row['vrel']);
      if ((therel.charAt(0) == "[") && (therel.charAt(therel.length - 1) == "]")) {
        reldb = JSON.parse(therel)
        relcheck = {}
        relcheck["target"] = reldb[0];
        relcheck["column"] = reldb[1];
        relcheck["data"] = datas;
        relcheck["num"] = colnum;
        table['db_relations'].push(relcheck);
      }

      colnum += 1
    }

    // Check unique-ness of the label
    if ((new Set(header_names)).size !== header_names.length) {
      error['error'] = "label";
      error['coordinate'] = 'table';
      error['description'] = "Label name should be unique";
      return error;          
    }

    console.log(table);
    //
    //////////////////////////////////////////////////////////////////////
    return JSON.stringify(table);
  };
  Table.prototype.TupleDeserialize = function(sdata){
    return JSON.parse(sdata);
  };
  Table.prototype.SetColumnRange = function(startcol, endcol){
    this.startcol = startcol;
    this.endcol = endcol;
    this.affectedcol = []
    for (i = this.startcol; i <= this.endcol; i++) {
      this.affectedcol.push(i); 
    }
    if (this.rawdata !== undefined && this.rawdata !== null) {
      this.ParseData(this.rawdata);
    }
    //this.data = this.datarow;
    this.data = this.datarow[0] + ":" + this.datarow[(this.datarow.length - 1)]; 
  };
  Table.prototype.IsHasData = function(){
    return this.datarow.length > 0;
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
    data['affectedcol'] = this.affectedcol;
    data['rows'] = this.rows;
    data['range'] = this.range;
    data['name'] = this.name;

    return JSON.stringify(data);
  };
  Table.prototype.Deserialize = function(sdata){
    var data;
    data = JSON.parse(sdata);
    //console.log(data);
    this.title = data['title'];
    this.footnote = data['footnote'];
    this.header = data['header'];

    // KAYANYA DISINI AJA? MUNGKIN PERLU PAS SERIALIZE?
    this.data = data['data'];
    if (this.data instanceof Array) {
      this.datarow = this.data;
      this.data = JSON.stringify(this.data);
    } else {
      try {
        this.data = JSON.parse(this.data);
        this.datarow = this.data;
      } catch (e) {
        r = this.data.split(":");
        for (i = parseInt(r[0]); i <= parseInt(r[1]); i++) {
          this.datarow.push(i);
        }
      }
    }

    this.range = data['range'];
    this.startcol = data['startcol'];
    this.endcol = data['endcol'];
    this.affectedcol = data['affectedcol'];
    this.rows = data['rows'];
    this.name = data['name'];
    //console.log(this.rows);
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
    minval = Math.min.apply(Math, this.datarow);
    maxval = Math.max.apply(Math, this.datarow);
    // Super simple.... for now :'(
    return SocialCalc.rcColname(mincol) + minval + ":" + SocialCalc.rcColname(maxcol) + maxval;
  };
  Table.prototype.MapHeaderData = function(){
    var i$, to$, col, tempobj, j$, ref$, len$, h, results$ = [];
    this.rows = [];

    console.log("DEBUG HERE");
    console.log(this.range);
    console.log(this.range.length);
    console.log(this.startcol);
    console.log(this.endcol);
    if (this.range && !this.startcol && !this.endcol) {
      try {
        console.log("here");
        this.affectedcol = JSON.parse(this.range);
        console.log(this.affectedcol);
      } catch (e$) {
        console.log(e$);
        temp = this.RangeComponent(String(this.range));
        this.startcol = temp[0];
        this.endcol = temp[2];
        this.affectedcol = []
        for (i = this.startcol; i <= this.endcol; i++) {
          this.affectedcol.push(i); 
        }
      }
    }

    // Yang di for itu kolom karena dengan asumsi bahwa tabelnya headernya horizontal
    for (i$ = 0, to$ = this.affectedcol.length; i$ < to$; ++i$) {
      col = this.affectedcol[i$];
      tempobj = {};
      tempobj['header'] = "";
      for (j$ = 0, len$ = (ref$ = this.header).length; j$ < len$; ++j$) {
        h = ref$[j$];
        hcell = this.sheet[this.sheetname]['sheetdict'][SocialCalc.rcColname(col) + h];
        mergemap = this.sheet[this.sheetname]['mergemap'];
        mergetarget = mergemap[SocialCalc.rcColname(col) + h];
        if (mergetarget) {
          mcstr = this.sheet[this.sheetname]['sheetdict'][mergetarget].cstr;
          if (tempobj["header"].trim() != mcstr.trim()) {
            tempobj['header'] += mcstr + " ";
          }
        }
        if (hcell) {
          try {
            if (tempobj['header'].trim() != hcell.cstr.trim()) {
              tempobj['header'] += hcell.cstr + " ";
            }
          } catch (e) {
            tempobj['header'] += hcell.cstr + " ";
          }
        }
      }
      tempobj['header'] = tempobj['header'].trim();
      tempobj['data'] = SocialCalc.rcColname(col);
      tempobj['vtype'] = 'non';
      tempobj['vrange'] = '';
      tempobj['vrel'] = '';
      tempobj['vunique'] = false;
      results$.push(this.rows.push(tempobj));
    }
    if (this.range == "") {
      this.range = this.GetDataRange(this.startcol, this.endcol);
    }
    return results$;
  };
  Table.prototype.GetHTMLForm = function(number){
    var i, hdata, whole_table, title_div, begin_table, n, i$, len$, hd, table_start, table_label, table_data, table_validations, is_int, is_dbl, is_str, is_txt, is_bln, table_datatype, table_end, table_per_data, end_table;
    i = number; // Used when there are multiple tables
    hdata = this.rows;
    whole_table = "";
    title_div = "<div style=\"margin-left:8px;border:1px solid rgb(192,192,192);display:inline-block;\"><div><table style=\"padding-top: 15px;padding-bottom: 15px; padding-left:20px; padding-right:20px; width:100%;\"><tr><td width=\"50%\">" + "<strong>Table " + i + "</strong><br><br>Name <input id=\"t" + i + ".databaseName\" class=\"btn btn-default btn-xs\" type=\"text\" value=\"" + this.name + "\"></td>";
    title_div += "<td width=\"50%\" style=\"text-align: right;\"><input type=\"button\" value=\"Save\" onclick=\"window.SaveConfiguration(" + i + ");\" style=\"font-size:x-small;\"> <input type=\"button\" value=\"Add Column\" onclick=\"window.AddColumn(" + i + ")\" style=\"font-size:x-small;\"> <input type=\"button\" value=\"Add Value Col.\" onclick=\"window.AddValueColumn(" + i + ")\" style=\"font-size:x-small;\"> <input type=\"button\" onclick=\"window.DeleteTable(" + i + ");\" value=\"Delete\" style=\"font-size:x-small;\">";
    title_div += "<br><br>Data Row <input id=\"t" + i + ".databaseRange\" class=\"btn btn-default btn-xs\" style=\"max-width: 105px\" value=\"" + this.data + "\"></td></tr></table>";
    whole_table += title_div;
    begin_table = "<table style=\"border-top:1px solid rgb(192,192,192);padding-top:16px;\"><thead><tr><th>Label Name</th><th>Data Column</th><th>Type</th><th>Permitted Values</th><th>Relation</th><th>Unique</th><th></th></tr></thead>";
    whole_table += begin_table;
    n = 1;
    for (i$ = 0, len$ = hdata.length; i$ < len$; ++i$) {
      hd = hdata[i$];
      table_start = "<tr>";

      if (hd["vvalue"] === true) {
        table_label = "<td><input id=\"t" + i + ".databaseLabel." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + hd['header'] + "\" /></td>";
        table_data = "<td style=\"text-align: right;\">Static value:</td><td colspan=\"4\"> <input id=\"t" + i + ".databaseValue." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + hd['value'] + "\" /></td>";
        table_cdelete = "<td><a onclick=\"window.DelColumn(" + i + ", " + n + ")\"> [x] </a></td>"
        table_end = "</tr>";
        table_per_data = table_start + table_label + table_data + table_cdelete + table_end;
        whole_table += table_per_data;
      } else {
        table_label = "<td><input id=\"t" + i + ".databaseLabel." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + hd['header'] + "\" /></td>";
        table_data = "<td><input id=\"t" + i + ".databaseData." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" style=\"max-width: 85px\" value=\"" + hd['data'] + "\" /></td>";
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
        table_datatype = "<td><select id=\"t" + i + ".databaseType." + n + "\" size=\"1\" class=\"btn btn-default btn-xs\"><option " + is_non + " value=\"non\">None</option><option " + is_int + " value=\"int\">Integer</option><option " + is_dbl + " value=\"dbl\">Double</option><option " + is_str + " value=\"str\">String</option><option " + is_bln + " value=\"bln\">Boolean</option></select></td>";
        table_permitted = "<td><input id=\"t" + i + ".databasePermitted." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + decodeURIComponent(hd['vrange']).replace(/"/g, '&quot;') + "\" ></td>";
        table_relations = "<td><input id=\"t" + i + ".databaseRelation." + n + "\" onchange=\"\" class=\"btn btn-default btn-xs\" value=\"" + decodeURIComponent(hd['vrel']).replace(/"/g, '&quot;') + "\" style=\"max-width: 105px\"></td>"
        
        checked = ""
        if (hd['vunique']) { checked = "checked"; }
        table_isunique = "<td><center><input type=\"checkbox\" id=\"t" + i + ".databaseUnique." + n + "\" class=\"btn btn-default btn-xs\" onclick=\"window.UniqueCheck(" + i + ", " + n + ");\" value=\"\" " + checked + "></center></td>"
        table_cdelete = "<td><a onclick=\"window.DelColumn(" + i + ", " + n + ")\"> [x] </a></td>"

        table_validations = table_datatype + table_permitted + table_relations;
        table_end = "</tr>";
        table_per_data = table_start + table_label + table_data + table_validations + table_isunique + table_cdelete + table_end;
        whole_table += table_per_data;
      }
  
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