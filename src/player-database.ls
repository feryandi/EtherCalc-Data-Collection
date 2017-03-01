## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"></td></tr></table>"

  window.DatabaseOnClick = !(s, t) ->
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!
    gview = sheet.views.database.element

    if savedData.value == null || savedData.value == ""
      pr = new PredictSheetRows
      dictTxt = pr.GenerateFromSheetFile sheetdict
      gview.innerHTML = header_div
    else
      table = new Table null, null
      table.Deserialize savedData.value
      gview.innerHTML = header_div + table.GetHTMLForm!
    return

  window.Save = ->
    console.log("SAVING TO DATABASE")
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    if !(savedData.value == null) && !(savedData.value == "")
      table = new Table sheetdict, null
      table.Deserialize savedData.value

    payload = 
      * name: SocialCalc._room
        table: table.TupleSerialize!

    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_database/create"
        contentType: "application/json"
        data: JSON.stringify payload
        success: (response) ->
          console.log("OK OK OK MYSQL OK OK OK")
        error: (response) ->
          console.log("Error saving data to database")

    $.ajax request
    return

  window.Synchronize = ->
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!
    pr = new PredictSheetRows
    featurestxt = pr.GenerateFromSheetFile sheetdict

    payload = 
      * features: featurestxt

    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_framefinder/" + SocialCalc._room
        contentType: "application/json"
        data: JSON.stringify payload
        success: (response) ->
          table = new Table sheetdict, response
          console.log(table.MapHeaderData!)
          gview = sheet.views.database.element
          savedData.value = table.Serialize!
          gview.innerHTML = header_div + table.GetHTMLForm!
        error: (response) ->
          console.log("Error getting predicted data")

    $.ajax request

    return

  return