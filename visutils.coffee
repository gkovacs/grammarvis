# 昨天我的猫在家里吃了五只鼠

root = exports ? this

do ($) ->

  depthToColor = (depth) ->
    #return ['white', 'blue', 'green', 'yellow', 'red', 'orange'][depth]
    #colors = '0123456789ABCDEF'
    colors = '00000000000012345678ABCDEF'
    #colors = 'FECA86420'
    return '#' + (colors[colors.length - depth - 1] for i in [0..5]).join('')

  $.fn.borderStuff = (depth, maxdepth, color) ->
    #if not width?
    width = 3
    #maxdepth = getMaxDepth('R') #getMaxDepth('R')
    ###
    depth = $(this).parents().attr('depth')
    console.log this.parent()
    if depth?
      depth = parseInt(depth) + 1
    else
      depth = 0
    ###
    #this.css('display', 'table-cell').css('vertical-align', 'middle')
    #this.css('font-size', (15+depth*3) + 'pt')
    padding = 8
    fontSize = 18
    lang = this.attr('foreignLang')
    if lang == 'zh' or lang == 'ja'
      fontSize = 32
    margin = 0
    if color == 'white' # terminals
      margin = (maxdepth-depth+1)*padding + (maxdepth-depth)
      #padding = (maxdepth-depth+1)*15 + (maxdepth-depth) # this last term to account for the border of 1
    if not color?
      color = depthToColor(depth)
    posTag = deserializeArray(this.attr('contenthierarchy')).pos
    if posTag? and posTag in ['N', 'NN']
      color = 'lightgreen'
    if posTag? and posTag in ['V', 'VC']
      color = 'pink'
    #if posTag? and posTag == 'P'
    #  color = '#FFAA55'
    this.addClass('bordered').css('position', 'relative').css('padding', padding + 'px').css('font-size', fontSize).attr('color', color).css('background-color', color).css('border-width', 1).css('border-style', 'solid').css('float', 'left').attr('depth', depth).css('border-color', 'black').css('border-radius', '10px').css('margin-top', margin).css('margin-bottom', margin)
    if this.attr('id') and this.attr('id').indexOf('_') == -1
      this.css('margin-top', $('#H' + this.attr('id')).height() )
    return this

  $.fn.showAsSibling = (color) ->
    #if not color?
    #  color = 'lightblue'
    if color?
      this.css('background-color', color)
    siblingToShow = $('#H' + this.attr('id'))
    siblingToShow.show()
    this.addClass('hovered')
    setWidth = () =>
      ownHalfWidth = this.width()/2
      siblingHalfWidth = siblingToShow.width()/2
      left = Math.max(0, ownHalfWidth - siblingHalfWidth)
      top = -siblingToShow.height()
      #siblingToShow.offset({'left': left, 'top': top})
      siblingToShow.css('left', left)
      siblingToShow.css('top', top)
    setWidth()
    #setTimeout(setWidth, 5000)
    siblingToShow.mouseover(() => 
      return false
    )
    return this

  $.fn.hoverId = () ->
    text = this.attr('translation')
    if not text?
      return this
    if text.indexOf('/EntL') != -1
      text = text[...text.indexOf('/EntL')]
    idNum = this.attr('id')
    textAsHtml = $('<div>')
    for x in text.split('\n')
      textAsHtml.append($('<span>').text(x)).append('<br>')
    #if this.attr('contenthierarchy')? and (typeof deserializeArray(this.attr('contenthierarchy'))[0]) == (typeof '')
    if text.indexOf('\n') != -1
      this.attr('title', text)
      this.attr('hovertext', text)
      this.tooltip({track: true, show:false, hide:false, content: textAsHtml.html()})
    shortTranslation = text
    if shortTranslation.indexOf('\n') != -1
      shortTranslation = shortTranslation[...shortTranslation.indexOf('\n')]
    shortTranslationDiv = $('<div>').addClass('Hovertips').attr('id', 'H' + idNum).text(shortTranslation).css('position', 'absolute').css('top', 0).css('zIndex', 100).css('color', 'white').css('background-color', 'black').css('border-top-left-radius', 5).css('border-top-right-radius', 5).css('font-size', 18).hide()
    shortTranslationDiv.css('text-align', 'center').css('word-wrap', 'break-word')
    this.append(shortTranslationDiv)
    #this.addClass(text.split(' ').join('-'))
    this.mouseover(() =>
      #synthesizeSpeech('hola', 'es')
      console.log this.attr('foreigntext')
      synthesizeSpeech(this.attr('foreigntext'), this.attr('foreignlang'))
      #console.log this.attr('hovertext')
      this.css('background-color', 'yellow')
      for x in $('.bordered')
        $(x).css('background-color', $(x).attr('color'))
      this.addClass('hovered')
      currentId = idNum
      $('.Hovertips').hide()
      while currentId.indexOf('_') != -1 # not yet at root
        parent = currentId.split('_')[...-1].join('_')
        siblings = (x for x in getChildrenOfId(parent) when x != currentId)
        for sibling in siblings
          $('#' + sibling).showAsSibling()
        #  $('#' + sibling).showAsSibling('lightblue')
        currentId = parent
        #console.log currentId
      this.showAsSibling('yellow')
      #if getChildrenOfId(idNum).length == 0
      #  this.showAsSibling('yellow')
      #else
      #  #console.log idNum
      #  for immediateChild in getChildrenOfId(idNum)
      #    $('#' + immediateChild).showAsSibling('pink')
      this.css('background-color', 'yellow')
      return false
    )
    this.mouseleave(() =>
      if $('audio')[0]?
        $('audio')[0].pause()
      for x in $('.hovered')
        $(x).css('background-color', $(x).attr('color'))
      $('.hovered').removeClass('hovered')
      $('.Hovertips').hide()
      myId = this.attr('id')
      rootId = myId
      if myId.indexOf('_') != -1
        rootId = myId[...myId.indexOf('_')]
      this.css('background-color', this.attr('color'))
      $('#' + rootId).showAsSibling()
    )
    return this

