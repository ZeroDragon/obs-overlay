fileDB = require './filedatabase'
brain = new fileDB
addZ = (i)-> "00#{i}".slice(-2)

saveComment = (comment)->
	brain.set "comments:#{comment.key}", comment.value
	brain.ttl "comments:#{comment.key}", 86400

saveReaction = (reaction,count)->
	{facebook:{postID:postID}} = brain.get 'config:facebook'
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
	{facebook:{postID:postID}} = brain.get 'config:facebook'
	reactionKey = "reactions:#{postID}"
	actual = brain.get reactionKey
	actual = {SALT:0} unless actual?.SALT?
	actual.SALT = actual.SALT + plusOrMinus
	actual.SALT = 0 if actual.SALT < 0
	brain.set reactionKey, actual
	brain.ttl reactionKey, 86400

if brain.get 'config:facebook'
	facebookMiner = require('./miner-facebook')(brain.get('config:facebook'))
	facebookMiner.on 'reaction', saveReaction
	facebookMiner.on 'comment', saveComment

if brain.get 'config:twitch'
	twitchMiner = require('./miner-twitch')(brain.get('config:twitch'))
	twitchMiner.on 'chat', saveComment
	twitchMiner.on 'salter', saveSalt

module.exports = brain