# FORM fallback exercise dataset

- Schema version: `1.0`
- Data version: `2026.10.25`
- Retrieved: `2026-10-25T12:08:28Z`
- Merged records: **1650**
- Records with paraphrased instructions: **1295**
- Merge groups: **1650** (35 contain more than one source)
- Conflicts recorded: **45**
- Share-alike affected records: **788**

## Files

| File | Bytes |
| --- | ---: |
| `taxonomy.json` | 3930 |
| `exercises.json` | 1009277 |
| `sources.json` | 1316 |
| `mapping.json` | 2545 |
| `validate.py` | 12827 |
| `report.md` | 65540 |

All files are UTF-8 with LF line endings and no trailing whitespace.

## Sources and licensing

| Source | Page opened | License as stated | License URL | Retrieved | Source records | Included | Excluded |
| --- | --- | --- | --- | --- | ---: | ---: | ---: |
| wger | https://wger.de/api/v2/exerciseinfo/ | Per-record: CC0 1.0, CC-BY-SA 3.0 or CC-BY-SA 4.0; see provenance for each exercise | https://wger.de/api/v2/license/ | 2026-10-25T12:08:28Z | 932 | 810 | 122 |
| free-exercise-db | https://github.com/yuhonas/free-exercise-db | The Unlicense (public domain) | http://unlicense.org/ | 2026-10-25T12:08:28Z | 876 | 876 | 0 |
| exercemus | https://github.com/exercemus/exercises | MIT License for repository code; exercises carry separate per-record licenses that are not present in `exercises.json` | https://github.com/exercemus/exercises/blob/main/LICENSE | 2026-10-25T12:08:28Z | 872 | 0 | 872 |

wger license full names present in the included data: "Creative Commons Public Domain 1.0" (CC0), "Creative Commons Attribution Share Alike 4" (CC-BY-SA 4) and "Creative Commons Attribution Share Alike 3" (CC-BY-SA 3). wger also lists CC-BY 4.0 and ODbL 1.0 at its license endpoint; no included record uses either.

free-exercise-db states its license as "The Unlicense" and describes the data as public domain. No attribution is required.

exercemus states that repository code is MIT, but that every exercise has its own license which the README says must be followed. The `exercises.json` records contain no license or license_author field, so those per-record terms are unreadable. The whole source is therefore excluded (see below).

## Excluded records

### wger: no readable attribution for a share-alike record

**122 records.** Each is licensed CC-BY-SA but has no `license_author`, so the attribution required by that license cannot be reproduced. They are excluded rather than guessed at.

