## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  nhr = "<hr style=\"display: block;height: 1px;border: 0;border-top: 1px solid rgb(204,204,204);margin: 1em 0;padding: 0;\">"
  header_div = "<span style=\"font-size: 14px;\"><br><br><b>Data Table</b></span><br/>You could add new table using two way;<br/>automatic detection and manually add table.<br/>" + nhr + "<b>Automatic Detection</b><br/>Using the automatic detection will reset all of the current table.<br/><input type=\"button\" value=\"Detect Spreadsheet Table\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"><br/>" + nhr + "<b>Add Manually</b><br/>Insert a JSON Object consist of `header`, `data`, and `range` to add new table.<br/><div><textarea id=\"databaseManualInput\" name=\"databaseManualInput\" style=\"width: 95%;min-height: 130px;\"></textarea></div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Add New Table\" onclick=\"window.AddManual();\" style=\"font-size:x-small;\"></td></tr></table>"
  
  sidebar_div = "<div style=\"position: relative; float: left; width: 250px; height: 100%; background: rgb(228,228,228); padding-left: 25px; padding-right: 25px;\">" + header_div + "</div>"
  content_div_s = "<div style=\"margin-left: 300px; width: auto; height: 100%; position: relative; overflow: auto; z-index: 1;\">"
  content_div_e = "</div>"

  notcon_div = "<div style=\"width: 100%; height: 100%; background-color: rgb(224,224,224); color: rgb(55,55,55);\"><div style=\"padding: 15px\"><span style=\"font-size: 18px;\"><b>Not Connected to Database</b></span><br/>Please input your database setting and<br/>click 'Connect' button.</div></div>"
  notest_div = "<div style=\"width: 100%; height: 100%; background-color: rgb(224,224,224); color: rgb(55,55,55);\"><div style=\"padding: 15px\"><span style=\"font-size: 18px;\"><b>Cannot Established Connection to Database</b></span><br/>Please check if your database is able to be connected by outside application.<br/><br/>Or, input other database setting and<br/>click 'Connect' button.</div></div>"
  plwait_div = "<div style=\"width: 100%; height: 100%; background-color: rgb(224,224,224); color: rgb(55,55,55);\"><div style=\"padding: 15px\"><span style=\"font-size: 18px;\"><b>Please Wait...</b></span><br/>Trying to establish connection with database.</div></div>"

  window.RefreshView = ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    content_div = content_div_s
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)
    i = 1
    for t in sd
      table = new Table null, null
      table.Deserialize JSON.stringify(t)
      content_div += table.GetHTMLForm i
      i++
    content_div += content_div_e
    gview.innerHTML = sidebar_div + content_div

  window.GetDBSetting = ->
    setting =
      * host: document.getElementById(spreadsheet.idPrefix + "databaseHost").value,
        port: document.getElementById(spreadsheet.idPrefix + "databasePort").value,
        user: document.getElementById(spreadsheet.idPrefix + "databaseUsername").value,
        password: document.getElementById(spreadsheet.idPrefix + "databasePassword").value,
        database: document.getElementById(spreadsheet.idPrefix + "databaseDBName").value
    return setting

  window.SaveState = ->
    console.log("Save State");
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")

    payload =
      * id: SocialCalc._room
        tables: savedData.value
        setting: JSON.parse(document.getElementById(spreadsheet.idPrefix + "databaseLoginData").value)

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

    payload =
      * setting: JSON.parse(document.getElementById(spreadsheet.idPrefix + "databaseLoginData").value)
    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_database/state/" + SocialCalc._room
        contentType: "application/json"
        data: JSON.stringify payload
        success: (response) ->
          console.log(response)
          if response.length == 1
            savedData.value = response[0]["table_json"]
            window.RefreshView!
        error: (response) ->
          console.log("Error loading state to database")
          console.log(response)
    $.ajax request

  window.DatabaseOnClick = !(s, t) ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    loginData = document.getElementById(spreadsheet.idPrefix + "databaseLoginData")

    if savedData.value == null || savedData.value == ""
      gview.innerHTML = notcon_div
      if loginData.value != null && loginData.value != ""
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
    table.name = document.getElementById("t" + n + ".databaseName").value

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

  window.Connect = ->
    console.log("CONNECTING/DISCONNECTING TO DATABASE")
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    gview.innerHTML = plwait_div

    loginData = document.getElementById(spreadsheet.idPrefix + "databaseLoginData")
    setting = window.GetDBSetting!

    # Test the connection
    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_database/connect"
        contentType: "application/json"
        data: JSON.stringify setting
        success: (response) ->
          console.log(response)
          if (response["status"] == "success")
            console.log("Connection could be established")
            # Save the connection
            loginData.value = JSON.stringify setting
            window.LoadState! 
          else
            console.log("Connection could NOT be established")
            gview.innerHTML = notest_div
        error: (response) ->
          console.log("Error connecting to API")
          console.log(response)

    $.ajax request
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

      spreadsheet_id = SocialCalc._room

      payload =
        * name: SocialCalc._room
          table: table.TupleSerializeWithChecker spreadsheet_id
          setting: JSON.parse(document.getElementById(spreadsheet.idPrefix + "databaseLoginData").value)

      error = true
      error = payload.table.error ? false

      request =
        * type: "POST"
          url: window.location.protocol + "//" + window.location.host + "/_database/create"
          contentType: "application/json"
          data: JSON.stringify payload
          success: (response) ->
            console.log("OK OK OK MYSQL OK OK OK")
            console.log(response)
          error: (response) ->
            console.log("Error saving data to database")
            console.log(response)

      if not error
        $.ajax request
      else
        console.log("ERROR VALIDATIONS")
        console.log(payload.table)
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
          content_div = content_div_s
          total = 0

          ## Start flooding API
          sd = []

          $.when.apply($, links).done ->
            $.each arguments, (i, d) ->
              data = d[0]
              if data.length > 0
                table = new Table sheetdict, data
                table.SetColumnRange(parseInt(clusters[i][0]), parseInt(clusters[i][1]))
                table.name = "" + SocialCalc._room + "_t" + (i - 1) + ""
                if table.IsHasData!
                  total += 1
                  sd.push JSON.parse(table.Serialize!)
                  content_div += table.GetHTMLForm total
            savedData.value = JSON.stringify sd
            content_div += content_div_e
            gview.innerHTML = sidebar_div + content_div
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
    table.name = "" + SocialCalc._room + "_t" + (sd.length + 1) + ""

    ### ADD TO SAVEDDATA
    sd.push(JSON.parse(table.Serialize!))
    savedData.value = JSON.stringify(sd)

    window.DatabaseOnClick!
    window.SaveState!

    return
  
  return
