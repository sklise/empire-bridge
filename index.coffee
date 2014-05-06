osc = require 'node-osc'
_ = require 'lodash'

oscServer = new osc.Server(1337, '0.0.0.0')

resque = require('coffee-resque').connect
  host: "localhost"
  port: 6379

resque.enqueue "empire","data", [{key:true}]

oscServer.on 'message', (msg, rinfo) ->
  points = _.rest(msg,2)
  _.forEach points, (point) ->
    resque.enqueue "empire", "data", [{value:point[1]}], (err, remain) ->
      console.log [{key:point[0].substr(1), info:point[1]}]
      console.log remain
