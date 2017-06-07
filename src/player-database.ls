## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"></td></tr><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div><textarea id=\"databaseManualInput\" name=\"databaseManualInput\"></textarea></div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Add Manually\" onclick=\"window.AddManual();\" style=\"font-size:x-small;\"></td></tr></table>"

  window.RefreshView = ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    gview.innerHTML = header_div
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)
    i = 1
    for t in sd
      table = new Table null, null
      table.Deserialize JSON.stringify(t)
      gview.innerHTML += table.GetHTMLForm i
      i++  

  window.SaveState = ->
    console.log("Save State");
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    payload =
      * id: SocialCalc._room
        tables: savedData.value

    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_database/state"
        contentType: "application/json"
        data: JSON.stringify payload
        success: (response) ->
          console.log("STATE SAVED")
        error: (response) ->
          console.log("Error saving state to database")
          console.log(response)
    $.ajax request

  window.LoadState = ->
    console.log("Load State");
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    request =
      * type: "GET"
        url: window.location.protocol + "//" + window.location.host + "/_database/state/" + SocialCalc._room
        success: (response) ->
          console.log(response)
          if response.length == 1
            savedData.value = response[0]["table_json"]
            window.RefreshView!
        error: (response) ->
          console.log("Error loading state to database")
    $.ajax request

  window.DatabaseOnClick = !(s, t) ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    if savedData.value == null || savedData.value == ""
      gview.innerHTML = header_div
      window.LoadState!
    else
      window.RefreshView!
    return

  window.SaveConfiguration = (n) ->
    console.log("SAVE CONFIGURATION TABLE " + n)
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)

    table = new Table null, null
    table.Deserialize JSON.stringify(sd[parseInt(n)-1])

    rows = table.rows
    table.range = document.getElementById("t" + n + ".databaseRange").value

    i = 1
    for row in rows
      row["data"] = document.getElementById("t" + n + ".databaseData." + i).value
      row["header"] = document.getElementById("t" + n + ".databaseLabel." + i).value

      e = document.getElementById("t" + n + ".databaseType." + i)
      row["vtype"] = e.options[e.selectedIndex].value

      e = document.getElementById("t" + n + ".databasePermitted." + i)
      row["vrange"] = e.value
      
      e = document.getElementById("t" + n + ".databaseRelation." + i)
      row["vrel"] = e.value
      i = i + 1

    table.rows = rows
    console.log(sd)
    sd[parseInt(n)-1] = JSON.parse(table.Serialize!)
    console.log(sd)
    savedData.value = JSON.stringify(sd)
    window.SaveState!

  window.DeleteTable = (n) ->
    console.log("DELETE TABLE " + n)
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)

    sd.splice(n-1, 1);
    savedData.value = JSON.stringify(sd)
    
    window.DatabaseOnClick!
    window.SaveState!
    return

  window.Save = ->
    console.log("SAVING TO DATABASE")
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    console.log(savedData.value)
    ### Its broken here
    tables = JSON.parse(savedData.value)

    i = 0
    for t in tables
      i += 1
      console.log("SAVING TABLE " + i)
      table = new Table sheetdict, null
      table.Deserialize JSON.stringify(t)

      tablename = SocialCalc._room + "_t" + i

      payload =
        * name: SocialCalc._room
          table: table.TupleSerializeWithChecker tablename
      console.log(payload.table)

      error = true
      error = payload.table.error ? false

      request =
        * type: "POST"
          url: window.location.protocol + "//" + window.location.host + "/_database/create"
          contentType: "application/json"
          data: JSON.stringify payload
          success: (response) ->
            console.log("OK OK OK MYSQL OK OK OK")
          error: (response) ->
            console.log("Error saving data to database")
            console.log(response)

      if not error
        $.ajax request
      else
        console.log("ERROR VALIDATIONS")
    window.SaveState!
    return

  window.Synchronize = ->
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    getLink = (sc, ec, sr, er) ->
      return "" + window.location.protocol + "//" + window.location.host + "/_framefinder/" + SocialCalc._room + "/" + sc + "/" + ec + "/" + sr + "/" + er

    request =
      * type: "GET"
        url: window.location.protocol + "//" + window.location.host + "/_hierachical/" + SocialCalc._room + "/20"
        contentType: "application/json"
        success: (response) ->
          links = []
          clusters = []
          raw = []

          data = JSON.parse response
          for cluster in data
            raw.push getLink(cluster.sc, cluster.ec, cluster.sr, cluster.er)
            links.push $.get(getLink(cluster.sc, cluster.ec, cluster.sr, cluster.er))
            clusters.push [cluster.sc, cluster.ec, cluster.sr, cluster.er]

          console.log(raw)
          gview = sheet.views.database.element
          gview.innerHTML = header_div
          total = 0

          ## Start flooding API
          sd = []

          $.when.apply($, links).done ->
            $.each arguments, (i, d) ->
              data = d[0]
              if data.length > 0
                table = new Table sheetdict, data
                table.SetColumnRange(parseInt(clusters[i][0]), parseInt(clusters[i][1]))
                if table.IsHasData!
                  total += 1
                  console.log(table.Serialize!)
                  sd.push JSON.parse(table.Serialize!)
                  gview.innerHTML += table.GetHTMLForm total
            savedData.value = JSON.stringify sd
            window.SaveState!
        
        error: (response) ->
          console.log("Error getting predicted data")
    $.ajax request 
    return

  window.AddManual = ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    manualData = document.getElementById("databaseManualInput")

    if savedData.value == null || savedData.value == ""
      savedData.value = "[]"

    sd = JSON.parse(savedData.value)
    md = JSON.parse(manualData.value)

    ### CHECK VALIDITY OF MANUAL INPUT
    ## Check for header
    if not md.hasOwnProperty('header')
      console.log("Error - header not found")
      return

    ## Check for data
    if not md.hasOwnProperty('data')
      console.log("Error - data not found")
      return

    ## Check for range
    if not md.hasOwnProperty('range')
      console.log("Error - range not found")
      return

    ## Completing the missing values using Table  
    table = new Table sheetdict, null
    table.Deserialize JSON.stringify(md)
    table.MapHeaderData!

    ### ADD TO SAVEDDATA
    sd.push(JSON.parse(table.Serialize!))
    savedData.value = JSON.stringify(sd)

    window.DatabaseOnClick!
    window.SaveState!

    return
  
  return
