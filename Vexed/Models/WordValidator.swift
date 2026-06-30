import Foundation

// Trie node for O(n) word lookup
private class TrieNode {
    var children: [Character: TrieNode] = [:]
    var isWord = false
}

final class WordValidator {
    static let shared = WordValidator()

    private let root = TrieNode()
    private(set) var wordCount = 0

    private init() {
        loadBuiltIn()
    }

    private func loadBuiltIn() {
        // Core word list — extended at runtime from system dictionary
        let words = """
        CAT BAT HAT RAT MAT SAT FAT PAT NAT
        DOG LOG FOG HOG BOG COG JOG
        RUN SUN FUN GUN BUN NUN PUN
        BIT HIT SIT FIT PIT WIT KIT
        BED FED RED TED WED LED
        TOP HOP MOP POP COP BOP
        CAVE GAVE HAVE RAVE SAVE WAVE PAVE
        BALE GALE MALE PALE SALE TALE VALE DALE
        CORE BORE FORE GORE MORE PORE SORE TORE WORE
        LIME TIME DIME MIME RIME
        MUTE CUTE LUTE JUTE
        CAPE TAPE NAPE GAPE
        RIDE HIDE SIDE TIDE WIDE
        ROBE LOBE
        TUBE CUBE LUBE
        GAME FAME DAME LAME NAME SAME TAME
        VOTE NOTE DOTE MOTE TOTE
        BONE CONE DONE GONE HONE LONE NONE TONE ZONE
        BANE CANE LANE MANE PANE SANE VANE WANE
        BITE CITE KITE LITE MITE SITE
        BEST REST TEST VEST WEST ZEST NEST PEST
        BOLT COLT JOLT MOLT VOLT
        BELT FELT MELT WELT
        GILT HILT JILT KILT LILT TILT WILT
        WORM DORM FORM
        CORN BORN HORN TORN WORN
        FARM HARM WARM
        DARK LARK MARK PARK BARK HARK
        CARD HARD LARD YARD
        RACE FACE LACE MACE PACE
        ICE ACE ORE ATE EAR OAK AIM OWL APE
        HORN HIRE FIRE WIRE TIRE DIRE SIRE
        WORD WARD BIRD HERD NERD
        CLAM CLAN CLAP CLAW CLAY
        PLAN PLAY PLOD PLOP PLOT PLOW PLOY PLUG PLUM
        BRED BREW BRIM BROW
        CROW CROP CRAM CRIB CREW CREST
        DROP DRAG DRAW DRIP DRUM DRUG DRUB
        FLAG FLAK FLAP FLAT FLAW FLAY FLEA FLEW FLIP FLIT FLOG FLOP FLOW FLUX
        GLAD GLEE GLEN GLOB GLOP GLOW GLUE
        GRIP GRIN GRIM GREW GRAY GRAM GRAB
        PREP PREY PRIM PROP
        SCAN SCAR SCAM SCAT
        SKIP SKIT SKIN SKEW
        SLAM SLAP SLAT SLAW SLAY SLED SLIM SLIP SLIT SLOB SLOP SLOT SLOW SLUG SLUM SLUR
        SNAP SNAG SNOB SNUG
        SPAN SPAR SPIT SPIN SPOT SPEW SPEC SPED
        STEM STEP STEW STRAP STRUM STUB STUD STUN
        SWAP SWAM SWAN SWAT SWIM SWUM
        THAN THAT THEM THEN THIN THIS
        TRAP TRIM TRIO TRIP TROD TROT TROW TROY
        WHIM WHIP WHIT
        WRAP WREN WRIT
        ADORE ABOVE ABODE ABUSE ACUTE ADOBE AGILE ALONE AMAZE AMUSE AMPLE
        BLADE BLAME BLAZE BLEAK BLEED BLEND BLESS BLEW BLIGHT BLIND BLOCK BLOOD BLOOM BLOWN BLUNT
        BRAVE BREAK BREED BRIDE BRINE BRISK BROKE BROOK BROWN BRUNT BRUSH BRUTE
        CANOE CARVE CAUSE CEASE CHAFE CHASE CHEAP CHEAT CHECK CHEEK CHEER CHEST CHIDE CHIEF CHILD CHIME CHOSE CIVIC CIVIL CLAIM CLEAN CLEAR CLERK CLICK CLIFF CLIMB CLING CLOAK CLOCK CLONE CLOSE CLOUD CLOUT CLOWN COACH COAST COATING COMET COMIC CORAL CRANE CRAZE CRAZY CREEK CREEP CRIME CRISP CROSS CRUDE CRUEL CRUSH CRUST CRYPT
        DANCE DAUNT DEATH DECAY DECOY DEFER DELAY DELTA DENSE DEPOT DEPOT DEPOT DEPTH DERBY DEVIL DIVER DIZZY DODGE DOING DONOR DOUBT DOUGH DOUSE DRANK DRAPE DREAD DREAM DRESS DRIFT DRILL DRINK DRIVE DROVE DROWN DRUDGE DRUNK DRYER DUSKY DWARF DWELL
        EAGLE EARLY EARTH EIGHT ELDER ELECT ELITE EMAIL EMBER EMPOWER EMPTY ENACT ENDOW ENEMY ENJOY ENTER EVENT EVERY EVICT EXACT EXIST EXTRA
        """.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

        for word in words { insert(word) }

        // Load from system dictionary if available
        loadSystemDictionary()
    }

    private func loadSystemDictionary() {
        let path = "/usr/share/dict/words"
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let word = line.uppercased().trimmingCharacters(in: .whitespaces)
            // Only include simple alpha words 3-8 letters (keeps trie small)
            guard word.count >= 3, word.count <= 8,
                  word.allSatisfy({ $0.isLetter && $0.isASCII }) else { continue }
            insert(word)
        }
    }

    private func insert(_ word: String) {
        var node = root
        for ch in word {
            if node.children[ch] == nil { node.children[ch] = TrieNode() }
            node = node.children[ch]!
        }
        if !node.isWord { node.isWord = true; wordCount += 1 }
    }

    func isValid(_ word: String) -> Bool {
        guard !word.isEmpty else { return false }
        var node = root
        for ch in word.uppercased() {
            guard let next = node.children[ch] else { return false }
            node = next
        }
        return node.isWord
    }
}
