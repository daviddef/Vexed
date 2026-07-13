# VEXED! Roadmap

Last updated: 2026-07-09

## Shipped

Grouped thematically (see `git log` for full chronological detail).

**Core loop & scoring**
- Locked tiles: a rare (~12% of forged tiles, mutually exclusive with multiplier tiles) tile that can't join a scored word until it's been slid adjacent to twice — shown dimmed with a lock badge counting down. Adds a spatial-planning constraint without touching the core slide mechanic.
- Multiplier tiles: a rare (~12% of forged tiles) bonus tile that doubles the score of any word collected through it — visually marked with a small gold star badge. Native to the Tile Forge spawn system, so no new interaction model was needed; rewards routing words through specific board positions.
- No-Repeat Mode (opt-in Settings toggle, off by default): once a word is scored (manually or via auto-score-on-slide), it can't be scored again for the rest of that game/puzzle. Enforced through a single `isScoreable(_:)` gate in `GameEngine` that every word-recognition path (scoring, the tappable word list, hints, potential-score calc) shares, so all of them agree on what still counts as a word — board-generation validity is deliberately exempt since regenerating a board should ignore player history.
- Ghost Preview (opt-in Settings toggle, off by default): sparkle icons on destination cells where sliding the selected tile would immediately score — surfaces the engine's own lookahead as a player-facing skill aid
- Double Play bonus: one slide completing 2+ words at once earns a 1.25x/1.5x multiplier and a distinct banner/haptic
- Word validation with reverse-direction reading (a word can be spelled either direction along its row/column)
- Combo multiplier (×1.5 / ×2 / ×3) for consecutive scoring moves, with escalating haptics/particle-burst intensity and a "hitstop" freeze on impact for a punchier feel
- Tile Forge bonus-tile system, with cascading (staggered) tile reveal
- Two-step word collection: tap a word to preview (bright yellow highlight + a discreet points/definition overlay), tap again to collect, or tap elsewhere to deselect
- Points badge on the first tile of every available word
- Fixed a false "no moves left" bug: the engine now searches 3 slides ahead (budget-capped) before declaring the board dead, not just 1–2

