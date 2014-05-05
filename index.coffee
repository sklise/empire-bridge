osc = require 'node-osc'
_ = require 'lodash'
resque = require('coffee-resque').connect
  host: "localhost"
  port: 6379

oscServer = new osc.Server(1337, '0.0.0.0')

oscServer.on 'message', (msg, rinfo) ->
  points = _.rest(msg,2)
  _.forEach points, (point) ->
    resque.enqueue point[0].substr(1), point[1], (err, remain) ->
      console.log remain
