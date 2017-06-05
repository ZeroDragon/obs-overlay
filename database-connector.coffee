fileDB = require 'filedatabase'
brain = new fileDB
addZ = (i)-> "00#{i}".slice(-2)

saveComment = (comment)->
	brain.set "comments:#{comment.key}", comment.value
	brain.ttl "comments:#{comment.key}", 86400

saveReaction = (reaction,count)->
	{post_id:postID} = brain.get 'config:facebook'
	reactionKey = "reactions:#{postID}"
	actual = brain.get reactionKey
	if actual?
		actual[reaction] = count
	else
		actual = {}
		actual[reaction] = count
	brain.set reactionKey, actual
	brain.ttl reactionKey, 86400

saveSalt = (plusOrMinus)->
	{post_id:postID} = brain.get 'config:facebook'
	reactionKey = "reactions:#{postID}"
	actual = brain.get reactionKey
	actual = {SALT:0} unless actual?.SALT?
	actual.SALT = actual.SALT + plusOrMinus
	actual.SALT = 0 if actual.SALT < 0
	brain.set reactionKey, actual
	brain.ttl reactionKey, 86400

saveTwitchData = (obj)->
	brain.set "twitchData:#{obj.key}", obj.value
saveTwitchFollowers = (arr)->
	actual = brain.get "followers"
	arr = arr.map (e)->
		return {
			key : e.id
			value : {
				name : e.name
				new : true
			}
		}
	arr = arr.filter (e)->
		return !actual.filter((ee)->ee.key is e.key)[0]?
	for follower in arr
		brain.set "followers:#{follower.key}", follower.value

if brain.get('config:facebook')?
	facebookMiner = require('./miner-facebook')(brain)
	facebookMiner.on 'reaction', saveReaction
	facebookMiner.on 'comment', saveComment

if brain.get('config:twitch')?
	twitchMiner = require('./miner-twitch')(brain)
	twitchMiner.on 'chat', saveComment
	twitchMiner.on 'salter', saveSalt
	twitchMiner.on 'saveTwitchData', saveTwitchData
	twitchMiner.on 'saveTwitchFollowers', saveTwitchFollowers

if brain.get('config:youtube')?
	youtubeMiner = require('./miner-youtube')(brain)
	youtubeMiner.on 'comment', saveComment

module.exports = brain