| wger id | Name | Reason |
| ---: | --- | --- |
| 801 | Dumbbell Push-Up | CC-BY-SA record has no license_author (attribution unreadable) |
| 802 | Barbell Lunges Walking | CC-BY-SA record has no license_author (attribution unreadable) |
| 803 | One Arm Triceps Extensions on Cable | CC-BY-SA record has no license_author (attribution unreadable) |
| 927 | Suspended crossess | CC-BY-SA record has no license_author (attribution unreadable) |
| 974 | Curl with kettlebell two hands | CC-BY-SA record has no license_author (attribution unreadable) |
| 981 | Step-ups | CC-BY-SA record has no license_author (attribution unreadable) |
| 983 | High knees | CC-BY-SA record has no license_author (attribution unreadable) |
| 984 | Lunges | CC-BY-SA record has no license_author (attribution unreadable) |
| 985 | Push-up rotations | CC-BY-SA record has no license_author (attribution unreadable) |
| 986 | Side split squats left | CC-BY-SA record has no license_author (attribution unreadable) |
| 987 | Side split squats right | CC-BY-SA record has no license_author (attribution unreadable) |
| 988 | Bulgarian split squats left | CC-BY-SA record has no license_author (attribution unreadable) |
| 989 | Bulgarian split squats right | CC-BY-SA record has no license_author (attribution unreadable) |
| 990 | Kneeling kickbacks | CC-BY-SA record has no license_author (attribution unreadable) |
| 991 | Split squats left | CC-BY-SA record has no license_author (attribution unreadable) |
| 992 | Split squats right | CC-BY-SA record has no license_author (attribution unreadable) |
| 993 | Jump rope: basic jumps | CC-BY-SA record has no license_author (attribution unreadable) |
| 994 | Forward arm circles | CC-BY-SA record has no license_author (attribution unreadable) |
| 995 | Backward arm circles | CC-BY-SA record has no license_author (attribution unreadable) |
| 996 | Mountain climbers | CC-BY-SA record has no license_author (attribution unreadable) |
| 997 | 4-count burpees | CC-BY-SA record has no license_author (attribution unreadable) |
| 998 | No push-up burpees | CC-BY-SA record has no license_author (attribution unreadable) |
| 999 | Reverse lunges | CC-BY-SA record has no license_author (attribution unreadable) |
| 1000 | Floor dips | CC-BY-SA record has no license_author (attribution unreadable) |
| 1001 | High plank | CC-BY-SA record has no license_author (attribution unreadable) |
| 1002 | Child's pose | CC-BY-SA record has no license_author (attribution unreadable) |
| 1003 | Kettlebell deadlifts | CC-BY-SA record has no license_author (attribution unreadable) |
| 1004 | Forward shoulder rotation | CC-BY-SA record has no license_author (attribution unreadable) |
| 1005 | Backward shoulder rotation | CC-BY-SA record has no license_author (attribution unreadable) |
| 1006 | Chin tuck | CC-BY-SA record has no license_author (attribution unreadable) |
| 1007 | Head turns | CC-BY-SA record has no license_author (attribution unreadable) |
| 1008 | Left neck stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1009 | Right neck stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1010 | Back neck stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1011 | Front neck stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1012 | Alternating bicep curls | CC-BY-SA record has no license_author (attribution unreadable) |
| 1013 | Left levator scapulae stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1014 | Right levator scapulae stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1015 | Clockwise neck circles | CC-BY-SA record has no license_author (attribution unreadable) |
| 1016 | Counterclockwise neck circles | CC-BY-SA record has no license_author (attribution unreadable) |
| 1017 | Neck half circles | CC-BY-SA record has no license_author (attribution unreadable) |
| 1018 | Head tilts | CC-BY-SA record has no license_author (attribution unreadable) |
| 1019 | Side plank right | CC-BY-SA record has no license_author (attribution unreadable) |
| 1020 | Pistol squats right | CC-BY-SA record has no license_author (attribution unreadable) |
| 1021 | Calf raises, right leg | CC-BY-SA record has no license_author (attribution unreadable) |
| 1022 | Single Arm Plank to Row | CC-BY-SA record has no license_author (attribution unreadable) |
| 1104 | Walking | CC-BY-SA record has no license_author (attribution unreadable) |
| 1188 | Side bend | CC-BY-SA record has no license_author (attribution unreadable) |
| 1204 | Cycling cardio session | CC-BY-SA record has no license_author (attribution unreadable) |
| 1216 | Recruitment Pulls | CC-BY-SA record has no license_author (attribution unreadable) |
| 1217 | Finger Pushup | CC-BY-SA record has no license_author (attribution unreadable) |
| 1737 | Assisted chin-ups | CC-BY-SA record has no license_author (attribution unreadable) |
| 1752 | Side lateral raise - Front (Cable) | CC-BY-SA record has no license_author (attribution unreadable) |
| 1753 | Side lateral raise - Back (Cable) | CC-BY-SA record has no license_author (attribution unreadable) |
| 1754 | 45° lateral raises | CC-BY-SA record has no license_author (attribution unreadable) |
| 1755 | Shoulder Y-pull cable | CC-BY-SA record has no license_author (attribution unreadable) |
| 1766 | Plank Reach | CC-BY-SA record has no license_author (attribution unreadable) |
| 1773 | Legend Incline Bench Press | CC-BY-SA record has no license_author (attribution unreadable) |
| 1778 | Supino inclinado | CC-BY-SA record has no license_author (attribution unreadable) |
| 1795 | unilateral cross body cable pull down | CC-BY-SA record has no license_author (attribution unreadable) |
| 1830 | Barbell Step Back Lunge | CC-BY-SA record has no license_author (attribution unreadable) |
| 1831 | Hammerstrength Decline Chest Press | CC-BY-SA record has no license_author (attribution unreadable) |
| 1832 | Ring Support Hold | CC-BY-SA record has no license_author (attribution unreadable) |
| 1833 | Floor Glider Hamstring Curls | CC-BY-SA record has no license_author (attribution unreadable) |
| 1904 | Pec Deck | CC-BY-SA record has no license_author (attribution unreadable) |
| 1914 | Isometria alle parallele | CC-BY-SA record has no license_author (attribution unreadable) |
| 1918 | Legend Chest Press | CC-BY-SA record has no license_author (attribution unreadable) |
| 1919 | Extreme Pec Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1920 | Extreme Shoulder Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1921 | Extreme Lat Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1924 | 3008 Abdominal Crunch | CC-BY-SA record has no license_author (attribution unreadable) |
| 1925 | Barbell Silverback Shrug | CC-BY-SA record has no license_author (attribution unreadable) |
| 1935 | Belt Squat | CC-BY-SA record has no license_author (attribution unreadable) |
| 1938 | Cat-Cow | CC-BY-SA record has no license_author (attribution unreadable) |
| 1939 | Neck CARs | CC-BY-SA record has no license_author (attribution unreadable) |
| 1940 | Diaphragmatic Breathing | CC-BY-SA record has no license_author (attribution unreadable) |
| 2480 | Easy Continuous Swim (Freestyle) | CC-BY-SA record has no license_author (attribution unreadable) |
| 2481 | Kick with Board | CC-BY-SA record has no license_author (attribution unreadable) |
| 2482 | Bobbing Exhale Drill | CC-BY-SA record has no license_author (attribution unreadable) |
| 2483 | Wall-Hold Rotation | CC-BY-SA record has no license_author (attribution unreadable) |
| 2484 | Side-Kick Breathing (Kickboard) | CC-BY-SA record has no license_author (attribution unreadable) |
| 2485 | Stroke-and-Roll Drill | CC-BY-SA record has no license_author (attribution unreadable) |
| 2486 | Recovery Bobbing | CC-BY-SA record has no license_author (attribution unreadable) |
| 2487 | Cool-Down Swim | CC-BY-SA record has no license_author (attribution unreadable) |
| 2555 | Kegel Exercise | CC-BY-SA record has no license_author (attribution unreadable) |
| 2557 | Supported Split Squat | CC-BY-SA record has no license_author (attribution unreadable) |
| 2564 | 90/90 Breathing | CC-BY-SA record has no license_author (attribution unreadable) |
| 2613 | 90/90 Hip Switches | CC-BY-SA record has no license_author (attribution unreadable) |
| 2614 | Adductor Rock Backs | CC-BY-SA record has no license_author (attribution unreadable) |
| 2615 | Elevated Hamstring Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 2625 | Wall Baby Breathing | CC-BY-SA record has no license_author (attribution unreadable) |
| 2626 | Machine Seated Leg Curl | CC-BY-SA record has no license_author (attribution unreadable) |
| 2627 | Machine Chest Press | CC-BY-SA record has no license_author (attribution unreadable) |
| 2628 | Machine Seated Calf Raise | CC-BY-SA record has no license_author (attribution unreadable) |
| 2629 | Controlled Kegels | CC-BY-SA record has no license_author (attribution unreadable) |
| 2630 | Pelvic Endurance Hold | CC-BY-SA record has no license_author (attribution unreadable) |
| 2631 | Machine Lat Pulldown | CC-BY-SA record has no license_author (attribution unreadable) |
| 2632 | Machine Incline Chest Press | CC-BY-SA record has no license_author (attribution unreadable) |
| 2633 | Preacher Curl Machine | CC-BY-SA record has no license_author (attribution unreadable) |
| 2634 | Machine Dip or Triceps Extension | CC-BY-SA record has no license_author (attribution unreadable) |
| 2640 | Quick Kegels | CC-BY-SA record has no license_author (attribution unreadable) |
| 2641 | Pelvic Wave | CC-BY-SA record has no license_author (attribution unreadable) |
| 2642 | One-Arm Dumbbell Row | CC-BY-SA record has no license_author (attribution unreadable) |
| 2643 | Dumbbell Bent-Over Reverse Fly | CC-BY-SA record has no license_author (attribution unreadable) |
| 2644 | Dumbbell or Machine Calf Raise | CC-BY-SA record has no license_author (attribution unreadable) |
| 2645 | Squat -> Stand Coordination | CC-BY-SA record has no license_author (attribution unreadable) |
| 2646 | Supported Deep Squat Breathing | CC-BY-SA record has no license_author (attribution unreadable) |
| 2647 | Pelvic Tilts | CC-BY-SA record has no license_author (attribution unreadable) |
| 2648 | 90/90 Hamstring / Barre-Style Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 2649 | Glute Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 2650 | Soleus / Achilles Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 2651 | Wall Calf Stretch | CC-BY-SA record has no license_author (attribution unreadable) |
| 2652 | Extended Arm Child's Pose | CC-BY-SA record has no license_author (attribution unreadable) |
| 2653 | Gentle Thoracic Rotation | CC-BY-SA record has no license_author (attribution unreadable) |
| 2654 | Gentle Upward-Facing Dog / Cobra | CC-BY-SA record has no license_author (attribution unreadable) |
| 2655 | Gentle Reverse Kegels | CC-BY-SA record has no license_author (attribution unreadable) |
| 2656 | Happy Baby | CC-BY-SA record has no license_author (attribution unreadable) |
| 2657 | Relaxed Diaphragmatic Breathing | CC-BY-SA record has no license_author (attribution unreadable) |
| 2658 | Dumbbell Lateral Raise | CC-BY-SA record has no license_author (attribution unreadable) |
| 2659 | Alternating Dumbbell Curl | CC-BY-SA record has no license_author (attribution unreadable) |
| 2660 | Bent-Over Dumbbell Triceps Extension | CC-BY-SA record has no license_author (attribution unreadable) |
| 2661 | Dumbbell Calf Raise | CC-BY-SA record has no license_author (attribution unreadable) |

### exercemus: per-record licenses missing

**All 872 records excluded.** The repository README says each exercise has a license that must be followed, but the published records carry no license, author or license URL. First ten names, for identification:

`3/4 Sit-Up`, `90/90 Hamstring`, `Machine Crunch`, `Ab Roller`, `Adductor`, `Adductor/Groin`, `Advanced Kettlebell Windmill`, `Air Bike`, `All Fours Quad Stretch`, `Alternate Hammer Curl`.

No wger record was excluded for a missing license: all 932 had a readable license object. No free-exercise-db record was excluded: its license is source-wide and readable.

## Merge and conflict rules

- Deduplication key: normalised name (lowercase, punctuation removed, simple plural stripping) plus mapped equipment set.
- License clarity used for field-level tie-breaking: The Unlicense (public domain) > CC0 > MIT > CC-BY-SA. This is a preference for fewer conditions, not a legal conclusion.
- When the clearer-licensed source had no value for a field, the next source with a readable value was used. No value was averaged, inferred from a photo, or filled from memory.
- Instructions are paraphrases of supplied steps only. Steps were capped at six, source metadata and volume prescriptions were dropped, and no exercise received invented cues. Any step that remained a verbatim source substring after paraphrasing was dropped, so some records carry null rather than copied text. Where a source supplied only descriptive prose, instructions are null.
- `image` fields are not present in the record schema and no images were copied.

### Conflicts

45 field conflicts were found in 1650 merge groups. Chosen values follow the ranking above; the losing values are preserved here.

