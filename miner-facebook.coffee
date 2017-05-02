{facebook:{access_token:access_token,postID:postID,refreshTime:refreshTime,defaultCount:defaultCount}} = require './config.json'
request = require 'request'
EventEmitter = require('events')
myEmitter = new EventEmitter()

addZ = (i)-> "00#{i}".slice(-2)
reactionsArray = ['LIKE', 'LOVE', 'WOW', 'HAHA', 'SAD', 'ANGRY']
reactions = reactionsArray
	.map (e)->
		code = "reactions_#{e.toLowerCase()}"
		return "reactions.type(#{e}).limit(0).summary(total_count).as(#{code})"
	.join(',')

refreshCounts = ->
	url = "https://graph.facebook.com/v2.8/?ids=#{postID}&fields=#{reactions}&access_token=#{access_token}"
	request.get url,{json:true},(err,res,body)->
		for reaction in reactionsArray
			myEmitter.emit 'reaction', "#{reaction}",body[postID]["reactions_#{reaction.toLowerCase()}"].summary.total_count

refreshComments = ->
	request {
		method : "GET"
		url : "https://graph.facebook.com/v2.8/#{postID}/comments?filter=stream&order=reverse_chronological"
		headers : {"Authorization" : "OAuth #{access_token}"}
		json : true
	},(err,res,body)->
		data = body.data.map (e)->
			{
				key : new Date(e.created_time).getTime()
				value : {
					author : e.from.name
					source : 'facebook'
					message : e.message
				}
			}
		for comment in data
			myEmitter.emit 'comment', comment

setInterval refreshCounts, refreshTime * 1000
refreshCounts()
setInterval refreshComments, refreshTime * 1000
refreshComments()

module.exports = myEmitter