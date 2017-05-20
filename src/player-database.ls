## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"></td></tr><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div><textarea id=\"manual\" name=\"manual\"></textarea></div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Add Manually\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"></td></tr></table>"

  window.DatabaseOnClick = !(s, t) ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    if savedData.value == null || savedData.value == ""
      gview.innerHTML = header_div
    else
      gview.innerHTML = header_div
      console.log(savedData.value)
      sd = JSON.parse(savedData.value)
      i = 1
      for t in sd
        table = new Table null, null
        table.Deserialize JSON.stringify(t)
        gview.innerHTML += table.GetHTMLForm i
        i++
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
      
      # row["vrel"] = ""
      i = i + 1

    table.rows = rows
    console.log(sd)
    sd[parseInt(n)-1] = JSON.parse(table.Serialize!)
    console.log(sd)
    savedData.value = JSON.stringify(sd)

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

      if not error
        $.ajax request
      else
        console.log("ERROR VALIDATIONS")

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
        
        error: (response) ->
          console.log("Error getting predicted data")
    $.ajax request    
    return
  return