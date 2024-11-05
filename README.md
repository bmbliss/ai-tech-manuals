# AI Tech Manuals

harness the power of AI to create technical documentation

## Setup

```
bundle install
```

run the app

```
bin/dev
```

uses openai 

## TODO
- [ ] sync changes across manuals (basically on edit or create, pull in the manuals using vector search and give recommendations somehow)

## Notes

The issue is with the interpretation of the neighbor_distance. In vector similarity search:
Cosine Distance (what neighbor uses):
Range: 0 to 2
0 = identical vectors (perfect match)
2 = completely opposite vectors
Lower is better
MongoDB's Vector Search Score:
Range: 0 to 1
1 = perfect match
0 = no similarity
Higher is better
