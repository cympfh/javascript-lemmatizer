###
# JavaScript Lemmatizer v0.0.2
# forked from
# (
#   https://github.com/takafumir/javascript-lemmatizer
#   MIT License
#   by Takafumi Yamano
# )
# by cympfh
###

##
# util

String::ends_with = (suffix) ->
  return this.indexOf(suffix, this.length - suffix.length) isnt -1

is_vowel = (x) -> x in ['a', 'e', 'i', 'o', 'u']
is_include = (lemmas, target) ->
  for lemma in lemmas
    if lemma[0] is target[0] and lemma[1] is target[1]
      return true
  false

uniq_lemmas = (lemmas) ->
  ret = []
  for lemma in lemmas
    if (not is_include ret, lemma) and (lemma[0].length > 1)
      ret.push lemma
  ret

ends_with_es = (form) ->
  bl = false
  ends = ['ches', 'shes', 'oes', 'ses', 'xes', 'zes']
  ends.forEach (end) ->
    bl = true if form.ends_with end
  return bl

ends_with_verb_vowel_ys = (form) ->
  bl = false
  ends = ['ays', 'eys', 'iys', 'oys', 'uys']
  ends.forEach (end) ->
    bl = true if form.ends_with end
  return bl

##
# dict files

wn_files =
  noun: [
    './dict/index.noun.json'
    './dict/noun.exc.json'
  ]
  verb: [
    './dict/index.verb.json'
    './dict/verb.exc.json'
  ]
  adj:  [
    './dict/index.adj.json'
    './dict/adj.exc.json'
  ]
  adv:  [
    './dict/index.adv.json'
    './dict/adv.exc.json'
  ]

morphological_substitutions =
  noun: [
    ['ies',  'y'  ]
    ['ves',  'f'  ]
    ['men',  'man']
  ]
  verb: [
    ['ies', 'y']
    ['ied', 'y']
    ['cked', 'c']
    ['cked', 'ck']
    ['able', 'e']
    ['able', '']
    ['ability', 'e']
    ['ability', '']
  ]
  adj:  [
    ['er',  '' ]
    ['est', '' ]
    ['er',  'e']
    ['est', 'e']
    ['ier', 'y']
    ['iest', 'y']
  ]
  adv:  [
    ['er',  '' ]
    ['est', '' ]
    ['er',  'e']
    ['est', 'e']
    ['ier', 'y']
    ['iest', 'y']
  ]

wordlists  = {}
exceptions = {}

# initialize wordlists and exceptions
for pos of wn_files
  wordlists[pos] = {}
  exceptions[pos] = {}

  idx_file = wn_files[pos][0]
  exc_file = wn_files[pos][1]

  words = require idx_file
  words.forEach (w) -> wordlists[pos][w] = w

  exc = require exc_file
  exc.forEach (item) ->
    w = item[0]
    s = item[1]
    exceptions[pos][w] = s

_ =
  include: (xs, x) -> x in xs
  nub: (xs) ->
    ret = []
    for x in xs
      ret.push x if not (x in ret)
    ret

