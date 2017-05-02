class Robot
	message : null
	constructor : (m)->
		@message = m
	on : (regex,cb)->
		cb @message.match(regex)
getRobot = (message,cb)->
	robot = new Robot message
	cb robot

module.exports = (m,cb)-> getRobot m,(robot)->
	robot.on /^\+salt$/i,(match)->
		return cb 'salter',1 if match
		cb null

	robot.on /^\-salt$/i,(match)->
		return cb 'salter',-1 if match
		cb null