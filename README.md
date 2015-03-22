JavaScript Lemmatizer
====

 forked from [takafumir/javascript-lemmatizer](https://github.com/takafumir/javascript-lemmatizer)

 As npm module in CoffeeScript

```coffee
{lemmas, lemmas_with_pos} = require './'

# lemmatize
lemmas('dying')                 # [ 'die', 'dying' ]
lemmas_with_pos('plays')        # [ ['play', 'verb'], ['play', 'noun'] ]

# lemmatize with pos hint
lemmas('larger', 'adj')         # [ 'large', 'larger' ]
lemmas_with_pos('huger', 'adj') # [ ['huge', 'adj'] ]
```

