---
description: Run unit tests for the SpanishSyllabifier
---
Create and run comprehensive unit tests for SpanishSyllabifier.syllabify():

Test cases must include:
- Single syllable words: "sol", "pan", "mar"
- CV pattern: "casa" → ["ca","sa"]
- CVC pattern: "mar" → ["mar"]
- VC-CV: "cantar" → ["can","tar"]
- Inseparable clusters: "libro" → ["li","bro"], "clase" → ["cla","se"]
- Diphthongs: "aire" → ["ai","re"], "tiene" → ["tie","ne"]
- Hiatus (two strong vowels): "poeta" → ["po","e","ta"]
- Accented weak vowel (hiatus): "país" → ["pa","ís"]
- Three-consonant clusters: "instante" → ["ins","tan","te"]
- Long words: "extraordinario" → ["ex","tra","or","di","na","rio"]
- Words with ñ: "mañana" → ["ma","ña","na"]
- Words with ll: "llave" → ["lla","ve"]

Run tests with XcodeBuildMCP. Fix any failures.
