var PredictSheetRows, FeatureFormat, FeatureSheetRow, MyCell, MySheet, LoadSheet, rcColname;

rcColname = (function(c) {
  if (c > 702) c = 702; // maximum number of columns - ZZ
  if (c < 1) c = 1;
  var collow = (c - 1) % 26 + 65;
  var colhigh = Math.floor((c - 1) / 26);
  if (colhigh)
    return String.fromCharCode(colhigh + 64) + String.fromCharCode(collow);
  else
    return String.fromCharCode(collow);
});

PredictSheetRows = (function(){
  PredictSheetRows.displayName = 'PredictSheetRows';
  var prototype = PredictSheetRows.prototype, constructor = PredictSheetRows;
  function PredictSheetRows(){
    this.fea_row = new FeatureSheetRow;
  }
  PredictSheetRows.prototype.GenerateFromSheetFile = function(sheetdict, sc, ec, sr, er){
    // start here for support multi table cluster
    var strout, i$, own$ = {}.hasOwnProperty;
    strout = '';
    for (i$ in sheetdict) if (own$.call(sheetdict, i$)) {
      (fn$.call(this, i$, sheetdict[i$]));
    }
    return strout;
    function fn$(sheetname, mysheet){
      var feadict, i$, own$ = {}.hasOwnProperty;
      feadict = this.fea_row.GenerateSingularFeatureCrf(mysheet, sheetname, sc, ec, sr, er);
      for (i$ in feadict) if (own$.call(feadict, i$)) {
        (fn$.call(this, i$, feadict[i$]));
      }
      function fn$(row, feavec){
        var numrow;
        numrow = row - 1;
        strout += numrow + ' ';
        feavec.forEach(function(item){
          if (item === true) {
            return strout += '1 ';
          } else {
            return strout += '0 ';
          }
        });
        strout += 'Title\n';
      }
    }
  };
  return PredictSheetRows;
}());
FeatureSheetRow = (function(){
  FeatureSheetRow.displayName = 'FeatureSheetRow';
  var prototype = FeatureSheetRow.prototype, constructor = FeatureSheetRow;
  function FeatureSheetRow(){
    this.naset = ['(na)', 'n/a', '(n/a)', '(x)', '-', '--', 'z', '...'];
    this.spcharset = ['<', '#', '>', ';', '$'];
    this.myformat = new FeatureFormat;
    this.goodrowset = [];
  }
  FeatureSheetRow.prototype.GenerateSingularFeatureCrf = function(mysheet, sheetname, sc, ec, sr, er){
    var feadict, i$, to$, crow, rowcelldict, j$, to1$, ccol, mycell, blankflag;
    feadict = {};
    console.log("SC: " + sc);
    console.log("EC: " + ec);
    console.log("SR: " + sr);
    console.log("ER: " + er);
    // batesin barisnya disini bisa
    crow = parseInt(sr);
    while (crow <= parseInt(er)) {
    // for (i$ = 1, to$ = mysheet.nrownum; i$ <= to$; ++i$) {
      rowcelldict = {};
      // disini dibatesin dari col berapa sampe col berapanya
      ccol = parseInt(sc);
      while (ccol <= parseInt(ec)) {
      // for (j$ = 1, to1$ = mysheet.ncolnum; j$ <= to1$; ++j$) {
        if (mysheet.sheetdict[rcColname(ccol) + crow] !== undefined) {
          mycell = mysheet.sheetdict[rcColname(ccol) + crow];
          rowcelldict[ccol - 1] = mycell;
        }
        ccol++;
      }
      if (Object.keys(rowcelldict).length !== 0) {
        if (feadict.hasOwnProperty(crow - 1)) {
          blankflag = false;
        } else {
          blankflag = true;
        }
        feadict[crow] = this.GenerateFeatureByRowCrf(crow, rowcelldict, mysheet, blankflag);
      }
      crow++;
    }
    return feadict;
  };
  FeatureSheetRow.prototype.GenerateFeatureByRowCrf = function(crow, rowcelldict, mysheet, blankflag){
    var feavec, clinetxt, i$, own$ = {}.hasOwnProperty;
    feavec = [];
    clinetxt = '';
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    feavec.push(blankflag);
    feavec.push(this.FeatureHasMergeCell(crow, mysheet));
    feavec.push(this.FeatureReachRightBound(crow, rowcelldict, mysheet.maxcolnum));
    feavec.push(this.FeatureReachLeftBound(rowcelldict));
    feavec.push(this.FeatureIsOneColumn(rowcelldict));
    feavec.push(this.FeatureHasCenterAlignCell(crow, rowcelldict));
    feavec.push(this.FeatureHasLeftAlignCell(crow, rowcelldict));
    feavec.push(this.FeatureHasBoldFontCell(crow, rowcelldict));
    feavec.push(this.FeatureIndentation(clinetxt));
    feavec.push(this.FeatureStartWithTable(clinetxt));
    feavec.push(this.FeatureStartWithPunctation(clinetxt));
    feavec.push(this.FeatureNumberPercentHigh(rowcelldict));
    feavec.push(this.FeatureDigitalPercentHigh(rowcelldict));
    feavec.push(this.FeatureAlphabetaAllCapital(clinetxt));
    feavec.push(this.FeatureAlphabetaStartWithCapital(rowcelldict));
    feavec.push(this.FeatureAlphabetaStartWithLowercase(rowcelldict));
    feavec.push(this.FeatureAlphabetaCellnumPercentHigh(rowcelldict));
    feavec.push(this.FeatureAlphabetaPercentHigh(clinetxt));
    feavec.push(this.FeatureContainSpecialChar(clinetxt));
    feavec.push(this.FeatureContainColon(clinetxt));
    feavec.push(this.FeatureYearRangeCellnumHigh(rowcelldict));
    feavec.push(this.FeatureYearRangePercentHigh(rowcelldict));
    feavec.push(this.FeatureWordLengthHigh(rowcelldict));
    return feavec;
    function fn$(key, value){
      clinetxt += value.cstr + ' ';
    }
  };
  FeatureSheetRow.prototype.FeatureOneVariableTxt = function(predicate, rowname, flag){
    if (flag === true) {
      return this.myformat.OneVariable(predicate, rowname);
    }
    return null;
  };
  FeatureSheetRow.prototype.FeatureIsRow = function(rowname){
    return this.myformat.OneVariable('IsRow', rowname);
  };
  FeatureSheetRow.prototype.FeatureWordRepeatHigh = function(clinetxt, csheettxt){
    var wordarr, reptcount, wordcount, csheetcount, i$, to$, i;
    wordarr = clinetxt.split(/[^A-Za-z]/);
    reptcount = 0;
    wordcount = 0;
    csheetcount = [];
    csheettxt.forEach(function(x){
      csheetcount[x] = (csheetcount[x] || 0) + 1;
    });
    for (i$ = 0, to$ = wordarr.length - 1; i$ <= to$; ++i$) {
      i = i$;
      if (wordarr[i].length !== 0) {
        wordcount += 1;
        reptcount += csheetcount[cword];
      }
    }
    if (wordcount === 0) {
      return false;
    }
    if (reptcount / wordcount >= 2) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureWordLengthHigh = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    if (Object.keys(rowcelldict).length !== 1) {
      return false;
    }
    this.retVal = false;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    return this.retVal;
    function fn$(key, value){
      var cval;
      cval = value.cstr;
      if (cval.length > 40) {
        this.retVal = true;
      }
      return;
    }
  };
  FeatureSheetRow.prototype.FeatureIndentation = function(clinetxt){
    var i$, to$, i;
    for (i$ = 0, to$ = clinetxt.length - 1; i$ <= to$; ++i$) {
      i = i$;
      if (clinetxt[i] >= 'A' && clinetxt[i] <= 'Z') {
        break;
      }
      if (clinetxt[i] >= 'a' && clinetxt[i] <= 'z') {
        break;
      }
      if (clinetxt[i] >= '0' && clinetxt[i] <= '9') {
        break;
      }
    }
    if (i > 0) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureHasMergeCell = function(crow, mysheet){
    if (mysheet.mergerowdict[crow] !== undefined) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureReachRightBound = function(crow, rowcelldict, ncolnum){
    if (rowcelldict[ncolnum - 1] !== undefined) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureReachLeftBound = function(rowcelldict){
    if (rowcelldict[0] !== undefined) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureNumberPercentHigh = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    if (Object.keys(rowcelldict).length === 0) {
      return false;
    }
    this.digitalcount = 0;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    if (this.digitalcount / Object.keys(rowcelldict).length >= 0.6) {
      return true;
    }
    return false;
    function fn$(key, value){
      var cstr;
      cstr = value.cstr;
      if (this.hasDigits(cstr)) {
        this.digitalcount += 1;
      } else if (this.isNa(cstr)) {
        this.digitalcount += 1;
      }
    }
  };
  FeatureSheetRow.prototype.FeatureDigitalPercentHigh = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    if (Object.keys(rowcelldict).length === 0) {
      return false;
    }
    this.digitalcount = 0;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    if (this.digitalcount / Object.keys(rowcelldict).length >= 0.6) {
      return true;
    }
    return false;
    function fn$(key, value){
      var cstr;
      cstr = value.cstr;
      if (this.isNumber(cstr)) {
        this.digitalcount += 1;
      } else if (this.isNa(cstr)) {
        this.digitalcount += 1;
      }
    }
  };
  FeatureSheetRow.prototype.FeatureYearRangeCellnumHigh = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    if (Object.keys(rowcelldict).length === 0) {
      return false;
    }
    this.yearcount = 0;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    if (this.yearcount >= 3) {
      return true;
    }
    return false;
    function fn$(key, value){
      var cstr, digitarr, i$, to$, i;
      cstr = value.cstr;
      digitarr = this.getNumset(cstr);
      for (i$ = 0, to$ = digitarr.length - 1; i$ <= to$; ++i$) {
        i = i$;
        if (digitarr[i] >= 1800 && digitarr[i] <= 2300) {
          this.yearcount += 1;
        }
      }
    }
  };
  FeatureSheetRow.prototype.FeatureYearRangePercentHigh = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    if (Object.keys(rowcelldict).length === 0) {
      return false;
    }
    this.yearcount = 0;
    this.totalcount = 1;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    if (this.yearcount / this.totalcount >= 0.7) {
      return true;
    }
    return false;
    function fn$(key, value){
      var cstr, digitarr, i$, to$, i;
      cstr = value.cstr;
      digitarr = this.getNumset(cstr);
      this.totalcount += digitarr.length;
      for (i$ = 0, to$ = digitarr.length - 1; i$ <= to$; ++i$) {
        i = i$;
        if (digitarr[i] >= 1800 && digitarr[i] <= 2300) {
          this.yearcount += 1;
        }
      }
    }
  };
  FeatureSheetRow.prototype.FeatureAlphabetaStartWithCapital = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    return true;
    function fn$(key, value){
      var cstr, mtype;
      cstr = value.cstr;
      mtype = value.mtype;
      if (mtype === 'str' && cstr.length !== 0) {
        if (this.hasLetter(cstr) && !(cstr.charAt(0) >= 'A' && cstr.charAt(0) <= 'Z')) {
          return false;
        }
      }
    }
  };
  FeatureSheetRow.prototype.FeatureAlphabetaStartWithLowercase = function(rowcelldict){
    var keys, ccol, cstr;
    keys = Object.keys(rowcelldict);
    ccol = Math.min.apply(null, keys);
    cstr = rowcelldict[ccol].cstr;
    if (cstr.length === 0) {
      return false;
    }
    if (this.hasLetter(cstr) && (cstr.charAt(0) >= 'a' && cstr.charAt(0) <= 'z')) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureAlphabetaAllCapital = function(clinetxt){
    var capitalcount, i$, to$, i;
    capitalcount = 0;
    for (i$ = 0, to$ = clinetxt.length - 1; i$ <= to$; ++i$) {
      i = i$;
      if (clinetxt.charAt(i) >= 'A' && clinetxt.charAt(i) <= 'Z') {
        capitalcount += 1;
      } else if (clinetxt.charAt(i) >= 'a' && clinetxt.charAt(i) <= 'z') {
        return false;
      }
    }
    if (capitalcount > 0) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureAlphabetaCellnumPercentHigh = function(rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    this.count = 0;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    if (this.count / Object.keys(rowcelldict).length >= 0.6) {
      return true;
    }
    return false;
    function fn$(key, value){
      var cstr, mtype;
      cstr = value.cstr;
      mtype = value.mtype;
      if (mtype === 'str' && String(cstr).search(/[A-Za-z]/) === 0) {
        this.count += 1;
      }
    }
  };
  FeatureSheetRow.prototype.FeatureAlphabetaPercentHigh = function(clinetxt){
    var count, i$, to$, i;
    count = 0;
    for (i$ = 0, to$ = clinetxt.length - 1; i$ <= to$; ++i$) {
      i = i$;
      if (clinetxt.charAt(i) >= 'A' && clinetxt.charAt(i) <= 'Z') {
        count += 1;
      } else if (clinetxt.charAt(i) >= 'a' && clinetxt.charAt(i) <= 'z') {
        count += 1;
      }
    }
    if (count / clinetxt.length >= 0.6) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureContainColon = function(clinetxt){
    var check;
    check = parseInt(String(clinetxt).search(':'));
    if (check > -1) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureContainSpecialChar = function(clinetxt){
    var i$, to$, i, check;
    for (i$ = 0, to$ = clinetxt.length - 1; i$ <= to$; ++i$) {
      i = i$;
      check = parseInt(String(clinetxt.charAt(i)).search(/[\<#>;$]/));
      if (check > -1) {
        return true;
      }
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureIsOneColumn = function(rowcelldict){
    if (Object.keys(rowcelldict).length === 1) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureHasCenterAlignCell = function(crow, rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    this.ret = false;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    return this.ret;
    function fn$(key, value){
      if (value.centeralign_flag) {
        this.ret = true;
      }
    }
  };
  FeatureSheetRow.prototype.FeatureHasLeftAlignCell = function(rownum, rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    this.ret = false;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    return this.ret;
    function fn$(key, value){
      if (value.leftalign_flag) {
        this.ret = true;
      }
    }
  };
  FeatureSheetRow.prototype.FeatureHasBoldFontCell = function(rownum, rowcelldict){
    var i$, own$ = {}.hasOwnProperty;
    this.ret = false;
    for (i$ in rowcelldict) if (own$.call(rowcelldict, i$)) {
      (fn$.call(this, i$, rowcelldict[i$]));
    }
    return this.ret;
    function fn$(key, value){
      if (value.boldflag) {
        this.ret = true;
      }
    }
  };
  FeatureSheetRow.prototype.FeatureStartWithTable = function(clinetxt){
    if (clinetxt.length === 0) {
      return false;
    }
    if (this.startsWith(clinetxt.trim(), "Table")) {
      return true;
    }
    if (this.startsWith(clinetxt.trim(), "Tabel")) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureStartWithPunctation = function(clinetxt){
    var cchar;
    if (clinetxt.length === 0) {
      return false;
    }
    cchar = clinetxt.charAt(0);
    if (this.hasDigits(cchar)) {
      return false;
    }
    if (this.hasLetter(cchar)) {
      return false;
    }
    return true;
  };
  FeatureSheetRow.prototype.FeatureEndWithAnd = function(clinetxt){
    if (clinetxt.length === 0) {
      return false;
    }
    if (this.endsWith(clinetxt.trim().toLowerCase(), "and")) {
      return true;
    }
    if (this.endsWith(clinetxt.trim(), ",")) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureIsFirstRow = function(rownum){
    if (rownum === 0) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.FeatureIsLastRow = function(rownum, maxrownum){
    if (rownum === maxrownum) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.isNumber = function(cstr){
    return !isNaN(cstr);
  };
  FeatureSheetRow.prototype.hasLetter = function(cstr){
    if (String(cstr).match(/[A-Za-z]/)) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.hasDigits = function(cstr){
    if (String(cstr).match(/[0-9]/)) {
      return true;
    }
    return false;
  };
  FeatureSheetRow.prototype.isNa = function(cstr){
    this.naset.forEach(function(value){
      if (cstr === value) {
        return true;
      }
    });
    return false;
  };
  FeatureSheetRow.prototype.getNumset = function(cstr){
    var carr, numset;
    carr = String(cstr).split(' ');
    numset = [];
    carr.forEach(function(value){
      if (!isNaN(value)) {
        return numset.push(value);
      }
    });
    return numset;
  };
  FeatureSheetRow.prototype.getRowname = function(filename, csheetname, rownum){
    var pfilename, psheetname;
    pfilename = filename.replace('.', '_');
    psheetname = csheetname.replace(' ', '_');
    return 'S' + pfilename + '____' + psheetname + '____' + rownum;
  };
  FeatureSheetRow.prototype.parseFilename = function(filepath){
    var iarr;
    iarr = filepath.split('/');
    return iarr[iarr.length - 1];
  };
  FeatureSheetRow.prototype.startsWith = function(str, prefix){
    return str.indexOf(prefix) === 0;
  };
  FeatureSheetRow.prototype.endsWith = function(str, suffix){
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
  };
  return FeatureSheetRow;
}());
FeatureFormat = (function(){
  FeatureFormat.displayName = 'FeatureFormat';
  var prototype = FeatureFormat.prototype, constructor = FeatureFormat;
  FeatureFormat.prototype.OneVariable = function(name, var1){
    return name + '(' + vari1 + ')\n';
  };
  FeatureFormat.prototype.TwoVariable = function(name, vari1, vari2){
    return name + '(' + vari1 + ',' + vari2 + ')\n';
  };
  function FeatureFormat(){}
  return FeatureFormat;
}());
MySheet = (function(){
  MySheet.displayName = 'MySheet';
  var prototype = MySheet.prototype, constructor = MySheet;
  function MySheet(){
    this.sheetdict = {};
    this.mergerowdict = [];
    this.maxcolnum = 0;
    this.maxrownum = 0;
    this.nrownum = 0;
    this.ncolnum = 0;
    this.txt = '';
    this.mergestrarr = [];
    this.mergecellset = [];
    this.mergemap = [];
  }
  MySheet.prototype.GetCellsArray = function(){
    var cellArray = []
    for (var key in this.sheetdict) {
      if (!this.sheetdict.hasOwnProperty(key)) continue;

      var cell = this.sheetdict[key];
      cellArray.push([key, cell.x, cell.y, cell.w, cell.h, , ]);
    }
    return cellArray;
  };
  MySheet.prototype.AddMergeCell = function(row1, row2, col1, col2){
    var i$, rownum, j$, colnum, obj;
    for (i$ = row1; i$ <= row2; ++i$) {
      rownum = i$;
      this.mergerowdict[rownum] = true;
      for (j$ = col1; j$ <= col2; ++j$) {
        colnum = j$;
        obj = rcColname(colnum) + rownum;
        this.mergecellset.push(obj);
        if (rownum != row1 || colnum != col1) {
          this.mergemap[obj] = rcColname(col1) + row1;
        }
      }
    }
  };
  MySheet.prototype.InsertCell = function(rownum, colnum, X, Y, W, H, nrownum, ncolnum, mtype, indents, alignstyle, borderstyle, bgcolor, boldflag, height, italicflag, underlineflag, value){
    var mycell;
    this.nrownum = nrownum;
    this.ncolnum = ncolnum;
    if (rownum > this.maxrownum) {
      this.maxrownum = rownum;
    }
    if (colnum > this.maxcolnum) {
      this.maxcolnum = colnum;
    }
    mycell = new MyCell(X, Y, W, H, value, mtype, indents, alignstyle, boldflag, borderstyle, bgcolor, height, italicflag, underlineflag);
    this.sheetdict[rcColname(colnum) + rownum] = mycell;
    if (mtype === 'str') {
      return this.txt += value + ' ';
    }
  };
  return MySheet;
}());
MyCell = (function(){
  MyCell.displayName = 'MyCell';
  var prototype = MyCell.prototype, constructor = MyCell;
  function MyCell(X, Y, W, H, value, mtype, indents, alignstyle, boldflag, borderstyle, bgcolor, height, italicflag, underlineflag){
    // Cell Coordinate
    this.x = X;
    this.y = Y;
    this.w = W;
    this.h = H;

    this.cstr = value;
    this.mtype = mtype;
    this.indents = this.GetIndents(indents);
    this.centeralign_flag = false;
    this.leftalign_flag = false;
    this.rightalign_flag = false;
    if (alignstyle === 1) {
      this.leftalign_flag = true;
    } else if (alignstyle === 2) {
      this.centeralign_flag = true;
    } else if (alignstyle === 3) {
      this.rightalign_flag = true;
    }
    this.boldflag = false;
    if (boldflag === 1) {
      this.boldflag = true;
    }
    this.bottomborder = false;
    this.upperborder = false;
    this.leftborder = false;
    this.rightborder = false;
    if (borderstyle[0] === '1') {
      this.bottomborder = true;
    }
    if (borderstyle[1] === '1') {
      this.upperborder = true;
    }
    if (borderstyle[2] === '1') {
      this.leftborder = true;
    }
    if (borderstyle[3] === '1') {
      this.rightborder = true;
    }
    this.bgcolor = bgcolor;
    this.height = height;
    this.italic = italicflag;
    this.underline = underlineflag;
    this.mergecellcount = 1;
    this.startcol = 0;
  }
  MyCell.prototype.WritestrAlignstyle = function(){
    if (this.leftalign_flag) {
      return '1';
    } else if (this.centeralign_flag) {
      return '2';
    } else if (this.rightalign_flag) {
      return '3';
    }
    return '0';
  };
  MyCell.prototype.WritestrBordstyle = function(){
    var cstr;
    cstr = '';
    if (this.bottomborder) {
      cstr += '1';
    } else {
      cstr += '0';
    }
    if (this.upperborder) {
      cstr += '1';
    } else {
      cstr += '0';
    }
    if (this.leftborder) {
      cstr += '1';
    } else {
      cstr += '0';
    }
    if (this.rightborder) {
      cstr += '1';
    } else {
      cstr += '0';
    }
    return cstr;
  };
  MyCell.prototype.GetIndents = function(indents){
    var i$, to$, i;
    if (this.cstr.length === 0) {
      return 0;
    }
    for (i$ = 0, to$ = this.cstr.length - 1; i$ <= to$; ++i$) {
      i = i$;
      if (this.cstr.charAt(i === ' ') || !!this.cstr.charAt(i).match(/^[.,:!?]/)) {
        continue;
      } else {
        break;
      }
    }
    return i + indents * 2;
  };
  return MyCell;
}());
LoadSheet = (function(){
  LoadSheet.displayName = 'LoadSheet';
  var prototype = LoadSheet.prototype, constructor = LoadSheet;
  function LoadSheet(spreadsheet){
    this.wb = spreadsheet;
  }
  LoadSheet.prototype.LoadSheetDict = function(){
    var sheetdict, cmysheet, str, i$, to$, rownum, j$, to1$, colnum, cellName, cell, cellType, cStr, cellDType, cellAttr, row1, row2, col1, col2, indents, alignstyle, borderstyle, bgcolor, boldflag, height, italicflag, underlineflag;
    sheetdict = {};
    cmysheet = new MySheet;
    str = '';

    curY = 0;
    nextY = 0;
    for (i$ = 1, to$ = this.wb.sheet.LastRow(); i$ <= to$; ++i$) {
      rownum = i$;

      rh = this.wb.sheet.rowattribs.height[rownum];
      if (rh === undefined) { rh = 15; } //TO-DO if default value changed!
      curY += parseInt(nextY);
      nextY = parseInt(rh);
      curX = 0;
      nextX = 0;

      for (j$ = 1, to1$ = this.wb.sheet.LastCol(); j$ <= to1$; ++j$) {
        colnum = j$;

        cw = this.wb.sheet.colattribs.width[rcColname(colnum)];
        if (cw === undefined) { cw = 80; } //TO-DO if default value changed!
        curX += parseInt(nextX);
        nextX = parseInt(cw);

        //console.log("Cell Coord: [" + curX + ", "+ curY + "]")

        cellName = rcColname(colnum) + rownum;

        cell = this.wb.sheet.GetAssuredCell(cellName);
        cellType = this.GetValueType(cell.valuetype);

        // console.log(cell)

        if (cellType > 0 || cellType < 5) {
          cStr = cell.datavalue;
          cellDType = this.GetDataType(cell.datatype, cStr);
          cellAttr = this.wb.sheet.EncodeCellAttributes(cellName);

          addX = 0;
          addY = 0;
          if (cellAttr.rowspan.val > 1 || cellAttr.colspan.val > 1) {
            row1 = rownum;
            row2 = rownum + cellAttr.rowspan.val - 1;
            col1 = colnum;
            col2 = colnum + cellAttr.colspan.val - 1;
            cmysheet.AddMergeCell(row1, row2, col1, col2);

            for (var rs = 1; rs < cellAttr.rowspan.val; rs++) {
              rsh = this.wb.sheet.rowattribs.height[rownum + rs];
              if (rsh === undefined) { rsh = 15; } //TO-DO if default value changed!
              addY += parseInt(rsh);
            }

            for (var cs = 1; cs < cellAttr.colspan.val; cs++) {
              csh = this.wb.sheet.colattribs.width[rcColname(colnum + cs)];
              if (csh === undefined) { csh = 80; } //TO-DO if default value changed!
              addX += parseInt(csh);
            }
          }
          if (cellDType !== null) {
            indents = parseInt(this.FeatureIndentation(cellAttr));
            alignstyle = parseInt(this.FeatureAlignStyle(cellAttr));
            borderstyle = this.FeatureBorderStyle(cellAttr);
            bgcolor = this.FeatureFontBgcolor(cellAttr);
            boldflag = parseInt(this.FeatureFontBold(cellAttr));
            height = parseInt(this.FeatureFontHeight(cellAttr));
            italicflag = parseInt(this.FeatureFontItalic(cellAttr));
            underlineflag = parseInt(this.FeatureFontUnderline(cellAttr));
            cmysheet.InsertCell(rownum, colnum, curX, curY, (nextX + addX), (nextY + addY), this.wb.sheet.LastRow(), this.wb.sheet.LastCol(), cellDType, indents, alignstyle, borderstyle, bgcolor, boldflag, height, italicflag, underlineflag, cStr);
          }
        }
      }
    }
    sheetdict['Sheet1'] = cmysheet;
    return sheetdict;
  };
  LoadSheet.prototype.GetValueType = function(type){
    var ct;
    switch (type) {
    case 't':
      ct = 1;
      break;
    case 'n':
      ct = 2;
      break;
    case 'nd':
      ct = 3;
      break;
    case 'nl':
      ct = 4;
      break;
    case 'e':
      ct = 5;
      break;
    case 'b':
      ct = 6;
      break;
    default:
      ct = 0;
    }
    return ct;
  };
  LoadSheet.prototype.GetDataType = function(type, value){
    var dtype;
    dtype = null;
    switch (type) {
    case 't':
    case 'f':
      dtype = 'str';
      break;
    case 'v':
      if (value % 1 === 0) {
        dtype = 'int';
      } else {
        dtype = 'float';
      }
      break;
    case 'c':
      dtype = 'str';
      break;
    default:
      dtype = null;
    }
    return dtype;
  };
  LoadSheet.prototype.FeatureIndentation = function(cellAttr){
    var val, unit;
    if (cellAttr.padleft.def) {
      return 0;
    } else {
      val = cellAttr.padleft.val;
      unit = val.substring(val.length - 2);
      if (unit === 'pt') {
        return val.substring(0, val.length - 2);
      } else if (unit === 'px') {
        return val.substring(0, val.length - 2) * 1.3333;
      }
    }
  };
  LoadSheet.prototype.FeatureAlignStyle = function(cellAttr){
    if (cellAttr.alignhoriz.def) {
      return '1';
    } else {
      switch (cellAttr.alignhoriz.val) {
      case 'left':
        return '1';
      case 'center':
        return '2';
      case 'right':
        return '3';
      default:
        return '1';
      }
    }
  };
  LoadSheet.prototype.FeatureFontBold = function(cellAttr){
    if (cellAttr.fontlook.def) {
      return '0';
    } else {
      switch (cellAttr.fontlook.val) {
      case 'normal bold':
        return '1';
      case 'italic bold':
        return '1';
      default:
        return '0';
      }
    }
  };
  LoadSheet.prototype.FeatureFontHeight = function(cellAttr){
    var val, unit;
    if (cellAttr.fontsize.def) {
      return 10;
    } else {
      val = cellAttr.fontsize.val;
      unit = val.substring(val.length - 2);
      if (unit === 'pt') {
        return val.substring(0, val.length - 2);
      } else if (unit === 'px') {
        return val.substring(0, val.length - 2) * 0.75;
      } else {
        switch (cellAttr.fontsize.val) {
        case 'x-small':
          return 8;
        case 'small':
          return 10;
        case 'medium':
          return 12;
        case 'large':
          return 14;
        case 'x-large':
          return 18;
        }
      }
    }
  };
  LoadSheet.prototype.FeatureFontUnderline = function(cellAttr){
    return '0';
  };
  LoadSheet.prototype.FeatureFontItalic = function(cellAttr){
    if (cellAttr.fontlook.def) {
      return '0';
    } else {
      switch (cellAttr.fontlook.val) {
      case 'italic normal':
        return '1';
      case 'italic bold':
        return '1';
      default:
        return '0';
      }
    }
  };
  LoadSheet.prototype.FeatureFontBgcolor = function(cellAttr){
    return cellAttr.bgcolor.val;
  };
  LoadSheet.prototype.FeatureBorderStyle = function(cellAttr){
    var str;
    str = '';
    if (cellAttr.bt.val === '') {
      str += '0';
    } else {
      str += '1';
    }
    if (cellAttr.bb.val === '') {
      str += '0';
    } else {
      str += '1';
    }
    if (cellAttr.bl.val === '') {
      str += '0';
    } else {
      str += '1';
    }
    if (cellAttr.br.val === '') {
      str += '0';
    } else {
      str += '1';
    }
    return str;
  };
  return LoadSheet;
}());

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {LoadSheet: LoadSheet, PredictSheetRows: PredictSheetRows};
}