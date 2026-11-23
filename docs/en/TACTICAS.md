# Team comparison and match tactics

[Español](../TACTICAS.md) · [English](TACTICAS.md) · [Français](../fr/TACTICAS.md) · [Index](README.md)

The preview compares all 17 attributes of the chosen XV, with separate forwards (8) and backs (7) views. It displays crests, averages, energy and morale. Values are arithmetic means for the starting players in each group, without replacements or internal rounding; the interface displays integers. Opening the preview does not start the match.

Opponents compare units to choose ball-in-hand, balanced or kicking play. They assess passing, handling, attack, speed, agility, tackling, defensive reading, set pieces and the best kicker. Effective values include energy, morale and form; exclusions weaken the unit. Advantages are proportional, including specialist receivers against the kicker, so different attribute scales remain meaningful. Fatigue, stamina, discipline and relative advantages determine tempo, pressure and penalty priority. Low pressure reduces fatigue and defensive effectiveness; high pressure increases both. At normal tempo, low pressure uses roughly 18% less energy than normal pressure. It changes neither stored attributes nor the user's decisions.

AI teams review tactics at kickoff and at stoppages, normally every five minutes. Score changes, exclusions or fatigue thresholds can bring a review forward after a one-minute cooldown; half-time and substitutions allow earlier reassessment. Each side keeps its own assessment. Live changes use the normal command queue and commentary, without changing user decisions or consuming random draws.

In the last twenty minutes, a leading team slows down and seeks territorial control. A team trailing by three points or fewer favours posts; a larger deficit calls for tries through touch or quick play, according to its strengths. Sufficient energy allows faster tempo and higher pressure; energy below 50 forces a slower tempo, and below 45 also lowers pressure, even when trailing.

Matches between AI clubs retain their abbreviated simulation: reviews are limited to a few scoring windows and the start of each half. They reuse the pre-match comparison and adjust tempo, pressure and priority using the running score and current players’ energy, without recalculating all 17 attributes. They neither run the visual engine nor store a review history: only each side’s latest assessment is retained.

Choose **penalty priority** in the line-up, staff report or match instructions:

- **According to context:** evaluates score, time, kicker range and both teams' strengths.
- **Take the points:** favours kickable penalties; outside range, kicks to touch.
- **Go for a try:** gains territory with a touch kick and retains the throw-in.
- **Tap and go:** uses an available carrier for continuity. Attributes, energy and participating defenders affect the outcome: metres, a try or lost possession.

Kick success considers distance, angle and effective kicking ability. Decisions appear in commentary and match audit. A missed goal that goes dead through in-goal gives a 22-metre drop-out. Older tactics without an explicit priority use the contextual option. Automatic matches weight try chances and goal attempts according to the opponent's priority.

References: [World Rugby penalties](https://passport.world.rugby/laws-of-the-game/laws-by-number/20-penalty-and-free-kick/) and [restarts](https://passport.world.rugby/laws-of-the-game/laws-by-number/12-kick-off-and-restart-kicks/).

Each half continues after time expires until the ball becomes dead, with outstanding conversions and penalties respected. In open play, the leading side seeks touch to end the half; the trailing side avoids clearing kicks that surrender possession. Added time is red. Sin-bin time, fatigue and playing minutes continue to accumulate. The second-half display starts at minute 40. [World Rugby Law 5](https://passport.world.rugby/laws-of-the-game/laws-by-number/5-time/).