| Record | Field | Chosen | Other source value |
| --- | --- | --- | --- |
| `band-pull-apart` | primary | free-exercise-db#Band_Pull_Apart: shoulders | wger#1380: other |
| `barbell-ab-rollout` | movement | free-exercise-db#Barbell_Ab_Rollout: pull | wger#41: core |
| `barbell-full-squat` | primary | free-exercise-db#Barbell_Full_Squat: quads | wger#1801: glutes, hamstrings, quads |
| `barbell-full-squat` | secondary | free-exercise-db#Barbell_Full_Squat: back, calves, glutes, hamstrings | wger#1801: calves, core |
| `barbell-full-squat` | movement | free-exercise-db#Barbell_Full_Squat: push | wger#1801: legs |
| `barbell-hack-squat` | secondary | free-exercise-db#Barbell_Hack_Squat: calves, forearms, hamstrings | wger#43: glutes, hamstrings |
| `barbell-hack-squat` | movement | free-exercise-db#Barbell_Hack_Squat: push | wger#43: legs |
| `cable-rear-delt-fly` | primary | free-exercise-db#Cable_Rear_Delt_Fly: shoulders | wger#822: back, shoulders |
| `chin-up` | primary | free-exercise-db#Chin-Up: back | wger#152: back, biceps |
| `chin-up` | secondary | free-exercise-db#Chin-Up: back, biceps, forearms | wger#152: back, biceps |
| `clean` | primary | free-exercise-db#Clean: hamstrings | wger#1438: glutes, quads |
| `clean` | secondary | free-exercise-db#Clean: back, calves, forearms, glutes, quads, shoulders | wger#1438: back, core, hamstrings |
| `clean` | movement | free-exercise-db#Clean: pull | wger#1438: legs |
| `clean-and-press` | secondary | free-exercise-db#Clean_and_Press: back, calves, core, glutes, hamstrings, quads, shoulders, triceps | wger#1901: quads |
| `deficit-deadlift` | primary | free-exercise-db#Deficit_Deadlift: back | wger#189: other |
| `deficit-deadlift` | secondary | free-exercise-db#Deficit_Deadlift: back, forearms, glutes, hamstrings, quads | wger#189: back, calves, core, glutes, hamstrings |
| `dumbbell-floor-press` | primary | free-exercise-db#Dumbbell_Floor_Press: triceps | wger#1084: chest |
| `dumbbell-floor-press` | secondary | free-exercise-db#Dumbbell_Floor_Press: chest, shoulders | wger#1084: biceps, shoulders, triceps |
| `dumbbell-rear-lunge` | primary | free-exercise-db#Dumbbell_Rear_Lunge: quads | wger#1651: glutes, quads |
| `dumbbell-rear-lunge` | secondary | free-exercise-db#Dumbbell_Rear_Lunge: calves, glutes, hamstrings | wger#1651: calves |
| `dumbbell-rear-lunge` | movement | free-exercise-db#Dumbbell_Rear_Lunge: push | wger#1651: legs |
| `dumbbell-scaption` | primary | free-exercise-db#Dumbbell_Scaption: shoulders | wger#1602: back |
| `dumbbell-scaption` | secondary | free-exercise-db#Dumbbell_Scaption: back | wger#1602: shoulders |
| `dumbbell-side-bend` | movement | free-exercise-db#Dumbbell_Side_Bend: pull | wger#1650: core |
| `isometric-wipers` | secondary | free-exercise-db#Isometric_Wipers: core, shoulders, triceps | wger#314: core |
| `jm-press` | secondary | free-exercise-db#JM_Press: chest, shoulders | wger#1302: biceps, chest |
| `kettlebell-sumo-high-pull` | secondary | free-exercise-db#Kettlebell_Sumo_High_Pull: glutes, hamstrings, other, quads, shoulders | wger#1970: glutes, hamstrings, quads, shoulders |
| `pallof-press` | primary | free-exercise-db#Pallof_Press: core | wger#1194: back, core, glutes, other, shoulders |
| `pallof-press` | secondary | free-exercise-db#Pallof_Press: chest, shoulders, triceps | wger#1194: chest, triceps |
| `pallof-press` | movement | free-exercise-db#Pallof_Press: pull | wger#1194: core |
| `power-clean` | primary | free-exercise-db#Power_Clean: hamstrings | wger#683: chest |
| `reverse-crunch` | movement | free-exercise-db#Reverse_Crunch: pull | wger#1772: core |
| `romanian-deadlift` | primary | free-exercise-db#Romanian_Deadlift: hamstrings | wger#507: glutes, hamstrings |
| `romanian-deadlift` | secondary | free-exercise-db#Romanian_Deadlift: back, calves, glutes | wger#507: back |
| `romanian-deadlift` | movement | free-exercise-db#Romanian_Deadlift: pull | wger#507: legs |
| `seated-cable-rows` | secondary | free-exercise-db#Seated_Cable_Rows: back, biceps, shoulders | wger#1117: back, biceps |
| `single-leg-glute-bridge` | movement | free-exercise-db#Single_Leg_Glute_Bridge: push | wger#1740: legs |
| `sled-push` | primary | free-exercise-db#Sled_Push: quads | wger#1523: calves, glutes, quads |
| `sled-push` | secondary | free-exercise-db#Sled_Push: calves, chest, glutes, hamstrings, triceps | wger#1523: hamstrings, shoulders, triceps |
| `sled-push` | type | free-exercise-db#Sled_Push: strength | wger#1523: cardio |
| `snatch` | primary | free-exercise-db#Snatch: quads | wger#599: shoulders |
| `stomach-vacuum` | type | free-exercise-db#Stomach_Vacuum: mobility | wger#2673: strength |
| `v-bar-pulldown` | secondary | free-exercise-db#V-Bar_Pulldown: back, biceps, shoulders | wger#695: back, biceps |
| `kettlebell-swings` | primary | wger#331: glutes | wger#960: glutes, shoulders |
| `kettlebell-swings` | secondary | wger#331: hamstrings | wger#960: back, core, quads |

### Slug collisions

24 records share a base name with a differently-equipped exercise and received a suffix.

| Name | Base slug | Allocated id | Equipment |
| --- | --- | --- | --- |
| Leg Press | `leg-press` | `leg-press-other` | other |
| Glute-Ham Raise | `glute-ham-raise` | `glute-ham-raise-other` | other |
| Butterfly | `butterfly` | `butterfly-other` | other |
| Crunches | `crunches` | `crunches-other` | other |
| Flutter Kicks | `flutter-kicks` | `flutter-kicks-other` | other |
| Muscle up | `muscle-up` | `muscle-up-bodyweight` | bodyweight |
| Overhead Squat | `overhead-squat` | `overhead-squat-other` | other |
| Push Press | `push-press` | `push-press-other` | other |
| Seated Triceps Press | `seated-triceps-press` | `seated-triceps-press-dumbbell-other` | dumbbell, other |
| Smith Machine Close-grip Bench Press | `smith-machine-close-grip-bench-press` | `smith-machine-close-grip-bench-press-other` | other |
| Standing Calf Raises | `standing-calf-raises` | `standing-calf-raises-other` | other |
| Sumo Deadlift | `sumo-deadlift` | `sumo-deadlift-other` | other |
| Superman | `superman` | `superman-other` | other |
| Box squat | `box-squat` | `box-squat-bodyweight` | bodyweight |
| Russian Twist | `russian-twist` | `russian-twist-dumbbell-other` | dumbbell, other |
| Recumbent Bike | `recumbent-bike` | `recumbent-bike-other` | other |
| Good Morning | `good-morning` | `good-morning-bodyweight` | bodyweight |
| Spider Curl | `spider-curl` | `spider-curl-other` | other |
| Kettlebell One Legged Deadlift | `kettlebell-one-legged-deadlift` | `kettlebell-one-legged-deadlift-dumbbell-kettlebell` | dumbbell, kettlebell |
| Smith machine squat | `smith-machine-squat` | `smith-machine-squat-other` | other |
| Reverse Hyperextension | `reverse-hyperextension` | `reverse-hyperextension-other` | other |
| Quad Stretch | `quad-stretch` | `quad-stretch-bodyweight` | bodyweight |
| Wrist circles | `wrist-circles` | `wrist-circles-other` | other |
| Hamstring Stretch | `hamstring-stretch` | `hamstring-stretch-bodyweight` | bodyweight |

## Mapping notes

Category values map to the taxonomy `type` axis: stretching to mobility, cardio to cardio, and every strength discipline (strength, plyometrics, strongman, powerlifting, olympic weightlifting, calisthenics) to strength.

Ambiguous mappings made deliberately:

| Source value | Taxonomy | Rationale |
| --- | --- | --- |
| Trapezius / traps | back | Upper-back region; taxonomy has no traps value. |
| Brachialis | biceps | Elbow flexor adjacent to the biceps; taxonomy has no brachialis value. |
| Serratus anterior | other | No taxonomy muscle covers it without overstating chest or back. |
| Adductors / abductors | other | No taxonomy muscle covers hip adduction or abduction. |
| Neck | other | No taxonomy value. |
| Bench / incline bench / gym mat / Swiss ball / medicine ball / exercise ball / foam roll | other | Support or implement not represented by the eight equipment values. |
| Pull-up bar | bodyweight | The exercise is loaded by bodyweight; the bar is the fixed support. |
| SZ-Bar / e-z curl bar | barbell | A bar loaded with plates. |

