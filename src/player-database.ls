@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"\" style=\"font-size:x-small;\"></td></tr></table>"

  table_template = "<div style=\"margin-left:8px;border:1px solid rgb(192,192,192);display:inline-block;\"><div><center><h4>Table 1</h4></center></div><div><table style=\"border-top:1px solid rgb(192,192,192);padding-top:16px;\"><thead><tr><th>Label Name</th><th>Data Range</th><th>Type Validation</th><th>Range Validation</th><th>Relation Validation</th></tr></thead><tr><td><input id=\"%id.t1.databaseLabel1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><input id=\"%id.t1.databaseData1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><select id=\"%id.t1.databaseTypeV1\" size=\"1\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"><option selected>None</option><option>String</option><option>Integer</option></select></td><td><input id=\"%id.t1.databaseRangeV1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td><td><input id=\"%id.t1.databaseRelationV1\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" class=\"btn btn-default btn-xs\"/></td></tr></table></div></div>"

  ### DEFAULT VALUE MASIH BISA DIGANTI TERNYATA AAAA!!! ###

  class MySheet
    (null) ->
      @sheetdict = []
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

      @sheetdict.splice SocialCalc.rcColname(colnum) + rownum, 0, mycell
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
      sheetdict = []
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
            cellTxt = JSON.stringify @wb.sheet.EncodeCellAttributes cellName

            if cellAttr.rowspan.val > 1 or cellAttr.colspan.val > 1
              row1 = rownum
              row2 = rownum + cellAttr.rowspan.val - 1
              col1 = colnum
              col2 = colnum + cellAttr.colspan.val - 1
              cmysheet.AddMergeCell row1, row2, col1, col2

            indents = parseInt @FeatureIndentation cellAttr
            alignstyle = parseInt @FeatureAlignStyle cellAttr                
            borderstyle = @FeatureBorderStyle cellAttr
            bgcolor = @FeatureFontBgcolor cellAttr
            boldflag = parseInt @FeatureFontBold cellAttr
            height = parseInt @FeatureFontHeight cellAttr
            italicflag = parseInt @FeatureFontItalic cellAttr
            underlineflag = parseInt @FeatureFontUnderline cellAttr

            cmysheet.InsertCell rownum, colnum, @wb.sheet.LastRow!, @wb.sheet.LastCol!, cellType, indents, alignstyle, borderstyle, bgcolor, boldflag, height, italicflag, underlineflag, cStr

          str += '([' + cellName + '] ' + indents + ', ' + alignstyle + ', ' + borderstyle + ', ' + bgcolor + ', ' + boldflag + ', ' + height + ', ' + italicflag + ', ' + underlineflag + ')'
        str += '<br/>'        

      sheetdict.splice 'Sheet1', 0, cmysheet ## BELUM BAKAL MAU SUPPORT MULTI-SHEET
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
      switch type
        case 't' then type = 'str'
        case 'v' 
          if value % 1 == 0
            type = 'int'
          else 
            type = 'float'
        case 'c' then type = 'str'
      return type

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
    ls = new LoadSheet SocialCalc.GetSpreadsheetControlObject!
    gview = spreadsheet.views.database.element
    gview.innerHTML = ls.LoadSheetDict!
    return

  return