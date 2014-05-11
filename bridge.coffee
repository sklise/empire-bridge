osc = require 'node-osc'
_ = require 'lodash'
require('dotenv').load()

oscServer = new osc.Server(1337, '0.0.0.0')
nano = require('nano')(process.env.CLOUDANT_URL)
resque = require('coffee-resque').connect
  host: "localhost"
  port: 6379

cookie = ''
couch = {}

nano.auth(process.env.CLOUDANT_KEY, process.env.CLOUDANT_PASSWORD, (err, body, headers) ->
  throw(err) if (err)

  console.log "Connected to Cloudant"
  cookie = _.first(headers['set-cookie'][0].split(";")) if headers and headers['set-cookie']

  couch = require('nano')({
    url: process.env.CLOUDANT_URL+"/" + process.env.CLOUDANT_DB
    cookie: cookie
  })
  run()
)

run = ->
  oscServer.on 'message', (msg, rinfo) ->
    points = _.rest(msg,2)
    _.forEach points, (point) ->
      key = point[0].substr(1)

      # data = [{"key":"foo","hey":1},{"key":"bar","hey":2},{"key":"baz","hey":3}]
      # console.log(data)
      # console.log(JSON.stringify(data))

      # couch.bulk(docs:data,{method:"post"},(a,b,c) -> console.log(a,b,c))

      # couch.insert(arg, (a,b,c) -> console.log(a,b,c))

      if key isnt 'flash'
        color = point[1].substr(2)
        resque.enqueue "empire", key, [{value:color}], (err, remain) ->
          console.log key + ":" + color
      else
        console.log "FLASH"