synthesizeSpeech = root.synthesizeSpeech = (sentence, lang, isloop) ->
  audioTag = $('audio')[0]
  if not audioTag
    $('body').append($('<audio>').attr('autoplay', true).attr('loop', isloop))
    audioTag = $('audio')[0]
  audioTag.src = 'http://geza.csail.mit.edu:1357/synthesize?sentence=' + sentence + '&lang=' + lang
  if isloop or not isloop?
    $('audio').attr('loop', true)
  else
    $('audio').attr('loop', false)
  audioTag.play()

'''
ref_hierarchy = [['私', 'の', '猫'], 'が', [['家', 'で'], [ [['五', '匹'], 'の', '鼠'], 'を', '食べた']]]
translations = {
'私の猫が家で五匹の鼠を食べた': 'my cat ate 5 mice in the house',
'私の猫': 'my cat',
'私': 'me',
'の': 'of',
'猫': 'cat',
'が': 'subject marker',
'家で五匹の鼠を食べた': 'ate 5 mice in the house',
'家で': 'in the house',
'家': 'house',
'で': 'in',
'五匹の鼠を食べた': 'ate 5 mice',
'五匹の鼠': '5 mice',
'五匹': '5 small animals',
'五': '5',
'匹': 'counter for small animals',
'鼠': 'mouse',
'を': 'object marker',
'食べた': 'ate',
}
'''

'''
getMaxDepth = root.getMaxDepth = (id) ->
  maxval = 0
  for child in getChildrenOfId(id)
    maxval = Math.max(maxval, getMaxDepth(child)+1)
  return maxval
'''

getMaxDepth = root.getMaxDepth = (subtree) ->
  #if not subtree?
  #  subtree = root.ref_hierarchy_with_ids
  if typeof subtree != typeof []
    return 0
  maxval = 0
  for child in subtree
    maxval = Math.max(maxval, getMaxDepth(child)+1)
  return maxval

