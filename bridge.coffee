osc = require 'node-osc'
_ = require 'lodash'
url = require 'url'
require('dotenv').load()

redisUrl = url.parse(process.env.REDISCLOUD_URL)
oscServer = new osc.Server(1337, '0.0.0.0')
nano = require('nano')(process.env.CLOUDANT_URL)
resque = require('coffee-resque').connect
  host: redisUrl.hostname
  port: redisUrl.port
  password: redisUrl.auth.split(":")[1]
  timeout: 1000

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
    # Based on how the OSC messages are being sent the first two elements
    # are inconsequential to this application, get rid of them.
    points = _.rest(msg,2)
    couch_data = []

    _.forEach points, (point) ->
      key = point[0].substr(1)

      if key is 'flashes'
        parsed = JSON.parse(point[1])

        resque.enqueue "empire", key, [{details:parsed}]

        couch_data.push {
          time: (new Date()).getTime()
          type: key
          details: parsed
        }
      else
        colors = _.map point[1].split(","), (d) ->
          d.substr(2)
        couch_data.push {
          time: (new Date()).getTime()
          type: key
          details: {
            color: colors
          }
        }

      # Bulk upload to couch to reduce the amount of requests being made both
      # for this server as well as for couch.
      couch.bulk {docs: couch_data}, {method:"post"}, (err,b,c) ->
        if err then throw err