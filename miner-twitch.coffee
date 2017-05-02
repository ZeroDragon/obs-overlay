WebSocket = require 'ws' 
parseIRC = require './parseIRC'
getEmotes = require './generateEmotes'
{twitch} = require './config.json'
robot = require './robot'
emoticons = null
EventEmitter = require('events')
myEmitter = new EventEmitter()

processTwitchMessage = (nick,tags,message)->
	robot message,(r,v)-> myEmitter.emit(r,v) if r
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
	

socket = new WebSocket 'wss://irc-ws.chat.twitch.tv', 'irc', { reconnectInterval: 3000 }
socket.onopen = (data)->
	{emoticons} = getEmotes()
	# processTwitchMessage(null, null, "Connected.")
	socket.send("PASS #{twitch.pass}\r\n")
	socket.send("NICK #{twitch.user}\r\n")
	socket.send('CAP REQ :twitch.tv/commands twitch.tv/tags\r\n')
	socket.send("JOIN ##{twitch.user}\r\n")

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
			# processTwitchMessage null, null, "Joined channel: #{twitch.user}"
			return
		when "CLEARCHAT"
			console.log(message.params[1]) if message.params[1]
			return
		when "PRIVMSG"
			{emoticons} = getEmotes()
			return if message.params[0] isnt "##{twitch.user}" or !message.params[1]
			nick = message.prefix.split('@')[0].split('!')[0]
			processTwitchMessage nick, message.tags, message.params[1]
			return

module.exports = myEmitter