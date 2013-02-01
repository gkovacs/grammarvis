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
    maxdepth = 5
    ###
    depth = $(this).parents().attr('depth')
    console.log this.parent()
    if depth?
      depth = parseInt(depth) + 1
    else
      depth = 0
    ###
    #this.css('display', 'table-cell').css('vertical-align', 'middle')
    padding = 15
    margin = 0
    if color == 'white' # terminals
      margin = (maxdepth-depth+1)*15 + (maxdepth-depth)
      #padding = (maxdepth-depth+1)*15 + (maxdepth-depth) # this last term to account for the border of 1
    if not color?
     color = depthToColor(depth)
    return this.addClass('bordered').css('position', 'relative').css('padding', padding + 'px').css('font-size', '32px').attr('color', color).css('background-color', color).css('border-width', 1).css('border-style', 'solid').css('float', 'left').attr('depth', depth).css('border-color', 'black').css('border-radius', '10px').css('margin-top', margin).css('margin-bottom', margin)

  $.fn.showSibling = () ->
    this.show().parent().css('background-color', 'green')

  #$.fn.getSiblings = () ->
  
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
    this.addClass(text.split(' ').join('-'))
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
  
  $.fn.hoverText = (text) ->
    this.tooltip({track: true, show:false, hide:false})
    this.attr('title', text)
    this.attr('hovertext', text)
    this.append($('<div>').addClass('Hovertips').addClass('H' + text.split(' ').join('-')).text(text).css('position', 'absolute').css('left', 0).css('bottom', -18).css('zIndex', 100).css('color', 'white').css('background-color', 'green').css('font-size', 18).hide())
    this.addClass(text.split(' ').join('-'))
    this.mouseover(() =>
      console.log this.attr('hovertext')

      #$('#transRegion').text(text)
      #for x in $('.hovered')
      #  $(x).css('background-color', $(x).attr('color'))
      #$('.hovered').removeClass('hovered')
      this.css('background-color', 'yellow')
      ###
      parent = this.parent()
      #console.log parent
      while parent.length > 0 and parent.attr? and parent.attr('color')?
        parent.css('background-color', parent.attr('color'))
        parent = parent.parent()
      ###
      for x in $('.bordered')
        $(x).css('background-color', $(x).attr('color'))
      this.addClass('hovered')

      $('.Hovertips').hide()
      if this.attr('hovertext') == 'my cat'
        $('.Hate-5-mice-in-the-house').showSibling()
        #$('.Hmy-cat-ate-5-mice-in-the-house').show()
      if this.attr('hovertext') == 'ate 5 mice in the house'
        $('.Hmy-cat').showSibling()
      if this.attr('hovertext') == 'in the house'
        $('.Hmy-cat').showSibling()
        $('.Hate-5-mice').showSibling()
      if this.attr('hovertext') == 'ate 5 mice'
        $('.Hin-the-house').showSibling()
        $('.Hmy-cat').showSibling()
      if this.attr('hovertext') == '5 mice'
        $('.Hin-the-house').showSibling()
        $('.Hmy-cat').showSibling()
        $('.Hate').showSibling()
      if this.attr('hovertext') == '5 small animals'
        $('.Hin-the-house').showSibling()
        $('.Hmy-cat').showSibling()
        $('.Hate').showSibling()
        $('.Hmouse').showSibling()
      this.css('background-color', 'yellow')
      #console.log text
      #this.tooltip({track: true})
      #this.html($('<span>').addClass('translation').text(text))
      #this.find('.translation').show()
      return false
    )
    this.mouseleave(() =>
      #for x in $('.hovered')
      #  $(x).css('background-color', $(x).attr('color'))
      #$('.hovered').removeClass('hovered')
      this.css('background-color', this.attr('color'))
    )
    return this

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
  id = hierarchy[0]
  contents = hierarchy[1..]
  if contents.length == 1
    return contents[0]
  else
    children = (hierarchyWithIdToTerminals(x, lang) for x in contents)
    if not lang? or lang == 'zh' or lang == 'ja'
      return children.join('')
    else
      return children.join(' ')

makeDivs = (subHierarchy, depth=1) ->
  basediv = $('<div>')
  id = subHierarchy[0]
  contentHierarchy = subHierarchy[1..]
  currentText = hierarchyToTerminals(contentHierarchy)
  console.log currentText
  console.log translations[currentText]
  basediv.addClass('hovertext').attr('id', id)
  basediv.addClass('hovertext').addClass('textRegion')
  foreignText = hierarchyWithIdToTerminals(subHierarchy)
  console.log 'foreign text: ' + foreignText
  basediv.attr('foreignText', foreignText)
  translation = translations[foreignText]
  basediv.attr('translation', translation)
  basediv.hoverId()
  #basediv.hoverText(translations[currentText])
  if contentHierarchy.length > 1
    basediv.borderStuff(depth)
    for child in contentHierarchy
      basediv.append makeDivs(child, depth+1)
  else if contentHierarchy.length == 1
    basediv.borderStuff(depth, 'white').text(contentHierarchy[0]).hoverId()

addIdsToHierarchy = (hierarchy, myId='R') ->
  if typeof hierarchy == typeof []
    output = [myId]
    for x,i in hierarchy
      output.push addIdsToHierarchy(x, myId + '_' + i)
    return output
  else
    return [myId, hierarchy]

$(document).ready(() ->
  #$(document).tooltip({track: true, show:false, hide:false})
  ref_hierarchy_with_ids = root.ref_hierarchy_with_ids = addIdsToHierarchy(ref_hierarchy)
  $('body').css('display', 'table').append(
    makeDivs(ref_hierarchy_with_ids)
  )
  return
  $('body').css('position', 'relative').append(
    $('<div>').borderStuff(1).hoverText('my cat ate 5 mice in the house').append(
      $('<div>').borderStuff(2).hoverText('my cat').append(
        $('<div>').borderStuff(0).hoverText('me').text('私')
      ).append(
        $('<div>').borderStuff(0).hoverText('of').text('の')
      ).append(
        $('<div>').borderStuff(0).hoverText('cat').text('猫')
      )
    ).append(
      $('<div>').borderStuff(0).hoverText('subject marker').text('が')
    ).append(
        $('<div>').borderStuff(2).hoverText('ate 5 mice in the house').append(
          $('<div>').borderStuff(3).hoverText('in the house').append(
            $('<div>').borderStuff(0).hoverText('house').text('家')
          ).append(
            $('<div>').borderStuff(0).hoverText('at').text('で')
          )
        ).append(
          $('<div>').borderStuff(3).hoverText('ate 5 mice').append(
            $('<div>').borderStuff(4).hoverText('5 mice').append(
              $('<div>').borderStuff(5).hoverText('5 small animals').append(
                $('<div>').borderStuff(0).hoverText('5').text('五')#.append($('<div>').text('the number five is very important').css('font-size', '12px'))
              ).append(
                $('<div>').borderStuff(0).hoverText('counter for small animals').text('匹')
              )
            ).append(
              $('<div>').borderStuff(0).hoverText('of').text('の')
            ).append(
              $('<div>').borderStuff(0).hoverText('mouse').text('鼠')
            )
          ).append(
            $('<div>').borderStuff(0).hoverText('object marker').text('を')
          ).append(
            $('<div>').borderStuff(0).hoverText('ate').text('食べた')
          )
        )
    )
  ).append(
    $('<div>').attr('id', 'transRegion')
  )
  $('.ate').hoverText('ate')
  $('.mouse').hoverText('mouse')
  $('.me').hoverText('me')
  $('.of').hoverText('of')
  $('.cat').hoverText('cat')
)
