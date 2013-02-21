fs = require 'fs'
wiktionarydict = require './wiktionarydict'

main = ->
  #print chinesedict.toneNumberToMark('hu1 ma3 xian4')
  dictText = fs.readFileSync('fra-eng.txt', 'utf8')
  fdict = new wiktionarydict.WiktionaryDict(dictText)
  #print cdict.getPinyinForWord('家')
  #print cdict.getWordList('大家好')
  #print cdict.getPinyin('大家好')
  #print cdict.getEnglishForWord('大')
  #print cdict.getWordList('中华人民共和国中央人民政府门户网站')
  #print cdict.wordLookup['什']
  print fdict.wordLookup['jument']

main() if require.main is module