Values explicitly mapped to `other` (not silently dropped):

- wger / muscle / `Serratus anterior` -> `other`
- wger / equipment / `Bench` -> `other`
- wger / equipment / `Gym mat` -> `other`
- wger / equipment / `Incline bench` -> `other`
- wger / equipment / `Swiss Ball` -> `other`
- free-exercise-db / muscle / `abductors` -> `other`
- free-exercise-db / muscle / `adductors` -> `other`
- free-exercise-db / muscle / `neck` -> `other`
- free-exercise-db / equipment / `exercise ball` -> `other`
- free-exercise-db / equipment / `foam roll` -> `other`
- free-exercise-db / equipment / `medicine ball` -> `other`
- free-exercise-db / equipment / `other` -> `other`
- exercemus / muscle / `abductors` -> `other`
- exercemus / muscle / `adductors` -> `other`
- exercemus / muscle / `neck` -> `other`
- exercemus / equipment / `bench` -> `other`
- exercemus / equipment / `exercise ball` -> `other`
- exercemus / equipment / `foam roll` -> `other`
- exercemus / equipment / `medicine ball` -> `other`
- exercemus / equipment / `other` -> `other`

No source value was left unmapped. The mapping file contains every distinct source value observed in each source.

## Share-alike records

788 merged records include at least one CC-BY-SA provenance entry. Every such provenance entry has `share_alike: true`. The full affected id list follows.

