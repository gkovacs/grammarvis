root = exports ? this
print = console.log

fs = require 'fs'

$ = require('jquery')(require("jsdom").jsdom().parentWindow)

und = require 'underscore'

jmorph = require './japanesemorphology'
jdict = new jmorph.rcxDict(false)

hira = {
  'あ': ['a'],
  'い': ['i'],
  'う': ['u'],
  'え': ['e'],
  'お': ['o'],
  'か': ['ka'],
  'き': ['ki'],
  'く': ['ku'],
  'け': ['ke'],
  'こ': ['ko'],
  'が': ['ga']
  'ぎ': ['gi']
  'ぐ': ['gu']
  'げ': ['ge']
  'ご': ['go']
  'さ': ['sa'],
  'し': ['shi', 'si'],
  'す': ['su'],
  'せ': ['se'],
  'そ': ['so'],
  'ざ': ['za']
  'じ': ['ji', 'zi']
  'ず': ['zu']
  'ぜ': ['ze']
  'ぞ': ['zo']
  'た': ['ta'],
  'ち': ['chi', 'ti'],
  'つ': ['tsu', 'tu'],
  'て': ['te'],
  'と': ['to'],
  'だ': ['da']
  'ぢ': ['ji', 'di']
  'づ': ['zu', 'du']
  'で': ['de']
  'ど': ['do']
  'な': ['na'],
  'に': ['ni'],
  'ぬ': ['nu'],
  'ね': ['ne'],
  'の': ['no'],
  'は': ['ha'],
  'ひ': ['hi'],
  'ふ': ['fu', 'hu'],
  'へ': ['he'],
  'ほ': ['ho'],
  'ば': ['ba'],
  'び': ['bi'],
  'ぶ': ['bu'],
  'べ': ['be'],
  'ぼ': ['bo'],
  'ぱ': ['pa'],
  'ぴ': ['pi'],
  'ぷ': ['pu'],
  'ぺ': ['pe'],
  'ぽ': ['po'],
  'ま': ['ma'],
  'み': ['mi'],
  'む': ['mu'],
  'め': ['me'],
  'も': ['mo'],
  'や': ['ya'],
  'ゆ': ['yu'],
  'よ': ['yo'],
  'ら': ['ra', 'la'],
  'り': ['ri', 'li'],
  'る': ['ru', 'lu'],
  'れ': ['re', 'le'],
  'ろ': ['ro', 'lo'],
  'わ': ['wa'],
  'ゐ': ['wi'],
  'ゑ': ['we'],
  'を': ['o', 'wo'],
  'ん': ["n'", "n", 'nn'],
  'きゃ': ['kya'],
  'きゅ': ['kyu'],
  'きょ': ['kyo'],
  'ぎゃ': ['gya'],
  'ぎゅ': ['gyu'],
  'ぎょ': ['gyo'],
  'しゃ': ['sha', 'sya'],
  'しゅ': ['shu', 'syu'],
  'しょ': ['sho', 'syo'],
  'じゃ': ['ja', 'zya'],
  'じゅ': ['ju', 'zyu'],
  'じょ': ['jo', 'zyo'],
  'ちゃ': ['cha', 'tya'],
  'ちゅ': ['chu', 'tyu'],
  'ちょ': ['cho', 'tyo'],
  'にゃ': ['nya'],
  'にゅ': ['nyu'],
  'にょ': ['nyo'],
  'ひゃ': ['hya'],
  'ひゅ': ['hyu'],
  'ひょ': ['hyo'],
  'びゃ': ['bya'],
  'びゅ': ['byu'],
  'びょ': ['byo'],
  'ぴゃ': ['pya'],
  'ぴゅ': ['pyu'],
  'ぴょ': ['pyo'],
  'りゃ': ['rya'],
  'りゅ': ['ryu'],
  'りょ': ['ryo'],
}

do ->
  for nkana,romanizations of hira
    if true in romanizations.map((x) -> x[-1..-1] == 'a')
      hira[nkana + 'あ'] = romanizations.map((x) -> x[...-1] + 'ā')
    if true in romanizations.map((x) -> x[-1..-1] == 'i')
      hira[nkana + 'い'] = romanizations.map((x) -> x[...-1] + 'ī')
    if true in romanizations.map((x) -> x[-1..-1] == 'e')
      hira[nkana + 'え'] = romanizations.map((x) -> x[...-1] + 'ē')
    if true in romanizations.map((x) -> x[-1..-1] == 'o')
      hira[nkana + 'お'] = romanizations.map((x) -> x[...-1] + 'ō')
    if true in romanizations.map((x) -> x[-1..-1] == 'o')
      hira[nkana + 'う'] = romanizations.map((x) -> x[...-1] + 'ō')
    if true in romanizations.map((x) -> x[-1..-1] == 'u')
      hira[nkana + 'う'] = romanizations.map((x) -> x[...-1] + 'ū')

