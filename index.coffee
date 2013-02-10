now.ready(() ->
  #$(document).tooltip({track: true, show:false, hide:false})
  phraseText = getUrlParameters()['sentence'].split('(').join(' [ ').split(')').join(' ] ').split('  ').join(' ') ? 'the cat jumped over the dog'
  console.log phraseText
  lang = getUrlParameters()['lang'] ? 'en'
  sentences = [phraseText]
  addSentences(sentences, lang)
)

