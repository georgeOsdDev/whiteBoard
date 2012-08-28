###################
# dependencies
express  = require 'express'
routes   = require './routes'
http     = require 'http'
path     = require 'path'
socketIO = require 'socket.io'
# for data persistence,MongoDB and mongoose will be used　
# mongoose = require 'mongoose'

# app instance
app = express()

###################
# config
app.configure ->
  app.set 'title','WhiteBoard'
  app.set 'port', process.env.PORT || 3000
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'ejs'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use require('stylus').middleware("#{__dirname}/public")
  app.use express.static(path.join(__dirname, 'public'))
  app.use express.errorHandler()

###################
# config for development
# setup db info for local
app.configure 'development', ->
#  mongoose.connect 'mongodb://localhost/whiteboard-dev'

###################
# config for development
# set db info for Heroku
app.configure 'production', ->
#  mongoose.connect 'mongodb://localhost/whiteboard-pro'

###################
# routing
app.get '/', routes.index

###################
# Create express Server and listen it with socket.IO
io = socketIO.listen http.createServer(app).listen(app.get('port'))
console.log "Express server listening on port #{app.get('port')}"
console.log "Go http://#{process.env.VCAP_APP_HOST || 'localhost'}:#{app.get('port')}/" 

names = {}
texts = {}
lineNo = 1

io.sockets.on 'connection',  (socket) ->
  # console.log "new user connected"
  socket.emit 'init', {
                        names:names
                        texts:texts
                        lineNo:lineNo
                      }

  socket.on 'update', (receivedata) ->
    # console.log " #{socket.id} updated"
    console.warn receivedata
    id = receivedata.id
    val = receivedata.val
    name = receivedata.name
    if name is 'name' then names[id] = val
    if name is 'text' then texts[id] = val
    io.sockets.emit 'update' , {
                                  id:id
                                  val:val
                                }

  socket.on 'addLine', (receivedata) ->
    # console.log " #{socket.id} addLine"
    lineNo++
    io.sockets.emit 'addLine' , {
                                  lineNo:lineNo
                                }

  socket.on 'heartbeat', ->
    # console.log " #{socket.id} is alive"

  socket.on 'disconnect', ->
    # console.log "one user disconnected #{socket.id}"

  socket.on 'error', (event)->
    # console.log "Error occured", event
