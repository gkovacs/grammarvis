$ = require 'jQuery'
request = require 'request'

exec = require('child_process').exec

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

everyone.now.getParse = getParse = (sentence, lang, callback) ->
  request.get('http://localhost:3555/parse?lang=' + lang + '&sentence=' + sentence, (error, result, data) ->
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

parseToHierarchy = (parse, lang) ->
  output = []
  for children in getChildren(parse)
    output.push parseToHierarchy(children, lang)
  if output.length == 1
    return output[0]
  if output.length == 0
    return terminals(parse, lang)
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

getParseCached = (sentence, lang, callback) ->
  rkeylang = lang
  if rkeylang == 'ja'
    rkeylang = 'ja_2'
  redisKey = 'parseHierarchy|' + rkeylang + '|' + sentence
  rclient.get(redisKey, (rerr, rparseres) ->
    if rparseres?
      hierarchy = JSON.parse(rparseres)
      hierarchy = fixHierarchy(hierarchy, lang)
      callback(hierarchy)
      return
    if lang == 'ja'
      exec('./japanese-parse.py ' + escapeshell(sentence.split('\n').join(' ').split(' ').join('')), (error, stdout, stderr) ->
        hierarchy = JSON.parse(stdout)
        rclient.set(redisKey, JSON.stringify(hierarchy))
        hierarchy = fixHierarchy(hierarchy, lang)
        callback(hierarchy)
      )
    else
      getParse(sentence, lang,(parse) ->
        hierarchy = parseToHierarchy(parse, lang)
        rclient.set(redisKey, JSON.stringify(hierarchy))
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
  request.get('http://transgame.csail.mit.edu:9537/?varname=win7ipaddress', (error, result, body) ->
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

node_static = require 'node-static'
static_files = new node_static.Server('./synthesize')

app.get '/synthesize', (req, res) ->
  sentence = req.query.sentence
  if not sentence?
    res.end 'need sentence param'
    return
  lang = req.query.lang
  if not lang?
    res.end 'need lang param'
    return
  filepath = './synthesize/' + lang + '/' + sentence + '.mp3'
  if fs.existsSync(filepath)
    console.log "serving existing file:" + filepath
    static_files.serveFile(lang + '/' + sentence + '.mp3', 200, {'Content-type': 'audio/mpeg'}, req, res)
    return
  else
    console.log "downloading new file:" + filepath
    http_get.get('http://translate.google.com/translate_tts?tl=' + lang + '&q=' + sentence, filepath, (err2, res2) ->
      console.log "downloaded new file:" + filepath
      static_files.serveFile(lang + '/' + sentence + '.mp3', 200, {'Content-type': 'audio/mpeg'}, req, res)
      return
    )

app.get('/getParseHierarchyAndTranslations', (req, res) ->
  sentence = req.query.sentence.toString()
  lang = req.query.lang.toString()
  getParseHierarchyAndTranslations(sentence, lang, (hierarchy, translations) ->
    res.end(JSON.stringify({'hierarchy': hierarchy, 'translations': translations}))
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
  )
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
      romaji = cdict.getPinyin(sentence)
    if dictionaryList[lang]?
      ldict = dictionaryList[lang]
      englishDef = ldict.getEnglishListForWord(sentence).join('; ')
      if englishDef.length == 0
        englishDef = ldict.getEnglishListForWord(stripPunctuation(sentence)).join('; ')
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

