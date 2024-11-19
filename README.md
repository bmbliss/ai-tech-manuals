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
- [ ] display the diff HTML rather than the raw html tags...
- [ ] close comments after approval/rejection
- [ ] add a "revert to revision" button
- [ ] test that multiple edits can be made out of order and resolved correctly...
- [ ] fix the table of contents sidebar
- [ ] import pdf and convert to HTML and sections 

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
