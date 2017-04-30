## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"></td></tr></table>"

  window.DatabaseOnClick = !(s, t) ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    if savedData.value == null || savedData.value == ""
      gview.innerHTML = header_div
    else
      table = new Table null, null
      table.Deserialize savedData.value
      gview.innerHTML = header_div + table.GetHTMLForm!
    return

  window.SaveConfiguration = (n) ->
    console.log("SAVE CONFIGURATION TABLE " + n)
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    table = new Table null, null
    table.Deserialize savedData.value

    rows = table.rows
    
    i = 1
    for row in rows
      row["data"] = document.getElementById("t" + n + ".databaseData." + i).value
      row["header"] = document.getElementById("t" + n + ".databaseLabel." + i).value
      e = document.getElementById("t" + n + ".databaseType." + i)
      row["vtype"] = e.options[e.selectedIndex].value
      # row["vrange"] = ""
      # row["vrel"] = ""
      i = i + 1

    table.rows = rows
    savedData.value = table.Serialize!

    console.log(table.rows)

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

    request =
      * type: "GET"
        url: window.location.protocol + "//" + window.location.host + "/_framefinder/" + SocialCalc._room
        contentType: "application/json"
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