root = exports ? this

class WiktionaryDict
  constructor: (dictText) ->
    wordLookup = {} # word -> [definition list]
    for line in dictText.split('\n')
      if line.indexOf(':') != 0
        continue
      splitByColon = line.split(':')
      if splitByColon[0] == ''
        splitByColon = splitByColon[1..]
      if splitByColon.length < 2
        continue
      foreignWord = splitByColon[0]
      englishWord = splitByColon[1..].join(':')
      if not wordLookup[foreignWord]?
        wordLookup[foreignWord] = []
      wordLookup[foreignWord].push englishWord
    @wordLookup = wordLookup

  getEnglishListForWord: (word) ->
    if not @wordLookup[word]?
      return []
    return @wordLookup[word]

root.WiktionaryDict = WiktionaryDict

