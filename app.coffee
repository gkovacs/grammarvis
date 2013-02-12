$ = require 'jQuery'
request = require 'request'

exec = require('child_process').exec

#translator = require './translator'
translator = require './googletranslate'

express = require 'express'
app = express()

http = require 'http'
https = require 'https'

redis = require 'redis'
rclient = redis.createClient()

fs = require 'fs'

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
      currentText = hierarchyToTerminals(subHierarchy, lang)
      getTranslation(currentText, lang, defer(translations[currentText]))
  callback(translations)

escapeshell = (shellcmd) ->
  return '"'+shellcmd.replace(/(["\s'$`\\])/g,'\\$1')+'"'

getParseHierarchyAndTranslations = everyone.now.getParseHierarchyAndTranslations = (sentence, lang, callback) ->
  console.log "getting constituents and translations"
  console.log "lang: " + lang
  sentence = sentence.trim()
  if lang == 'ja'
    exec('./japanese-parse.py ' + escapeshell(sentence.trim()), (error, stdout, stderr) ->
      hierarchy = JSON.parse(stdout)
      getTranslationsForParseHierarchy(hierarchy, lang, (translations) ->
        callback(hierarchy, translations)
      )
    )
  else
    getParse(sentence, lang,(parse) ->
      hierarchy = parseToHierarchy(parse, lang)
      getTranslationsForParseHierarchy(hierarchy, lang, (translations) ->
        callback(hierarchy, translations)
      )
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

#getParse('Hilda est la fille de Grace Hazard Conkling (poète et professeur d\'anglais au Smith College)', 'fr', (parse) -> console.log parse)

#console.log translator.getTranslations('你好吗', 'zh', 'en', (translation) -> console.log translation[0].TranslatedText)

foreignText = '''
Oh, Herr, bitte gib mir meine Sprache zurück,
ich sehne mich nach Frieden und 'nem kleinen Stückchen Glück.
Lass uns noch ein Wort verstehen in dieser schweren Zeit,
öffne unsre Herzen, mach' die Hirne weit.

Ich bin zum Bahnhof gerannt und war a little bit too late
Auf meiner neuen Swatch war's schon kurz vor after eight.
Ich suchte die Toilette, doch ich fand nur ein "McClean",
ich brauchte noch Connection und ein Ticket nach Berlin.
Draußen saßen Kids und hatten Fun mit einem Joint.
Ich suchte eine Auskunft, doch es gab nur 'n Service Point.
Mein Zug war leider abgefahr'n - das Traveln konnt' ich knicken.
Da wollt ich Hähnchen essen, doch man gab mir nur McChicken.

Oh, Herr bitte gib mir meine Sprache zurück,
ich sehne mich nach Frieden und 'nem kleinen Stückchen Glück.
Lass uns noch ein Wort verstehen in dieser schweren Zeit,
öffne unsre Herzen, mach' die Hirne weit.

Du versuchst mich upzudaten, doch mein Feedback turned dich ab.
Du sagst, dass ich ein Wellness-Weekend dringend nötig hab.
Du sagst, ich käm' mit good Vibrations wieder in den Flow.
Du sagst, ich brauche Energy. Und ich denk: "Das sagst du so..."
Statt Nachrichten bekomme ich den Infotainment-Flash.
Ich sehne mich nach Bargeld, doch man gibt mir nicht mal Cash.
Ich fühl' mich beim Communicating unsicher wie nie –
da nützt mir auch kein Bodyguard. Ich brauch Security!

Oh, Lord, bitte gib mir meine Language zurück,
ich sehne mich nach Peace und 'nem kleinen Stückchen Glück,
Lass uns noch ein Wort verstehn in dieser schweren Zeit,
öffne unsre Herzen, mach' die Hirne weit.

Ich will, dass beim Coffee-Shop "Kaffeehaus" oben draufsteht,
oder dass beim Auto-Crash die "Lufttasche" aufgeht,
und schön wär's, wenn wir Bodybuilder "Muskel-Mäster" nennen
und wenn nur noch "Nordisch Geher" durch die Landschaft rennen...

Oh, Lord, please help, denn meine Language macht mir Stress,
ich sehne mich nach Peace und a bit of Happiness.
Hilf uns, dass wir understand in dieser schweren Zeit,
open unsre hearts und make die Hirne weit.

Oh, Lord, please gib mir meine Language back,
ich krieg hier bald die crisis, man, it has doch keinen Zweck.
Let us noch a word verstehen, it goes me on the Geist,
und gib, dass "Microsoft" bald wieder "Kleinweich" heißt.
'''.split('\n')

englishText = '''
Oh, Lord, please give me my language back,
I long for Frieden [peace] and a little bit of Glück [happiness].
Let us understand a word in this difficult time,
open our hearts, expand the brain.

I ran to the train station and was "a little bit too late"
on my new Swatch it was already just before "after eight."
I looked for a toilet, but only found a "McClean,"
I still needed "Connection" and a "Ticket" to Berlin.
Outside sat "Kids" and had "Fun" with a "Joint."
I looked for information, but there was only a "Service Point."
My train was gone - "Traveln" I could do without.
Then I wanted to eat "Hähnchen" [chicken], but there was only "McChicken."

Oh, Lord, please give me my language back,
I long for Frieden [peace] and a little bit of Glück [happiness].
Let us understand a word in this difficult time,
open our hearts, expand the brain.

You try to "update" me, but my "Feedback turned" you off.
You say I really need a "Wellness-Weekend."
You say with "good Vibrations" I'd get back in the "Flow."
You say I need "Energy." And I think: "So you say..."
Instead of "Nachrichten" I get the "Infotainment-Flash."
I'm longing for Bargeld [cash], but they don't even give me "Cash."
When "Communicating," I feel insecure as never before –
a "Bodyguard" is no use. I need "Security"!

Oh, "Lord," please give me my "Language" back,
I'm longing for "Peace" and a little bit of Glück [happiness].
Let us understand a word in this difficult time,
open our hearts, expand the brain.

For "Coffee-Shop" I want to see "Kaffeehaus" written up there,
or that in an "Auto-Crash" the "Lufttasche" (airbag) goes off,
and it would be nice, if we called "Bodybuilder" "Muskel-Mäster"
and if only "Nordisch Geher" would run across the landscape...

"Oh, Lord, please help," because my "Language" causes me "Stress,"
I long for "Peace" and "a bit of Happiness."
Help us, so we "understand" in this difficult time,
"open" our "hearts" and "make" the brain wide.

"Oh, Lord, please" give me my "Language back,"
I soon here in "crisis, man, it has" no point.
"Let us" still "a word" understand, "it goes me on the" Geist,*
and let "Microsoft" soon be known as "Kleinweich" [small soft].
'''.split('\n')

zip = (arr1, arr2) ->
  basic_zip = (el1, el2) -> [el1, el2]
  zipWith basic_zip, arr1, arr2

zipWith = (func, arr1, arr2) ->
  min = Math.min arr1.length, arr2.length
  ret = []

  for i in [0...min]
    ret.push func(arr1[i], arr2[i])

  ret

manualTranslations = {}

for [foreign,english] in zip(foreignText, englishText)
  manualTranslations[foreign.trim()] = english.trim()

japanesedict = require './japanesedict_v2'
jdict = new japanesedict.JapaneseDict(fs.readFileSync('edict2_full.txt', 'utf8'))
chinesedict = require './chinesedict'
cdict = new chinesedict.ChineseDict(fs.readFileSync('cedict_full.txt', 'utf8'))

#everyone.now.core.options.socketio.resource = 'https://localhost:1358/socket.io'

app.get('/getFullTranslation', (req, res) ->
  sentence = req.query.sentence.toString()
  lang = req.query.lang.toString()
  getTranslation(sentence, lang, (translation) ->
    res.end(translation)
  )
)

everyone.now.getTranslation = getTranslation = (sentence, lang, callback) ->
  #if manualTranslations[sentence]?
  #   callback manualTranslations[sentence]
  #   return
  await
    getManualTranslation(sentence, lang, 'en', defer(manualtranslation))
    translator.getTranslations(sentence, lang, 'en', defer(translation))
  do (manualtranslation, translation) ->
    output = []
    console.log translation
    translatedText = translation[0].TranslatedText
    if not translatedText? or translatedText.length < 1
      translatedText = translation[0].translatedText
    if lang == 'ja'
      englishDef = jdict.getDefinition(sentence)
      romaji = jdict.getRomaji(sentence)
      if englishDef? and englishDef.length > 0
        if manualtranslation?
          output.push manualtranslation
          output.push romaji
          output.push englishDef
        else
          output.push translatedText
          output.push romaji
          output.push englishDef
      else
        if manualtranslation?
          output.push manualtranslation
          output.push romaji
          output.push translatedText
        else
          output.push translatedText
          output.push romaji
    else if lang == 'zh'
      englishDef = cdict.getEnglishListForWord(sentence).join('; ')
      pinyin = cdict.getPinyin(sentence)
      if englishDef? and englishDef.length > 0
        if manualtranslation?
          output.push manualtranslation
          output.push pinyin
          output.push englishDef
        else
          output.push translatedText
          output.push pinyin
          output.push englishDef
      else
        if manualtranslation?
          output.push manualtranslation
          output.push pinyin
          output.push translatedText
        else
          output.push translatedText
          output.push pinyin
    else
      if manualtranslation?
        output.push manualtranslation
        output.push translatedText
      else
        output.push translatedText
    callback(output.join('\n'))