jconsonants = 'kptgsjzcdbh'

do ->
  for nkana,romanizations of hira
    if true in romanizations.map((x) -> x[0] in jconsonants)
      hira['っ' + nkana] = romanizations.map((x) -> x[0] + x)

kata = {
  'ア': ['a'],
  'イ': ['i'],
  'ウ': ['u'],
  'エ': ['e'],
  'オ': ['o'],
  'カ': ['ka'],
  'キ': ['ki'],
  'ク': ['ku'],
  'ケ': ['ke'],
  'コ': ['ko'],
  'ガ': ['ga']
  'ギ': ['gi']
  'グ': ['gu']
  'ゲ': ['ge']
  'ゴ': ['go']
  'サ': ['sa'],
  'シ': ['shi', 'si'],
  'ス': ['su'],
  'セ': ['se'],
  'ソ': ['so'],
  'ザ': ['za']
  'ジ': ['ji', 'zi']
  'ズ': ['zu']
  'ゼ': ['ze']
  'ゾ': ['zo']
  'タ': ['ta'],
  'チ': ['chi', 'ti'],
  'ツ': ['tsu', 'tu'],
  'テ': ['te'],
  'ト': ['to'],
  'ダ': ['da']
  'ヂ': ['ji', 'di']
  'ヅ': ['zu', 'du']
  'デ': ['de']
  'ド': ['do']
  'ナ': ['na'],
  'ニ': ['ni'],
  'ヌ': ['nu'],
  'ネ': ['ne'],
  'ノ': ['no'],
  'ハ': ['ha'],
  'ヒ': ['hi'],
  'フ': ['fu', 'hu'],
  'ヘ': ['he'],
  'ホ': ['ho'],
  'バ': ['ba'],
  'ビ': ['bi'],
  'ブ': ['bu'],
  'ベ': ['be'],
  'ボ': ['bo'],
  'パ': ['pa'],
  'ピ': ['pi'],
  'プ': ['pu'],
  'ペ': ['pe'],
  'ポ': ['po'],
  'マ': ['ma'],
  'ミ': ['mi'],
  'ム': ['mu'],
  'メ': ['me'],
  'モ': ['mo'],
  'ヤ': ['ya'],
  'ユ': ['yu'],
  'ヨ': ['yo'],
  'ラ': ['ra', 'la'],
  'リ': ['ri', 'li'],
  'ル': ['ru', 'lu'],
  'レ': ['re', 'le'],
  'ロ': ['ro', 'lo'],
  'ワ': ['wa'],
  'ン': ["n'", "n", 'nn'],
  'キャ': ['kya'],
  'キュ': ['kyu'],
  'キョ': ['kyo'],
  'ギャ': ['gya'],
  'ギュ': ['gyu'],
  'ギョ': ['gyo'],
  'シャ': ['sha', 'sya'],
  'シュ': ['shu', 'syu'],
  'ショ': ['sho', 'syo'],
  'ジャ': ['ja', 'zya'],
  'ジュ': ['ju', 'zyu'],
  'ジョ': ['jo', 'zyo'],
  'チャ': ['cha', 'tya'],
  'チュ': ['chu', 'tyu'],
  'チョ': ['cho', 'tyo'],
  'ニャ': ['nya'],
  'ニュ': ['nyu'],
  'ニョ': ['nyo'],
  'ヒャ': ['hya'],
  'ヒュ': ['hyu'],
  'ヒョ': ['hyo'],
  'ビャ': ['bya'],
  'ビュ': ['byu'],
  'ビョ': ['byo'],
  'ピャ': ['pya'],
  'ピュ': ['pyu'],
  'ピョ': ['pyo'],
  'リャ': ['rya'],
  'リュ': ['ryu'],
  'リョ': ['ryo'],
  'ティ': ['ti'],
  'ディ': ['di'],
  'トゥ': ['tu'],
  'ドゥ': ['du'],
  'テュ': ['tyu'],
  'デュ': ['dyu'],
  'トヮ': ['toa'],
  'モヮ': ['moa'],
  'ウィ': ['wi'],
  'ウェ': ['we'],
  'ワォ': ['wo'],
  'ファ': ['fa'],
  'フィ': ['fi'],
  'フェ': ['fe'],
  'フォ': ['fo'],
  'ヴァ': ['va'],
  'ヴィ': ['vi'],
  'ヴェ': ['ve'],
  'ヴォ': ['vo'],
  'ヴュ': ['vyu'],
  'クァ': ['kwa', 'qwa', 'qua'],
  'クィ': ['kwi', 'qwi', 'qui'],
  'クェ': ['kwe', 'qwe', 'que'],
  'クォ': ['kwo', 'qwo', 'quo'],
  'スァ': ['swa'],
  'スィ': ['swi'],
  'スェ': ['swe'],
  'スォ': ['swo'],
  'シェ': ['she'],
  'ジェ': ['je'],
  'チェ': ['che'],
  'ツァ': ['tsa'],
  'ツィ': ['tsi'],
  'ツェ': ['tse'],
  'ツォ': ['tso'],
  'ィ': ['i'],
  'ェ': ['e'],
  'ァ': ['a'],
  'ォ': ['o'],
  'ゥ': ['u'],
}

