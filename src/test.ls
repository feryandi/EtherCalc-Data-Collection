
class PredictSheetRows
  (null) ->
    @fea_row = new FeatureSheetRow

  GenerateFromSheetFile: (sheetdict) ->
    strout = ''

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


if typeof module isnt 'undefined' and module.exports
  module.exports = Table


