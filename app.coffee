$ = require('jquery')(require("jsdom").jsdom().parentWindow)
request = require 'request'
needle = require 'needle'

exec = require('child_process').exec
spawn = require('child_process').spawn

#translator = require './translator'
translator = require './googletranslate'

express = require 'express'
app = express()

http = require 'http'
https = require 'https'

http_get = require 'http-get'

redis = require 'redis'
rclient = redis.createClient()

fs = require 'fs'

async = require 'async'
memoize = async.memoize

cmdArgs = (x for x in process.argv when x.indexOf('node') == -1 and x.indexOf('iced') == -1 and x.indexOf('coffee') == -1 and x.indexOf('supervisor') == -1)

#console.log cmdArgs

if cmdArgs.indexOf('https') != -1
  console.log 'starting with https'
  https_options = {
    'key': fs.readFileSync('ssl-cert-snakeoil.key'),
    'cert': fs.readFileSync('ssl-cert-snakeoil.pem'),
  }
  app.get('/nowjs/now2.js', (req, res) ->
    myhost = req.headers.host
    console.log 'https://' + myhost + '/nowjs/now.js'
    if not myhost?
      myhost = 'geza.csail.mit.edu:1358'
    request.get('https://localhost:1358/nowjs/now.js', (err, result, body) ->
      res.end body.split('nowInitialize("//localhost:1358').join('nowInitialize("https://' + myhost)
    )
  )
  httpserver = https.createServer(https_options, app)
  httpserver.listen(1358)
else
  app.get('/nowjs/now2.js', (req, res) ->
    myhost = req.headers.host
    console.log 'http://' + myhost + '/nowjs/now.js'
    if not myhost?
      myhost = 'geza.csail.mit.edu:1357'
    request.get('http://localhost:1357/nowjs/now.js', (err, result, body) ->
      res.end body.split('nowInitialize("//localhost:1357').join('nowInitialize("http://' + myhost)
    )
  )
  httpserver = http.createServer(app)
  httpserver.listen(1357)

app.get('/nowjs/now2.js', (req, res) ->
  request.get("#{req.method}://#{req.hostname}:#{req.port}/nowjs/now.js", (err, result, body) ->
    res.end body.split('nowInitialize("//').join('nowInitialize("' + req.method + '://')
  )
)

nowjs = require 'now'
everyone = nowjs.initialize(httpserver)

app.configure('development', () ->
  app.use(express.errorHandler())
)

app.configure( ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'ejs')
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.set('view options', { layout: false })
  app.locals({ layout: false })
  app.use(express.static(__dirname + '/'))
)

app.get('/pull', (req, res) ->
  exec('git pull origin master', console.log)
  res.send 'done'
)

app.post('/pull', (req, res) ->
  exec('git pull origin master', console.log)
  res.send 'done'
)

ocrServiceURL = null

getOCRServiceURL = (callback) ->
  if ocrServiceURL?
    callback(ocrServiceURL)
  else
    request.get('http://transgame.csail.mit.edu:9537/?varname=win7ipaddress', (error, result, body) ->
      ocrServiceURL = 'http://' + body.trim() + ':8080/'
      callback(ocrServiceURL)
    )

everyone.now.getOCR = getOCR = (image, lang, callback) ->
  request.post({'url': ocrServiceURL, 'body': image}, (error, result, body) ->
    callback(body)
  )

app.get '/getParse', (req, res) ->
  console.log 'getParse called'
  console.log req.query.sentence
  console.log req.query.lang
  getParse(req.query.sentence, req.query.lang, (parsed) ->
    console.log 'have parse:'
    console.log parsed
    res.end parsed
  )

everyone.now.getParse = getParse = (sentence, lang, callback) ->
  console.log 'http://geza.csail.mit.edu:3555/parse?lang=' + lang + '&sentence=' + sentence
  request.get('http://geza.csail.mit.edu:3555/parse?lang=' + lang + '&sentence=' + sentence, (error, result, data) ->
    callback(data)
  )

terminals = (s, lang) ->
  output = []
  current_terminal = []
  for c in s
    if c == '('
      last_paren_type = '('
      current_terminal = []
    else if c == ')'
      if last_paren_type == '('
        if current_terminal.length > 0
          to_print = current_terminal.join('')
          [tag,terminal] = to_print.split(' ')
          output.push terminal
      last_paren_type = ')'
      current_terminal = []
    else
      current_terminal.push(c)
  if lang == 'zh'
    return output.join('')
  return output.join(' ')

