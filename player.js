// Generated by LiveScript 1.5.0
(function(){
  this.include = function(){
    return this.client({
      '/player/main.js': function(){
        var $, doPlay, onReady, onLoad, ref$, this$ = this;
        $ = window.jQuery || window.$;
        if (!$) {
          return location.reload();
        }
        doPlay = function(){
          var requestParams, ref$, endpoint, ref1$, ref2$, ref3$, options, showError, x$, ref4$, emit;
          window.SocialCalc == null && (window.SocialCalc = {});
          SocialCalc._username = Math.random().toString();
          SocialCalc.isConnected = true;
          requestParams = SocialCalc.requestParams;
          if (requestParams['auth'] != null) {
            SocialCalc._auth = requestParams['auth'];
          }
          if (requestParams['app'] != null) {
            SocialCalc._app = true;
          }
          if (requestParams['view'] != null) {
            SocialCalc._view = true;
          }
          SocialCalc._room == null && (SocialCalc._room = ((ref$ = window.EtherCalc) != null ? ref$._room : void 8) || window.location.hash.replace('#', ''));
          SocialCalc._room = (SocialCalc._room + "").replace(/^_+/, '').replace(/\?.*/, '');
          endpoint = (ref1$ = $('script[src*="/socket.io/socket.io.js"]')) != null ? (ref2$ = ref1$.attr('src')) != null ? ref2$.replace(/\.?\/socket.io\/socket.io.js.*/, '') : void 8 : void 8;
          if (endpoint === '') {
            endpoint = location.pathname.replace(/\/(view|edit)$/, '');
            endpoint = endpoint.replace(RegExp('' + SocialCalc._room + '$'), '');
          }
          if ((ref3$ = window.Drupal) != null && ref3$.sheetnode) {
            if (/overlay=node\/\d+/.test(window.location.hash)) {
              SocialCalc._room = window.location.hash.match(/=node\/(\d+)/)[1];
            } else if (/\/node\/\d+/.test(window.location.href)) {
              SocialCalc._room = window.location.href.match(/\/node\/(\d+)/)[1];
            }
          } else if (SocialCalc._room) {
            if (!SocialCalc.CurrentSpreadsheetControlObject) {
              setTimeout(function(){
                window.history.pushState({}, '', "./" + SocialCalc._room + (function(){
                  switch (false) {
                  case !SocialCalc._app:
                    return '/app';
                  case !SocialCalc._view:
                    return '/view';
                  case !SocialCalc._auth:
                    return '/edit';
                  default:
                    return '';
                  }
                }()));
                if (/^(?:www\.)?ethercalc\.(?:org|com)$/.exec(location.host)) {
                  return $('<a />', {
                    id: "restore",
                    target: "_blank",
                    href: "https://ethercalc.org/log/?" + SocialCalc._room,
                    title: "View & Restore Backups"
                  }).text("↻").appendTo('body');
                }
              }, 100);
            }
          } else {
            window.location = './_start';
            return;
          }
          options = {
            'connect timeout': 1500,
            reconnect: true,
            'reconnection delay': 500,
            'max reconnection attempts': 1800
          };
          if (endpoint) {
            options.path = endpoint.replace(/\/?$/, '/socket.io');
          }
          showError = function(it){
            if (typeof vex != 'undefined' && vex !== null) {
              vex.closeAll();
            }
            if (typeof vex != 'undefined' && vex !== null) {
              vex.defaultOptions.className = 'vex-theme-flat-attack';
            }
            return typeof vex != 'undefined' && vex !== null ? vex.dialog.open({
              message: it,
              buttons: []
            }) : void 8;
          };
          window.addEventListener('offline', function(){
            return showError('Disconnected from server. please check network connection and refresh.');
          });
          x$ = (ref4$ = this$.connect('/', options)) != null ? ref4$.io : void 8;
          if (x$ != null) {
            x$.on('reconnect', function(){
              if (!((typeof SocialCalc != 'undefined' && SocialCalc !== null) && SocialCalc.isConnected)) {
                return;
              }
              return SocialCalc.Callbacks.broadcast('ask.log');
            });
          }
          if (x$ != null) {
            x$.on('connect_error', function(){
              return showError('Connection error; please refresh to try again.');
            });
          }
          if (x$ != null) {
            x$.on('connect_timeout', function(){
              return showError('Connection timeout; please refresh to try again.');
            });
          }
          if (x$ != null) {
            x$.on('reconnect_error', function(){
              if (!((typeof SocialCalc != 'undefined' && SocialCalc !== null) && SocialCalc.isConnected)) {
                return;
              }
              SocialCalc.hadSnapshot = false;
              return showError('Disconnected from server. Reconnecting....');
            });
          }
          if (x$ != null) {
            x$.on('connect_failed', function(){
              return showError('Reconnection Failed.');
            });
          }
          emit = function(data){
            return this$.emit({
              data: data
            });
          };
          SocialCalc.Callbacks.broadcast = function(type, data){
            data == null && (data = {});
            if (!SocialCalc.isConnected) {
              return;
            }
            data.user = SocialCalc._username;
            if (data.room == null) {
              data.room = SocialCalc._room;
            }
            data.type = type;
            if (SocialCalc._auth) {
              data.auth = SocialCalc._auth;
            }
            return emit(data);
          };
          SocialCalc.isConnected = true;
          SocialCalc.RecalcInfo.LoadSheetCache = {};
          SocialCalc.RecalcInfo.LoadSheet = function(ref){
            if (/[^.=_a-zA-Z0-9]/.exec(ref)) {
              return;
            }
            ref = ref.toLowerCase();
            return emit({
              type: 'ask.recalc',
              user: SocialCalc._username,
              room: ref
            });
          };
          return this$.on({
            data: function(){
              var ss, ref$, ref1$, editor, user, ref2$, ecell, peerClass, find, cr, cell, origCR, origCell, ref3$, parts, cmdstr, line, refreshCmd, sheetdata, ref4$;
              if (!((typeof SocialCalc != 'undefined' && SocialCalc !== null) && SocialCalc.isConnected)) {
                return;
              }
              if (this.data.user === SocialCalc._username && this.data.room === SocialCalc._room) {
                return;
              }
              if (this.data.to && this.data.to !== SocialCalc._username) {
                return;
              }
              ss = window.spreadsheet;
              if (!ss) {
                return;
              }
              if (this.data.room && this.data.room !== SocialCalc._room && ((ref$ = ss.formDataViewer) != null ? ref$._room : void 8) !== this.data.room && this.data.type === "log") {
                return;
              }
              if (this.data.room && this.data.room !== SocialCalc._room && this.data.type !== "recalc" && this.data.type !== "log") {
                if (((ref1$ = ss.formDataViewer) != null ? ref1$._room : void 8) !== this.data.room) {
                  return;
                }
                ss = ss.formDataViewer;
              }
              editor = ss.editor;
              switch (this.data.type) {
              case 'confirmemailsent':
                SocialCalc.EditorSheetStatusCallback(null, "confirmemailsent", this.data.message, editor);
                break;
              case 'chat':
                if (typeof window.addmsg == 'function') {
                  window.addmsg(this.data.msg);
                }
                break;
              case 'ecells':
                if (SocialCalc._app) {
                  break;
                }
                for (user in ref2$ = this.data.ecells) {
                  ecell = ref2$[user];
                  if (user === SocialCalc._username) {
                    continue;
                  }
                  peerClass = " " + user + " defaultPeer";
                  find = new RegExp(peerClass, 'g');
                  cr = SocialCalc.coordToCr(ecell);
                  cell = SocialCalc.GetEditorCellElement(editor, cr.row, cr.col);
                  if ((cell != null ? cell.element.className.search(find) : void 8) === -1) {
                    cell.element.className += peerClass;
                  }
                }
                break;
              case 'ecell':
                peerClass = " " + this.data.user + " defaultPeer";
                find = new RegExp(peerClass, 'g');
                if (this.data.original) {
                  origCR = SocialCalc.coordToCr(this.data.original);
                  origCell = SocialCalc.GetEditorCellElement(editor, origCR.row, origCR.col);
                  if (origCell != null) {
                    origCell.element.className = origCell.element.className.replace(find, '');
                  }
                  if (this.data.original === editor.ecell.coord || this.data.ecell === editor.ecell.coord) {
                    SocialCalc.Callbacks.broadcast('ecell', {
                      to: this.data.user,
                      ecell: editor.ecell.coord
                    });
                  }
                }
                if (SocialCalc._app) {
                  break;
                }
                cr = SocialCalc.coordToCr(this.data.ecell);
                cell = SocialCalc.GetEditorCellElement(editor, cr.row, cr.col);
                if ((cell != null ? (ref2$ = cell.element) != null ? ref2$.className.search(find) : void 8 : void 8) === -1) {
                  cell.element.className += peerClass;
                }
                break;
              case 'ask.ecell':
                if (SocialCalc._app) {
                  break;
                }
                SocialCalc.Callbacks.broadcast('ecell', {
                  to: this.data.user,
                  ecell: editor.ecell.coord
                });
                break;
              case 'log':
                ss = window.spreadsheet;
                if (typeof vex != 'undefined' && vex !== null) {
                  vex.closeAll();
                }
                if (((ref3$ = ss.formDataViewer) != null ? ref3$._room : void 8) === this.data.room) {
                  if (this.data.snapshot) {
                    parts = ss.DecodeSpreadsheetSave(this.data.snapshot);
                  }
                  ss.formDataViewer.sheet.ResetSheet();
                  ss.formDataViewer.loaded = true;
                  SocialCalc.Callbacks.broadcast('ask.log');
                  if (parts != null && parts.sheet) {
                    ss.formDataViewer.ParseSheetSave(this.data.snapshot.substring(parts.sheet.start, parts.sheet.end));
                    ss.formDataViewer.context.sheetobj.ScheduleSheetCommands("recalc\n", false, true);
                  }
                  break;
                }
                if (SocialCalc.hadSnapshot) {
                  break;
                }
                SocialCalc.hadSnapshot = true;
                if (this.data.snapshot) {
                  parts = ss.DecodeSpreadsheetSave(this.data.snapshot);
                }
                if (parts != null) {
                  if (parts.sheet) {
                    ss.sheet.ResetSheet();
                    ss.ParseSheetSave(this.data.snapshot.substring(parts.sheet.start, parts.sheet.end));
                  }
                  if (parts.edit) {
                    ss.editor.LoadEditorSettings(this.data.snapshot.substring(parts.edit.start, parts.edit.end));
                  }
                }
                if (typeof window.addmsg == 'function') {
                  window.addmsg(this.data.chat.join('\n'), true);
                }
                cmdstr = (function(){
                  var i$, ref$, len$, results$ = [];
                  for (i$ = 0, len$ = (ref$ = this.data.log).length; i$ < len$; ++i$) {
                    line = ref$[i$];
                    if (!/^re(calc|display)$/.test(line)) {
                      results$.push(line);
                    }
                  }
                  return results$;
                }.call(this)).join('\n');
                if (cmdstr.length) {
                  refreshCmd = 'recalc';
                  ss.context.sheetobj.ScheduleSheetCommands(cmdstr + "\n" + refreshCmd + "\n", false, true);
                } else {
                  ss.context.sheetobj.ScheduleSheetCommands("recalc\n", false, true);
                }
                break;
              case 'snapshot':
                if (typeof vex != 'undefined' && vex !== null) {
                  vex.closeAll();
                }
                SocialCalc.hadSnapshot = true;
                if (this.data.snapshot) {
                  parts = ss.DecodeSpreadsheetSave(this.data.snapshot);
                }
                if (parts != null && parts.sheet) {
                  ss.sheet.ResetSheet();
                  ss.ParseSheetSave(this.data.snapshot.substring(parts.sheet.start, parts.sheet.end));
                  ss.context.sheetobj.ScheduleSheetCommands("recalc\n", false, true);
                }
                break;
              case 'recalc':
                if (this.data.force) {
                  delete SocialCalc.Formula.SheetCache.sheets[this.data.room];
                  if (ss != null) {
                    ss.sheet.recalconce = true;
                  }
                }
                if (this.data.snapshot) {
                  parts = ss.DecodeSpreadsheetSave(this.data.snapshot);
                }
                if (parts != null && parts.sheet) {
                  sheetdata = this.data.snapshot.substring(parts.sheet.start, parts.sheet.end);
                  SocialCalc.RecalcLoadedSheet(this.data.room, sheetdata, true);
                  if (SocialCalc.RecalcInfo.LoadSheetCache[this.data.room] !== sheetdata) {
                    SocialCalc.RecalcInfo.LoadSheetCache[this.data.room] = sheetdata;
                    ss.context.sheetobj.ScheduleSheetCommands("recalc\n", false, true);
                  }
                } else {
                  SocialCalc.RecalcLoadedSheet(this.data.room, '', true);
                }
                break;
              case 'execute':
                ss.context.sheetobj.ScheduleSheetCommands(this.data.cmdstr, this.data.saveundo, true);
                if (ss.currentTab === ((ref4$ = ss.tabnums) != null ? ref4$.graph : void 8)) {
                  setTimeout(function(){
                    return window.DoGraph(false, false);
                  }, 100);
                }
                break;
              case 'stopHuddle':
                $('#content').uiDisable();
                alert("[Collaborative Editing Session Completed]\n\nThank you for your participation.\n\nCheck the activity stream to see the newly edited page!");
                window.onunload = null;
                window.onbeforeunload = null;
                window.location = '/';
                break;
              case 'error':
                if (typeof vex != 'undefined' && vex !== null) {
                  vex.closeAll();
                }
                if (typeof vex != 'undefined' && vex !== null) {
                  vex.defaultOptions.className = 'vex-theme-flat-attack';
                }
                if (typeof vex != 'undefined' && vex !== null) {
                  vex.dialog.open({
                    message: this.data.message,
                    buttons: [$.extend({}, typeof vex != 'undefined' && vex !== null ? vex.dialog.buttons.YES : void 8, {
                      text: 'Return to ready-only mode',
                      click: function(){
                        return location.href = "../" + SocialCalc._room;
                      }
                    })]
                  });
                }
              }
            }
          });
        };
        window.doresize = function(){
          var ref$;
          if ((ref$ = window.spreadsheet) != null) {
            ref$.DoOnResize();
          }
        };
        onReady = function(){
          var ref$, ref1$, ref2$, $container, ref3$;
          if (!((ref$ = window.Drupal) != null && ((ref1$ = ref$.sheetnode) != null && ((ref2$ = ref1$.sheetviews) != null && ref2$.length)))) {
            return onLoad();
          }
          $container = (ref3$ = window.Drupal) != null ? ref3$.sheetnode.sheetviews[0].$container : void 8;
          return $container.bind('sheetnodeReady', function(_, arg$){
            var spreadsheet;
            spreadsheet = arg$.spreadsheet;
            if (spreadsheet.tabbackground === 'display:none;') {
              if (spreadsheet.InitializeSpreadsheetControl) {
                return;
              }
              SocialCalc._auth = '0';
            }
            return onLoad(spreadsheet);
          });
        };
        $(function(){
          return setTimeout(onReady, 1);
        });
        onLoad = function(ssInstance){
          var ss, ref$, ref1$, ref2$, ref3$, ref4$, ref5$;
          ssInstance == null && (ssInstance = SocialCalc.CurrentSpreadsheetControlObject);
          window.spreadsheet = ss = ssInstance || (SocialCalc._view || SocialCalc._app
            ? new SocialCalc.SpreadsheetViewer()
            : new SocialCalc.SpreadsheetControl());
          if (window.GraphOnClick == null) {
            SocialCalc.Callbacks.broadcast('ask.log');
            return;
          }
          ss.ExportCallback = function(s){
            return alert(SocialCalc.ConvertSaveToOtherFormat(SocialCalc.Clipboard.clipboard, "csv"));
          };
          SocialCalc.Constants.s_loc_form = "Form";
          if (ss.tabs) {
            ss.tabnums.form = ss.tabs.length;
          }
          if ((ref$ = ss.tabs) != null) {
            ref$.push({
              name: 'form',
              text: SocialCalc.Constants.s_loc_form,
              html: "<div id=\"%id.formtools\" style=\"display:none;\"><div style=\"%tbt.\"><table cellspacing=\"0\" cellpadding=\"0\">\n<tr><td style=\"vertical-align:middle;padding-right:32px;padding-left:16px;\"><div style=\"%tbt.\">\n<input type=\"button\" value=\"Live Form\" onclick=\"parent.location='" + SocialCalc._room + "/form'\" style=\"background-color: #5cb85c;border-color: #4cae4c;cursor: pointer;\"> " + document.location.origin + "/" + SocialCalc._room + "/form </div></td>\n</tr></table></div></div>",
              view: 'sheet',
              onclick: null,
              onclickFocus: true
            });
          }
          if (ss.tabs) {
            ss.tabnums.graph = ss.tabs.length;
          }
          if ((ref1$ = ss.tabs) != null) {
            ref1$.push({
              name: 'graph',
              text: SocialCalc.Constants.s_loc_graph,
              html: "<div id=\"%id.graphtools\" style=\"display:none;\"><div style=\"%tbt.\"><table cellspacing=\"0\" cellpadding=\"0\"><tr><td style=\"vertical-align:middle;padding-right:32px;padding-left:16px;\"><div style=\"%tbt.\">Cells to Graph</div><div id=\"%id.graphrange\" style=\"font-weight:bold;\">Not Set</div></td><td style=\"vertical-align:top;padding-right:32px;\"><div style=\"%tbt.\">Set Cells To Graph</div><select id=\"%id.graphlist\" size=\"1\" onfocus=\"%s.CmdGotFocus(this);\"><option selected>[select range]</option><option>Select all</option></select></td><td style=\"vertical-align:middle;padding-right:4px;\"><div style=\"%tbt.\">Graph Type</div><select id=\"%id.graphtype\" size=\"1\" onchange=\"window.GraphChanged(this);\" onfocus=\"%s.CmdGotFocus(this);\"></select><input type=\"button\" value=\"OK\" onclick=\"window.GraphSetCells();\" style=\"font-size:x-small;\"></div></td><td style=\"vertical-align:middle;padding-right:16px;\"><div style=\"%tbt.\">&nbsp;</div><input id=\"%id.graphhelp\" type=\"button\" onclick=\"DoGraph(true);\" value=\"Help\" style=\"font-size:x-small;\"></div></td><td style=\"vertical-align:middle;padding-right:16px;\">Min X <input id=\"%id.graphMinX\" onchange=\"window.MinMaxChanged(this,0);\" onfocus=\"%s.CmdGotFocus(this);\" size=5/>Max X <input id=\"%id.graphMaxX\" onchange=\"window.MinMaxChanged(this,1);\" onfocus=\"%s.CmdGotFocus(this);\" size=5/><br/>Min Y <input id=\"%id.graphMinY\" onchange=\"window.MinMaxChanged(this,2);\" onfocus=\"%s.CmdGotFocus(this);\" size=5/>Max Y <input id=\"%id.graphMaxY\" onchange=\"window.MinMaxChanged(this,3);\" onfocus=\"%s.CmdGotFocus(this);\" size=5/></div></td></tr></table></div></div>",
              view: 'graph',
              onclick: window.GraphOnClick,
              onclickFocus: true
            });
          }
          if ((ref2$ = ss.views) != null) {
            ref2$.graph = {
              name: 'graph',
              divStyle: "overflow:auto;",
              values: {},
              html: '<div style="padding:6px;">Graph View</div>'
            };
          }
          if ((ref3$ = ss.editor) != null) {
            ref3$.SettingsCallbacks.graph = {
              save: window.GraphSave,
              load: window.GraphLoad
            };
          }
          SocialCalc.Constants.s_loc_database = "Data Collector";
          if (ss.tabs) {
            ss.tabnums.database = ss.tabs.length;
          }
          if ((ref4$ = ss.tabs) != null) {
            ref4$.push({
              name: 'database',
              text: SocialCalc.Constants.s_loc_database,
              html: "<div id=\"%id.databasetools\" style=\"display:none;\"><div style=\"%tbt.\"><table cellspacing=\"0\" cellpadding=\"0\"><tr><td style=\"vertical-align:middle;padding-right:32px;padding-left:16px;\"><div style=\"%tbt.\">Database<br>Settings</div></td><td style=\"vertical-align:middle;padding-right:16px;\"><div style=\"%tbt.\">Host</div><input type=\"text\" id=\"%id.databaseHost\" style=\"font-size:x-small;width:75px;\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" value=\"172.17.0.2\"/></td><td style=\"vertical-align:middle;padding-right:16px;\"><div style=\"%tbt.\">Port</div><input type=\"text\" id=\"%id.databasePort\" style=\"font-size:x-small;width:75px;\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" value=\"3306\"/></td><td style=\"vertical-align:middle;padding-left:16px;padding-right:16px;border-left: 1px solid rgb(192,192,192);\"><div style=\"%tbt.\">Username</div><input type=\"text\" id=\"%id.databaseUsername\" style=\"font-size:x-small;width:75px;\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" value=\"root\"/></td><td style=\"vertical-align:middle;padding-right:16px;\"><div style=\"%tbt.\">Password</div><input type=\"text\" id=\"%id.databasePassword\" style=\"font-size:x-small;width:75px;\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" value=\"root\"/></td><td style=\"vertical-align:middle;padding-left:16px;padding-right:16px;border-left: 1px solid rgb(192,192,192);\"><div style=\"%tbt.\">Database Name</div><input type=\"text\" id=\"%id.databaseDBName\" style=\"font-size:x-small;width:75px;\" onchange=\"\" onfocus=\"%s.CmdGotFocus(this);\" value=\"TA\"/></td><td style=\"vertical-align:middle;padding-left:16px;padding-right:16px;border-left: 1px solid rgb(192,192,192);\"><input type=\"button\" value=\"Connect\" onclick=\"window.Connect();\" style=\"font-size:x-small;\"></td><td style=\"vertical-align:middle;padding-left:16px;padding-right:16px;border-left: 1px solid rgb(192,192,192);\"><input type=\"button\" id=\"%id.databaseBtnSave\" value=\"Save to Database\" onclick=\"window.Save();\" style=\"font-size:x-small;\"></td></tr></table>\n<input type=\"hidden\" id=\"%id.databaseSavedData\"/><input type=\"hidden\" id=\"%id.databaseLoginData\"/></div></div>",
              view: 'database',
              onclick: window.DatabaseOnClick,
              onclickFocus: true
            });
          }
          if ((ref5$ = ss.views) != null) {
            ref5$.database = {
              name: 'database',
              divStyle: "overflow:auto;",
              values: {},
              html: '<div style="padding:6px;">Data Collector View</div>'
            };
          }
          ss.sheet.cells["A1"] = new SocialCalc.Cell("A1");
          ss.sheet.cells["A1"].displaystring = '<div class="loader"></div>';
          if (typeof ss.InitializeSpreadsheetViewer == 'function') {
            ss.InitializeSpreadsheetViewer('tableeditor', 0, 0, 0);
          }
          if (typeof ss.InitializeSpreadsheetControl == 'function') {
            ss.InitializeSpreadsheetControl('tableeditor', 0, 0, 0);
          }
          if (SocialCalc._view == null && ss.formDataViewer != null) {
            ss.formDataViewer.sheet._room = ss.formDataViewer._room = SocialCalc._room + "_formdata";
            SocialCalc.Callbacks.broadcast('ask.log', {
              room: ss.formDataViewer._room
            });
          } else {
            SocialCalc.Callbacks.broadcast('ask.log');
          }
          if (typeof ss.ExecuteCommand == 'function') {
            ss.ExecuteCommand('redisplay', '');
          }
          if (typeof ss.ExecuteCommand == 'function') {
            ss.ExecuteCommand('set sheet defaulttextvalueformat text-wiki');
          }
          $(document).on('mouseover', '.te_download tr:nth-child(2) td:first', function(){
            return $(this).attr({
              title: 'Export...'
            });
          });
          return $(document).on('click', '.te_download tr:nth-child(2) td:first', function(){
            var isMultiple;
            if ((typeof vex != 'undefined' && vex !== null) && vex.dialog.open) {
              SocialCalc.Keyboard.passThru = true;
            }
            isMultiple = window.__MULTI__ || /\.[1-9]\d*$/.exec(SocialCalc._room);
            if (typeof vex != 'undefined' && vex !== null) {
              vex.defaultOptions.className = 'vex-theme-flat-attack';
            }
            return typeof vex != 'undefined' && vex !== null ? vex.dialog.open({
              message: "Please choose an export format." + (isMultiple ? "<br><small>(EXCEL supports multiple sheets.)</small>" : ""),
              callback: function(){
                return SocialCalc.Keyboard.passThru = false;
              },
              buttons: [
                $.extend({}, typeof vex != 'undefined' && vex !== null ? vex.dialog.buttons.YES : void 8, {
                  text: 'Excel',
                  click: function(){
                    if (isMultiple) {
                      if (window.parent.location.href.match(/(^.*\/=[^?/]+)/)) {
                        return window.open(RegExp.$1 + ".xlsx");
                      } else {
                        return window.open("." + (window.parent.location.pathname.match('/.*/view$') || window.parent.location.pathname.match('/.*/edit$') ? '.' : '') + "/=" + SocialCalc._room.replace(/\.[1-9]\d*$/, '') + ".xlsx");
                      }
                    } else {
                      return window.open("." + (window.parent.location.pathname.match('/.*/view$') || window.parent.location.pathname.match('/.*/edit$') ? '.' : '') + "/" + SocialCalc._room + ".xlsx");
                    }
                  }
                }), $.extend({}, typeof vex != 'undefined' && vex !== null ? vex.dialog.buttons.YES : void 8, {
                  text: 'CSV',
                  click: function(){
                    return window.open("." + (window.parent.location.pathname.match('/.*/view$') || window.parent.location.pathname.match('/.*/edit$') ? '.' : '') + "/" + SocialCalc._room + ".csv");
                  }
                }), $.extend({}, typeof vex != 'undefined' && vex !== null ? vex.dialog.buttons.YES : void 8, {
                  text: 'HTML',
                  click: function(){
                    return window.open("." + (window.parent.location.pathname.match('/.*/view$') || window.parent.location.pathname.match('/.*/edit$') ? '.' : '') + "/" + SocialCalc._room + ".html");
                  }
                }), $.extend({}, typeof vex != 'undefined' && vex !== null ? vex.dialog.buttons.NO : void 8, {
                  text: 'Cancel'
                })
              ]
            }) : void 8;
          });
        };
        if ((ref$ = window.Document) != null && ref$.Parser) {
          SocialCalc.Callbacks.expand_wiki = function(val){
            return "<div class=\"wiki\">" + new Document.Parser.Wikitext().parse(val, new Document.Emitter.HTML()) + "</div>";
          };
        }
        return doPlay();
      }
    });
  };
}).call(this);
