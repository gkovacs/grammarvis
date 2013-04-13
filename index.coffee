$(document).ready(() ->
  #$(document).tooltip({track: true, show:false, hide:false})
  urlParams = getUrlParameters()
  phraseText = urlParams['sentence'].split('(').join(' [ ').split(')').join(' ] ').split('  ').join(' ') ? 'the cat jumped over the dog'
  console.log phraseText
  highlightRegion = urlParams['highlight'] ? ''
  hideStructure = false
  if urlParams['hideStructure']?
    hideStructure = (urlParams['hideStructure'] != 'false')
  lang = getUrlParameters()['lang'] ? 'en'
  if false #lang == 'de'
    console.log '/segmentSentences?lang=' + lang + '&text=' + phraseText
    $.get('/segmentSentences?lang=' + lang + '&text=' + phraseText, (sentences) ->
      console.log sentences
      sentences = JSON.parse(sentences)
      console.log sentences
      addSentences(sentences, lang, $('#sentenceDisplay'), {'hideStructure': hideStructure})
    )
  else
    sentences = [phraseText]
    addSentences(sentences, lang, $('#sentenceDisplay'), {'hideStructure': hideStructure, 'highlight': highlightRegion})
)