getChildren = (s) ->
  curchild = []
  children = []
  depth = 0
  for c in s
    if c == '('
      depth += 1
    if depth >= 2
      curchild.push c
    if c == ')'
      depth -= 1
      if depth == 1
        children.push curchild.join('')
        curchild = []
  return children

app.get '/getPartList', (req, res) ->
  console.log 'getPartList called'
  console.log req.query.sentence
  console.log req.query.lang
  sentence = req.query.sentence
  callbackName = req.query.callback
  lang = req.query.lang
  getParse(sentence, lang, (parsed) ->
    constituents = getPartList(parsed, lang)
    jsonOutput = JSON.stringify(constituents)
    if not callbackName?
      res.end(jsonOutput)
    else
      res.writeHead(200, { 'Content-Type': 'application/javascript' })
      res.end(callbackName + '(' + jsonOutput + ')')
  )

getPartList = (parse, lang) ->
  output = []
  seen_parts = {}
  agenda = [parse]
  while agenda.length > 0
    current = agenda.shift()
    terms = terminals(current, lang)
    if not seen_parts[terms]?
      output.push terms
      seen_parts[terms] = true
    for child in getChildren(current)
      agenda.unshift child
  return output.reverse()

getParseConstituents = root.getParseConstituents = (parse, lang) ->
  output = {}
  agenda = [parse]
  while agenda.length > 0
    current = agenda.pop(0)
    for child in getChildren(current)
      agenda.push child
      curt = terminals(current, lang)
      childt = terminals(child, lang)
      if curt != childt
        if not output[curt]?
          output[curt] = []
        output[curt].push childt
  return output

textToIndex = root.textToIndex = (sentence, text) ->
  start = sentence.indexOf(text)
  end = start + text.length
  return [parseInt(start), parseInt(end)]

indexToText = root.indexToText = (sentence, start, end) ->
  if (not end?) and (typeof start == typeof [])
    [start,end] = start
  return sentence[start...end]

makeConstituents = (sentence, textConstituents) ->
  nconstituents = {}
  for key,val of textConstituents
    nconstituents[textToIndex(sentence, key).join(',')] = (textToIndex(sentence, x) for x in val)
  return nconstituents

getPOSTag = (s) ->
  if s[0] == '('
    s = s[1..]
  if s.indexOf(' ') != -1
    s = s[...s.indexOf(' ')]
  return s

arrayToObj = (arr) ->
  if (typeof arr != typeof []) and (typeof arr != typeof {})
    return arr
  obj = {}
  for k of arr
    v = arr[k]
    if (typeof v == typeof []) or (typeof v == typeof {})
      v = arrayToObj(v)
    obj[k] = v
  return obj

objToArray = (obj) ->
  if typeof obj != typeof {}
    return obj
  arr = []
  for k of obj
    v = obj[k]
    if typeof v == typeof {}
      v = objToArray(v)
    if not isNaN(k)
      k = parseInt(k)
    arr[k] = v
  return arr

serializeArray = (arr) ->
  serializable = arrayToObj(arr)
  return JSON.stringify(serializable)

deserializeArray = (s) ->
  obj = JSON.parse(s)
  return objToArray(obj)

parseToHierarchy = (parse, lang) ->
  output = []
  postags = []
  for children in getChildren(parse)
    postags.push getPOSTag(children)
    output.push parseToHierarchy(children, lang)
  if output.length == 1
    tout = output[0]
    if typeof tout == typeof ''
      tout = [tout]
    tout.pos = postags[0]
    return tout
  if output.length == 0
    tout = terminals(parse, lang)
    if typeof tout == typeof ''
      tout = [tout]
    tout.pos = getPOSTag(parse)
    return tout
  output.pos = getPOSTag(parse)
  currentText = terminals(parse, lang)
  #if lang == 'ja' and doesWordExist(word, lang)
  #  return currentText
  return output

hierarchyToTerminals = (hierarchy, lang) ->
  if typeof hierarchy == typeof []
    children = (hierarchyToTerminals(x, lang) for x in hierarchy)
    if not lang? or lang == 'zh' or lang == 'ja'
      return children.join('')
    else
      return children.join(' ')
  else
    return hierarchy

subHierarchies = (hierarchy) ->
  output = []
  agenda = [hierarchy]
  while agenda.length > 0
    current = agenda.pop(0)
    output.push current
    if typeof current == typeof []
      for x in current
        agenda.push x
  return output

