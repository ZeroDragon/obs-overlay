fileDB = require './filedatabase'
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

prevConfigFacebook = null
prevConfigTwitch = null

configFacebook = brain.get 'config:facebook'
if configFacebook
	prevConfigFacebook = configFacebook
	facebookMiner = require('./miner-facebook')(configFacebook)
	facebookMiner.on 'reaction', saveReaction
	facebookMiner.on 'comment', saveComment

configTwitch = brain.get 'config:twitch'
if configTwitch
	brain.del "twitchData:channelID"
	configTwitch.bot_in_chat = brain.get('config:displays').bot_in_chat
	fb = brain.get('config:facebook')
	if fb?
		configTwitch.refresh_time = fb.refresh_time or 5
	twitchMiner = require('./miner-twitch')(configTwitch,brain)
	twitchMiner.on 'chat', saveComment
	twitchMiner.on 'salter', saveSalt
	twitchMiner.on 'saveTwitchData', saveTwitchData
	twitchMiner.on 'saveTwitchFollowers', saveTwitchFollowers

module.exports = brain