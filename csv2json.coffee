Row = (columns) ->
  @columns = columns or []
  @data = {}
  this

csv2json = (opts) ->
  that = this
  that.currentData = ""
  that.rows = []
  that.started = false
  that.headers = opts.headers or false
  that.outputArray = opts.outputArray or false
  that.opts = opts or {}
  that.opts.delim = /,(?!(?:[^",]|[^"],[^"])+")/  if not that.opts.delim or that.opts.delim is ","
  that.opts.delim = "\\t"  if that.opts.delim is "\t"
  that.opts.doublequote = true  if typeof that.opts.doublequote is `undefined`
  that.heades = true  if that.opts.headers is true
  s = new Stream()
  s.writable = true
  s.readable = true
  that.hasStarted = ->
    if that.started is false
      s.emit "data", "["  if that.outputArray
      that.started = true

  that.lineEnding = null
  that.getLineEnding = ->
    that.lineEnding = (if (that.currentData.indexOf("\r") isnt -1) then "\r\n" else "\n")  unless that.lineEnding
    that.lineEnding

  s.write = (buffer) ->
    that.currentData += buffer
    that.getLineEnding()
    if that.currentData.indexOf(that.lineEnding) isnt -1
      i = 0
      arr = that.currentData.split(that.lineEnding)
      
      # if the first line is headers has been set
      if that.headers and that.started is false
        that.opts.columns = arr[0].split(that.opts.delim)
        i = 1
        that.hasStarted()
      len = arr.length
      while i < len - 1
        emitend = (if (that.outputArray) then "," else "")
        dr = new Row(that.opts.columns)
        dr.parseToRow arr[i], that.opts.delim, (err, data) ->
          s.emit "data", data + emitend

        i++
      that.currentData = arr[len - 1]

  s.end = (buffer) ->
    that.getLineEnding()
    arr = that.currentData.split(that.lineEnding)
    len = arr.length
    
    # if the first line is headers has been set
    if that.headers and that.started is false
      that.opts.columns = arr[0].split(that.opts.delim)
      i = 1
      that.hasStarted()
    i = 0

    while i < len
      emitend = undefined
      if that.outputArray
        emitend = (if (i is len - 1) then "] \n" else ", \n")
      else
        emitend = "\n"
      dr = new Row(that.opts.columns)
      dr.parseToRow arr[i], that.opts.delim, (err, data) ->
        s.emit "data", data + emitend

      i++
    s.writable = false

  s.destroy = ->
    s.writable = false

  s
Stream = require("stream")
tryParse = require("tryparse")
Row::parseToRow = (data, delim, cb) ->
  that = this
  array = data.split(delim)
  hasColumns = undefined
  parseNum = undefined
  hasColumns = false  unless that.columns
  parseNum = false  unless that.parseNum
  i = 0

  while i < array.length
    that.columns.push "Column" + i  unless hasColumns
    data = array[i].replace(/"/g, "").trim()
    val = tryParse.float(data) or tryParse.int(data) or data if parseNum
    val = data if !parseNum
    that.data[that.columns[i]] = (if (val is data) then val else data)
    i++
  cb null, JSON.stringify(that.data, null, 4)

module.exports = csv2json