everyone.now.getTranslationsForParseHierarchy = getTranslationsForParseHierarchy = (hierarchy, lang, callback) ->
  translations = {}
  await
    for subHierarchy in subHierarchies(hierarchy)
      isTerminal = false
      if subHierarchy.length == 1 or (typeof subHierarchy == typeof '')
        isTerminal = true
      currentText = hierarchyToTerminals(subHierarchy, lang)
      getTranslation(currentText, lang, defer(translations[currentText]), isTerminal)
  callback(translations)

escapeshell = (shellcmd) ->
  return '"'+shellcmd.replace(/(["\s'$`\\])/g,'\\$1')+'"'

fixHierarchy = (hierarchy, lang) ->
  if lang != 'ja'
    return hierarchy
  if hierarchy.length == 1 or hierarchy.length == 0 or (typeof hierarchy != typeof [])
    return hierarchy
  currentTerminals = hierarchyToTerminals(hierarchy, lang)
  if doesWordExist(currentTerminals, lang)
    return currentTerminals
  output = []
  i = 0
  while i < hierarchy.length
    current = hierarchy[i]
    next = hierarchy[i+1]
    next2 = hierarchy[i+2]
    wlj3 = hierarchyToTerminals([current, next, next2], lang)
    if doesWordExist(wlj3, lang)
      output.push wlj3
      i += 3
      continue
    wlj2 = hierarchyToTerminals([current, next], lang)
    if doesWordExist(wlj2, lang)
      output.push wlj2
      i += 2
      continue
    output.push fixHierarchy(current, lang)
    i += 1
  return output

app.get '/getParseCached', (req, res) ->
  console.log 'getParseCached'
  console.log req.query.sentence
  console.log req.query.lang
  getParseCached(req.query.sentence, req.query.lang, (hierarchy) ->
    res.end serializeArray(hierarchy)
  )

segmentSentences = (text, lang, callback) ->
  if lang == 'de'
    sentences = []
    sentenceSeg = spawn('./opennlp/bin/opennlp', ['SentenceDetector', 'opennlp/de-sent.bin'])
    sentenceSeg.stdout.on('data', (data) ->
      data = data.toString()
      if data.trim() == ''
        callback(sentences)
      else
        for sentence in data.split('\n')
          sentences.push sentence
    )
    #sentenceSeg.on('close', (code) ->
    #  callback(sentences)
    #)
    sentenceSeg.stdin.write(text + '\n\n')

app.get '/segmentSentences', (req, res) ->
  text = req.query.text
  lang = req.query.lang ? 'de'
  segmentSentences(text, lang, (sentences) ->
    res.end JSON.stringify(sentences)
  )

getParseCached = (sentence, lang, callback) ->
  rkeylang = lang
  if rkeylang == 'ja'
    rkeylang = 'ja_2'
  if rkeylang == 'ko'
    rkeylang = 'ko_5'
  redisKey = 'parseHierarchy7|' + rkeylang + '|' + sentence
  rclient.get(redisKey, (rerr, rparseres) ->
    console.log 'rediskey is:' + redisKey
    if rparseres?
      hierarchy = deserializeArray(rparseres)
      hierarchy = fixHierarchy(hierarchy, lang)
      callback(hierarchy)
      return
    if lang == 'ja'
      exec('./japanese-parse.py ' + escapeshell(sentence.split('\n').join(' ').split(' ').join('')), (error, stdout, stderr) ->
        hierarchy = deserializeArray(stdout)
        rclient.set(redisKey, serializeArray(hierarchy))
        hierarchy = fixHierarchy(hierarchy, lang)
        callback(hierarchy)
      )
    else if lang == 'ko'
      exec('java -jar BerkeleyParser_KorV2.jar "' + (sentence.split('\n').join(' ').split('"').join(' ') + '"'), (error, stdout, stderr) ->
        hierarchy = parseToHierarchy(stdout.trim(), lang)
        rclient.set(redisKey, serializeArray(hierarchy))
        hierarchy = fixHierarchy(hierarchy, lang)
        callback(hierarchy)
      )
    else
      console.log 'getting parse:sentence=' + sentence + '; lang=' + lang
      getParse(sentence, lang, (parse) ->
        console.log 'have parse:' + parse
        hierarchy = parseToHierarchy(parse, lang)
        console.log 'have hierarchy:' + serializeArray(hierarchy)
        rclient.set(redisKey, serializeArray(hierarchy))
        hierarchy = fixHierarchy(hierarchy, lang)
        callback(hierarchy)
      )
  )

getParseHierarchyAndTranslations = everyone.now.getParseHierarchyAndTranslations = (sentence, lang, callback) ->
  console.log "getting constituents and translations"
  console.log "lang: " + lang
  sentence = sentence.trim()
  getParseCached(sentence, lang, (hierarchy) ->
    getTranslationsForParseHierarchy(hierarchy, lang, (translations) ->
      callback(hierarchy, translations)
    )
  )

getOCRService = (callback) ->
  needle.get('http://transgame.csail.mit.edu:9537/?varname=win7ipaddress', (error, result, body) ->
    callback(body)
  )

getOCRService = memoize(getOCRService)

app.get('/getOCRServiceIP', (req, res) ->
  getOCRService((ocrIP) ->
    res.end ocrIP
  )
)

app.get('/getOCR', (req, res) ->
  lang = req.query.lang ? 'en'
  data = req.query.data
  dataPrefix = 'data:image/png;base64,'
  if data.indexOf(dataPrefix) == 0
    data = data[dataPrefix.length..]
  #data = decodeURIComponent(data)
  data = data.split(' ').join('+')
  console.log data
  getOCRService((ocrIP) ->
    console.log ocrIP
    #res.end data
    request.post({'url': 'http://' + ocrIP + ':8080/', 'body': data, 'headers': {'content-type': 'application/x-www-form-urlencoded', 'Content-Length': data.length}}, (error, result, body) ->
      res.end body
    )
  )
)

#node_static = require 'node-static'
#static_files = new node_static.Server('./synthesize')
#querystring = require 'querystring'
#util = require 'util'
send = require 'send'

app.get '/synthesize', (req, res) ->
  sentence = req.query.sentence
  if not sentence?
    res.end 'need sentence param'
    return
  sentence = unescape(sentence)
  lang = req.query.lang
  if not lang?
    res.end 'need lang param'
    return
  filepath = './synthesize/' + lang + '/' + sentence + '.mp3'
  if fs.existsSync(filepath)
    console.log "serving existing file:" + filepath
    send(req, lang + '/' + sentence + '.mp3').root('./synthesize').pipe(res)
    #static_files.serveFile(lang + '/' + sentence + '.mp3', 200, {'Content-type': 'audio/mpeg'}, req, res)
    #res.writeHead(200, {'Content-Type': 'audio/mpeg', 'Content-Length': fs.statSync(filepath)})
    #readStream = fs.createReadStream(filepath)
    #util.pump(readStream, res)
    return
  else
    #remotefilepath = 'http://translate.google.com/translate_tts?tl=' + lang + '&q=' + sentence
    remotefilepath = 'http://translate.google.com/translate_tts?tl=' + lang + '&q=' + encodeURIComponent(sentence)
    console.log "downloading new file:" + remotefilepath
    http_get_options = {
      'url': remotefilepath,
      'headers': {
        'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.32 (KHTML, like Gecko) Chrome/27.0.1425.0 Safari/537.32',
        'Host': 'translate.google.com',
      }
    }
    http_get.get(http_get_options, filepath, (err2, res2) ->
      console.log "downloaded new file:" + filepath
      #static_files.serveFile(lang + '/' + sentence + '.mp3', 200, {'Content-type': 'audio/mpeg'}, req, res)
      send(req, lang + '/' + sentence + '.mp3').root('./synthesize').pipe(res)
      return
    )

app.get('/getParseHierarchyAndTranslations', (req, res) ->
  sentence = req.query.sentence.toString()
  lang = req.query.lang.toString()
  callbackName = req.query.callback
  getParseHierarchyAndTranslations(sentence, lang, (hierarchy, translations) ->
    jsonOutput = serializeArray({'hierarchy': hierarchy, 'translations': translations})
    if not callbackName?
      #res.writeHead(200, { 'Content-Type': 'application/json' })
      res.end(jsonOutput)
    else
      res.writeHead(200, { 'Content-Type': 'application/javascript' })
      res.end(callbackName + '(' + jsonOutput + ')')
  )
)

app.get('/submitTranslation', (req, res) ->
  sentence = req.query.sentence.toString()
  lang = req.query.lang.toString()
  targetlang = req.query.targetlang ? 'en'
  translation = req.query.translation.toString()
  redisKey = 'manualtrans|' + lang + '_to_' + targetlang + '|' + sentence
  rclient.set(redisKey, translation, () ->
    res.end(translation)
  )
)

getManualTranslation = (sentence, lang, targetlang, callback) ->
  redisKey = 'manualtrans|' + lang + '_to_' + targetlang + '|' + sentence
  rclient.get(redisKey, (err, result) ->
    callback(result)
  )

app.get('/getTranslation', (req, res) ->
  sentence = req.query.sentence.toString()
  lang = req.query.lang.toString()
  targetlang = req.query.targetlang ? 'en'
  getManualTranslation(sentence, lang, targetlang, (translation) ->
    res.end(translation)
  )
)

getConstituentsAndTranslations = everyone.now.getConstituentsAndTranslations = (sentence, lang, callback) ->
  getParse(sentence, lang,(parse) ->
    constituentsText = getParseConstituents(parse, lang)
    console.log constituentsText
    constituents = makeConstituents(sentence, constituentsText)
    console.log constituents
    translations = {}
    await
      for k,v of constituentsText
        getTranslation(k, lang, defer(translations[k]))
        for indvv in v
          getTranslation(indvv, lang, defer(translations[indvv]))
    callback(constituents, translations)
  )

zip = (arr1, arr2) ->
  basic_zip = (el1, el2) -> [el1, el2]
  zipWith basic_zip, arr1, arr2

zipWith = (func, arr1, arr2) ->
  min = Math.min arr1.length, arr2.length
  ret = []

  for i in [0...min]
    ret.push func(arr1[i], arr2[i])

  ret

japanesedict = require './japanesedict_v3'
jdict = new japanesedict.JapaneseDict()
chinesedict = require './chinesedict'
cdict = new chinesedict.ChineseDict(fs.readFileSync('cedict_full.txt', 'utf8'))
wiktionarydict = require './wiktionarydict'
frdict = new wiktionarydict.WiktionaryDict(fs.readFileSync('fra-eng.txt', 'utf8'))
dedict = new wiktionarydict.WiktionaryDict(fs.readFileSync('deu-eng.txt', 'utf8'))

dictionaryList = {
  'fr': frdict,
  'de': dedict,
}

#everyone.now.core.options.socketio.resource = 'https://localhost:1358/socket.io'

app.get('/getFullTranslation', (req, res) ->
  sentence = req.query.sentence.toString()
  lang = req.query.lang.toString()
  getTranslation(sentence, lang, (translation) ->
    res.end(translation)
  , false)
)

doesWordExist = (word, lang) ->
  if lang == 'ja'
    return jdict.doesWordExist(word)
  return false

stripPunctuation = (word) ->
  punctuation = '!,()_-'
  return (c for c in word when punctuation.indexOf(c) == -1).join('')

getromaji = require './getromaji'
getpinyin = require './getpinyin'

everyone.now.getTranslation = getTranslation = (sentence, lang, callback, isTerminal) ->
  if not isTerminal?
    isTerminal = true
  romaji = null
  await
    getManualTranslation(sentence, lang, 'en', defer(manualtranslation))
    translator.getTranslations(sentence, lang, 'en', defer(translation))
    #if lang == 'ja'
    #  wordDef = jdict.getDefinition(sentence)
    #  if wordDef? and wordDef.length > 0
    #    getromaji.getRomajiRateLimitedCached(sentence, defer(origText_unused, romaji))
    #if lang == 'zh'
    #  wordDef = cdict.getEnglishListForWord(sentence).join('; ')
    #  if wordDef? and wordDef.length > 0
    #    getpinyin.getPinyinRateLimitedCached(sentence, defer(origText_unused, romaji))
  do (manualtranslation, translation) ->
    output = []
    #console.log translation
    translatedText = translation[0].TranslatedText
    if not translatedText? or translatedText.length < 1
      translatedText = $('<span>').html(translation[0].translatedText).text()
    englishDef = null
    #romaji = null
    if lang == 'ja'
      if isTerminal or jdict.doesWordExist(sentence)
        englishDef = jdict.getDefinition(sentence, isTerminal)
        romaji = jdict.getRomaji(sentence)
    if lang == 'zh'
      englishDef = cdict.getEnglishListForWord(sentence).join('; ')
      if isTerminal
        romaji = cdict.getPinyin(sentence)
    if dictionaryList[lang]?
      ldict = dictionaryList[lang]
      englishDef = ldict.getEnglishListForWord(sentence).join('; ')
      if englishDef.length == 0
        englishDef = ldict.getEnglishListForWord(stripPunctuation(sentence)).join('; ')
      lowerCaseDefinitions = ldict.getEnglishListForWord(sentence.toLowerCase()).join('; ')
      if lowerCaseDefinitions != englishDef
        englishDef = englishDef + '\n' + lowerCaseDefinitions
    if manualtranslation?
      output.push manualtranslation
      if romaji?
        output.push romaji
      if englishDef? and englishDef.length > 0
        output.push englishDef
    else
      output.push translatedText
      if romaji?
        output.push romaji
      if englishDef? and englishDef.length > 0
        output.push englishDef
    callback(output.join('\n'))

