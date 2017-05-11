port = 1337

express = require 'express'
app = express()
brain = require './database-connector'
bParser = require 'body-parser'
stylus = require 'stylus'
fs = require 'fs'

app.set('view engine', 'pug')
app.use(express.static('assets'))
app.use bParser.urlencoded { extended: true,limit: '2mb' }
app.use bParser.json({limit: '2mb'})

app.get '/', (req, res)->
	displays = brain.get 'config:displays'
	display = {
		displayChat : displays.chat is 'true'
		displayCamera : displays.camera is 'true'
		displayReactions : displays.reactions is 'true'
		reactions : ['LIKE','LOVE','THANKFUL','HAHA','WOW','SAD','ANGRY','SALT'].filter (e)->
			displays["reaction_#{e}"] is 'true'
	}
	res.render "index", display
app.get '/style.css', (req,res)->
	variables = {
		accentColor : "#ff6a00"
		cameraWidth : 300
		cameraHeight : 170
		reactionsHeight : 70
		spacing : 10
	}
	str = stylus(fs.readFileSync('./assets/style.styl',{encoding:'utf8'}))
	for own k,v of variables
		str.define k,v
	str.render (err,css)->
		console.log(err) if err
		if css
			res.header "Content-type", "text/css"
			res.send css
		else
			res.sendStatus(404)

app.get '/configure', (req,res)->
	res.render 'configure'
app.get '/oauth/:key?', (req,res)->
	if !req.params.key?
		res.render 'oauth'
		return
	actual = brain.get("config:twitch") or {}
	actual.pass = req.params.key
	brain.set "config:twitch", actual
	res.sendStatus 200
app.get '/actualConfigurations', (req,res)->
	res.json brain.get "config"

app.post '/saveConfig', (req,res)->
	for own k,v of req.body
		brain.set "config:#{k}",v
	res.sendStatus 200

app.get '/comments',(req,res)->
	comments = brain.get 'comments'
	res.json comments.sort (a,b)-> ~~a.key - ~~b.key
app.get '/reactions',(req,res)->
	facebookConfig = brain.get "config:facebook"
	postID = facebookConfig?.post_id or null
	reactions = brain.get("reactions:#{postID}") or {}
	for i in ['LIKE','LOVE','THANKFUL','HAHA','WOW','SAD','ANGRY','SALT']
		reactions[i] = 0 unless reactions[i]?
	res.json reactions
app.get '/newFollower',(req,res)->
	followers = brain.get('followers')
	newFollower = followers.filter((e)->e.value.new?)[0]
	if newFollower?
		delete newFollower.value.new
		brain.set "followers:#{newFollower.key}", newFollower.value
		res.json newFollower.value
	else
		res.json null

app.listen port, ->
	console.log("Listening on port #{port}!")