`1-2-kneeling-thoracic-rotation`, `1-arm-half-kneeling-lat-pulldown`, `1-leg-box-squat`, `2-handed-kettlebell-swing`, `3d-lunge-warmup`, `ab-wheel`, `abdominal-crunch`, `abdominal-draw-in`
`abdominal-stabilization`, `abduction-while-standing`, `active-hang`, `alternate-back-lunges`, `alternate-walking`, `alternating-biceps-curls-with-dumbbell`, `alternating-dumbbell-hammer-curl`, `alternating-high-cable-row`
`alternative-db-gorilla-rows`, `ankle-dorsiflexion-rocks`, `ankle-roll`, `arabesque`, `arch-hang`, `archer-pull-up`, `arm-and-neck-stretch`, `arm-raises-t-y-i`
`arnold-shoulder-press`, `assisted-pull-up`, `australian-pull-ups`, `axe-hold`, `back-bridge`, `back-lever`, `bag-training`, `ball-crunches`
`ball-slams`, `band-pull-apart`, `band-pull-apart-with-external-rotation`, `band-terminal-knee-extension`, `banded-ankle-mobility`, `banded-clamshell`, `banded-front-raise`, `banded-monster-walk`
`banded-scapular-retraction`, `banded-shoulder-drills`, `barbell-ab-rollout`, `barbell-clean-and-press`, `barbell-full-squat`, `barbell-hack-squat`, `barbell-lunges-standing`, `barbell-reverse-wrist-curl`
`barbell-romanian-deadlift-rdl`, `barbell-row-overhand`, `barbell-row-underhand`, `barbell-triceps-extension`, `barbell-wrist-curl`, `battle-ropes`, `bayesian-curl`, `bear-crawl-pull-through`
`bear-walk-2`, `behind-the-back-cable-lateral-raise`, `bench-dips-on-floor-hd`, `bench-press`, `bench-press-isometric`, `bench-press-narrow-grip`, `benchpress-dumbbells`, `bent-high-pulls`
`bent-knee-iron-cross`, `bent-leg-hamstring-stretch`, `bent-over-cable-flye`, `bent-over-dumbbell-rows-single-arm`, `bent-over-dumbbell-rows-two-arms`, `bent-over-lateral-raises`, `bent-over-row-to-external-rotation`, `bent-over-rowing`
`bent-over-rowing-reverse`, `biceps-close-grip-pull-down`, `biceps-curl-machine`, `biceps-curl-with-cable`, `biceps-curls-with-barbell`, `biceps-curls-with-dumbbell`, `biceps-curls-with-sz-bar`, `biceps-with-trx`
`bicycle-crunches`, `bird-dog`, `bizeps-curls-trifecta`, `black-widow-knee-slides`, `blackroll`, `blaze`, `body-ups`, `bodyweight-biceps-curl`
`bodyweight-lunge-hd`, `bodyweight-squat-hd`, `box-handstand-push-up`, `box-jumps`, `box-squat-bodyweight`, `boxing`, `braced-squat`, `bretzel-stretch`
`bronco`, `bulgarian-squat-with-dumbbells`, `burpees`, `bus-drivers`, `butchers-block-stretch`, `butterfly-narrow-grip`, `butterfly-other`, `butterfly-reverse`
`butterfly-sit-up`, `butterfly-stretch`, `butterfly-superman`, `cable-chest-press-decline`, `cable-chest-press-incline`, `cable-concentration-curl`, `cable-cross-over`, `cable-curls`
`cable-external-rotation`, `cable-fly-lower-chest`, `cable-fly-middle-chest`, `cable-fly-upper-chest`, `cable-front-raise-with-a-small-bar`, `cable-glute-extension`, `cable-lateral-raises-single-arm`, `cable-press-around`
`cable-pull-through`, `cable-rear-delt-fly`, `cable-rear-delt-fly-single-arm`, `cable-shrug-in`, `cable-tri-extension-internal-rotation`, `cable-tricep-kickback`, `cable-triceps-press`, `cable-woodchoppers`
`calf-press-using-leg-press-machine`, `calf-raise-using-hack-squat-machine`, `calf-raises-left-leg`, `calf-raises-on-hackenschmitt-machine`, `calf-raises-one-legged`, `calves-foam-roller`, `cat-plank`, `chair-dips`
`chest-press`, `chest-supported-rear-delt-raise`, `chin-up-isometric-hold`, `clamshell`, `clamshell-to-reverse-clamshell`, `clap-push-up`, `claps-over-the-head`, `clean`
`clean-and-jerk-ol`, `clean-and-press`, `climbmill`, `close-grip-lat-pull-down`, `close-grip-press-ups`, `close-grip-supinated-lat-pulldown`, `cobra-stretch`, `commando-pull-ups`
`copenhagen-adduction-exercise`, `core-rotation`, `cossack-squat`, `couch-stretch`, `cross-bench-dumbbell-pullovers`, `cross-body-cable-y-raise`, `cross-body-stretch`, `crossbody-hamstring-stretch`
`crossbody-leg-swings`, `crunches-on-machine`, `crunches-other`, `crunches-with-cable`, `crunches-with-legs-up`, `curl-de-muneca-con-barra`, `curl-with-shoulder-elevated`, `db-cross-body-hammer-curls`
`db-underhand-bench-press`, `db-upper-chest-variation`, `db-wrist-extension`, `deadbug`, `deadhang`, `deadlifts`, `decline-bench-leg-raise`, `decline-bench-press-barbell`
`decline-bench-press-dumbbell`, `deep-breathing-standing-or-seated`, `deficit-deadlift`, `deficit-push-ups`, `delt-stretch`, `devils-press`, `diagonal-shoulder-press`, `diamond-push-ups`
`dips-between-two-benches`, `doorway-pectoral-stretch`, `double-kettlebell-clean-and-press`, `double-kettlebell-front-squat`, `double-leg-abdominal-press`, `double-leg-calf-raise`, `drag-pushdown`, `dragon-flag`
`dragon-squat`, `drop-curl`, `dumbbell-bent-over-face-pull`, `dumbbell-bicep-curl-to-press`, `dumbbell-bradford-press`, `dumbbell-cheat-curl`, `dumbbell-close-grip-bench-press`, `dumbbell-concentration-curl`
`dumbbell-crunches`, `dumbbell-curl`, `dumbbell-cyclist-squat`, `dumbbell-deadlift`, `dumbbell-donkey-kick`, `dumbbell-drag-curls`, `dumbbell-farmers-carry`, `dumbbell-floor-press`
`dumbbell-frog-press`, `dumbbell-front-squat`, `dumbbell-goblet-squat`, `dumbbell-hang-power-cleans`, `dumbbell-hex-press`, `dumbbell-hip-thrust`, `dumbbell-incline-curl`, `dumbbell-lunges-standing`
`dumbbell-lunges-walking`, `dumbbell-rear-delt-row`, `dumbbell-rear-lunge`, `dumbbell-romanian-deadlift`, `dumbbell-scaption`, `dumbbell-shoulder-rotations`, `dumbbell-side-bend`, `dumbbell-side-squat`
`dumbbell-single-arm-row`, `dumbbell-single-leg-hip-thrust`, `dumbbell-snatch`, `dumbbell-split-squat`, `dumbbell-sumo-deadlift`, `dumbbell-thruster`, `dumbbell-triceps-extension`, `dumbbell-underhand-dead-row`
`dumbbell-wide-bicep-curls`, `dumbbells-on-scott-machine`, `dumbell-tate-press`, `dynamic-planche`, `dynamic-side-hold`, `dynamic-side-plank`, `elbow-lever`, `elbows-tucked-db-bench-press`
`elephant-walks`, `elevated-prayer-stretch`, `elliptical`, `exercise-band-dorsiflexion`, `exercise-band-plantarflexion`, `explosive-push-ups`, `external-rotation-stretch`, `face-pulls-with-yellow-green-band`
`facepull`, `fingerboard-20-mm-edge`, `fire-hydrant-circles`, `flat-machine-press`, `flexbar-tyler-twist`, `flexbar-wrist-extension`, `flexbar-wrist-flexion`, `floor-skull-crusher`
`flutter-kicks-other`, `fly-with-cable`, `fly-with-dumbbells`, `fly-with-dumbbells-decline-bench`, `foam-roll-it-band`, `foam-roller-adductors`, `foam-roller-anterior-tibialis`, `foam-roller-gluteus`
`foam-roller-iliotibial-band`, `foam-roller-quadriceps`, `forearm-curls-underhand-grip`, `frog-stand`, `frog-stretch`, `front-lever`, `front-lever-pull-up`, `front-lever-tuck`
`front-plank`, `front-pull-narrow`, `front-pull-wide`, `front-raise-cable`, `front-raises`, `front-raises-with-plates`, `front-split-stretch`, `front-squats`
`front-wood-chop`, `full-sit-outs`, `glute-bridge`, `glute-bridge-single-arm-press`, `glute-drive`, `glute-kickback-machine`, `good-morning-bodyweight`, `guided-or-free-meditation`
`hack-squats`, `half-kneeling-unilateral-lat-pulldown`, `hammer-curls`, `hammercurls-on-cable`, `hamstring-chokes`, `hamstring-foam-roller`, `hamstring-kicks`, `hamstring-stretch-bodyweight`
`hand-grip`, `handstand`, `hanging-leg-raises`, `heel-touches`, `helms-row`, `hercules-pillars`, `high-cable-cross-tricep-extention-nb`, `high-cable-lateral-raise`
`high-incline-smith-machine-press`, `high-knee-jumps`, `high-knee-skips-hd`, `high-pull`, `high-pulley-pullover`, `high-row`, `hindu-pushups`, `hindu-squats`
`hip-airplane`, `hip-bridge`, `hip-circles`, `hip-crossover`, `hip-flexor-stretch`, `hip-hinge`, `hip-out-and-hip-in-lateral-steps`, `hip-raise-lying`
`hip-thrust`, `horizontal-shoulder-flexion-stretch`, `horizontal-traction-isometry`, `horse-stance-side-splits`, `hyper-y-w-combo`, `hyperextensions`, `ice-cream-maker`, `incline-bench-press-barbell`
`incline-bench-press-dumbbell`, `incline-bench-press-mp`, `incline-bench-pulldown`, `incline-bench-reverse-fly`, `incline-chest-supported-dumbbell-row`, `incline-close-grip-barbell-bench-press`, `incline-crunches`, `incline-db-y-raise`
`incline-dumbbell-fly`, `incline-dumbbell-row`, `incline-ohp-db`, `incline-plank-with-alternate-floor-touch`, `incline-row-rings`, `incline-shoulder-press-up`, `incline-skull-crush`, `incline-static-hold`
`inverted-lat-pull-down`, `inverted-rows`, `isometric-squat-to-failure`, `isometric-wipers`, `jalon-al-pecho-con-agarre-ancho`, `jerk-ol`, `jm-press`, `jogging`
`jumping-jack-hd`, `jumping-jacks`, `kelso-shrugs`, `kettlebell-one-legged-deadlift-dumbbell-kettlebell`, `kettlebell-sumo-deadlift`, `kettlebell-sumo-high-pull`, `kettlebell-swings`, `kickstand-rdl`
`knee-push-ups`, `knee-raises`, `knee-to-chest-stretch`, `kneeling-superman`, `knieheben-beinhebemaschine`, `knieheben-beinhebemaschine-seitlich`, `kong-curl`, `kreis-press-db`
`kroc-row`, `l-hold`, `l-sit`, `l-sit-foot-supported`, `l-sit-pull-ups`, `landmine-press`, `landmine-rotation`, `landmine-squat-to-press`
`larsen-press`, `lat-pull-db`, `lat-pull-down-leaning-back`, `lat-pull-down-straight-back`, `lat-pulldown-cross-body-single-arm`, `lat-pulldown-isometric`, `lateral-push-off`, `lateral-raise-isometric`
`lateral-raises`, `lateral-rows-on-cable-one-armed`, `lateral-to-front-raises`, `lateral-walk`, `lean-away-cable-lateral-raise`, `leg-and-hip-stretch`, `leg-curl-with-elastic`, `leg-curls-laying`
`leg-curls-sitting`, `leg-curls-standing`, `leg-extension-isometric`, `leg-press-on-hackenschmidt-machine`, `leg-press-toe-press`, `leg-presses-narrow`, `leg-presses-wide`, `leg-raises-lying`
`leg-raises-pull-up-bar`, `leg-raises-standing`, `leg-swings-frontback`, `leg-wheel`, `lento-avanti-seduto`, `leverage-machine-chest-press`, `leverage-machine-iso-row`, `levitation-crunch`
`limber-11`, `long-lunge-pulse-stretch`, `long-pulley-low-row`, `long-pulley-narrow`, `low-box-squat-wide-stance`, `low-cable-cross-over-nb`, `low-pulley-cable-fly`, `lower-back-extensions`
`lunge-with-twist-stretch`, `lying-dumbbell-curls`, `lying-dumbbell-row-ss-seated-shrug`, `lying-figure-four-stretch`, `lying-hamstring-stretch-with-band`, `lying-rotator-cuff-exercise`, `lying-triceps-extensions`, `lying-triceps-kickback`
`machine-chest-fly`, `machine-glute-extension`, `machine-hip-abduction`, `machine-lateral-raise`, `machine-side-lateral-raises`, `march-or-jog-in-place`, `marching-high-knees`, `meadows-row`
`medicine-ball-booklet-crunch`, `medicine-ball-twist`, `mentzer-pulldown`, `military-press-mit-sz-bar`, `modified-pulldown`, `muscle-up-bodyweight`, `neck-extension`, `negative-crunches`
`neutral-grip-chest-pulldown`, `neutral-grip-lat-pulldown`, `neutral-grip-pull-ups-or-trx-rows`, `no-leg-drive-dumbbell-chest-press`, `nordic-curl`, `omni-cable-cross-over`, `one-arm-bent-row`, `one-arm-heavy-row`
`one-arm-overhead-cable-tricep-extension`, `one-armed-push-ups`, `one-handed-kettlebell-curls`, `open-book`, `overhand-cable-curl`, `overhead-barbell-press`, `overhead-cable-tricep-extension`, `overhead-press`
`overhead-press-isometric`, `overhead-squat-other`, `overhead-triceps-extension`, `pallof-press`, `parallel-bar-hold`, `patadas-traseras`, `pause-hack-squats`, `paused-squats`
`pec-deck-rear-delt-fly`, `pendelay-rows`, `pendular-hack`, `pendulum-squat`, `perpendicular-unilateral-landmine-row`, `pigeon-stretch`, `pike-hold-floor`, `pike-push-ups`
`pin-bench-press-bb`, `pin-ohp`, `pin-squat`, `pistol-squat`, `planche-lean-hold`, `plank`, `plank-jacks`, `plank-shoulder-taps`
`plank-to-elbow-extension`, `plank-with-alternating-leg-lift`, `plantarflexion-stretch-with-band`, `plate-loaded-lat-pulldown`, `plate-pinch-hold`, `posterior-pelvic-tilt`, `power-clean`, `preacher-curl`
`preacher-curl-externally-rotated`, `preacher-curl-internally-rotated`, `preacher-curl-isometric`, `prisoner-squat`, `prone-scapular-retraction-arms-at-side`, `pseudo-planche-push-up`, `pull-up-isometric-hold`, `pull-ups`
`pull-ups-neutral-grip`, `pull-ups-on-machine`, `pull-ups-wide-grip`, `pullback`, `pullover`, `pullover-machine`, `pullup-on-fingerboard`, `punches`
`push-ohp`, `push-press-other`, `push-up`, `push-ups-decline`, `push-ups-incline`, `push-ups-parallettes`, `quad-sets`, `quad-stretch-bodyweight`
`quadriceps-stretch`, `quadriped-arm-and-leg-raise`, `quadruped-hip-abduction`, `quadruped-thoracic-rotation-left`, `quadruped-thoracic-rotation-right`, `rack-deadlift`, `radio-taiso`, `reach-ups`
`rear-delt-raises`, `rear-foot-elevated-hip-flexor-stretch`, `recumbent-bike-other`, `remo-alto-polea-alta`, `remo-maquina-agarre-estrecho`, `remo-maquina-agarre-estrecho-supino`, `rest-for-timed-workouts`, `retro-treadmill-walking`
`reverse-bar-curl`, `reverse-cable-flye`, `reverse-clamshell`, `reverse-crunch`, `reverse-ez-bar-cable-curls`, `reverse-fly-standing`, `reverse-grip-barbell-curls`, `reverse-grip-bench-press`
`reverse-grip-pull-ups`, `reverse-hyperextension-other`, `reverse-nordic-curl`, `reverse-plank`, `reverse-preacher-curl-close-grip`, `reverse-snow-angel`, `reverse-v-squat`, `reverse-wood-chops`
`ring-dips`, `rocking-triceps-pushdown`, `roll-down`, `roll-overs-into-v-sits`, `roman-chair-crunch`, `roman-chair-rdls`, `romanian-deadlift`, `rope-pullover-row`
`rotary-torso-machine`, `rowing-lying-on-bench`, `rowing-machine`, `rowing-seated-narrow-grip`, `rowing-t-bar`, `rowing-with-trx-band`, `rubber-band-glute-kickback`, `run`
`run-interval-training`, `run-treadmill`, `runners-lunge-stretch`, `russian-push-ups`, `russian-twist-dumbbell-other`, `scapula-pulls`, `scapular-pushups`, `schwimmen`
`scissors`, `scorpion-kick`, `seated-back-extension-machine`, `seated-band-row`, `seated-bench-press`, `seated-cable-chest-fly`, `seated-cable-mid-trap-shrug`, `seated-cable-rows`
`seated-corkscrew`, `seated-dumbbell-calf-raise`, `seated-dumbbell-curl`, `seated-dumbbell-side-lateral`, `seated-figure-four`, `seated-hip-abduction`, `seated-hip-adduction`, `seated-knee-extension-with-overpressure`
`seated-knee-tuck`, `seated-pancake-good-morning`, `seated-piriformis-stretch`, `seated-rear-delt-rise`, `seated-row-machine`, `seated-shoulder-extension-stretch`, `seated-triceps-press-dumbbell-other`, `seated-v-grip-row`
`seated-w-curl`, `serratus-wall-slide-stretch`, `shinbox-ir-stretch`, `shotgun-row`, `shoulder-dislocates`, `shoulder-dumbbell-pendular-exercise`, `shoulder-external-rotation-cable`, `shoulder-external-rotation-with-dumbbell`
`shoulder-internal-rotation-cable`, `shoulder-press-barbell`, `shoulder-press-dumbbells`, `shoulder-press-on-machine`, `shoulder-press-on-multi-press`, `shoulder-raise-dumbbell`, `shoulder-raise-side-and-front-db`, `shoulder-width-three-point-push-up`
`shrimp-squat`, `shrugs-barbells`, `shrugs-dumbbells`, `shrugs-on-multipress`, `side-bends-on-machine`, `side-crunch`, `side-dumbbell-trunk-flexion`, `side-lateral-raise-cable`
`side-laying-interior-rotation`, `side-lying-external-rotation`, `side-lying-hip-abduction`, `side-plank`, `side-slides-squats`, `side-straight-arm-pulldown-cable`, `side-stretch`, `side-to-side-push-ups`
`single-arm-cable-pushdown`, `single-arm-cable-row-w-rotation-floor`, `single-arm-dumbbell-shoulder-press`, `single-arm-lat-pulldown`, `single-arm-preacher-curl`, `single-arm-row`, `single-leg-balance-with-eyes-closed`, `single-leg-balance-with-kettlebell-circles`
`single-leg-bosu-balance`, `single-leg-deadlift-with-dumbbell`, `single-leg-extension`, `single-leg-glute-bridge`, `single-leg-hamstring-curl`, `single-leg-hamstring-stretch`, `single-leg-lunge-with-kettlebell`, `single-leg-press`
`single-leg-rdl`, `single-leg-side-glute-press`, `single-leg-soft-landing-holds`, `sit-and-reach`, `sit-up-elbow-thrust`, `sit-ups`, `sitting-calf-raises`, `sitting-calf-stretch-dorsiflexion`
`ski-machine`, `skipping-standard`, `skullcrusher-dumbbells`, `skullcrusher-sz-bar`, `skydiver-with-arms-in-t-position`, `sled-push`, `sleeper-stretch`, `sliding-lateral-lunge`
`sloper-hanging`, `slow-squat`, `smith-machine-close-grip-bench-press-other`, `smith-machine-slight-incline-press`, `smith-machine-split-squat`, `smith-machine-squat-other`, `smith-press`, `smr-glutes-lax-ball`
`snap-down`, `snatch-ol`, `solo-hip-flexor-stretch`, `speed-deadlift`, `sphinx`, `spider-curl-other`, `splinter-sit-ups`, `squat-jumps`
`squat-sky-reach-stretch`, `squats`, `squats-on-multipress`, `stair-master`, `standing-adduction-cable`, `standing-biceps-stretch-left`, `standing-biceps-stretch-right`, `standing-calf-raises-other`
`standing-calf-stretch`, `standing-dowel-shoulder-press`, `standing-it-band-stretch`, `standing-pancake`, `standing-pancake-good-morning`, `standing-rope-forearm`, `standing-side-crunches`, `standing-soleus-stretch`
`stationary-bike`, `stationary-bike-cardio`, `step-calf-stretch`, `step-jack`, `stiff-legged-deadlifts`, `stomach-vacuum`, `straddle-l-sit`, `straight-arm-pull-down-bar-attachment`
`straight-arm-pull-down-rope-attachment`, `straight-arm-pulldown-cable`, `straight-bar-cable-curls`, `straight-bar-cable-front-raise`, `suitcase-carry`, `sumo-deadlift-other`, `sumo-squats`, `superman-other`
`supine-hip-abduction`, `supine-press`, `supported-calf-stretch`, `swimming-50m-sprints`, `t-bar-row`, `talons-fesses`, `tibialis-raises`, `toe-taps`
`toe-touch`, `toes-to-bar`, `torso-rotation-stretch`, `torso-twist`, `towel-superman`, `trap-3-raise`, `trap-bar-squat`, `trap-press`
`treadmill-cardio`, `tricep-dumbbell-kickback`, `tricep-pushdown-on-cable`, `tricep-rope-pushdowns`, `triceps-dips-assisted`, `triceps-extensions-on-cable`, `triceps-extensions-on-cable-with-bar`, `triceps-on-machine`
`triceps-overhead-dumbbell`, `triceps-push-up`, `triceps-pushdown`, `triceps-pushdown-isometric`, `triceps-stretch-left`, `triceps-stretch-right`, `trunk-rotation-with-cable`, `trx-dips`
`trx-gorilla-biceps-curl`, `trx-hammer-curl`, `trx-obliques`, `trx-roll-out`, `trx-rows`, `trx-single-arm-bicep-curl`, `trx-tricep-extension`, `tuck-l-sit`
`tuck-planche`, `turkish-get-up`, `typewriter-pull-ups`, `tyson-push-ups`, `underhand-lat-pull-down`, `unilateral-cable-lateral-raise`, `unilateral-cable-row`, `unilateral-hip-thrust`
`unilateral-lunges`, `upper-back`, `upper-external-oblique`, `upright-row-on-multi-press`, `upright-row-sz-bar`, `upright-row-w-dumbbells`, `v-bar-pulldown`, `v-up-mark-lauren`
`vpushup`, `w-raise`, `walking-bridge`, `wall-angels`, `wall-balls`, `wall-drills`, `wall-handstand`, `wall-pushup`
`wall-sit`, `wall-slides`, `weighted-crunch`, `weighted-neck-flexion`, `weighted-push-ups`, `wide-grip-pulldown`, `wide-grip-supinated-lat-pulldown`, `wide-push-up`
`windshield-wipers`, `wrist-circles-other`, `wrist-curl-cable`, `wrist-curl-dumbbells`, `wrist-rocks`, `wrist-stretch`, `yoga-exercise-cow-cat`, `ytw-raises`
`ytwl-exercise`, `ywts`, `zone-2-running`, `zottman-curl`

