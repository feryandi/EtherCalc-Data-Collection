// Generated by LiveScript 1.5.0
(function(){
  this.include = function(){
    return this.client({
      '/player/database.js': function(){
        var $, SocialCalc, header_div;
        $ = window.jQuery || window.$;
        if (!$) {
          return location.reload();
        }
        SocialCalc = window.SocialCalc || alert('Cannot find window.SocialCalc');
        header_div = "<table cellspacing=\"0\" cellpadding=\"0\" style=\"font-weight:bold;margin:8px;\"><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div>Current Label and Data</div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Scan Spreadsheet\" onclick=\"window.Synchronize();\" style=\"font-size:x-small;\"></td></tr><tr><td style=\"vertical-align:middle;padding-right:16px;\"><div><textarea id=\"databaseManualInput\" name=\"databaseManualInput\"></textarea></div></td><td style=\"vertical-align:middle;text-align:right;\"><input type=\"button\" value=\"Add Manually\" onclick=\"window.AddManual();\" style=\"font-size:x-small;\"></td></tr></table>";
        window.RefreshView = function(){
          var sheet, gview, savedData, sd, i, i$, len$, t, table, results$ = [];
          sheet = SocialCalc.GetSpreadsheetControlObject();
          gview = sheet.views.database.element;
          gview.innerHTML = header_div;
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          sd = JSON.parse(savedData.value);
          i = 1;
          for (i$ = 0, len$ = sd.length; i$ < len$; ++i$) {
            t = sd[i$];
            table = new Table(null, null);
            table.Deserialize(JSON.stringify(t));
            gview.innerHTML += table.GetHTMLForm(i);
            results$.push(i++);
          }
          return results$;
        };
        window.SaveState = function(){
          var savedData, payload, request;
          console.log("Save State");
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          payload = {
            id: SocialCalc._room,
            tables: savedData.value
          };
          request = {
            type: "POST",
            url: window.location.protocol + "//" + window.location.host + "/_database/state",
            contentType: "application/json",
            data: JSON.stringify(payload),
            success: function(response){
              return console.log("STATE SAVED");
            },
            error: function(response){
              return console.log("Error saving state to database");
            }
          };
          return $.ajax(request);
        };
        window.LoadState = function(){
          var savedData, request;
          console.log("Load State");
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          request = {
            type: "GET",
            url: window.location.protocol + "//" + window.location.host + "/_database/state/" + SocialCalc._room,
            success: function(response){
              console.log(response);
              if (response.length === 1) {
                savedData.value = response[0]["table_json"];
                return window.RefreshView();
              }
            },
            error: function(response){
              console.log("Error loading state to database");
              return console.log(response);
            }
          };
          return $.ajax(request);
        };
        window.DatabaseOnClick = function(s, t){
          var sheet, gview, savedData;
          sheet = SocialCalc.GetSpreadsheetControlObject();
          gview = sheet.views.database.element;
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          if (savedData.value === null || savedData.value === "") {
            gview.innerHTML = header_div;
            window.LoadState();
          } else {
            window.RefreshView();
          }
          return;
        };
        window.SaveConfiguration = function(n){
          var savedData, sd, table, rows, i, i$, len$, row, e;
          console.log("SAVE CONFIGURATION TABLE " + n);
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          sd = JSON.parse(savedData.value);
          table = new Table(null, null);
          table.Deserialize(JSON.stringify(sd[parseInt(n) - 1]));
          rows = table.rows;
          table.range = document.getElementById("t" + n + ".databaseRange").value;
          i = 1;
          for (i$ = 0, len$ = rows.length; i$ < len$; ++i$) {
            row = rows[i$];
            row["data"] = document.getElementById("t" + n + ".databaseData." + i).value;
            row["header"] = document.getElementById("t" + n + ".databaseLabel." + i).value;
            e = document.getElementById("t" + n + ".databaseType." + i);
            row["vtype"] = e.options[e.selectedIndex].value;
            e = document.getElementById("t" + n + ".databasePermitted." + i);
            row["vrange"] = e.value;
            e = document.getElementById("t" + n + ".databaseRelation." + i);
            row["vrel"] = e.value;
            i = i + 1;
          }
          table.rows = rows;
          console.log(sd);
          sd[parseInt(n) - 1] = JSON.parse(table.Serialize());
          console.log(sd);
          savedData.value = JSON.stringify(sd);
          return window.SaveState();
        };
        window.DeleteTable = function(n){
          var savedData, sd;
          console.log("DELETE TABLE " + n);
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          sd = JSON.parse(savedData.value);
          sd.splice(n - 1, 1);
          savedData.value = JSON.stringify(sd);
          window.DatabaseOnClick();
          window.SaveState();
        };
        window.Save = function(){
          var savedData, sheet, loadsheet, sheetdict, tables, i, i$, len$, t, table, tablename, payload, error, ref$, request;
          console.log("SAVING TO DATABASE");
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          sheet = SocialCalc.GetSpreadsheetControlObject();
          loadsheet = new LoadSheet(sheet);
          sheetdict = loadsheet.LoadSheetDict();
          console.log(savedData.value);
          tables = JSON.parse(savedData.value);
          i = 0;
          for (i$ = 0, len$ = tables.length; i$ < len$; ++i$) {
            t = tables[i$];
            i += 1;
            console.log("SAVING TABLE " + i);
            table = new Table(sheetdict, null);
            table.Deserialize(JSON.stringify(t));
            tablename = SocialCalc._room + "_t" + i;
            payload = {
              name: SocialCalc._room,
              table: table.TupleSerializeWithChecker(tablename)
            };
            console.log(payload.table);
            error = true;
            error = (ref$ = payload.table.error) != null ? ref$ : false;
            request = {
              type: "POST",
              url: window.location.protocol + "//" + window.location.host + "/_database/create",
              contentType: "application/json",
              data: JSON.stringify(payload),
              success: fn$,
              error: fn1$
            };
            if (!error) {
              $.ajax(request);
            } else {
              console.log("ERROR VALIDATIONS");
            }
          }
          window.SaveState();
          function fn$(response){
            return console.log("OK OK OK MYSQL OK OK OK");
          }
          function fn1$(response){
            return console.log("Error saving data to database");
          }
        };
        window.Synchronize = function(){
          var savedData, sheet, loadsheet, sheetdict, getLink, request;
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          sheet = SocialCalc.GetSpreadsheetControlObject();
          loadsheet = new LoadSheet(sheet);
          sheetdict = loadsheet.LoadSheetDict();
          getLink = function(sc, ec, sr, er){
            return "" + window.location.protocol + "//" + window.location.host + "/_framefinder/" + SocialCalc._room + "/" + sc + "/" + ec + "/" + sr + "/" + er;
          };
          request = {
            type: "GET",
            url: window.location.protocol + "//" + window.location.host + "/_hierachical/" + SocialCalc._room + "/20",
            contentType: "application/json",
            success: function(response){
              var links, clusters, raw, data, i$, len$, cluster, gview, total, sd;
              links = [];
              clusters = [];
              raw = [];
              data = JSON.parse(response);
              for (i$ = 0, len$ = data.length; i$ < len$; ++i$) {
                cluster = data[i$];
                raw.push(getLink(cluster.sc, cluster.ec, cluster.sr, cluster.er));
                links.push($.get(getLink(cluster.sc, cluster.ec, cluster.sr, cluster.er)));
                clusters.push([cluster.sc, cluster.ec, cluster.sr, cluster.er]);
              }
              console.log(raw);
              gview = sheet.views.database.element;
              gview.innerHTML = header_div;
              total = 0;
              sd = [];
              return $.when.apply($, links).done(function(){
                $.each(arguments, function(i, d){
                  var data, table;
                  data = d[0];
                  if (data.length > 0) {
                    table = new Table(sheetdict, data);
                    table.SetColumnRange(parseInt(clusters[i][0]), parseInt(clusters[i][1]));
                    if (table.IsHasData()) {
                      total += 1;
                      console.log(table.Serialize());
                      sd.push(JSON.parse(table.Serialize()));
                      return gview.innerHTML += table.GetHTMLForm(total);
                    }
                  }
                });
                savedData.value = JSON.stringify(sd);
                return window.SaveState();
              });
            },
            error: function(response){
              return console.log("Error getting predicted data");
            }
          };
          $.ajax(request);
        };
        window.AddManual = function(){
          var sheet, loadsheet, sheetdict, savedData, manualData, sd, md, table;
          sheet = SocialCalc.GetSpreadsheetControlObject();
          loadsheet = new LoadSheet(sheet);
          sheetdict = loadsheet.LoadSheetDict();
          savedData = document.getElementById(spreadsheet.idPrefix + "databaseSavedData");
          manualData = document.getElementById("databaseManualInput");
          if (savedData.value === null || savedData.value === "") {
            savedData.value = "[]";
          }
          sd = JSON.parse(savedData.value);
          md = JSON.parse(manualData.value);
          if (!md.hasOwnProperty('header')) {
            console.log("Error - header not found");
            return;
          }
          if (!md.hasOwnProperty('data')) {
            console.log("Error - data not found");
            return;
          }
          if (!md.hasOwnProperty('range')) {
            console.log("Error - range not found");
            return;
          }
          table = new Table(sheetdict, null);
          table.Deserialize(JSON.stringify(md));
          table.MapHeaderData();
          sd.push(JSON.parse(table.Serialize()));
          savedData.value = JSON.stringify(sd);
          window.DatabaseOnClick();
          window.SaveState();
        };
      }
    });
  };
}).call(this);
