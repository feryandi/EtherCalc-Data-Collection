## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"\" style=\"font-size:x-small;\"></td></tr></table>"

  table_template = "<div style=\"margin-left:8px;border:1px solid rgb(192,192,192);display:inline-block;\"><div><center><h4>Table 1</h4></center></div><div><table style=\"border-top:1px solid rgb(192,192,192);padding-top:16px;\"><thead><tr><th>Label Name</th><th>Data Range</th><th>Type Validation</th><th>Range Validation</th><th>Relation Validation</th></tr></thead><tr><td><input id=\"%id.t1.databaseLabel1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><input id=\"%id.t1.databaseData1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><select id=\"%id.t1.databaseTypeV1\" size=\"1\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"><option selected>None</option><option>String</option><option>Integer</option></select></td><td><input id=\"%id.t1.databaseRangeV1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><input id=\"%id.t1.databaseRelationV1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td></tr></table></div></div>"

  class PredictSheetRows
    (null) ->
      @fea_row = new FeatureSheetRow

    GenerateFromSheetFile: ->
      strout = ''
      loadsheet = new LoadSheet SocialCalc.GetSpreadsheetControlObject!
      sheetdict = loadsheet.LoadSheetDict!

      for own let sheetname, mysheet of sheetdict
        feadict = @fea_row.GenerateSingularFeatureCrf mysheet, sheetname

        for own let row, feavec of feadict
          numrow = row - 1
          strout += numrow + ' '
          feavec.forEach (item) ->
            if item == true
              strout += '1 '
            else
              strout += '0 '
          strout += 'Title\n'
      return strout


  class FeatureSheetRow
    (null) ->
      @naset = ['(na)', 'n/a', '(n/a)', '(x)', '-', '--', 'z', '...']
      @spcharset = ['<', '#', '>', ';', '$'] #notused because using regex
      @myformat = new FeatureFormat
      @goodrowset = []

    GenerateSingularFeatureCrf: (mysheet, sheetname) ->
      feadict = {}
      for crow from 1 to mysheet.nrownum
        rowcelldict = {}
        for ccol from 1 to mysheet.ncolnum
          if (mysheet.sheetdict[SocialCalc.rcColname(ccol) + crow]) != undefined
            mycell = mysheet.sheetdict[SocialCalc.rcColname(ccol) + crow]
            rowcelldict[ccol-1] = mycell
            #console.log("(" + SocialCalc.rcColname(ccol) + crow + ")[" + (ccol-1) + "] ~ " + rowcelldict[ccol-1].cstr)
        if Object.keys(rowcelldict).length != 0
          if feadict.hasOwnProperty crow - 1
            blankflag = false
          else
            blankflag = true
          feadict[crow] = @GenerateFeatureByRowCrf crow, rowcelldict, mysheet, blankflag
      return feadict

    GenerateFeatureByRowCrf: (crow, rowcelldict, mysheet, blankflag) ->
      feavec = []        
      clinetxt = ''

      for own let key, value of rowcelldict
        clinetxt += value.cstr + ' '      

      # layout features
      feavec.push blankflag #1
      feavec.push @FeatureHasMergeCell crow, mysheet #2
      feavec.push @FeatureReachRightBound crow, rowcelldict, mysheet.maxcolnum #3
      feavec.push @FeatureReachLeftBound rowcelldict #4
      feavec.push @FeatureIsOneColumn rowcelldict #5
      feavec.push @FeatureHasCenterAlignCell crow, rowcelldict #6
      feavec.push @FeatureHasLeftAlignCell crow, rowcelldict #7
      feavec.push @FeatureHasBoldFontCell crow, rowcelldict #8
      feavec.push @FeatureIndentation clinetxt #9
      # textual features
      feavec.push @FeatureStartWithTable clinetxt #10
      feavec.push @FeatureStartWithPunctation clinetxt #11
      feavec.push @FeatureNumberPercentHigh rowcelldict #12
      feavec.push @FeatureDigitalPercentHigh rowcelldict #13
      feavec.push @FeatureAlphabetaAllCapital clinetxt #14
      feavec.push @FeatureAlphabetaStartWithCapital rowcelldict #15
      feavec.push @FeatureAlphabetaStartWithLowercase rowcelldict #16
      feavec.push @FeatureAlphabetaCellnumPercentHigh rowcelldict #17
      feavec.push @FeatureAlphabetaPercentHigh clinetxt #18
      feavec.push @FeatureContainSpecialChar clinetxt #19
      feavec.push @FeatureContainColon clinetxt #20
      feavec.push @FeatureYearRangeCellnumHigh rowcelldict #21
      feavec.push @FeatureYearRangePercentHigh rowcelldict #22
      feavec.push @FeatureWordLengthHigh rowcelldict #23!!!!!!
      return feavec

    FeatureOneVariableTxt: (predicate, rowname, flag) ->
      if flag == true
        return @myformat.OneVariable predicate, rowname
      return null

    #########################################################
    ####    row features
    #########################################################

    FeatureIsRow: (rowname) ->
      return @myformat.OneVariable 'IsRow', rowname

    FeatureWordRepeatHigh: (clinetxt, csheettxt) ->
      wordarr = clinetxt.split /[^A-Za-z]/
      reptcount = 0
      wordcount = 0

      csheetcount = []
      csheettxt.forEach (x) -> 
        csheetcount[x] = (csheetcount[x] || 0) + 1
        return

      for i from 0 to wordarr.length-1
        if wordarr[i].length != 0
          wordcount += 1
          reptcount += csheetcount[cword]
      if wordcount == 0
        return false
      if reptcount/wordcount >= 2
        return true
      return false

    FeatureWordLengthHigh: (rowcelldict) ->
      if Object.keys(rowcelldict).length != 1
        return false
      this.retVal = false
      for own let key, value of rowcelldict
        cval = value.cstr
        if cval.length > 40
          this.retVal = true
        return
      return this.retVal

    FeatureIndentation: (clinetxt) ->
      for i from 0 to clinetxt.length-1
        if clinetxt[i] >= 'A' and clinetxt[i] <= 'Z'
          break
        if clinetxt[i] >= 'a' and clinetxt[i]<= 'z'
          break
        if clinetxt[i] >= '0' and clinetxt[i] <= '9'
          break
      if i > 0
        return true
      return false

    FeatureHasMergeCell: (crow, mysheet) ->      
      if mysheet.mergerowdict[crow] != undefined
        return true
      return false

    FeatureReachRightBound: (crow, rowcelldict, ncolnum) ->
      if rowcelldict[ncolnum-1] != undefined
        return true
      return false
    
    FeatureReachLeftBound: (rowcelldict) ->
      if rowcelldict[0] != undefined
        return true
      return false

    FeatureNumberPercentHigh: (rowcelldict) ->
      if Object.keys(rowcelldict).length == 0
        return false
      this.digitalcount = 0
      for own let key, value of rowcelldict
        cstr = value.cstr
        if @hasDigits cstr
          this.digitalcount += 1
        else if @isNa cstr
          this.digitalcount += 1
      if this.digitalcount/(Object.keys(rowcelldict).length) >= 0.6
          return true
      return false

    FeatureDigitalPercentHigh: (rowcelldict) ->
      if Object.keys(rowcelldict).length == 0
        return false
      this.digitalcount = 0
      for own let key, value of rowcelldict
        cstr = value.cstr
        if @isNumber cstr
          this.digitalcount += 1
        else if @isNa cstr
          this.digitalcount += 1
      if this.digitalcount/(Object.keys(rowcelldict).length) >= 0.6
          return true
      return false

    FeatureYearRangeCellnumHigh: (rowcelldict) ->
      if Object.keys(rowcelldict).length == 0
        return false
      this.yearcount = 0
      for own let key, value of rowcelldict
        cstr = value.cstr
        digitarr = @getNumset cstr
        for i from 0 to digitarr.length-1
          if (digitarr[i] >= 1800) and (digitarr[i] <= 2300)
            this.yearcount += 1
      if this.yearcount >= 3
        return true
      return false

    FeatureYearRangePercentHigh: (rowcelldict) ->
      if Object.keys(rowcelldict).length == 0
        return false
      this.yearcount = 0
      this.totalcount = 1
      for own let key, value of rowcelldict
        cstr = value.cstr
        digitarr = @getNumset cstr
        this.totalcount += digitarr.length
        for i from 0 to digitarr.length-1          
          if (digitarr[i] >= 1800) and (digitarr[i] <= 2300)
            this.yearcount += 1
      if this.yearcount/this.totalcount >= 0.7
        return true
      return false

    FeatureAlphabetaStartWithCapital: (rowcelldict) ->
      for own let key, value of rowcelldict
        cstr = value.cstr
        mtype = value.mtype
        if mtype == 'str' and cstr.length != 0
          if @hasLetter cstr and !((cstr.charAt 0) >= 'A' and (cstr.charAt 0) <= 'Z')
            return false
      return true
      
    FeatureAlphabetaStartWithLowercase: (rowcelldict) ->
      keys = Object.keys rowcelldict
      ccol = Math.min.apply null, keys
      cstr = rowcelldict[ccol].cstr

      if cstr.length == 0
        return false
      if @hasLetter cstr and ((cstr.charAt 0)>='a' and (cstr.charAt 0)<='z')
        return true
      return false

    FeatureAlphabetaAllCapital: (clinetxt) ->
      capitalcount = 0
      for i from 0 to clinetxt.length-1
        if (clinetxt.charAt i) >= 'A' and (clinetxt.charAt i) <= 'Z'
          capitalcount += 1
        else if (clinetxt.charAt i) >= 'a' and (clinetxt.charAt i) <= 'z'
          return false
      if capitalcount > 0
        return true
      return false
    
    FeatureAlphabetaCellnumPercentHigh: (rowcelldict) ->
      this.count = 0
      for own let key, value of rowcelldict
        cstr = value.cstr
        mtype = value.mtype
        if mtype == 'str' and (String(cstr).search(/[A-Za-z]/) == 0)
          this.count += 1
      if this.count/(Object.keys(rowcelldict).length) >= 0.6
        return true
      return false
     
    FeatureAlphabetaPercentHigh: (clinetxt) ->
      count = 0
      for i from 0 to clinetxt.length-1
        if (clinetxt.charAt i) >= 'A' and (clinetxt.charAt i) <= 'Z'
          count += 1
        else if (clinetxt.charAt i) >= 'a' and (clinetxt.charAt i) <= 'z'
          count += 1
      if count/clinetxt.length >= 0.6
        return true
      return false

    FeatureContainColon: (clinetxt) ->
      check = parseInt(String(clinetxt).search ':')
      if check > -1
        return true
      return false

    FeatureContainSpecialChar: (clinetxt) ->
      for i from 0 to clinetxt.length-1
        check = parseInt(String(clinetxt.charAt i).search /[\<#>;$]/)
        if check > -1
          return true
      return false
    
    FeatureIsOneColumn: (rowcelldict) ->
      if Object.keys(rowcelldict).length == 1
        return true
      return false

    FeatureHasCenterAlignCell: (crow, rowcelldict) ->
      this.ret = false
      for own let key, value of rowcelldict
        if value.centeralign_flag
          this.ret = true
      return this.ret
    
    FeatureHasLeftAlignCell: (rownum, rowcelldict) ->
      this.ret = false
      for own let key, value of rowcelldict
        if value.leftalign_flag
          this.ret = true
      return this.ret

    FeatureHasBoldFontCell: (rownum, rowcelldict) ->
      this.ret = false
      for own let key, value of rowcelldict
        if value.boldflag
          this.ret = true
      return this.ret

    FeatureStartWithTable: (clinetxt) ->
      if clinetxt.length == 0
        return false
      if @startsWith clinetxt.trim!, "Table"
        return true
      if @startsWith clinetxt.trim!, "Tabel"
        return true
      return false

    FeatureStartWithPunctation: (clinetxt) ->
      if clinetxt.length == 0
        return false
      cchar = clinetxt.charAt 0
      if @hasDigits cchar
        return false
      if @hasLetter cchar
        return false
      return true

    FeatureEndWithAnd: (clinetxt) ->
      if clinetxt.length == 0
        return false
      if @endsWith (clinetxt.trim!).toLowerCase!, "and"
        return true
      if @endsWith clinetxt.trim!, ","
        return true
      return false

    FeatureIsFirstRow: (rownum) ->
      if rownum == 0
        return true
      return false
    
    FeatureIsLastRow: (rownum, maxrownum) ->
      if rownum == maxrownum
        return true
      return false

    #########################################################    

    isNumber: (cstr) ->
      return !(isNaN cstr)

    hasLetter: (cstr) ->
      if String(cstr).match /[A-Za-z]/
        return true
      return false

    hasDigits: (cstr) ->
      if String(cstr).match /[0-9]/
        return true
      return false
    
    isNa: (cstr) ->
      @naset.forEach (value) ->
        if cstr == value
          return true
      return false
    
    getNumset: (cstr) ->
      carr = String(cstr).split(' ')
      numset = []
      carr.forEach (value) ->
        if !(isNaN value)
          numset.push(value)
      return numset

    getRowname: (filename, csheetname, rownum) ->
      pfilename = filename.replace('.', '_')
      psheetname = csheetname.replace(' ', '_')
      return 'S' + pfilename + '____' + psheetname + '____' + rownum
    
    parseFilename: (filepath) ->
      iarr = filepath.split('/')
      return iarr[iarr.length-1]

    startsWith: (str, prefix) ->
      return (str.indexOf prefix) == 0

    endsWith: (str, suffix) ->
      return (str.indexOf suffix, (str.length - suffix.length)) != -1

  class FeatureFormat
    OneVariable: (name, var1) ->
      return name + '(' + vari1 + ')\n'
    TwoVariable: (name, vari1, vari2) ->
      return name + '(' + vari1 + ',' + vari2 + ')\n'

  ### DEFAULT VALUE MASIH BISA DIGANTI TERNYATA AAAA!!! ###

  class MySheet
    (null) ->
      @sheetdict = {}
      @mergerowdict = []
      @maxcolnum = 0
      @maxrownum = 0
      @nrownum = 0 
      @ncolnum = 0
       
      @txt = ''
       
      @mergestrarr = []
      @mergecellset = []

    AddMergeCell: (row1, row2, col1, col2) ->
      for rownum from row1 to row2
        @mergerowdict[rownum] = true
        for colnum from col1 to col2
          obj = SocialCalc.rcColname(colnum) + rownum
          @mergecellset.push obj
      return

    InsertCell: (rownum, colnum, nrownum, ncolnum, mtype, indents, alignstyle, borderstyle, bgcolor, boldflag, height, italicflag, underlineflag, value) ->
      @nrownum = nrownum
      @ncolnum = ncolnum
      if rownum > @maxrownum
          @maxrownum = rownum
      if colnum > @maxcolnum
          @maxcolnum = colnum
      
      mycell = new MyCell value, mtype, indents, alignstyle, boldflag, borderstyle, bgcolor, height, italicflag, underlineflag

      @sheetdict[SocialCalc.rcColname(colnum) + rownum] = mycell
      if mtype == 'str'
          @txt += value + ' '

  class MyCell
    (value, mtype, indents, alignstyle, boldflag, borderstyle, bgcolor, height, italicflag, underlineflag) ->
      @cstr = value
      @mtype = mtype
      @indents = @GetIndents(indents)
            
      @centeralign_flag = false
      @leftalign_flag = false
      @rightalign_flag = false

      if alignstyle == 1
        @leftalign_flag = true
      else if alignstyle == 2
        @centeralign_flag = true
      else if alignstyle == 3
        @rightalign_flag = true
      
      @boldflag = false
      if boldflag == 1
          @boldflag = true
      
      @bottomborder = false
      @upperborder = false 
      @leftborder = false
      @rightborder = false

      if borderstyle[0] == '1'
          @bottomborder = true
      if borderstyle[1] == '1'
          @upperborder = true
      if borderstyle[2] == '1'
          @leftborder = true
      if borderstyle[3] == '1'
          @rightborder = true
          
      @bgcolor = bgcolor
      @height = height
      @italic = italicflag
      @underline = underlineflag
      
      @mergecellcount = 1
      @startcol = 0

    WritestrAlignstyle: ->
      if @leftalign_flag
        return '1'
      else if @centeralign_flag
        return '2'
      else if @rightalign_flag
        return '3'
      return '0'

    WritestrBordstyle: ->
      cstr = ''
      if @bottomborder
        cstr += '1'
      else
        cstr += '0'
      if @upperborder
        cstr += '1'
      else
        cstr += '0'
      if @leftborder
        cstr += '1'
      else
        cstr += '0'
      if @rightborder
        cstr += '1'
      else
        cstr += '0'
      return cstr  
        
    GetIndents: (indents) ->
      if @cstr.length == 0
        return 0
      for i from 0 to @cstr.length-1
        if @cstr.charAt i == ' ' or (!!(@cstr.charAt i).match /^[.,:!?]/)
          continue
        else
          break
      return i+indents*2


  class LoadSheet
    (spreadsheet) ->
      @wb = spreadsheet
    LoadSheetDict: ->
      sheetdict = {}
      cmysheet = new MySheet

      str = ''
      for rownum from 1 to @wb.sheet.LastRow!
        for colnum from 1 to @wb.sheet.LastCol!
          cellName = SocialCalc.rcColname(colnum) + rownum
          cell = @wb.sheet.GetAssuredCell(cellName)
          cellType = @GetValueType cell.valuetype

          if cellType > 0 or cellType < 5
            cStr = cell.datavalue
            cellDType = @GetDataType cell.datatype, cStr
            cellAttr = @wb.sheet.EncodeCellAttributes cellName

            if cellAttr.rowspan.val > 1 or cellAttr.colspan.val > 1
              row1 = rownum
              row2 = rownum + cellAttr.rowspan.val - 1
              col1 = colnum
              col2 = colnum + cellAttr.colspan.val - 1
              cmysheet.AddMergeCell row1, row2, col1, col2

            if cellDType != null
              indents = parseInt @FeatureIndentation cellAttr
              alignstyle = parseInt @FeatureAlignStyle cellAttr
              borderstyle = @FeatureBorderStyle cellAttr
              bgcolor = @FeatureFontBgcolor cellAttr
              boldflag = parseInt @FeatureFontBold cellAttr
              height = parseInt @FeatureFontHeight cellAttr
              italicflag = parseInt @FeatureFontItalic cellAttr
              underlineflag = parseInt @FeatureFontUnderline cellAttr

              cmysheet.InsertCell rownum, colnum, @wb.sheet.LastRow!, @wb.sheet.LastCol!, cellDType, indents, alignstyle, borderstyle, bgcolor, boldflag, height, italicflag, underlineflag, cStr

      sheetdict['Sheet1'] = cmysheet ## BELUM BAKAL MAU SUPPORT MULTI-SHEET
      #TADI SIH OK, DENGAN JIKA CELL TSB KOSONG MAKA DILEWAT
      return sheetdict

    GetValueType: (type) ->
      switch type
        case 't'  then ct = 1
        case 'n'  then ct = 2
        case 'nd' then ct = 3
        case 'nl' then ct = 4
        case 'e'  then ct = 5
        case 'b'  then ct = 6
        default ct = 0
      return ct

    GetDataType: (type, value) ->
      dtype = null
      switch type
        case 't' then dtype = 'str'
        case 'v' 
          if value % 1 == 0
            dtype = 'int'
          else 
            dtype = 'float'
        case 'c' then dtype = 'str'
        default dtype = null
      return dtype

    FeatureIndentation: (cellAttr) ->
      ## Karena sepertinya ga bisa pake tab, lihat padding
      if cellAttr.padleft.def
        return 0
      else
        val = cellAttr.padleft.val
        unit = val.substring val.length-2

        if unit == 'pt'
          return val.substring 0, val.length-2
        else if unit == 'px'
          return (val.substring 0, val.length-2) * 1.3333

    FeatureAlignStyle: (cellAttr) ->
      if cellAttr.alignhoriz.def
        return '1' # default: Left
      else
        switch cellAttr.alignhoriz.val
          case 'left' then return '1'
          case 'center' then return '2'
          case 'right' then return '3'
          default return '1'

    FeatureFontBold: (cellAttr) ->
      if cellAttr.fontlook.def
        return '0' # default: not bold
      else
        switch cellAttr.fontlook.val
          case 'normal bold' then return '1'
          case 'italic bold' then return '1'
          default return '0'

    FeatureFontHeight: (cellAttr) ->
      if cellAttr.fontsize.def
        return 10 # default: 10pt
      else
        val = cellAttr.fontsize.val
        unit = val.substring val.length-2

        if unit == 'pt'
          return val.substring 0, val.length-2
        else if unit == 'px'
          return (val.substring 0, val.length-2) * 0.75
        else 
          switch cellAttr.fontsize.val
            case 'x-small' then return 8
            case 'small' then return 10
            case 'medium' then return 12
            case 'large' then return 14
            case 'x-large' then return 18

    FeatureFontUnderline: (cellAttr) ->
      ## Tidak menemukan underline
      return '0'

    FeatureFontItalic: (cellAttr) ->
      if cellAttr.fontlook.def
        return '0' # default: not bold
      else
        switch cellAttr.fontlook.val
          case 'italic normal' then return '1'
          case 'italic bold' then return '1'
          default return '0'

    FeatureFontBgcolor: (cellAttr) ->
      ## Sementara ini dulu deh...
      return cellAttr.bgcolor.val

    FeatureBorderStyle: (cellAttr) ->
      str = ''
      if cellAttr.bt.val == ''
        str += '0'
      else 
        str += '1'
      if cellAttr.bb.val == ''
        str += '0'
      else 
        str += '1'
      if cellAttr.bl.val == ''
        str += '0'
      else 
        str += '1'
      if cellAttr.br.val == ''
        str += '0'
      else 
        str += '1'
      return str

  window.DatabaseOnClick = !(s, t) ->
    pr = new PredictSheetRows
    dictTxt = JSON.stringify pr.GenerateFromSheetFile!
    gview = spreadsheet.views.database.element
    gview.innerHTML = dictTxt
    return

  window.Synchronize = !(s, t) ->
    pr = new PredictSheetRows
    featurestxt = pr.GenerateFromSheetFile!

    payload = 
      * features: featurestxt

    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_framefinder/" + SocialCalc._room
        contentType: "application/json"
        data: JSON.stringify payload
        success: (response) ->
          console.log("SUX")
          gview = spreadsheet.views.database.element
          gview.innerHTML = response
        error: (response) ->
          console.log("FUXERR")

    $.ajax request

    return

  return