**Question for the developer:** if this dataset is distributed or adapted, do the CC-BY-SA attribution and share-alike terms attach to the combined database, or only to the wger-derived records? This report does not answer that legal question.

wger CC0 records (21) have no share-alike or attribution requirement. free-exercise-db records are public domain under The Unlicense.

## 20-record review sample

Full records, chosen to cover barbell, bodyweight, dumbbell, machine, cable and core work. Instructions are the paraphrased steps the app would show.

```json
[
  {
    "id": "bench-press",
    "name": "Bench Press",
    "aliases": [],
    "primary_muscles": [
      "chest"
    ],
    "secondary_muscles": [
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "barbell",
      "other"
    ],
    "movement": "other",
    "type": "strength",
    "mechanic": null,
    "level": null,
    "instructions": [
      "Lie on a flat bench and take a grip slightly wider than the shoulders.",
      "Breathe in and bring the bar down under control until it lightly meets the chest.",
      "Press the bar back up to the start and breathe out."
    ],
    "provenance": [
      {
        "source": "wger",
        "source_id": "73",
        "license": "CC-BY-SA 3",
        "author": "sistab2",
        "license_url": "https://creativecommons.org/licenses/by-sa/3.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "barbell-full-squat",
    "name": "Barbell Full Squat",
    "aliases": [],
    "primary_muscles": [
      "quads"
    ],
    "secondary_muscles": [
      "back",
      "calves",
      "glutes",
      "hamstrings"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "push",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Set the bar in a rack and take it across the upper back with both hands.",
      "Lift it clear of the rack, step back, and set the feet about shoulder width with the toes turned slightly out.",
      "Keep the head up and the back straight, then sit the hips back as the knees bend.",
      "Descend under control while maintaining an upright posture.",
      "Push through the heel or mid-foot, straighten the legs, and extend the hips to return to the start."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Barbell_Full_Squat",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      },
      {
        "source": "wger",
        "source_id": "1801",
        "license": "CC-BY-SA 4",
        "author": "fabrice",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "barbell-deadlift",
    "name": "Barbell Deadlift",
    "aliases": [],
    "primary_muscles": [
      "back"
    ],
    "secondary_muscles": [
      "back",
      "calves",
      "forearms",
      "glutes",
      "hamstrings",
      "quads"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Stand with a loaded barbell in front of the shins.",
      "Bend the knees and hinge forward with a straight back, then take a medium overhand grip.",
      "Drive with the legs and bring the torso upright while breathing out.",
      "At the top, lift the chest and draw the shoulder blades back.",
      "Reverse by bending the knees and leaning the torso forward, keeping the back straight."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Barbell_Deadlift",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "pullups",
    "name": "Pullups",
    "aliases": [],
    "primary_muscles": [
      "back"
    ],
    "secondary_muscles": [
      "back",
      "biceps"
    ],
    "equipment": [
      "bodyweight"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "compound",
    "level": "beginner",
    "instructions": [
      "Take the bar with an overhand grip.",
      "Choose a wide, medium, or close hand spacing relative to shoulder width.",
      "Draw the shoulders and upper arms down and back to raise the torso until the bar reaches the upper chest.",
      "Breathe out through this part of the movement.",
      "Squeeze the back at the top, then return under control."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Pullups",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "push-up",
    "name": "Push-Up",
    "aliases": [],
    "primary_muscles": [
      "chest"
    ],
    "secondary_muscles": [
      "core",
      "shoulders",
      "triceps"
    ],
    "equipment": [
      "bodyweight"
    ],
    "movement": "other",
    "type": "strength",
    "mechanic": null,
    "level": null,
    "instructions": [
      "Start in a plank with the hands a little wider than the shoulders, feet together, and a straight line from head to heels.",
      "Brace the core and bend the elbows to lower the body.",
      "Keep the elbows close to the body or slightly flared, and maintain a neutral spine until the chest is near the floor.",
      "Press through the palms and straighten the arms to return to the start."
    ],
    "provenance": [
      {
        "source": "wger",
        "source_id": "1551",
        "license": "CC-BY-SA 4",
        "author": "Settebello",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "barbell-shoulder-press",
    "name": "Barbell Shoulder Press",
    "aliases": [],
    "primary_muscles": [
      "shoulders"
    ],
    "secondary_muscles": [
      "chest",
      "triceps"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "push",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Set a barbell in a rack just above head height and sit on a bench with back support.",
      "Take a pronated grip and hold the bar at shoulder level, slightly in front of the head.",
      "Breathe in and lower the bar under control to the shoulders.",
      "Breathe out and press the bar back to the start."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Barbell_Shoulder_Press",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "barbell-curl",
    "name": "Barbell Curl",
    "aliases": [],
    "primary_muscles": [
      "biceps"
    ],
    "secondary_muscles": [
      "forearms"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "isolation",
    "level": "beginner",
    "instructions": [
      "Stand upright and take a barbell with a shoulder-width grip.",
      "Move only the forearms to curl the bar up.",
      "At the top, squeeze the biceps and hold briefly.",
      "Breathe in and bring the bar back down under control."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Barbell_Curl",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "plank",
    "name": "Plank",
    "aliases": [],
    "primary_muscles": [
      "core"
    ],
    "secondary_muscles": [
      "biceps",
      "quads",
      "triceps"
    ],
    "equipment": [
      "bodyweight"
    ],
    "movement": "core",
    "type": "strength",
    "mechanic": "isolation",
    "level": "beginner",
    "instructions": [
      "Set the body in a straight line and brace the trunk.",
      "Hold the position without letting the line break."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Plank",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      },
      {
        "source": "wger",
        "source_id": "458",
        "license": "CC-BY-SA 3",
        "author": "YYCfit / BFad07",
        "license_url": "https://creativecommons.org/licenses/by-sa/3.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "barbell-lunge",
    "name": "Barbell Lunge",
    "aliases": [],
    "primary_muscles": [
      "quads"
    ],
    "secondary_muscles": [
      "calves",
      "glutes",
      "hamstrings"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "push",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Set the bar in a rack, take it across the back with both hands, and lift it clear.",
      "Step back from the rack, then step forward with the right leg and lower through the hips.",
      "Keep the torso upright and stay balanced.",
      "Breathe in as you descend."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Barbell_Lunge",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "bent-over-barbell-row",
    "name": "Bent Over Barbell Row",
    "aliases": [],
    "primary_muscles": [
      "back"
    ],
    "secondary_muscles": [
      "back",
      "biceps",
      "shoulders"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "compound",
    "level": "beginner",
    "instructions": [
      "Take a barbell with a pronated grip and soften the knees.",
      "Hinge at the waist with a straight back until the torso is almost parallel to the floor.",
      "Keep the head up and let the bar hang in front of the shins with the arms perpendicular to the floor.",
      "Brace the torso, breathe out, and draw the bar up.",
      "Squeeze the back at the top and pause briefly.",
      "Breathe in and lower the bar under control."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Bent_Over_Barbell_Row",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "leg-press",
    "name": "Leg Press",
    "aliases": [],
    "primary_muscles": [
      "quads"
    ],
    "secondary_muscles": [
      "calves",
      "glutes",
      "hamstrings"
    ],
    "equipment": [
      "machine"
    ],
    "movement": "push",
    "type": "strength",
    "mechanic": "compound",
    "level": "beginner",
    "instructions": [
      "Sit in a leg press machine and set the feet on the platform at a medium stance.",
      "Release the safety bars and press the platform up until the legs are extended.",
      "Breathe in and lower the platform under control until the knees are bent to about ninety degrees.",
      "Drive mainly through the heels and press back to the start while breathing out."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Leg_Press",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "barbell-romanian-deadlift-rdl",
    "name": "Barbell Romanian Deadlift (RDL)",
    "aliases": [],
    "primary_muscles": [
      "glutes",
      "hamstrings"
    ],
    "secondary_muscles": [],
    "equipment": [
      "barbell"
    ],
    "movement": "other",
    "type": "strength",
    "mechanic": null,
    "level": null,
    "instructions": [
      "Push the hips back while keeping a slight bend in the knees.",
      "Lower the barbell along the front of the thighs and shins with a neutral spine.",
      "Keep the bar close to the body throughout."
    ],
    "provenance": [
      {
        "source": "wger",
        "source_id": "1700",
        "license": "CC-BY-SA 4",
        "author": "daiben",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "chin-up",
    "name": "Chin-Up",
    "aliases": [
      "Chin Up"
    ],
    "primary_muscles": [
      "back"
    ],
    "secondary_muscles": [
      "back",
      "biceps",
      "forearms"
    ],
    "equipment": [
      "bodyweight"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "compound",
    "level": "beginner",
    "instructions": [
      "Take the pull-up bar with the palms facing the torso and the hands closer than shoulder width.",
      "Keep the torso straight to emphasize the biceps.",
      "Breathe out and draw the torso up until the head is near bar height.",
      "Squeeze the biceps at the top, then lower under control.",
      "Breathe in during the lowering phase."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Chin-Up",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      },
      {
        "source": "wger",
        "source_id": "152",
        "license": "CC0",
        "author": "BFad07",
        "license_url": "http://creativecommons.org/publicdomain/zero/1.0/"
      }
    ]
  },
  {
    "id": "barbell-hip-thrust",
    "name": "Barbell Hip Thrust",
    "aliases": [],
    "primary_muscles": [
      "glutes"
    ],
    "secondary_muscles": [
      "calves",
      "hamstrings"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "push",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Sit on the ground with a bench directly behind the upper back.",
      "Roll the bar over the hips and lean back so the shoulder blades rest near the top of the bench.",
      "Drive through the feet and extend the hips vertically against the bar.",
      "Reach full extension, then reverse the motion to the start."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Barbell_Hip_Thrust",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "russian-twist",
    "name": "Russian Twist",
    "aliases": [],
    "primary_muscles": [
      "core"
    ],
    "secondary_muscles": [
      "back"
    ],
    "equipment": [
      "bodyweight"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Sit on the floor and fix the feet under something stable or have a partner hold them.",
      "Lift the upper body until the torso and thighs form a V shape.",
      "Breathe out and turn the torso to the right until the arms are parallel to the floor.",
      "Pause briefly, then return to the centre.",
      "Repeat the turn on the left side with the same technique."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Russian_Twist",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "squats",
    "name": "Squats",
    "aliases": [],
    "primary_muscles": [
      "quads"
    ],
    "secondary_muscles": [
      "glutes"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "legs",
    "type": "strength",
    "mechanic": null,
    "level": null,
    "instructions": [
      "Set a barbell in a rack just below shoulder height.",
      "Step under the bar so it rests across the upper back, and take a grip wider than shoulder width.",
      "Lift the chest and draw the shoulder blades together to keep the back straight.",
      "Stand to unrack the bar, step back, and set the feet a little wider than shoulder width.",
      "Sit the hips back with the back straight and chest up, lowering until the hips pass below the knees."
    ],
    "provenance": [
      {
        "source": "wger",
        "source_id": "615",
        "license": "CC-BY-SA 3",
        "author": "wger.de",
        "license_url": "https://creativecommons.org/licenses/by-sa/3.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "deadlifts",
    "name": "Deadlifts",
    "aliases": [],
    "primary_muscles": [
      "back"
    ],
    "secondary_muscles": [
      "glutes"
    ],
    "equipment": [
      "barbell"
    ],
    "movement": "other",
    "type": "strength",
    "mechanic": null,
    "level": null,
    "instructions": [
      "Stand with the feet slightly wider than shoulder width and the bar close to the shins.",
      "Point the toes slightly out, bend down with a straight back, and let the knees track outward.",
      "Take a shoulder-width grip with one overhand and one underhand hand.",
      "At the top, hold a slight hollow in the back and draw the bar back.",
      "Pause there for a moment before reversing."
    ],
    "provenance": [
      {
        "source": "wger",
        "source_id": "184",
        "license": "CC-BY-SA 3",
        "author": "wger.de",
        "license_url": "https://creativecommons.org/licenses/by-sa/3.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "dumbbell-bicep-curl",
    "name": "Dumbbell Bicep Curl",
    "aliases": [],
    "primary_muscles": [
      "biceps"
    ],
    "secondary_muscles": [
      "forearms"
    ],
    "equipment": [
      "dumbbell"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "isolation",
    "level": "beginner",
    "instructions": [
      "Keep the elbows close to the torso and turn the palms of the hands until they are facing forward",
      "Hold the contracted position for a brief pause as you squeeze the biceps"
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Dumbbell_Bicep_Curl",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  },
  {
    "id": "seated-cable-rows",
    "name": "Seated Cable Rows",
    "aliases": [
      "Seated Cable Row"
    ],
    "primary_muscles": [
      "back"
    ],
    "secondary_muscles": [
      "back",
      "biceps",
      "shoulders"
    ],
    "equipment": [
      "cable"
    ],
    "movement": "pull",
    "type": "strength",
    "mechanic": "compound",
    "level": "beginner",
    "instructions": [
      "Take a seat on the machine and set the feet on the front platform or crossbar with the knees slightly bent.",
      "Keep the back naturally aligned, hinge forward slightly, and take the V-bar handles.",
      "With the arms extended, draw the torso back until it is about ninety degrees to the legs.",
      "Hold the torso still, pull the handles toward the abdomen with the arms close to the body, and breathe out.",
      "Pause at the contraction, then return to the start while breathing in."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Seated_Cable_Rows",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      },
      {
        "source": "wger",
        "source_id": "1117",
        "license": "CC-BY-SA 4",
        "author": "Franpol",
        "license_url": "https://creativecommons.org/licenses/by-sa/4.0/deed.en",
        "share_alike": true
      }
    ]
  },
  {
    "id": "dumbbell-shoulder-press",
    "name": "Dumbbell Shoulder Press",
    "aliases": [],
    "primary_muscles": [
      "shoulders"
    ],
    "secondary_muscles": [
      "triceps"
    ],
    "equipment": [
      "dumbbell"
    ],
    "movement": "push",
    "type": "strength",
    "mechanic": "compound",
    "level": "intermediate",
    "instructions": [
      "Sit on a bench with back support and hold a dumbbell in each hand.",
      "Set the dumbbells upright on the thighs, then raise them to shoulder height one at a time with help from the thighs.",
      "Turn the wrists so the palms face forward.",
      "Breathe out and press the dumbbells upward until they meet at the top."
    ],
    "provenance": [
      {
        "source": "free-exercise-db",
        "source_id": "Dumbbell_Shoulder_Press",
        "license": "The Unlicense",
        "author": null,
        "license_url": "http://unlicense.org/"
      }
    ]
  }
]
```

## Validation

`python3 data_build/validate.py` exits nonzero on any structural, enum, sort, provenance, duplicate-key, file-encoding or trailing-whitespace failure.

```text
PASS
  records: 1650
  provenance: {'wger': 810, 'free-exercise-db': 876, 'exercemus': 0}
  taxonomy.json: 3930 bytes
  exercises.json: 1009277 bytes
  sources.json: 1316 bytes
  mapping.json: 2545 bytes
  validate.py: 12827 bytes
```

## Developer questions

- Share-alike scope: see the question in the share-alike section above.
- wger attribution: 122 CC-BY-SA records were excluded because no author was supplied. If wger can provide author names for them, they can be added without changing any other rule.
- exercemus: if the project can obtain the per-record license fields, those records can be reconsidered. Until then they are excluded rather than assumed to inherit MIT.
