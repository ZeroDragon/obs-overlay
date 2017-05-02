express = require 'express'
app = express()
brain = require './database-connector'
app.set('view engine', 'pug')
app.use(express.static('assets'))
{facebook:{postID:postID}} = require './config.json'

app.get '/', (req, res)->
	res.render "index"
app.get '/configure', (req,res)->
	res.render 'configure'
app.get '/comments',(req,res)->
	comments = brain.get 'comments'
	res.json comments.sort (a,b)-> ~~a.key - ~~b.key
app.get '/reactions',(req,res)->
	reactions = brain.get "reactions:#{postID}"
	for i in ['LIKE','LOVE','HAHA','WOW','SAD','ANGRY','SALT']
		reactions[i] = 0 unless reactions[i]?
	res.json reactions

app.listen 1337, ->
	console.log('Listening on port 3000!')