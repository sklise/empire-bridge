osc = require 'node-osc'
_ = require 'lodash'
require('dotenv').load()

oscServer = new osc.Server(1337, '0.0.0.0')

resque = require('coffee-resque').connect
  host: "localhost"
  port: 6379

nano = require('nano')(process.env.CLOUDANT_URL)
cookie = ''
couch = {}

nano.auth(process.env.CLOUDANT_KEY, process.env.CLOUDANT_PASSWORD, (err, body, headers) ->
  throw(err) if (err)

  if headers and headers['set-cookie']
    console.log headers['set-cookie']
    cookie = _.first(headers['set-cookie'][0].split(";"))

  couch = require('nano')({
    url: process.env.CLOUDANT_URL+"/empire"
    cookie: cookie
  })

  console.log "Connected to Couch"

  data = [{"key":"foo","hey":1},{"key":"bar","hey":2},{"key":"baz","hey":3}]
  console.log(data)
  console.log(JSON.stringify(data))

  couch.bulk(docs:data,{method:"post"},(a,b,c) -> console.log(a,b,c))

  run()
)

run = ->
  oscServer.on 'message', (msg, rinfo) ->
    points = _.rest(msg,2)
    _.forEach points, (point) ->
      resque.enqueue "empire", "data", [{value:point[1]}], (err, remain) ->
        console.log [{key:point[0].substr(1), info:point[1]}]
        console.log remain
        # couch.insert(arg, (a,b,c) -> console.log(a,b,c))
