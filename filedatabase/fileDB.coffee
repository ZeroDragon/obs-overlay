fs = require 'fs'
config = require './config.json'
module.exports = class FileDB
	storage : "#{__dirname}/storage/"
	constructor : (storage)->
		@storage = storage if storage?
		{@info} = require('nicelogger').config(config.logger)
		@info "Connected to database on #{@storage}"
	setLogLevel : (level)->
		# info > info > warning > error > log > countdown > progress
		@setLogLvl {logLevel:level}
	setToFile : (file,data)->
		fs.writeFileSync "#{@storage}#{file}", JSON.stringify data
	getFromFile : (file)->
		if fs.existsSync "#{@storage}#{file}"
			try
				return JSON.parse fs.readFileSync "#{@storage}#{file}", {encoding:'utf8'}
			catch e
				return []
		return []
	processRef : (ref)->
		[file,key] = ref.split(':')
		actual = @getFromFile(file)
		return [file,key,actual]
	set : (ref,value)->
		[file,key,actual] = @processRef ref
		filtered = actual.filter (e)-> e.key isnt key
		filtered.push {key:key,value:value}
		@setToFile file, filtered
	get : (ref)->
		[file,key,actual] = @processRef ref
		len1 = actual.length
		actual = actual.filter (e)->
			if e.ttl?
				return e.ttl > ~~(new Date().getTime()/1000)
			return true
		if len1 isnt actual.length
			@setToFile file, actual
		if key?
			itm = actual.filter((e)-> e.key is key)[0]
			return itm.value if itm?
			return null
		return actual
	del : (ref)->
		[file,key,actual] = @processRef ref
		filtered = actual.filter (e)-> e.key isnt key
		@setToFile file, filtered
	ttl : (ref,ttl)->
		[file,key,actual] = @processRef ref
		itm = actual.filter((e)-> e.key is key)[0]
		if itm?
			itm.ttl = ~~(new Date().getTime()/1000)+ttl
			filtered = actual.filter (e)-> e.key isnt key
			filtered.push itm
			@setToFile file, filtered
	clearTtl : (ref)->
		[file,key,actual] = @processRef ref
		itm = actual.filter((e)-> e.key is key)[0]
		if itm?
			delete itm.ttl
			filtered = actual.filter (e)-> e.key isnt key
			filtered.push itm
			@setToFile file, filtered