# return Array of ["lemma", "pos"] pairs
# like [ ["lemma1", "verb"], ["lemma2", "noun"]... ]
lemmas_with_pos = (form, pos) ->
  lems = []

  is_lemma_empty = -> lems.length is 0
  double_consonant = (suffix) ->
    len = form.length - suffix.length
    (is_vowel form[len-3]) and (not is_vowel form[len-2]) and (form[len-2] is form[len-1])

  irregular_bases = (pos) ->
    if exceptions[pos][form] and exceptions[pos][form] isnt form
      lems.push [exceptions[pos][form], pos]

  regular_bases = (pos) ->
    bases = switch pos
      when 'verb' then possible_verb_bases()
      when 'noun' then possible_noun_bases()
      when 'adj'  then possible_adj_adv_bases 'adj'
      when 'adv'  then possible_adj_adv_bases 'adv'
      else null
    if bases
      check_lemmas bases

  base_forms = (pos) ->
    irregular_bases pos
    regular_bases pos

  check_lemmas = (bases) ->
    lemmas = bases[0]
    pos = bases[1]
    lemmas.forEach (lemma) ->
      if wordlists[pos][lemma] is lemma
        lems.push [lemma, pos]

  possible_verb_bases = ->
    f = form
    lemmas = []
    switch
      when ends_with_es f # goes -> go
        verb_base = f.slice 0, -2
        lemmas.push verb_base
        if not wordlists['verb'][verb_base]? or wordlists['verb'][verb_base] isnt verb_base
          lemmas.push f.slice 0, -1 # opposes -> oppose

      when ends_with_verb_vowel_ys f
        lemmas.push f.slice 0, -1 # annoys -> annoy

      when (f.ends_with 'ed') and (not f.ends_with 'ied') and (not f.ends_with 'cked')
        post_base = f.slice 0, -1 # saved -> save
        lemmas.push post_base
        if (not wordlists['verb'][post_base]) or (wordlists['verb'][post_base] isnt post_base)
          lemmas.push f.slice 0, -2 # talked -> talk

      when (f.ends_with 'ed') and (double_consonant 'ed')
        lemmas.push f.slice 0, -4 # dragged -> drag
        lemmas.push f.slice 0, -3 # adding -> add
        lemmas.push (f.slice 0, -3) + 'e' # pirouetted -> pirouette

      when (f.ends_with 'ing') and (double_consonant 'ing')
        lemmas.push f.slice 0, -4 # dragging -> drag
        lemmas.push f.slice 0, -3 # adding -> add
        lemmas.push (f.slice 0, -3) + 'e' # pirouetting -> pirouette

      when (f.ends_with 'ing') and (not exceptions['verb'][f]?)
        ing_base = (f.slice 0, -3) + 'e'
        lemmas.push ing_base # coding -> code
        if (not wordlists['verb'][ing_base]) or (wordlists['verb'][ing_base] isnt ing_base)
          lemmas.push f.slice 0, -3 # talking -> talk

      when (f.ends_with 'able') and (double_consonant 'able')
        lemmas.push f.slice 0, -5

      when (f.ends_with 'ability') and (double_consonant 'ability')
        lemmas.push f.slice 0, -8
      when f.ends_with 's'
        lemmas.push f.slice 0, -1

    morphological_substitutions['verb'].forEach (entry) ->
      morpho = entry[0]
      origin = entry[1]
      if f.ends_with morpho
        lemmas.push (f.slice 0, -morpho.length) + origin

    lemmas.push f
    return [lemmas, 'verb']

  possible_noun_bases = ->
    f = form
    lemmas = []
    if ends_with_es f
      noun_base = f.slice 0, -2 # watches -> watch
      lemmas.push noun_base
      if (not wordlists['noun'][noun_base]?) or (wordlists['noun'][noun_base] isnt noun_base)
        lemmas.push f.slice 0, -1 # horses -> horse
    else if f.ends_with 's'
      lemmas.push f.slice 0, -1

    morphological_substitutions['noun'].forEach (entry) ->
      morpho = entry[0]
      origin = entry[1]
      if f.ends_with morpho
        lemmas.push (f.slice 0, -morpho.length) + origin

    lemmas.push f
    return [lemmas, 'noun']

  possible_adj_adv_bases = (pos) ->
    f = form
    lemmas = []
    if (f.ends_with 'est') and (double_consonant 'est')
      lemmas.push f.slice 0, -4 # biggest -> big
    else if (f.ends_with 'er') and (double_consonant 'er')
      lemmas.push f.slice 0, -3 # bigger -> big

    morphological_substitutions[pos].forEach (entry) ->
      morpho = entry[0]
      origin = entry[1]
      if f.ends_with morpho
        lemmas.push (f.slice 0, -morpho.length) + origin

    lemmas.push f
    return [lemmas, pos]

  parts = ['verb', 'noun', 'adj', 'adv']
  if pos and (not _.include parts, pos)
    console.warn "warning: pos must be 'verb' or 'noun' or 'adj' or 'adv'."
    return

  if not pos
    parts.forEach (pos) ->
      base_forms pos
      # irregular_bases pos
      # regular_bases pos
      
    # when lemma not found and the form is included in wordlists.
    if is_lemma_empty()
      parts.filter (pos) -> wordlists[pos][form]
        .forEach (pos) -> lems.push [form, pos]

    if is_lemma_empty()
      lems.push [form, '']

  else
    base_forms pos
    if is_lemma_empty()
      lems.push [form, pos]

  # sort to verb -> noun -> adv -> adj
  uniq_lemmas(lems).sort (a, b) ->
    if a[1] isnt b[1] then (a[1] < b[1]) else (a[0] > b[0])

# return only uniq lemmas without pos like [ 'high' ] or [ 'leave', 'leaf' ]
lemmas = (form, pos) ->
  result = lemmas_with_pos form, pos
    .map (val) -> val[0]
  _.nub result

module.exports =
  lemmas: lemmas
  lemmas_with_pos: lemmas_with_pos
