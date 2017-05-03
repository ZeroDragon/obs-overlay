request = require 'request'
EventEmitter = require('events')
myEmitter = new EventEmitter()

access_token = postID = refreshTime = null
timer1 = timer2 = null
addZ = (i)-> "00#{i}".slice(-2)
reactionsArray = ['LIKE', 'LOVE', 'WOW', 'HAHA', 'SAD', 'ANGRY']
reactions = reactionsArray
	.map (e)->
		code = "reactions_#{e.toLowerCase()}"
		return "reactions.type(#{e}).limit(0).summary(total_count).as(#{code})"
	.join(',')

refreshCounts = ->
	return unless postID?
	return if postID is ''
	url = "https://graph.facebook.com/v2.8/?ids=#{postID}&fields=#{reactions}&access_token=#{access_token}"
	request.get url,{json:true},(err,res,body)->
		for reaction in reactionsArray
			myEmitter.emit 'reaction', "#{reaction}",body[postID]["reactions_#{reaction.toLowerCase()}"].summary.total_count

refreshComments = ->
	return unless postID?
	return if postID is ''
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

rComments = ->
	clearTimeout(timer1) if timer1
	refreshComments()
	timer1 = setTimeout rComments, ~~refreshTime * 1000

rCounts = ->
	clearTimeout(timer2) if timer2
	refreshCounts()
	timer2 = setTimeout rCounts, ~~refreshTime * 1000

module.exports = (conf)->
	{access_token,post_id:postID,refresh_time:refreshTime} = conf
	rComments()
	rCounts()
	return myEmitter