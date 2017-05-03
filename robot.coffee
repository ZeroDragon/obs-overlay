class Robot
	message : null
	transport : null
	constructor : (m,t)->
		@message = m
		@transport = t
	send : (message)->
		@transport null,null,message
	on : (regex,cb)->
		cb(@message.params[1].match(regex),@message.tags) if @message.params[1].match(regex)
getRobot = (message,transport,cb)->
	robot = new Robot message,transport
	cb robot

module.exports = (m,cb)-> getRobot m,cb,(robot)->
	robot.on /^\+salt$/i,(match)->
		cb 'salter',1

	robot.on /^\-salt$/i,(match)->
		return cb 'salter',-1

	robot.on /hola Zero/,(match,tags)->
		robot.send 'here '+tags['display-name']