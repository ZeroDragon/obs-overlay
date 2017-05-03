request = require 'request'
fs = require 'fs'
file = "#{__dirname}/emoticons.json"
cacheTime = 30 #30 minutes to re-create the file from web
generateFile = (wReturn)->
	console.log 'Re-Generating emoticons file'
	request.get 'https://api.twitch.tv/kraken/chat/emoticons',(err,resp,body)->
		fs.writeFileSync file, body
		checkFile() if wReturn?

checkFile = ->
	if fs.existsSync file
		{mtime} = fs.statSync file
		lastUpdated = ~~(mtime.getTime()/1000)
		now = ~~(new Date().getTime()/1000)
		if now - lastUpdated > cacheTime*60
			generateFile()
		return JSON.parse(fs.readFileSync(file))
	else
		generateFile(true)

module.exports = checkFile