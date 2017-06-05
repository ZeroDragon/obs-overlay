EventEmitter = require('events')
myEmitter = new EventEmitter()

cheerio = require 'cheerio'
request = require 'request'

youtube = null
timer = null

getYoutubeComments = ->
	clearTimeout(timer) if timer
	request {
		url: "https://www.youtube.com/live_chat?is_popout=1&v=#{youtube.video_id}"
		method: 'GET'
		headers: {
			'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
		}
	},(err,res,body)->
		try
			$ = cheerio.load body
			rs = $('script')

			arr = rs[6].children[0].data.split('contextMenuEndpoint').map (e)->
				return e[2...-2]
			arr.pop()
			arr.shift()

			arr = arr.map (e)->
				message = JSON.parse e.split("liveChatTextMessageRenderer")[1][2...]+'}'
				timestampUsec = e.split("liveChatTextMessageRenderer")[0].split('timestampUsec')[1].split(',')[0][3...-1]

				return {
					key: parseInt(timestampUsec/1000,10)
					value: {
						author: message.authorName.runs[0].text
						source: 'youtube'
						message: message.message.runs[0].text
					}
				}

			for comment in arr
				myEmitter.emit 'comment', comment
		timer = setTimeout getYoutubeComments ,~~youtube.refresh_time * 1000

module.exports = (b)->
	brain = b
	youtube = brain.get 'config:youtube'
	youtube.refresh_time = 5
	fb = brain.get('config:facebook')
	if fb?
		youtube.refresh_time = fb.refresh_time or 5
	getYoutubeComments()
	return myEmitter