**Modes**
- Kid Mode: age tiers (Little/Explorer/Challenger), auto-hints with a two-phase glow+beacon system, mascot word-reading via text-to-speech, collectible word stickers (deterministic emoji per word, persisted across sessions)
- Adult Mode: on-demand hint button (30s cooldown) using the same hint system Kid Mode gets automatically
- Daily Puzzle: seeded (SplitMix64 + FNV-1a date hash — deterministic across devices/relaunches, unlike Swift's salted `Hasher`) so every player gets an identical board; streak tracking; 3+ day streaks bank a pre-placed Tile Forge bonus on the next puzzle; shareable result card rendered via `ImageRenderer`
- Puzzle Mode: solve a board within a capped number of slides (Quick/Standard/Long presets), with a per-preset best score

**Visual themes**
- Four themes, decoupled from game mode (Kid/Adult): Regular, Fun (bright sky-blue/rainbow), Arcade (neon/CRT-scanline), Light (genuine white board, saturated candy-block tiles)
- Kid Mode defaults to Fun, Adult defaults to Regular, but an explicit theme pick sticks regardless of mode afterward

**Fixes worth remembering**
- `Info.plist` had hardcoded `"1.0"`/`"1"` instead of referencing `$(MARKETING_VERSION)`/`$(CURRENT_PROJECT_VERSION)` — every archive before this shipped as build "1" regardless of the project's build number. Fixed.
- Easy/Kid word lists were missing common words (MEW, PEED, etc.) because the original curation used an overly strict "must be in macOS's top-8 autocomplete" filter. Backfilled ~1,400–1,500 words per list using frequency data, filtered through a proper-noun list and a profanity blocklist. Also found and removed pre-existing mature words (MURDER, SUICIDE, WEAPON, etc.) from the Kid list that predated this session.
- TestFlight publishing: Vexed's Xcode project is signed under a team Xcode's local account cache doesn't recognize, causing `-exportArchive` to fail with "No Account for Team." Fixed by passing the App Store Connect API key directly to `xcodebuild` (`-authenticationKeyPath`/`-authenticationKeyID`/`-authenticationKeyIssuerID`), which handles signing without needing an Xcode-signed-in session.

## Deferred (scoped out, not forgotten)

- **Monetization** — cosmetic theme-pack IAP (four themes now exist as a natural paywall surface) and Kid-Mode-ad-free gating. Explicitly not picked when the engagement-research round's priorities were chosen. See "Next: Monetization" below for a dedicated research pass.
- **Multiplayer / social / leaderboards** — research flagged this as the weakest fit for a solo word game (disproportionate live-service infrastructure for the payoff). A *lightweight* async leaderboard for the Daily Puzzle (compare streak/score, no live infra) was raised as a smaller possibility but never scoped.
- **Light theme design polish** — the theme shipped from first-principles reasoning + a reference screenshot; the original research pass on light-theme palette/shadow technique came back thin (no strong sourcing found). Worth a dedicated look if it needs another pass.
- **Puzzle Mode content** — currently reuses the same random board generator with a move cap, not hand-curated, guaranteed-solvable levels. If the mode gets traction, real level design is the next step up.

## Next: Gameplay Depth

Researched 2026-07-08, specifically scoped to *mastery depth* (what makes a puzzle game rewarding over hundreds of hours), separate from the earlier engagement/retention research. Full findings: 105 agents, 22 sources, 16 confirmed / 9 refuted claims.

**Headline finding:** no commercial or indie precedent was found combining slide-until-blocked tile movement with word formation. VEXED!'s core hybrid is open design space — the ideas below are original synthesis grounded in cited principles from analogous games (2048, Threes, Tetris), not directly-cited prior art. Flagged accordingly; all need playtesting before committing to any of them.

### A. Make the engine's own lookahead into a player-facing skill

The game already computes 2–3 move lookahead internally (`anySlideCanScoreWord`, `findHintMoves`) — it's just hidden behind the hint button. Research on 2048/Threes shows the entire skill ceiling in slide-based games *is* positional planning: 2048's "corner method" (anchor + monotonic gradient) and Threes' "keep tiles against a wall, avoid staggering" are both about reading the board several moves ahead, not reacting to what's in front of you right now (sources: the2048league.com, trysolitaire.com, nbickford.wordpress.com — high confidence, corroborated 3+ ways).

- *Grounded in:* the above. VEXED's failure mode is closer to Threes than 2048 (tiles glide to a stop rather than freely place), so the design lesson is "avoid stranding a needed letter where it can't reach a forming word," not "anchor a max-value tile in a corner."
- **Shipped 2026-07-09 — Ghost Preview toggle**: opt-in, off by default (Settings). When a tile is selected, a sparkle badge appears on any destination cell where that slide would immediately complete a word — `GameEngine.slideWouldScore`, computed in `updateSlidePaths()` by reusing the same `applying`/`gridHasWordAt` helpers the hint system already relies on. Turns the previously-hidden lookahead into a discoverable technique instead of something only reachable via the hint button. Un-tuned; whether the 4-directions-at-once reveal is too generous (removes too much of the "read the board" skill) versus just right needs actual playtesting.

### B. Reward setups, not just reactions — a real combo/chain layer

Tetris' combo system rewards *consecutive* clears (counter resets to −1 on any non-clearing placement, score scales as `base × combo × level`), and its most famous advanced technique — the "4-wide well" — is literally about **deliberately not scoring now** to set up a bigger payoff later (source: tetris.wiki/Combo, gamedeveloper.com — high confidence, stable community knowledge since ~2014).

- *Grounded in:* the above.
- **Shipped 2026-07-08 — Double Play bonus**: the narrowest, lowest-risk slice of this idea. When one slide completes 2+ words simultaneously (a row word and a column word sharing the moved tile), award a 1.25x bonus (1.5x for 3+) plus a distinct banner/haptic. Purely additive, no new interaction model, so it didn't need playtesting/steering to build.
- **Shipped 2026-07-09 — Chain Bonus, resolved in spirit**: the "bigger, riskier version" flagged below got built via a different, lower-risk path than originally proposed. Rather than letting arbitrarily many previewed words stack, tapping a tile that belongs to 2+ available words (row + column sharing that tile) now previews and highlights all of them together, and a second tap collects them all at once via `GameEngine.collectWords(_:)`, reusing the same Double Play multiplier/banner/haptic. Narrower than "any 2+ previewed words in a time window," but delivers the core reward (collecting intersecting words together pays more) without changing the one-word-at-a-time preview model for the common case.

### C. Procedural difficulty via constraint density, not just bigger numbers

The confirmed design principle (gamedeveloper.com, gamedesignskills.com — medium confidence, opinion/design-blog sourced but convergent across 3 sources) is that puzzle-game depth comes from layering new *constraints* onto one simple core mechanic, and having later puzzles require *recombining* previously-learned techniques (Baba Is You is the canonical example) — not from bolting on unrelated new mechanics.

- *Grounded in:* the above (heuristic-level confidence, not proven).
- *Speculative extension for Puzzle Mode specifically:* scale board *density* (lower empty-cell percentage → harder maneuvering) and *letter awkwardness* (bias toward Q/X/Z/J as the player's rolling performance improves) rather than just changing move-limit presets. This keeps the mechanic identical while the "puzzle-ness" of the constraint escalates — the toolbelt-recombination principle, not new UI.

### D. Novel mechanic layers — clearly speculative, no cited precedent

These are original ideas inspired by the research but not found in any cited source, since nothing combines this genre pairing. Listed roughly by implementation cost:

- **Shipped 2026-07-08 — No-Repeat Mode**: a session-scoped constraint — can't score the same word twice (tracked via a `Set<String>` of used words this session; repeats are simply no longer recognized as valid). Cheap to build, forces vocabulary breadth, is a genuine constraint-based mode rather than a reskinned booster.
- **Double Play bonus**: when a single slide completes 2+ words simultaneously (a row word and a column word sharing the moved tile — already mechanically possible today, just not specially rewarded), grant an explicit multiplier and a distinct celebration. Rewards players who engineer intersections rather than treating it as incidental.
- **Shipped 2026-07-08 — Locked tiles**: a tile that can't be collected as part of a word until it's been slid past/adjacent to N times — adds a spatial-planning constraint layer without touching the core slide mechanic.
- **Shipped 2026-07-08 — Multiplier tiles**: a rare tile type that multiplies the score of any word passing through it — native to the slide mechanic (unlike a purchased booster), rewards routing words *through* specific board positions.

### Open questions from the research (unresolved, worth answering before building B–D)

- Would a Tetris-style "combo resets on any non-scoring move" feel punishing in a word game, where "no valid word this move" is common even for skilled players? Needs playtesting — word formation doesn't have Tetris' guaranteed-eventual-clear property.
- Does anchoring a high-value letter (the closest VEXED analog to 2048's corner tile) conflict with the existing vowel-vanish tension mechanic (3+ same vowels touching autoscore-vanishes)? These two systems might fight each other spatially.
- Is there a word-puzzle precedent in a regional market (Japanese/Korean mobile) this research pass didn't surface? Worth a follow-up search if pursuing this direction seriously.

## Next: Monetization

Researched 2026-07-08, scoped to VEXED! specifically: solo-dev, zero monetization today, Kid Mode + Adult Mode, Daily Puzzle with streaks, four cosmetic themes. 107 agents, 24 sources, 16 confirmed / 9 refuted claims (several candidate stats on cosmetic conversion rates and ads/IAP revenue splits were explicitly refuted on adversarial re-verification and excluded — this area has thinner hard data than the gameplay-depth research did).

**Headline finding:** the evidence points away from ads entirely and toward a lightweight, calm-friendly stack: cosmetic theme IAP first, compliance work second, an optional low-priced subscription later only once there's a recurring content reason to justify it. The closest real comparable — NYT Games (Wordle free as a funnel, $5–10/mo subscription for deeper content, puzzle *creation* paywalled but *solving* free) — is a much bigger publisher with a multi-game content pipeline, so its price points are directional, not a template to copy verbatim.

**Recommended build order:**
1. **Cosmetic theme IAP** (the four existing themes: Regular/Fun/Arcade/Light) — individual + bundle pricing, sold only in Adult Mode context. Lowest-risk first revenue surface; no new interaction model, no pay-to-win concerns since themes are purely aesthetic.
2. **Compliance pass before any purchase surface ships** — Kid Mode must carry no third-party ad or behavioral-analytics SDKs (Apple Kids Category guideline 1.3, confirmed high-confidence), and any purchase flow reachable from Kid Mode needs a parental gate (Apple requirement; Texas SB 2420, effective 2026-01-01, additionally requires per-transaction parental consent for IAP in some jurisdictions). Simplest compliant shape: keep Kid Mode monetization-free entirely rather than building a parental-gate flow.
3. **Optional low-priced subscription** (~$3–5/mo or ~$20–40/yr, going by the NYT price ladder) — only once there's a recurring content reason (extra Daily Puzzle packs, extra modes) to justify a recurring charge. Not a launch priority.
4. **Ads: not recommended.** No reliable data was found supporting an ads+IAP blend for this genre (the "puzzle games split ~50/50 ads/IAP" claim was refuted 0-3 on verification), and ads conflict with both the calm-daily-puzzle positioning and the Kids Category compliance burden. If revisited, confine to Adult Mode only, non-behavioral/contextual only.
5. **Streak-protection or streak-badge purchases: hold as a later experiment.** Streaks are validated as a retention/FOMO mechanic (medium confidence — single-source), not a proven direct monetization lever; no data was found on streak-purchase conversion specifically.

**Open questions the research didn't resolve** (worth answering before committing further):
- No verified data exists on cosmetic-only IAP conversion rates in a non-competitive single-player game — the two candidate stats found were both refuted on adversarial re-verification.
- Whether VEXED!'s current paid/premium app pricing (no IAP at all) is itself a viable end-state monetization strategy wasn't addressed — this research focused on freemium comparables (NYT, Wordle) and didn't compare against premium-priced indie puzzle apps.
- Apple's Kids Category rules (guideline 1.3) technically govern apps *listed in* the Kids Category — since VEXED! has a Kid Mode but may not be listed there, it's unclear how much of guideline 1.3 applies versus the general "any app/section directed at kids" language. Worth a direct compliance check (or asking Apple) before shipping any Kid Mode purchase surface.

**Direction taken instead of the above (2026-07-08):** explicitly rejected subscriptions/paywalls — the game should stay free-to-play-feeling with no recurring charges. Chosen model: rewarded-video ads as the *sole* monetization lever, exchanged for gameplay power-ups rather than cosmetics or removing friction. This inverts the earlier "cosmetic IAP first" recommendation; superseded by the Power-ups section below.

- **Shipped 2026-07-08 — Power-ups (Bomb + Reveal)**: Adult Mode only power-up tray. **Bomb** (💣) consumes a charge to remove any one tile from the board on tap — useful for clearing a blocker with no valid word. **Reveal** (🔍) consumes a charge to trigger an immediate hint, bypassing the normal 30s cooldown. Charges are earned 3-at-a-time by watching a rewarded ad, persisted across games via `UserDefaults` (`GameEngine.bombCharges`/`revealCharges`). Kid Mode never shows the tray — no ads/purchase surface reaches Kid Mode, per Apple's Kids Category rules confirmed in the monetization research above.
  - **Not yet wired to a real ad network.** The reward flow is fully built and testable (`Vexed/Views/PowerUpTrayView.swift` shows a placeholder "watch to completion" countdown sheet), but it's backed by `MockAdRewardProvider` (`Vexed/Utilities/AdRewardProvider.swift`), which grants the reward immediately rather than showing a real ad. Swapping in Google Mobile Ads (or another network) means: (1) creating an AdMob account and ad unit IDs, (2) adding the Google Mobile Ads SDK via Swift Package Manager in Xcode (couldn't be done headlessly this session — needs the Xcode GUI or a manual `.pbxproj` package reference), (3) writing a `GADRewardedAd`-backed `AdRewardProvider` conformance and swapping it in at `PowerUpTrayView`'s `adProvider` default. Everything else (charges, UI, gameplay hooks) is already done and won't need to change.
  - **Not yet built:** more power-up types beyond Bomb/Reveal (e.g. Shuffle, Swap) — deferred until the two shipped ones prove out.

## Next: Onboarding & Discoverability

Researched 2026-07-09. Prompted by a simple observation: this sprint shipped seven new mechanics (Locked tiles, Multiplier tiles, Ghost Preview, No-Repeat Mode, Double Play/Chain Bonus, Bomb, Reveal) on top of an already-nontrivial base game (vowel-vanish, Tile Forge, combo multiplier, Kid/Adult modes), and **none of them have any in-game explanation** — new tile types silently appear with a small badge, and two mechanics (Ghost Preview, No-Repeat Mode) are opt-in toggles buried in Settings that a player has no reason to ever open. 104 agents, sources across game-design and UX literature.

**Headline finding:** progressive disclosure — teach one mechanic at a time, in-context, at the moment it becomes relevant, not up front — is the well-corroborated consensus approach (Hyper Light Drifter's one-mechanic-per-unlock, Super Mario 3D Land's introduce→practice→twist→mastery loop). The specific numeric claims worth being skeptical of (hard "3 items" cognitive-load caps, quantified completion-rate deltas, level-gating as a proven pattern) did **not** survive adversarial verification — treat those as folklore. Critically, the two questions most specific to VEXED — does silent/discoverable design work as well as tooltips for opt-in systems, and does burying a feature in Settings suppress adoption versus a discovery prompt — have **no direct evidence either way** in this research; recommendations there are reasoned extrapolation, flagged accordingly.

**Prioritized recommendations:**
1. **Shipped 2026-07-09 — First-encounter contextual micro-tooltips.** `MechanicTip.swift` + `GameEngine.offerTip`. The first time a Locked tile, Multiplier tile, Tile Forge spawn, combo (×2+), or Double Play occurs in live play, a dismissible green-accented card explains it — once per install, one at a time (later ones fire on a subsequent appearance so tips never stack). Tile contents in `spawnForgeTiles` are now decided up front so the right tip fires. Tap the card or wait to dismiss.
2. **(High, well-supported) Don't expand "How to Play" to cover everything.** Keep that screen scoped to the core loop only (slide, form words, vowel-vanish). Let every mechanic added this sprint be taught contextually at first appearance instead — dumping full instructions up front is specifically called out as producing boring, unengaged early sessions. *(Followed by omission — the tips above cover the new mechanics; "How to Play" was left as-is on the core loop.)*
3. **(Medium, reasoned extrapolation) One-time prompt when a power-up is first earned.** When Bomb or Reveal charges are earned for the first time (not just visible as a tray icon), show a one-time contextual prompt at that moment — the point where the player can actually act on it. *Deferred: bundle with real AdMob integration, since the earn moment only becomes real once a live ad grants the charge.*
4. **Shipped 2026-07-09 — Ghost Preview discovery nudge.** `GameEngine.slidesSinceLastScore` + a one-time banner in `GameView`. After 6 scoreless slides in Adult Mode (only when Ghost Preview is off, suppressed while a tip is showing), a dismissible banner offers to turn Ghost Preview on directly — tapping it flips the toggle and confirms with a toast, rather than sending the player to dig through Settings. Once per install. *No-Repeat Mode intentionally left out of this nudge — it's a difficulty-increasing challenge, not a struggling-player aid, so nudging toward it when someone's stuck would be backwards.* Still the weakest-evidenced item (no source measured buried-vs-prompted adoption); worth watching whether it actually lifts adoption.
5. **Shipped 2026-07-09 — "What's New" recap screen.** `WhatsNewView.swift` + `WhatsNew.shouldPresent()`. A one-time post-splash full-screen recap of the sprint's mechanics, keyed on build number. Existing installs (launched before this tracking) see it once; genuinely fresh installs skip it in favor of the first-encounter tips.

**Explicitly not recommended:** a full replayable multi-mechanic tutorial wizard, a hard-capped "N mechanics per session" gating system, or mandatory isolated practice levels per mechanic — none had surviving evidentiary support, and the closest related claims were refuted on verification.

## What's next — synthesized priority order

Pulling together everything above into one list, ranked by (impact × how well-specified/low-risk the build is).

**Shipped 2026-07-09 — the three cheap onboarding items:**
- ✅ First-encounter tooltips for Locked/Multiplier tiles, Tile Forge, combo, Double Play
- ✅ Ghost Preview discovery nudge
- ✅ "What's New" recap for returning players

**Still open, current priority order:**

1. **Shipped 2026-07-14 — Real AdMob integration (test ads).** Google Mobile Ads SDK v13.6.0 added via SPM (bundles the UMP consent SDK). `GoogleAdRewardProvider` (real `RewardedAd`, preloads + reloads, only rewards on genuine watch-to-completion) replaces the mock as the tray's default. SDK starts at launch (`AdsBootstrap.startSDK`); EEA/UK consent gathered via UMP **Adult Mode only** (`AdsBootstrap.gatherConsentIfNeeded`, called from `GameView.onAppear` guarded on `!kidMode`). `Info.plist` has `GADApplicationIdentifier` (`…~1849747214`), a full `SKAdNetworkItems` list, and `NSUserTrackingUsageDescription`. Verified: builds against v13 API, launches without the SDK-init crash a bad App ID would cause.
   - **Still using Google's TEST rewarded ad unit** (`AdConfig.rewardedAdUnitID`) — correct/policy-safe for TestFlight (live units in beta = invalid traffic = account-strike risk). **One-line swap to the real unit ID before the public App Store release.**
   - **Blocked on (for real revenue):** AdMob's 2–3 day app review to finish, then swapping in the production rewarded ad unit ID.
2. **Power-up first-earn prompt** (Onboarding #3) — a one-time tip the first time a Bomb/Reveal charge is earned. Deliberately deferred until AdMob is live, since the earn moment only becomes real once a live ad grants the charge. Small addition; bundle with item 1. *The `MechanicTip` infrastructure from this pass can be reused directly — just add `.bomb`/`.reveal` cases and call `offerTip` at the grant site.*
3. **Playtest tuning pass on this sprint's mechanics** — several shipped features are explicitly un-tuned and flagged for playtesting: Ghost Preview's 4-direction reveal (too generous?), Locked-tile unlock count (2 slides — right?), Multiplier/Locked spawn rates (~12% each), the combo-reset feel. None of these need new code, just numbers + judgment from real play. Cheap, high-leverage, and the honest next step before adding *more* mechanics.
4. **Puzzle Mode difficulty scaling** (density + letter-awkwardness) — still speculative/unproven principle, larger build, lower confidence than the above.
5. **Lightweight Daily Puzzle leaderboard** — smaller-scoped version of the multiplayer idea that was otherwise deferred; still unscoped.

**Shipped 2026-07-09 — "Tiles & Bonuses" reference (surfaced while building the onboarding pass):**
The first-encounter tips fire once per install and are then gone forever, leaving no way to re-read what a Locked or Multiplier tile does. `MechanicsReferenceView` (in `WhatsNewView.swift`) adds a permanent list in the burger menu's Help section, built directly from `MechanicTip`'s content (via a reference-phrased `referenceBody`) so it stays in sync automatically — a lasting home for the info without re-cluttering the core "How to Play" screen.

Explicitly deprioritized: cosmetic theme IAP (superseded by the ads-for-power-ups pivot), Light theme polish pass, real Puzzle Mode level design — none blocked on anything, just lower leverage than the above right now.