'''
getMaxDepth = root.getMaxDepth = (id) ->
  if not id?
    id = 'R'
  maxval = 0
  for childId in getChildrenOfId(id)
    maxval = Math.max(maxval, getMaxDepth(childId) + 1)
  return maxval
'''

getChildrenOfId = root.getChildrenOfId = (id) ->
  return ($(x).attr('id') for x in $('#' + id).children('.textRegion'))

hierarchyToTerminals = (hierarchy, lang) ->
  if typeof hierarchy == typeof []
    children = (hierarchyToTerminals(x, lang) for x in hierarchy)
    if not lang? or lang == 'zh' or lang == 'ja'
      return children.join('')
    else
      return children.join(' ')
  else
    return hierarchy

hierarchyWithIdToTerminals = (hierarchy, lang) ->
  if typeof hierarchy == typeof ''
    return hierarchy
  id = hierarchy.id
  contents = hierarchy[..]
  if contents.length == 1
    return hierarchyWithIdToTerminals(contents[0])
  else
  if true
    children = (hierarchyWithIdToTerminals(x, lang) for x in contents)
    if not lang? or lang == 'zh' or lang == 'ja'
      return children.join('')
    else
      return children.join(' ')

initializeHover = (basediv) ->
  contentHierarchy = deserializeArray(basediv.attr('contentHierarchy'))
  depth = basediv.attr('depth')
  maxdepth = basediv.attr('maxdepth')
  basediv.hoverId()
  if contentHierarchy.length > 1
    basediv.borderStuff(depth, maxdepth)
  else if contentHierarchy.length == 1
    if typeof contentHierarchy[0] == typeof ''
      basediv.borderStuff(depth, maxdepth, 'white')
        #.css('font-size', 10+depth*10)
        .text(contentHierarchy[0]).hoverId()
    else
      basediv.borderStuff(depth, maxdepth, 'white')
        #.css('font-size', 20+depth*10)
        .text(contentHierarchy[0]).hoverId()
    

makeDivs = (subHierarchy, lang, translations, maxdepth, depth=1) ->
  basediv = $('<div>')
  id = subHierarchy.id
  contentHierarchy = subHierarchy #[..]
  basediv.addClass('hovertext').attr('id', id)
  basediv.addClass('hovertext').addClass('textRegion')
  foreignText = hierarchyWithIdToTerminals(subHierarchy, lang)
  #console.log 'foreign text: ' + foreignText
  basediv.attr('foreignText', foreignText)
  basediv.attr('foreignLang', lang)
  translation = translations[foreignText]
  basediv.attr('translation', translation)
  basediv.attr('depth', depth)
  basediv.attr('maxdepth', maxdepth)
  basediv.attr('contentHierarchy', serializeArray(contentHierarchy))
  basediv.hoverId()
  do (id) ->
    basediv.click(() ->
      lForeignText = $('#' + id).attr('foreignText')
      lTranslation = $('#' + id).attr('translation')
      console.log 'clicked:'
      console.log lForeignText
      console.log 'translation:'
      shortTranslation = lTranslation
      if shortTranslation.indexOf('\n') != -1
        shortTranslation = shortTranslation.split('\n')[0]
      console.log shortTranslation
      openTranslationPopup(foreignText, shortTranslation, lang, id)
      return false
    )
  #basediv.hoverText(translations[currentText])
  initializeHover(basediv)
  if contentHierarchy.length > 1
    basediv.borderStuff(depth, maxdepth)
    for child in contentHierarchy
      basediv.append makeDivs(child, lang, translations, maxdepth, depth+1)
  else if contentHierarchy.length == 1
    if typeof contentHierarchy[0] == typeof ''
      basediv.borderStuff(depth, maxdepth, 'white')
        #.css('font-size', 10+depth*10)
        .text(contentHierarchy[0]).hoverId()
    #else
    #  basediv.borderStuff(depth, maxdepth, 'white')
    #    #.css('font-size', 20+depth*10)
    #    .text(contentHierarchy[0]).hoverId()
  return basediv

