express = require 'express'
app = express()
brain = require './database-connector'
bParser = require 'body-parser'

app.set('view engine', 'pug')
app.use(express.static('assets'))
app.use bParser.urlencoded { extended: true,limit: '2mb' }
app.use bParser.json({limit: '2mb'})

app.get '/', (req, res)->
	res.render "index"
app.get '/configure', (req,res)->
	res.render 'configure'
app.get '/oauth/:key?', (req,res)->
	if !req.params.key?
		res.render 'oauth'
		return
	actual = brain.get("config:twitch") or {}
	actual.pass = "oauth:#{req.params.key}"
	brain.set "config:twitch", actual
	res.sendStatus 200
app.get '/actualConfigurations', (req,res)->
	res.json brain.get "config"

app.post '/saveConfig', (req,res)->
	console.log req.body
	res.sendStatus 200

app.get '/comments',(req,res)->
	comments = brain.get 'comments'
	res.json comments.sort (a,b)-> ~~a.key - ~~b.key
app.get '/reactions',(req,res)->
	facebookConfig = brain.get "config:facebook"
	postID = facebookConfig?.postID or null
	reactions = brain.get("reactions:#{postID}") or {}
	for i in ['LIKE','LOVE','HAHA','WOW','SAD','ANGRY','SALT']
		reactions[i] = 0 unless reactions[i]?
	res.json reactions

port = 1337
app.listen port, ->
	console.log("Listening on port #{port}!")