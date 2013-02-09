# 昨天我的猫在家里吃了五只鼠

root = exports ? this

do ($) ->

  depthToColor = (depth) ->
    #return ['white', 'blue', 'green', 'yellow', 'red', 'orange'][depth]
    #colors = '0123456789ABCDEF'
    colors = '02468ACEF'
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
    padding = 15
    margin = 0
    if color == 'white' # terminals
      margin = (maxdepth-depth+1)*15 + (maxdepth-depth)
      #padding = (maxdepth-depth+1)*15 + (maxdepth-depth) # this last term to account for the border of 1
    if not color?
     color = depthToColor(depth)
    return this.addClass('bordered').css('position', 'relative').css('padding', padding + 'px').css('font-size', '32px').attr('color', color).css('background-color', color).css('border-width', 1).css('border-style', 'solid').css('float', 'left').attr('depth', depth).css('border-color', 'black').css('border-radius', '10px').css('margin-top', margin).css('margin-bottom', margin)

  $.fn.showAsSibling = (color) ->
    if not color?
      color = 'lightblue'
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

  $.fn.hoverId = () ->
    text = this.attr('translation')
    if text.indexOf('/EntL') != -1
      text = text[...text.indexOf('/EntL')]
    idNum = this.attr('id')
    this.attr('title', text)
    this.attr('hovertext', text)
    textAsHtml = $('<div>')
    for x in text.split('\n')
      textAsHtml.append($('<span>').text(x)).append('<br>')
    this.tooltip({track: true, show:false, hide:false, content: textAsHtml.html()})
    shortTranslation = text
    if shortTranslation.indexOf('\n') != -1
      shortTranslation = shortTranslation[...shortTranslation.indexOf('\n')]
    shortTranslationDiv = $('<div>').addClass('Hovertips').attr('id', 'H' + idNum).text(shortTranslation).css('position', 'absolute').css('top', 0).css('zIndex', 100).css('color', 'white').css('background-color', 'black').css('border-top-left-radius', 5).css('border-top-right-radius', 5).css('font-size', 18).hide()
    shortTranslationDiv.css('text-align', 'center').css('word-wrap', 'break-word')
    this.append(shortTranslationDiv)
    #this.addClass(text.split(' ').join('-'))
    this.mouseover(() =>
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
          $('#' + sibling).showAsSibling('lightblue')
        currentId = parent
        #console.log currentId
      if getChildrenOfId(idNum).length == 0
        this.showAsSibling('yellow')
      else
        #console.log idNum
        for immediateChild in getChildrenOfId(idNum)
          $('#' + immediateChild).showAsSibling('pink')
      this.css('background-color', 'yellow')
      return false
    )
    this.mouseleave(() =>
      for x in $('.hovered')
        $(x).css('background-color', $(x).attr('color'))
      $('.hovered').removeClass('hovered')
      $('.Hovertips').hide()
      this.css('background-color', this.attr('color'))
    )
    return this

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

makeDivs = (subHierarchy, lang, translations, maxdepth, depth=1) ->
  basediv = $('<div>')
  id = subHierarchy.id
  contentHierarchy = subHierarchy[..]
  basediv.addClass('hovertext').attr('id', id)
  basediv.addClass('hovertext').addClass('textRegion')
  foreignText = hierarchyWithIdToTerminals(subHierarchy, lang)
  console.log 'foreign text: ' + foreignText
  basediv.attr('foreignText', foreignText)
  translation = translations[foreignText]
  basediv.attr('translation', translation)
  basediv.hoverId()
  #basediv.hoverText(translations[currentText])
  if contentHierarchy.length > 1
    basediv.borderStuff(depth, maxdepth)
    for child in contentHierarchy
      basediv.append makeDivs(child, lang, translations, maxdepth, depth+1)
  else if contentHierarchy.length == 1
    if typeof contentHierarchy[0] == typeof ''
      basediv.borderStuff(depth, maxdepth, 'white')
        #.css('font-size', 10+depth*10)
        .text(contentHierarchy[0]).hoverId()
    else
      basediv.borderStuff(depth, maxdepth, 'white')
        #.css('font-size', 20+depth*10)
        .text(contentHierarchy[0]).hoverId()

addIdsToHierarchy = (hierarchy, myId='R0') ->
  if typeof hierarchy == typeof []
    output = []
    for x,i in hierarchy
      console.log x
      output.push addIdsToHierarchy(x, myId + '_' + i)
    output.id = myId
    return output
  else
    output = [hierarchy]
    output.id = myId
    return output

getUrlParameters = () ->
  map = {}
  parts = window.location.href.replace(/[?&]+([^=&]+)=([^&]*)/gi, (m,key,value) ->
    map[key] = decodeURI(value)
  )
  return map

renderSentence = (sentence, ref_hierarchy, translations, lang) ->
  console.log ref_hierarchy
  console.log translations
  idnum = 0
  while $('#R' + idnum).length > 0
    idnum += 1
  ref_hierarchy_with_ids = addIdsToHierarchy(ref_hierarchy, 'R' + idnum)
  console.log ref_hierarchy_with_ids
  $('#sentenceDisplay').append(
    makeDivs(ref_hierarchy_with_ids, lang, translations, getMaxDepth(ref_hierarchy_with_ids) - 1)
  ).append('<br>')

addSentence = root.addSentence = (sentence, lang) ->
  addSentences([sentence], lang)

addSentences = root.addSentences = (sentences, lang) ->
  if not lang?
    lang = getUrlParameters()['lang'] ? 'en'
  parseHierarchyAndTranslationsForLang = (sentence, callback) ->
    now.getParseHierarchyAndTranslations(sentence, lang, (ref_hierarchy,translations) -> callback(null, [ref_hierarchy,translations]))
  async.mapSeries(sentences, parseHierarchyAndTranslationsForLang, (err, results) ->
    for i in [0...results.length]
      sentence = sentences[i]
      [ref_hierarchy,translations] = results[i]
      renderSentence(sentence, ref_hierarchy, translations, lang)
  )

now.ready(() ->
  #$(document).tooltip({track: true, show:false, hide:false})
  phraseText = getUrlParameters()['sentence'].split('(').join(' [ ').split(')').join(' ] ').split('  ').join(' ') ? 'the cat jumped over the dog'
  console.log phraseText
  lang = getUrlParameters()['lang'] ? 'en'
  sentences = [phraseText]
  addSentences(sentences, lang)
)

