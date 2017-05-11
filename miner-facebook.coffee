request = require 'request'
EventEmitter = require('events')
myEmitter = new EventEmitter()

timer1 = timer2 = brain = null
addZ = (i)-> "00#{i}".slice(-2)
reactionsArray = ['LIKE', 'LOVE', 'THANKFUL' ,'WOW', 'HAHA', 'SAD', 'ANGRY']
reactions = reactionsArray
	.map (e)->
		code = "reactions_#{e.toLowerCase()}"
		return "reactions.type(#{e}).limit(0).summary(total_count).as(#{code})"
	.join(',')

getBrainData = (cb)->
	cnfFacebook = brain.get('config:facebook')
	rft = 1
	if cnfFacebook?.refresh_time?
		rft = ~~cnfFacebook.refresh_time
	if rft < 1 then rft = 1
	if cnfFacebook?
		if cnfFacebook.access_token? and cnfFacebook.post_id?
			cb {
				access_token : cnfFacebook.access_token
				postID : cnfFacebook.post_id
				refreshTime : rft
			}
			return
	cb {refreshTime:rft}
	return

refreshCounts = -> getBrainData ({access_token,postID})->
	return unless postID?
	return if postID is ''
	url = "https://graph.facebook.com/v2.8/?ids=#{postID}&fields=#{reactions}&access_token=#{access_token}"
	request.get url,{json:true},(err,res,body)->
		return unless body?[postID]?
		for reaction in reactionsArray
			myEmitter.emit 'reaction', "#{reaction}",body[postID]["reactions_#{reaction.toLowerCase()}"].summary.total_count

refreshComments = -> getBrainData ({access_token,postID})->
	return unless postID?
	return if postID is ''
	request {
		method : "GET"
		url : "https://graph.facebook.com/v2.8/#{postID}/comments?filter=stream&order=reverse_chronological"
		headers : {"Authorization" : "OAuth #{access_token}"}
		json : true
	},(err,res,body)->
		return unless body?.data?
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

rComments = -> getBrainData ({refreshTime})->
	clearTimeout(timer1) if timer1
	refreshComments()
	timer1 = setTimeout rComments, ~~refreshTime * 1000

rCounts = -> getBrainData ({refreshTime})->
	clearTimeout(timer2) if timer2
	refreshCounts()
	timer2 = setTimeout rCounts, ~~refreshTime * 1000

module.exports = (b)->
	brain = b
	rComments()
	rCounts()
	return myEmitter