do ->
  for nkana,romanizations of kata
    if true in romanizations.map((x) -> x[-1..-1] == 'a')
      kata[nkana + 'ー'] = romanizations.map((x) -> x[...-1] + 'ā')
    if true in romanizations.map((x) -> x[-1..-1] == 'i')
      kata[nkana + 'ー'] = romanizations.map((x) -> x[...-1] + 'ī')
    if true in romanizations.map((x) -> x[-1..-1] == 'e')
      kata[nkana + 'ー'] = romanizations.map((x) -> x[...-1] + 'ē')
    if true in romanizations.map((x) -> x[-1..-1] == 'o')
      kata[nkana + 'ー'] = romanizations.map((x) -> x[...-1] + 'ō')
    if true in romanizations.map((x) -> x[-1..-1] == 'u')
      kata[nkana + 'ー'] = romanizations.map((x) -> x[...-1] + 'ū')

do ->
  for nkana,romanizations of kata
    if true in romanizations.map((x) -> x[0] in jconsonants)
      kata['ッ' + nkana] = romanizations.map((x) -> x[0] + x)

do ->
  for nkana,romanizations of kata
    hira[nkana] = romanizations

toRomaji = root.toRomaji = (kana) ->
  output = []
  kana_idx = 0
  while kana_idx < kana.length
    matched = false
    if kana[kana_idx...kana_idx+3].length == 3 and hira[kana[kana_idx...kana_idx+3]]?
      output.push hira[kana[kana_idx...kana_idx+3]][0]
      kana_idx += 3
      matched = true
    if matched
      continue
    if kana[kana_idx...kana_idx+2].length == 2 and hira[kana[kana_idx...kana_idx+2]]?
      output.push hira[kana[kana_idx...kana_idx+2]][0]
      kana_idx += 2
      matched = true
    if matched
      continue
    if kana[kana_idx...kana_idx+1].length == 1 and hira[kana[kana_idx...kana_idx+1]]?
      output.push hira[kana[kana_idx...kana_idx+1]][0]
      kana_idx += 1
      matched = true
    if matched
      continue
    output.push kana[kana_idx...kana_idx+1]
    kana_idx += 1
  return output.join('')

isKatakana = (word) ->
  for c in word
    if not kata[c]?
      return false
  return true

