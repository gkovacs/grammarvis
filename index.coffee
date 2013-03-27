$(document).ready(() ->
  #$(document).tooltip({track: true, show:false, hide:false})
  phraseText = getUrlParameters()['sentence'].split('(').join(' [ ').split(')').join(' ] ').split('  ').join(' ') ? 'the cat jumped over the dog'
  console.log phraseText
  lang = getUrlParameters()['lang'] ? 'en'
  if false #lang == 'de'
    console.log '/segmentSentences?lang=' + lang + '&text=' + phraseText
    $.get('/segmentSentences?lang=' + lang + '&text=' + phraseText, (sentences) ->
      console.log sentences
      sentences = JSON.parse(sentences)
      console.log sentences
      addSentences(sentences, lang)
    )
  else
    sentences = [phraseText]
    addSentences(sentences, lang)
)

