## Added by feryandi ##
@include = -> @client '/player/database.js': ->
  $ = window.jQuery || window.$
  return location.reload! unless $
  SocialCalc = window.SocialCalc || alert 'Cannot find window.SocialCalc'

  nhr = "<hr style=\"display: block;height: 1px;border: 0;border-top: 1px solid rgb(204,204,204);margin: 1em 0;padding: 0;\">"
  header_div = "<span style=\"font-size: 14px;\"><br><br><b>Data Table</b></span><br/>You could add new table using two way;<br/>automatic detection and manually add table.<br/>" + nhr + "<b>Automatic Detection</b><br/>Using the automatic detection will reset all of the current table.<br/><input type=\"button\" value=\"Detect Spreadsheet Table\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"><br/>" + nhr + "<b>Add Manually</b><br/>Insert a JSON Object consist of `header`, `data`, and `range` to add new table.<br/><div><textarea id=\"databaseManualInput\" name=\"databaseManualInput\" style=\"width: 95%;min-height: 130px;\"></textarea></div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Add New Table\" onclick=\"window.AddManual();\" style=\"font-size:x-small;\"></td></tr></table>"
  error_div = "<div id=\"databaseErrorMessages\" style=\"width: 100%; min-height: 15px; background-color: rgb(242,152,137); padding: 15px; \">TEST</div>"
  
  sidebar_div = "<div style=\"position: relative; float: left; width: 250px; height: 100%; background: rgb(228,228,228); padding-left: 25px; padding-right: 25px;\">" + header_div + "</div>"
  content_div_s = "<div style=\"margin-left: 300px; width: auto; height: 100%; position: relative; overflow: auto; z-index: 1;\">"
  content_div_e = "</div>"

  notcon_div = "<div style=\"width: 100%; height: 100%; background-color: rgb(224,224,224); color: rgb(55,55,55);\"><div style=\"padding: 15px\"><span style=\"font-size: 18px;\"><b>Not Connected to Database</b></span><br/>Please input your database setting and<br/>click 'Connect' button.</div></div>"
  notest_div = "<div style=\"width: 100%; height: 100%; background-color: rgb(224,224,224); color: rgb(55,55,55);\"><div style=\"padding: 15px\"><span style=\"font-size: 18px;\"><b>Cannot Established Connection to Database</b></span><br/>Please check if your database is able to be connected by outside application.<br/><br/>Or, input other database setting and<br/>click 'Connect' button.</div></div>"
  plwait_div = "<div style=\"width: 100%; height: 100%; background-color: rgb(224,224,224); color: rgb(55,55,55);\"><div style=\"padding: 15px\"><span style=\"font-size: 18px;\"><b>Please Wait...</b></span><br/>Trying to establish connection with database.</div></div>"

  window.UniqueCheck = (i, n) ->
    is_checked = $("[id=t" + i + "\\.databaseUnique\\." + n + "]").prop('checked')
    console.log(is_checked)
    $("[id^=t" + i + "\\.databaseUnique]").prop('checked', false)
    $("[id=t" + i + "\\.databaseUnique\\." + n + "]").prop('checked', (is_checked))

  window.RefreshView = ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    gview = sheet.views.database.element
    content_div = content_div_s
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    errorMsg = document.getElementById(spreadsheet.idPrefix + "databaseErrorMsg")
    errorMsg.innerHTML = ""
    if savedData.value != null && savedData.value != ""
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
    lastDB = document.getElementById(spreadsheet.idPrefix + "databaseLastDB")

    payload =
      * id: SocialCalc._room
        tables: savedData.value
        last_db: lastDB.value
        setting: JSON.parse(document.getElementById(spreadsheet.idPrefix + "databaseLoginData").value)
    console.log(payload)

    request =
      * type: "POST"
        url: window.location.protocol + "//" + window.location.host + "/_database/state"
        contentType: "application/json"
        data: JSON.stringify payload
        success: (response) ->
          console.log(response)
          console.log("STATE SAVED")
        error: (response) ->
          console.log("Error saving state to database")
          console.log(response)
    $.ajax request

  window.LoadState = ->
    console.log("Load State");
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    lastDB = document.getElementById(spreadsheet.idPrefix + "databaseLastDB")

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
            if response[0]["last_db_json"] == "undefined"
              lastDB.value = ""
            else
              lastDB.value = response[0]["last_db_json"]
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
    table.name = document.getElementById("t" + n + ".databaseName").value
    table.data = document.getElementById("t" + n + ".databaseRange").value

    i = 1
    for row in rows
      row["header"] = document.getElementById("t" + n + ".databaseLabel." + i).value
      if row["vvalue"] == true
        row["value"] = document.getElementById("t" + n + ".databaseValue." + i).value
      else
        row["data"] = document.getElementById("t" + n + ".databaseData." + i).value

        e = document.getElementById("t" + n + ".databaseType." + i)
        row["vtype"] = e.options[e.selectedIndex].value

        e = document.getElementById("t" + n + ".databasePermitted." + i)
        row["vrange"] = encodeURIComponent(e.value)
        
        e = document.getElementById("t" + n + ".databaseRelation." + i)
        row["vrel"] = encodeURIComponent(e.value)

        e = document.getElementById("t" + n + ".databaseUnique." + i)
        row["vunique"] = e.checked
      i = i + 1
    table.rows = rows

    sd[parseInt(n)-1] = JSON.parse(table.Serialize!)

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

  window.Validate = ->
    console.log("Validate")
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    errorMsg = document.getElementById(spreadsheet.idPrefix + "databaseErrorMsg")
    errorMsg.innerHTML = "Validating..."

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    try
      tables = JSON.parse(savedData.value)

      i = 0;
      for t in tables
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
            url: window.location.protocol + "//" + window.location.host + "/_database/validate"
            contentType: "application/json"
            data: JSON.stringify payload
            success: (response) ->
              i += 1
              console.log("OK OK !!OK MYSQL OK!! OK OK")
              console.log(response)
              if response.code == 1
                error_box = "<div style=\"background: rgb(255, 210, 202); padding: 5px; border-radius: 3px;\">(`" + response.table + "`) " + response.status + "</div>"
                errorMsg.innerHTML = error_box
            error: (response) ->
              i += 1
              console.log("Error validating data to database")
              console.log(response)

        $.ajax request

      #while i != tables.length
      errorMsg.innerHTML = "No conflict detected"

    catch err
      errorMsg.innerHTML = "Failed validating to database"
      console.log(err)
    return    
    

  window.Save = ->
    console.log("SAVING TO DATABASE")
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    lastDB = document.getElementById(spreadsheet.idPrefix + "databaseLastDB")
    errorMsg = document.getElementById(spreadsheet.idPrefix + "databaseErrorMsg")
    errorMsg.innerHTML = "Saving..."
    errCount = 0

    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    console.log(savedData.value)
    ### Its broken here
    try
      tables = JSON.parse(savedData.value)

      i = 0
      ## Garbage Collecting
      dbSaved = []
      dbLast = []
      dbDelete = []

      sd = JSON.parse(savedData.value)
      for t in sd
        dbSaved.push(t["name"])

      ### DISINI NGEBUG
      if lastDB.value != null || lastDB.value != ""
        try
          ld = JSON.parse(lastDB.value)
          for t in ld
            dbLast.push(t["name"])

          for dl in dbLast
            if dbSaved.indexOf(dl) == -1
              dbDelete.push(dl)

          console.log("Collecting Garbage")
          console.log(dbDelete)

          payload =
            * id: SocialCalc._room
              db: dbDelete
              setting: JSON.parse(document.getElementById(spreadsheet.idPrefix + "databaseLoginData").value)

          request =
            * type: "POST"
              url: window.location.protocol + "//" + window.location.host + "/_database/clean"
              contentType: "application/json"
              data: JSON.stringify payload
              success: (response) ->
                console.log(response)
              error: (response) ->
                console.log("Error cleaning database")
                console.log(response)
          $.ajax request
        catch err
          console.log("Not collecting garbage")
          console.log(err)     

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
              if response.code == 1
                error_box = "<div style=\"background: rgb(255, 210, 202); padding: 5px; border-radius: 3px;\">(`" + response.table + "`) " + response.status + "</div>"
                errorMsg.innerHTML = error_box
              else
                lastDB.value = savedData.value
                window.SaveState!
            error: (response) ->
              console.log("Error saving data to database")
              console.log(response)

        if not error
          $.ajax request
        else
          errCount += 1
          console.log("ERROR VALIDATIONS")
          console.log(payload.table)
          val_type = payload.table.error.charAt(0).toUpperCase() + payload.table.error.slice(1)
          error_box = "<div style=\"background: rgb(255, 210, 202); padding: 5px; border-radius: 3px;\">" + val_type + " validation error on cell " + payload.table.coordinate + ". " + payload.table.description + "</div>"
          errorMsg.innerHTML = error_box

      if errCount == 0        
        errorMsg.innerHTML = "Successfully saved all tables!"
    catch err
      errorMsg.innerHTML = "Failed saving to database"
      console.log(err)
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

          ## console.log(raw)
          ## console.log("DEBUGAA");
          ## console.log(clusters);
          ## console.log(links);

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
                table.name = "" + SocialCalc._room + "_t" + (i) + ""
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

  window.AddColumn = (n) ->
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)
    console.log(sd)
    sd[(n-1)]["rows"].push({"header":"","data":"","vtype":"non","vrange":"","vrel":"","vunique":false})
    savedData.value = JSON.stringify(sd)
    window.RefreshView!
    return

  window.AddValueColumn = (n) ->
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)
    console.log(sd)
    sd[(n-1)]["rows"].push({"header":"","value":"","vvalue":true})
    savedData.value = JSON.stringify(sd)
    window.RefreshView!
    return

  window.DelColumn = (n, i) ->
    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    sd = JSON.parse(savedData.value)
    sd[(n-1)]["rows"].splice((i-1), 1)
    savedData.value = JSON.stringify(sd)
    window.RefreshView!
    return

  window.AddManual = ->
    sheet = SocialCalc.GetSpreadsheetControlObject!
    loadsheet = new LoadSheet sheet
    sheetdict = loadsheet.LoadSheetDict!

    savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData")
    manualData = document.getElementById("databaseManualInput")
    errorMsg = document.getElementById(spreadsheet.idPrefix + "databaseErrorMsg")
    errorMsg.innerHTML = ""
    error_box_s = "<div style=\"background: rgb(255, 210, 202); padding: 5px; border-radius: 3px;\">"
    error_box_e = "</div>"

    if savedData.value == null || savedData.value == ""
      savedData.value = "[]"

    try
      sd = JSON.parse(savedData.value)
      md = JSON.parse(manualData.value)
      console.log(md);
    catch
      console.log("Error - manual input is not valid")
      errorMsg.innerHTML = error_box_s + "Manual input is not valid" + error_box_e
      return

    mds = []
    ## Check if bulk add manual (array)
    if !(md instanceof Array)
      mds.push(md)
    else
      mds = md

    for md in mds
      ### CHECK VALIDITY OF MANUAL INPUT
      ## Check for header
      if not md.hasOwnProperty('header')
        console.log("Error - header not found")
        errorMsg.innerHTML = error_box_s + "Error parsing, header not found" + error_box_e
        return

      if not (md['header'] instanceof Array)
        console.log("Error - header not valid JSON Array")
        errorMsg.innerHTML = error_box_s + "Error parsing, header not valid array" + error_box_e
        return

      ## Check for data
      if not md.hasOwnProperty('data')
        console.log("Error - data not found")
        errorMsg.innerHTML = error_box_s + "Error parsing, data not found" + error_box_e
        return

      patt = new RegExp("([0-9]+):([0-9]+)", "g");
      if (!((md['data'] instanceof Array) or (patt.test(md['data']))) or (md['data'] == ""))
        console.log("Error - data not valid JSON Array")
        errorMsg.innerHTML = error_box_s + "Error parsing, data not valid format" + error_box_e
        return

      ## Check for range
      if not md.hasOwnProperty('range')
        console.log("Error - range not found")
        errorMsg.innerHTML = error_box_s + "Error parsing, range not found" + error_box_e
        return

      patt = new RegExp("([A-Z]+)([0-9]+):([A-Z]+)([0-9]+)", "g");
      if (!((md['range'] instanceof Array) or (patt.test(md['range']))) or (md['range'] == ""))
        console.log("Error - range not valid")
        errorMsg.innerHTML = error_box_s + "Error parsing, range not valid format" + error_box_e
        return
      if (md['range'] instanceof Array)
        md['range'] = JSON.stringify(md['range'])

      ## Completing the missing values using Table
      console.log(JSON.stringify(md))
      table = new Table sheetdict, null
      table.Deserialize JSON.stringify(md)
      table.MapHeaderData!
      table.name = "" + SocialCalc._room + "_t" + (sd.length + 1) + ""

      ### ADD TO SAVEDDATA
      sd.push(JSON.parse(table.Serialize!))

    savedData.value = JSON.stringify(sd)

    window.DatabaseOnClick!
    window.SaveState!
    errorMsg.innerHTML = "Table added successfully"

    return
  
  return
