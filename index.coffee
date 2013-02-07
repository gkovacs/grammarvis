# 昨天我的猫在家里吃了五只鼠

root = exports ? this

do ($) ->

  depthToColor = (depth) ->
    #return ['white', 'blue', 'green', 'yellow', 'red', 'orange'][depth]
    #colors = '0123456789ABCDEF'
    colors = '02468ACEF'
    #colors = 'FECA86420'
    return '#' + (colors[colors.length - depth - 1] for i in [0..5]).join('')

  $.fn.borderStuff = (depth, color) ->
    #if not width?
    width = 3
    maxdepth = getMaxDepth() #getMaxDepth('R')
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

  $.fn.showAsSibling = () ->
    this.css('background-color', 'pink')
    $('#H' + this.attr('id')).show()

  $.fn.hoverId = () ->
    this.tooltip({track: true, show:false, hide:false})
    text = this.attr('translation')
    this.attr('title', this.attr('translation'))
    this.attr('hovertext', this.attr('translation'))
    idNum = this.attr('id')
    this.attr('title', text)
    this.attr('hovertext', text)
    this.append($('<div>').addClass('Hovertips').attr('id', 'H' + idNum).text(text).css('position', 'absolute').css('left', 0).css('bottom', 0).css('zIndex', 100).css('color', 'white').css('background-color', 'black').css('font-size', 18).hide())
    #this.addClass(text.split(' ').join('-'))
    this.mouseover(() =>
      console.log this.attr('hovertext')
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
        currentId = parent
        console.log currentId
      this.css('background-color', 'yellow')
      return false
    )
    this.mouseleave(() =>
      #for x in $('.hovered')
      #  $(x).css('background-color', $(x).attr('color'))
      #$('.hovered').removeClass('hovered')
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
  if not subtree?
    subtree = root.ref_hierarchy
  if typeof subtree != typeof []
    return 0
  maxval = 0
  for child in subtree
    maxval = Math.max(maxval, getMaxDepth(child)+1)
  return maxval

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

makeDivs = (subHierarchy, lang, depth=1) ->
  basediv = $('<div>')
  id = subHierarchy.id
  contentHierarchy = subHierarchy[..]
  basediv.addClass('hovertext').attr('id', id)
  basediv.addClass('hovertext').addClass('textRegion')
  foreignText = hierarchyWithIdToTerminals(subHierarchy, lang)
  console.log 'foreign text: ' + foreignText
  basediv.attr('foreignText', foreignText)
  translation = root.translations[foreignText]
  basediv.attr('translation', translation)
  basediv.hoverId()
  #basediv.hoverText(translations[currentText])
  if contentHierarchy.length > 1
    basediv.borderStuff(depth)
    for child in contentHierarchy
      basediv.append makeDivs(child, lang, depth+1)
  else if contentHierarchy.length == 1
    if typeof contentHierarchy[0] == typeof ''
      basediv.borderStuff(depth, 'white')
        #.css('font-size', 10+depth*10)
        .text(contentHierarchy[0]).hoverId()
    else
      basediv.borderStuff(depth, 'white')
        #.css('font-size', 20+depth*10)
        .text(contentHierarchy[0]).hoverId()

addIdsToHierarchy = (hierarchy, myId='R') ->
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

now.ready(() ->
  #$(document).tooltip({track: true, show:false, hide:false})
  root.phraseText = getUrlParameters()['sentence'].split('(').join(' [ ').split(')').join(' ] ').split('  ').join(' ') ? 'the cat jumped over the dog'
  console.log root.phraseText
  lang = getUrlParameters()['lang'] ? 'en'
  now.getParseHierarchyAndTranslations(root.phraseText, lang, (ref_hierarchy, translations) ->
  #ref_hierarchy = ['会議', ['中に', ['遊ぶ', ['のは', ['やめなさい']]]]]
  #ref_hierarchy = [['私の', ['猫が']], '家で', '鼠を', ['食べた']]
  #ref_hierarchy = [[['私 の'], '猫 が', '鼠 を'], '食べた']
  #ref_hierarchy = [['私 の', '猫 が'], '家 で', ['鼠 を', '食べた']]
  #ref_hierarchy = [['会議 中 に  '], [['遊ぶ の は  '], ['やめ なさい ']]]
  #ref_hierarchy = [[['私', 'の'], ['猫', 'が']], ['家', 'で'], [['青い'], ['鼠', 'を']], ['食べた']]
  #now.getTranslationsForParseHierarchy(ref_hierarchy, lang, (translations) ->
    console.log ref_hierarchy
    console.log translations
    root.ref_hierarchy = ref_hierarchy
    root.translations = translations
    ref_hierarchy_with_ids = root.ref_hierarchy_with_ids = addIdsToHierarchy(ref_hierarchy)
    console.log ref_hierarchy_with_ids
    $('body').css('display', 'table').append(
      makeDivs(ref_hierarchy_with_ids, lang)
    )
  )
)
