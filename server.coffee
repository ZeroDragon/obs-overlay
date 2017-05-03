express = require 'express'
app = express()
brain = require './database-connector'
app.set('view engine', 'pug')
app.use(express.static('assets'))

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
app.post '/saveConfig', (req,res)->
	console.log req,res
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

app.listen 1337, ->
	console.log('Listening on port 3000!')