kanaMatchesRomajiScore = (romaji, kana) ->
  romaji = romaji.toLowerCase()
  if romaji == 'wa' and kana == 'は'
    return 2
  if romaji == 'e' and kana == 'へ'
    return 1
  kana_idx = 0
  romaji_idx = 0
  rom_matched = 0
  while kana_idx < kana.length and romaji_idx < romaji.length
    matched = false
    if kana[kana_idx...kana_idx+3].length == 3 and hira[kana[kana_idx...kana_idx+3]]?
      for rom in hira[kana[kana_idx...kana_idx+3]]
        if romaji[romaji_idx...romaji_idx+rom.length] == rom
          rom_matched += rom.length
          romaji_idx += rom.length
          kana_idx += 3
          matched = true
          break
    if matched
      continue
    if kana[kana_idx...kana_idx+2].length == 2 and hira[kana[kana_idx...kana_idx+2]]?
      for rom in hira[kana[kana_idx...kana_idx+2]]
        if romaji[romaji_idx...romaji_idx+rom.length] == rom
          rom_matched += rom.length
          romaji_idx += rom.length
          kana_idx += 2
          matched = true
          break
    if matched
      continue
    if kana[kana_idx...kana_idx+1].length == 1 and hira[kana[kana_idx...kana_idx+1]]?
      for rom in hira[kana[kana_idx...kana_idx+1]]
        if romaji[romaji_idx...romaji_idx+rom.length] == rom
          rom_matched += rom.length
          romaji_idx += rom.length
          kana_idx += 1
          matched = true
          break
    if matched
      continue
    return rom_matched
  return rom_matched

prettyPrintDefinition = (defpair) ->
  [definition,defnotes] = defpair
  if defnotes?
    return $('<span>').html(defnotes).text() + '\n' + definition
  else
    return definition

getKanaFromDef = (defpair) ->
  definition = defpair[0]
  definition = definition[...definition.indexOf('/')]
  if definition.indexOf('[') != -1 and definition.indexOf(']') != -1
    newKana = definition[definition.indexOf('[')+1...definition.indexOf(']')]
    return newKana.trim()
  return definition.trim()

haveAnnotation = (defpair) ->
  if defpair.length >= 2 and defpair[1]?
    return true
  return false

getTranslationAnnotationList = (translation) ->
  if translation.indexOf('/(') != -1
    translation = translation[translation.indexOf('/(')+2..]
  if translation.indexOf(')/') != -1
    translation = translation[...translation.indexOf(')/')]
  return translation.split(',')

maxArray = (l) -> Math.max(l...)

reorderTranslations = (word, allTranslations) ->
  sortable = []
  kanaLengthsForDefs = (getKanaFromDef(defpair).length for defpair in allTranslations)
  longestKana = maxArray(kanaLengthsForDefs)
  for defpair,idx in allTranslations
    if getKanaFromDef(defpair).length < longestKana - 2
      continue
    score = 0
    score += getKanaFromDef.length
    score += idx/10.0
    sortable.push [score, defpair]
  sortable.sort()
  return (x[1] for x in sortable)

class JapaneseDict

  constructor: () ->
    console.log 'jdict3 constructed'

  doesWordExist: (word) ->
    wordTranslation = jdict.wordSearch(word)
    if wordTranslation? and wordTranslation.data? and wordTranslation.data[0]?
      removeLast = jdict.wordSearch(word[...word.length-1])
      if removeLast? and removeLast.data? and removeLast.data[0]?
        if not und.isEqual(removeLast.data[0], wordTranslation.data[0])
          return true
        else
          return false
      else
        return true
    wordTranslation = jdict.kanjiSearch(word)
    if wordTranslation? and wordTranslation.eigo?
      return true
    return false

  getRomaji: (word) ->
    wordTranslation = jdict.wordSearch(word)
    if wordTranslation? and wordTranslation.data? and wordTranslation.data.length >= 1
      translations = reorderTranslations(word, wordTranslation.data)
      if translations[0]?
        kanaFromDef = getKanaFromDef(translations[0])
        if kanaFromDef?
          return toRomaji(kanaFromDef)
    wordTranslation = jdict.kanjiSearch(word)
    if wordTranslation? and wordTranslation.onkun?
      return toRomaji(wordTranslation.onkun)

  getDefinition: (word) ->
    wordTranslation = jdict.wordSearch(word)
    if wordTranslation? and wordTranslation.data? and wordTranslation.data.length >= 1
      translations = reorderTranslations(word, wordTranslation.data)
      translations = translations[...3]
      return (prettyPrintDefinition(x) for x in translations).join('\n')
    wordTranslation = jdict.kanjiSearch(word)
    if wordTranslation? and wordTranslation.eigo?
      return wordTranslation.eigo
    #if wordTranslation? and wordTranslation.data? and wordTranslation.data.length >= 1
    #  translations = wordTranslation.data[...3]
    #  return (prettyPrintDefinition(x) for x in translations).join('\n')
    return null

root.JapaneseDict = JapaneseDict
root.kanaMatchesRomajiScore = kanaMatchesRomajiScore
