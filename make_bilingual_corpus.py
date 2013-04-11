#!/usr/bin/python

lines = [x for x in open('sentences.csv')]
id_to_fra_sentence = {}
id_to_eng_sentence = {}
links = [x for x in open('links.csv')]
id_links = {}

for line in links:
  [id1, id2] = line.split('\t', 1)
  id1 = int(id1)
  id2 = int(id2)
  id_links[id1] = id2
  id_links[id2] = id1

for line in lines:
  [id,lang,sentence] = line.strip().split('\t', 2)
  id = int(id)
  if lang == 'cmn':
    id_to_fra_sentence[id] = sentence
  if lang == 'eng':
    id_to_eng_sentence[id] = sentence

for id in id_to_fra_sentence.keys():
  #if id not in id_links:
  #  continue
  #engid = id_links[id]
  #if engid not in id_to_eng_sentence:
  #  continue
  if id in id_links:
    engid = id_links[id]
    if engid in id_to_eng_sentence:
      continue
  print id
  print id_to_fra_sentence[id]
  #print id_to_eng_sentence[engid]
  print 'none'
  print '==='

