WebSocket = require 'ws'
parseIRC = require './parseIRC'
getEmotes = require './generateEmotes'
robot = require './robot'
emoticons = null
twitch = null
EventEmitter = require('events')
myEmitter = new EventEmitter()

processTwitchMessage = (nick,tags,message)->
	displayNick = "Chat"
	if nick? and tags?
		displayNick = tags["display-name"] or nick
		emotes = tags.emotes.toString().split('/').filter (e)-> e isnt 'true'
		replacements = []
		for type,k in emotes
			t = type.split(':')
			t.shift()
			t = t.join('').split(',')
			for pos in t
				[start,end] = pos.split('-')
				mess = message.split('')
				wide = (end-start)+1
				fill = [0...wide].map(-> k).join('')
				replacements.push mess[start..end].join('')
				mess.splice(start,wide,fill)
				message = mess.join('')

		replacements = replacements.filter (e,i,s)->
			s.indexOf(e) is i

		for rep,k in replacements
			search = [0...rep.length].map(-> k).join('')
			emoticon = emoticons.filter((e)-> e.regex is rep)[0]
			emoticon = emoticon.images[0]
			emoticon = "<img src='#{emoticon.url}' style='width:#{emoticon.width}px;height:#{emoticon.height}'/>"
			r = new RegExp search,'g'
			message = message.replace r, emoticon
	myEmitter.emit 'chat', {
		key : new Date().getTime()
		value : {
			author : displayNick
			source : 'twitch'
			message : message
		}
	}
	
startSocket = ->
	return unless twitch.pass? and twitch.username? and twitch.channel?
	return if twitch.pass is '' or twitch.username is ''
	channel = if twitch.channel isnt '' then twitch.channel else twitch.username
	socket = new WebSocket 'wss://irc-ws.chat.twitch.tv', 'irc', { reconnectInterval: 3000 }
	socket.onopen = (data)->
		# processTwitchMessage(null, null, "Connected.")
		socket.send("PASS oauth:#{twitch.pass}\r\n")
		socket.send("NICK #{twitch.username}\r\n")
		socket.send('CAP REQ :twitch.tv/commands twitch.tv/tags twitch.tv/membership\r\n')
		socket.send("JOIN ##{twitch.channel}\r\n")

	socket.onclose = ->
		# processTwitchMessage(null, null, "You were disconnected from the server.")

	socket.onmessage = (data)->
		message = parseIRC(data.data.trim())
		return if !message.command
		switch message.command
			when "PING"
				socket.send 'PONG ' + message.params[0]
				return
			when "JOIN"
				# processTwitchMessage null, null, "Joined channel: #{twitch.username}"
				return
			when "CLEARCHAT"
				# console.log(message.params[1]) if message.params[1]
				return
			when "PRIVMSG"
				{emoticons} = getEmotes()
				return if message.params[0] isnt "##{twitch.channel}" or !message.params[1]
				nick = message.prefix.split('@')[0].split('!')[0]
				processTwitchMessage nick, message.tags, message.params[1]
				robot message,(r,v,s)->
					if s
						socket.send("PRIVMSG ##{twitch.channel} :"+ s)
						if twitch.bot_in_chat is 'true'
							processTwitchMessage 'BOT', {emotes:true}, s
					myEmitter.emit(r,v) if r
				return
			# else
			# 	console.log message.command,message

module.exports = (cnf)->
	{emoticons} = getEmotes()
	twitch = cnf
	startSocket()
	return myEmitter