addIdsToHierarchy = (hierarchy, myId='R0') ->
  if typeof hierarchy != typeof ''
    output = []
    for x,i in hierarchy
      console.log x
      if typeof x != typeof ''
        output.push addIdsToHierarchy(x, myId + '_' + i)
      else
        output.push x
    output.id = myId
    if hierarchy.pos?
      output.pos = hierarchy.pos
    return output
  else
    #output = [hierarchy]
    #output.id = myId
    #return output
    return hierarchy

addFakePOSTags = (hierarchy) ->
  output = []
  if typeof hierarchy == typeof []
    for x,i in hierarchy
      output.push addFakePOSTags(x)
    output.pos = 'fakePOS'
    return output
  else
    output = [hierarchy]
    output.pos = 'fakePOS'
    return output

getUrlParameters = root.getUrlParameters = () ->
  map = {}
  parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, (m,key,value) ->
    map[key] = decodeURI(value)
  )
  return map

callOnceElementAvailable = (element, callback) ->
  if $(element).length > 0
    callback()
  else
    setTimeout(() ->
      callOnceElementAvailable(element, callback)
    , 10)

renderSentence = (sentence, ref_hierarchy, translations, lang, renderTarget) ->
  console.log ref_hierarchy
  console.log translations
  idnum = 0
  while $('#R' + idnum).length > 0
    idnum += 1
  if lang == 'ja'
    ref_hierarchy = addFakePOSTags(ref_hierarchy)
  ref_hierarchy_with_ids = addIdsToHierarchy(ref_hierarchy, 'R' + idnum)
  console.log ref_hierarchy_with_ids
  rootBaseDiv = makeDivs(ref_hierarchy_with_ids, lang, translations, getMaxDepth(ref_hierarchy_with_ids) - 1)
  renderTarget.append(rootBaseDiv).append('<br>')
  rootBaseDiv.showAsSibling()
  #currentTopMargin = parseInt(rootBaseDiv.css('margin-top').split('px').join(''))
  callOnceElementAvailable('#HR' + idnum, () ->
    currentTopMargin = 0
    rootBaseDiv.css('margin-top', currentTopMargin + $('#HR' + idnum).height())
  , 10)

addSentence = root.addSentence = (sentence, lang, renderTarget, clearExisting=false, callback) ->
  addSentences([sentence], lang, renderTarget, clearExisting, callback)

if not root.serverLocation?
  root.serverLocation = ''

submitTranslation = root.submitTranslation = (origPhrase, translation, lang) ->
  console.log 'translation submitted'
  console.log origPhrase
  console.log translation
  reqParams = {
    'sentence': origPhrase,
    'lang': lang,
    'targetlang': 'en',
    'translation': translation,
  }
  console.log root.serverLocation + '/submitTranslation?' + $.param(reqParams)
  if not root.isMTurk?
    $.get(root.serverLocation + '/submitTranslation?' + $.param(reqParams))

updateTranslation = (id, translation) ->
  console.log 'updateTranslation for:' + id
  basediv = $('#' + id)
  fullTranslation = basediv.attr('translation').split('\n')
  fullTranslation[0] = translation
  basediv.attr('translation', fullTranslation.join('\n'))
  basediv.hoverId()
  #initializeHover(basediv)
  $('#H' + id).text(translation)
  if id.indexOf('_') != -1
    parentId = id.split('_')[...-1].join('_')
    parentdiv = $('#' + parentId)
    #initializeHover(parentdiv)
    #basediv.mouseover()
  else
    basediv.css('margin-top', $('#H' + id).height() )

openTranslationPopup = root.openTranslationPopup = (sentenceToTranslate, translation, lang, id) ->
  initializePopup()
  $('#sentenceToTranslate').text(sentenceToTranslate)
  $('#translationInput').val(translation)
  $('#popupTranslateDisplay').attr('translationForId', id)
  $('#popupTranslateDisplay').attr('translationForLang', lang)
  $('#popupTranslateDisplay').dialog('open')

