fs = require 'fs'
root = exports ? this
print = console.log

japanesedict = require './japanesedict_v2'

main = ->
  dictText = fs.readFileSync('edict2_full.txt', 'utf8')
  jdict = new japanesedict.JapaneseDict(dictText)
  #print jdict.wordLookup['私']
  print jdict.getRomaji('私')
  print jdict.getDefinition('私')
  print jdict.getRomaji('問題が山積みなのじゃ')
  #print jdict.getRomaji('中華人民共和国')
  #print japanesedict.toRomaji('がっこう')
  #print japanesedict.kanaMatchesRomajiScore('watashi', 'わたし')
  #print japanesedict.kanaMatchesRomajiScore('chūgokugo', 'ちゅうごくご')
  #print japanesedict.kanaMatchesRomajiScore('pātī', 'パーティー')
  #dictText = fs.readFileSync('edict2_full.txt', 'utf8')
  #print dictText
  #jdict = new japanesedict.JapaneseDict(dictText)
  #print jdict.wordLookup['学校'][0][0]
  #jdict.getGlossForSentence('拳銃所持容疑:警視庁、組幹部ら逮捕', print)
  #jdict.getGlossForSentence('その１０倍もの神経細胞支持する細胞があります', print)
  #jdict.getGlossForSentence('お嬢さんの病気は何らかの理由で小脳が萎縮し', print)
  #jdict.getGlossForSentence('その中で体を自由にスムーズに動かす働きをしているのが', print)
  #jdict.getGlossForSentence('病気はどうして私を選んだのだろう', print)
  #jdict.getGlossForSentence('それらの神経細胞は中枢神経と末梢神経に分けられ', print)
  #jdict.getGlossForSentence('特別じゃない  ただ特別な病気に選ばれてしまった 少女の記録', print)
  #jdict.getGlossForSentence('なんか落ち着かなくて眠れなかった', print)
  #jdict.getGlossForSentence('でもね　うちのクラス　ピアノ弾けるのは　富田さんしかいなくて', print)
  #jdict.getGlossForSentence('クラス委員　前　出て', print)
  #jdict.getGlossForSentence('どんな転び方した　そんなところ怪我し', print)

main() if require.main is module
