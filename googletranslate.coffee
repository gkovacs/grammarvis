root = exports ? this
print = console.log

#sys = require 'util'
#child_process = require 'child_process'
#fs = require 'fs'

http_get = require 'http-get'

redis = require 'redis'
client = redis.createClient()

fs = require 'fs'
querystring = require 'querystring'

escapeUnicodeEncoded = (text) ->
  return unescape(text.split('\\u').join('%u'))

googleapikey = fs.readFileSync('google_api_key.txt', 'utf-8').trim()

getTranslationsReal = (fromtext, fromlanguage, tolanguage, callback) ->
  reqtxt = fromtext.split('"').join('')
  #command = 'w3m "http://translate.google.com/translate_a/t?client=t&text=' + reqtxt + '&sl=zh&tl=zh-CN&ie=UTF-8" -dump'
  #child_process.exec(command, (error, stdout, stderr) ->
  #req_headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.2; WOW64; rv:16.0.1) Gecko/20121011 Firefox/16.0.1'}
  #http_get.get({url: 'http://translate.google.com/translate_a/t?client=t&text=' + reqtxt + '&sl=zh&tl=zh-CN&ie=UTF-8', headers: req_headers}, (err, dlData) ->
  http_get.get({'url': 'https://www.googleapis.com/language/translate/v2?' + querystring.stringify({'key': googleapikey,'source': fromlanguage, 'target': tolanguage, 'q': fromtext})}, (err, dlData) ->
    buffer = dlData.buffer
    responseJSON = JSON.parse(buffer)
    translations = responseJSON['data']['translations']
    #for i in [0...translations.length]
    #  translations[i].TranslatedText = translations[i].translatedText
    client.set('gtrans_' + fromlanguage + '_to_' + tolanguage + '_j5|' + reqtxt, JSON.stringify(translations))
    callback(translations)
  )

getTranslations = root.getTranslations = (fromtext, fromlanguage, tolanguage, callback) ->
  reqtxt = fromtext.split('"').join('')
  client.get('gtrans_' + fromlanguage + '_to_' + tolanguage + '_j5|' + reqtxt, (err, reply) ->
    if reply?
      callback(JSON.parse(reply))
    else
      getTranslationsReal(fromtext, fromlanguage, tolanguage, callback)
  )

#getTranslationsReal('你好', 'zh', 'en', (trans) -> console.log trans)

lastPinyinFetchTimestamp = 0

getTranslationsRateLimited = (fromtext, fromlanguage, tolanguage, callback) ->
  timestamp = Math.round((new Date()).getTime() / 1000)
  if lastPinyinFetchTimestamp + 1 >= timestamp
    setTimeout(() ->
      getTranslationsRateLimited(fromtext, fromlanguage, tolanguage, callback)
    , 250)
  else
    lastPinyinFetchTimestamp = timestamp
    getTranslationsReal(text, callback)

getTranslationsRateLimitedCached = (fromtext, fromlanguage, tolanguage, callback) ->
  client.get('gtrans_' + fromlanguage + '_to_' + tolanguage + '_j5|' + text, (err, reply) ->
    if reply?
      callback(text, reply)
    else
      getTranslationsRateLimited(text, callback)
  )

#root.getPinyin = getPinyin
#root.getPinyinRateLimitedCached = getPinyinRateLimitedCached

main = ->
  text = process.argv[2] ? '你好'
  fromlang = process.argv[3] ? 'zh'
  tolang = process.argv[4] ? 'en'
  #console.log text
  getTranslations(text, fromlang, tolang, (translation) ->
    print translation
  )

main() if require.main is module