root.popupInitialized = false

initializePopup = root.initializePopup = () ->
  if root.popupInitialized
    return
  root.popupInitialized = true
  popupTranslateDisplay = $('''<div id="popupTranslateDisplay">Translation for <span id="sentenceToTranslate"></span><form action="javascript:void(0)" id="translationForm"><input type="text" id="translationInput" /><input type="hidden" value="submit" /></form></div>''')
  popupTranslateDisplay.dialog({
    'autoOpen': false,
    'modal': false,
    'title': '',
    #'show': 'clip',
    #'hide': 'clip',
    #'position': ['right', 'top'],
    'zIndex': 99,
    #'width': '100%',
    #'maxHeight': '500px',
    'create': () ->
      $(this).css("maxHeight", 500)
      $('#translationInput').keypress((e) ->
        if e.keyCode == 13 # enter pressed
          inputtedText = $('#translationInput').val()
          $('#popupTranslateDisplay').dialog('close')
          if inputtedText == ''
            return false
          else
            origPhrase = $('#sentenceToTranslate').text()
            translation = $('#translationInput').val()
            lang = $('#popupTranslateDisplay').attr('translationForLang')
            #callback(origPhrase, translation, lang)
            submitTranslation(origPhrase, translation, lang)
            updateTranslation($('#popupTranslateDisplay').attr('translationForId'), translation)
            return false
      )
  }).css('max-height', '500px')

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

serializeArray = root.serializeArray = (arr) ->
  serializable = arrayToObj(arr)
  return JSON.stringify(serializable)

deserializeArray = root.deserializeArray = (s) ->
  obj = JSON.parse(s)
  return objToArray(obj)

callbackParseHierarchy = root.callbackParseHierarchy = null

insertScript = root.insertScript = (url) ->
  scriptTag = document.createElement('script')
  scriptTag.type = 'text/javascript'
  scriptTag.src = url
  document.documentElement.appendChild(scriptTag)

addSentences = root.addSentences = (sentences, lang, renderTarget, clearExisting=false, doneCallback) ->
  if not lang? and not renderTarget?
    lang = getUrlParameters()['lang'] ? 'en'
    renderTarget = $('#sentenceDisplay')
  if not renderTarget?
    renderTarget = $('#sentenceDisplay')
  parseHierarchyAndTranslationsForLang = (sentence, callback) ->
    #now.getParseHierarchyAndTranslations(sentence, lang, (ref_hierarchy,translations) -> callback(null, [ref_hierarchy,translations]))
    if not root.isMTurk?
      $.get(root.serverLocation + '/getParseHierarchyAndTranslations?sentence=' + encodeURI(sentence) + '&lang=' + encodeURI(lang), (resultData, resultStatus) ->
        resultData = deserializeArray(resultData)
        currentPair = [resultData.hierarchy, resultData.translations]
        #console.log currentPair
        callback(null, currentPair)
      )
    else
      callbackParseHierarchy = root.callbackParseHierarchy = (resultData) ->
        resultData = objToArray(resultData)
        currentPair = [resultData.hierarchy, resultData.translations]
        callback(null, currentPair)
      insertScript(root.serverLocation + '/getParseHierarchyAndTranslations?sentence=' + encodeURI(sentence) + '&lang=' + encodeURI(lang) + '&callback=callbackParseHierarchy')
  async.mapSeries(sentences, parseHierarchyAndTranslationsForLang, (err, results) ->
    if clearExisting
      renderTarget.html('')
    for i in [0...results.length]
      sentence = sentences[i]
      [ref_hierarchy,translations] = results[i]
      renderSentence(sentence, ref_hierarchy, translations, lang, renderTarget)
    if doneCallback?
      doneCallback()
  )

console.log 'visutils loaded'
root.addSentence = addSentence

