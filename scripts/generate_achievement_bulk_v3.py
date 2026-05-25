#!/usr/bin/env python3
"""Generate lib/config/achievements_bulk_seeds_v3.dart (~162 entries toward 600 catalog)."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXISTING = [
    ROOT / "lib/config/achievements.dart",
    ROOT / "lib/config/achievements_bulk_seeds.dart",
    ROOT / "lib/config/achievements_bulk_seeds_v2.dart",
]
OUT = ROOT / "lib/config/achievements_bulk_seeds_v3.dart"

# (category, prefix, icon, templates[(slug, title, desc)])
WAVES = [
    (
        "education",
        "edu",
        "history_edu",
        [
            ("v3-latin-honors", "Latin Honors", "Graduated with cum laude or higher"),
            ("v3-community-college", "Community College", "Earned an associate degree"),
            ("v3-ged", "GED Complete", "Earned high school equivalency"),
            ("v3-sat-perfect", "Perfect Section", "Scored perfect on a major exam section"),
            ("v3-physics-olympiad", "Physics Medal", "Medaled in physics olympiad"),
            ("v3-chemistry-lab", "Chem Lab Lead", "Led a university chemistry lab section"),
            ("v3-history-paper", "History Prize Paper", "Won a history department paper prize"),
            ("v3-statistics-minor", "Statistics Minor", "Completed a statistics minor"),
            ("v3-philosophy-thesis", "Philosophy Thesis", "Defended a philosophy thesis"),
            ("v3-library-thesis", "Archival Research", "Completed archival thesis research"),
            ("v3-peer-review", "Peer Reviewer", "Peer-reviewed journal submissions"),
            ("v3-teaching-assistant", "Teaching Assistant", "TA'd a core course for a year"),
            ("v3-audit-course", "Audit Scholar", "Audited a university course for enrichment"),
            ("v3-coding-bootcamp-teach", "Bootcamp Mentor", "Mentored bootcamp cohort"),
            ("v3-grad-school-offer", "Grad School Offer", "Received a grad school offer"),
        ],
    ),
    (
        "career",
        "car",
        "home_work",
        [
            ("v3-four-day", "Four-Day Week", "Worked a four-day week policy a year"),
            ("v3-parental-leave", "Parental Return", "Returned from parental leave successfully"),
            ("v3-whistleblower", "Ethics Reporter", "Reported ethics issue through proper channels"),
            ("v3-union-organize", "Union Organizer", "Helped organize a workplace union drive"),
            ("v3-acquisition", "Acquisition Survivor", "Stayed through an acquisition integration"),
            ("v3-layoff-support", "Layoff Support", "Supported teammates through layoffs"),
            ("v3-customer-save", "Customer Save", "Saved a major customer relationship"),
            ("v3-zero-incident", "Zero Incident Quarter", "Team had zero safety incidents a quarter"),
            ("v3-innovation-award", "Innovation Award", "Won a company innovation award"),
            ("v3-cross-team", "Cross Team Lead", "Led a cross-functional initiative"),
            ("v3-mentor-program", "Mentor Program Lead", "Ran a formal mentorship program"),
            ("v3-exit-founder", "Founder Exit", "Exited a company you founded"),
            ("v3-performance-review", "Top Review", "Earned top performance review rating"),
            ("v3-salary-transparency", "Pay Transparency", "Advocated pay transparency successfully"),
            ("v3-contract-negotiate", "Contract Win", "Negotiated a strong contract"),
        ],
    ),
    (
        "relationships",
        "rel",
        "favorite",
        [
            ("v3-double-date", "Double Date", "Went on a double date that actually worked"),
            ("v3-apology-letter", "Apology Letter", "Wrote a meaningful apology letter"),
            ("v3-family-recipe", "Family Recipe", "Learned a family recipe from an elder"),
            ("v3-sibling-trip", "Sibling Trip", "Traveled with a sibling"),
            ("v3-neighbor-dinner", "Neighbor Dinner", "Hosted neighbors for dinner"),
            ("v3-friend-therapy", "Friend Support", "Supported a friend through crisis"),
            ("v3-pet-loss", "Pet Memorial", "Held memorial for a beloved pet"),
            ("v3-long-friendship", "Twenty Year Friend", "Friendship lasted twenty years"),
            ("v3-mentor-family", "Family Mentor", "Mentored a younger family member"),
            ("v3-community-parent", "Community Parent", "Parented with community support"),
            ("v3-engagement-party", "Engagement Party", "Hosted an engagement celebration"),
            ("v3-friend-roadtrip", "Friends Road Trip", "Road-tripped with close friends"),
            ("v3-family-game-night", "Family Game Night", "Ran monthly family game nights"),
        ],
    ),
    (
        "health",
        "hlth",
        "self_improvement",
        [
            ("v3-75-hard", "75 Hard", "Completed 75 Hard or equivalent challenge"),
            ("v3-ruck-march", "Ruck March", "Finished a weighted ruck event"),
            ("v3-swim-mile", "Mile Swim", "Swam a continuous mile"),
            ("v3-handstand", "Handstand Hold", "Held a handstand thirty seconds"),
            ("v3-flexibility", "Splits Progress", "Reached a flexibility milestone"),
            ("v3-sleep-8", "Eight Hour Month", "Slept eight hours average a month"),
            ("v3-no-caffeine", "Caffeine Break", "Skipped caffeine thirty days"),
            ("v3-plant-based", "Plant Based Quarter", "Ate plant-based ninety days"),
            ("v3-pt-complete", "PT Graduate", "Graduated physical therapy program"),
            ("v3-ergonomic", "Ergonomic Setup", "Built an ergonomic desk setup"),
            ("v3-flu-shot", "Flu Season Ready", "Got flu shot two years running"),
            ("v3-walk-10k-daily", "Walk Streak", "Walked ten thousand steps sixty days"),
            ("v3-blood-pressure", "BP Track", "Tracked blood pressure twelve weeks"),
            ("v3-cholesterol-down", "Cholesterol Win", "Improved cholesterol with lifestyle"),
            ("v3-posture-desk", "Desk Posture", "Fixed desk posture for ninety days"),
        ],
    ),
    (
        "skills",
        "skl",
        "code",
        [
            ("v3-rust-ship", "Rust Ship", "Shipped a Rust project to production"),
            ("v3-flutter-ship", "Flutter Ship", "Published a Flutter app"),
            ("v3-arduino", "Arduino Build", "Built a working Arduino project"),
            ("v3-hydroponics", "Hydroponics", "Ran a hydroponic grow cycle"),
            ("v3-knitting", "Knitting Gift", "Knitted gifts for five people"),
            ("v3-leathercraft", "Leather Craft", "Made a leather goods piece"),
            ("v3-glassblowing", "Glass Piece", "Created a glass art piece"),
            ("v3-magic-trick", "Magic Repertoire", "Performed ten magic tricks live"),
            ("v3-juggling", "Juggling Five", "Juggled five balls consistently"),
            ("v3-speedcube", "Cube Sub-60", "Solved Rubik cube under sixty seconds"),
            ("v3-home-lab", "Home Lab", "Ran a homelab server a year"),
            ("v3-ham-repeat", "Ham Contact", "Made fifty ham radio contacts"),
            ("v3-drone-license", "Drone Pilot", "Earned Part 107 or equivalent drone license"),
            ("v3-soldering", "Solder Pro", "Soldered complex electronics board"),
            ("v3-cnc-part", "CNC Part", "Machined a part on CNC"),
        ],
    ),
    (
        "travel",
        "trv",
        "hiking",
        [
            ("v3-biome-3", "Three Biomes", "Visited three biomes one trip"),
            ("v3-canyon", "Canyon Hike", "Hiked a major canyon"),
            ("v3-volcano", "Volcano View", "Viewed an active volcano safely"),
            ("v3-glacier", "Glacier Trek", "Trekked near a glacier"),
            ("v3-safari", "Safari Day", "Completed a safari day trip"),
            ("v3-metro-10", "Ten Metros", "Rode metros in ten cities"),
            ("v3-bike-tour", "Bike Tour", "Bike-toured a region"),
            ("v3-couch-surf", "Couch Surf", "Couch-surfed five cities ethically"),
            ("v3-border-walk", "Border Town", "Visited a border town thoughtfully"),
            ("v3-lighthouse", "Lighthouse", "Visited five lighthouses"),
            ("v3-overnight-train", "Sleeper Train", "Slept on an overnight train"),
            ("v3-cave-tour", "Cave Tour", "Toured a show cave or wild cave safely"),
            ("v3-thermal-spring", "Hot Spring", "Visited a thermal spring"),
        ],
    ),
    (
        "finance",
        "fin",
        "account_balance",
        [
            ("v3-credit-freeze", "Fraud Freeze", "Reacted quickly to fraud with freezes"),
            ("v3-split-bills", "Split Bills Pro", "Split shared bills fairly a year"),
            ("v3-coupon-master", "Coupon Master", "Saved meaningfully with intentional coupons"),
            ("v3-side-hustle-profit", "Side Profit", "Side hustle profitable six months"),
            ("v3-student-loan", "Student Loan Plan", "Executed a student loan payoff plan"),
            ("v3-mortgage-pay", "Mortgage Extra", "Paid extra mortgage principal a year"),
            ("v3-dividend-income", "Dividend Track", "Tracked dividend income quarterly"),
            ("v3-crypto-tax", "Crypto Taxes", "Filed crypto taxes accurately"),
            ("v3-financial-advisor", "Advisor Meet", "Met a fiduciary advisor"),
            ("v3-kids-allowance", "Allowance System", "Ran an allowance teaching system"),
            ("v3-emergency-3mo", "Three Month Fund", "Built three month emergency fund"),
            ("v3-credit-builder", "Credit Builder", "Used secured card to build credit"),
            ("v3-expense-track", "Expense Track", "Tracked every expense ninety days"),
        ],
    ),
    (
        "community",
        "com",
        "diversity_3",
        [
            ("v3-bike-repair", "Bike Repair Clinic", "Volunteered at bike repair clinic"),
            ("v3-meal-train", "Meal Train", "Organized a meal train"),
            ("v3-scholarship-fund", "Micro Scholarship", "Funded a micro scholarship"),
            ("v3-poll-worker", "Poll Worker", "Worked as election poll worker"),
            ("v3-translator-vol", "Translator Volunteer", "Translated for community events"),
            ("v3-habitat-lead", "Habitat Lead", "Led a habitat build day"),
            ("v3-park-bench", "Bench Sponsor", "Sponsored a park bench or tree"),
            ("v3-little-library", "Little Library", "Installed a little free library"),
            ("v3-neighbor-shovel", "Snow Neighbor", "Shoveled neighbors driveways"),
            ("v3-crisis-line", "Crisis Line Hours", "Volunteered crisis line hours"),
            ("v3-clothing-drive", "Clothing Drive", "Ran a clothing drive"),
            ("v3-book-drive", "Book Drive", "Collected books for schools"),
            ("v3-park-trash", "Park Trash Walk", "Picked up trash on weekly walks"),
        ],
    ),
    (
        "funny",
        "fun",
        "theater_comedy",
        [
            ("v3-wrong-meeting", "Wrong Meeting", "Joined wrong video call five minutes"),
            ("v3-mute-fail", "Forgot Unmute", "Presented while muted"),
            ("v3-camera-on", "Camera On Fail", "Stood up while camera on"),
            ("v3-food-in-teeth", "Teeth Food", "Talked with food in teeth"),
            ("v3-waved-wrong", "Wrong Wave", "Waved at stranger enthusiastically"),
            ("v3-trip-public", "Public Trip", "Tripped in public gracefully"),
            ("v3-wrong-name-tag", "Name Tag", "Wore someone else's name tag"),
            ("v3-autocorrect-boss", "Boss Autocorrect", "Autocorrected boss name"),
            ("v3-halloween-work", "Halloween Work", "Wore costume to normal meeting"),
            ("v3-birthday-wrong-day", "Wrong Birthday", "Celebrated wrong birthday"),
            ("v3-dog-ate-homework", "Dog Ate It", "Blamed dog with proof"),
            ("v3-locked-bathroom", "Bathroom Lock", "Got stuck in bathroom stall"),
            ("v3-wrong-order-name", "Coffee Name", "Barista said wrong name proudly"),
            ("v3-selfie-stranger", "Stranger Photo", "Photo bombed own selfie with stranger"),
            ("v3-lost-remote", "Remote Lost", "Found remote in fridge"),
            ("v3-wrong-haircut-style", "Barber Gamble", "Asked barber to surprise you"),
            ("v3-ate-microwave", "Microwave Spoon", "Almost microwaved metal"),
            ("v3-wrong-parking", "Wrong Parking", "Pulled into wrong driveway"),
            ("v3-text-screenshot", "Screenshot Leak", "Screenshot included embarrassing bar"),
            ("v3-voice-text-fail", "Voice Text Fail", "Voice text said something wild"),
        ],
    ),
    (
        "creative",
        "crt",
        "brush",
        [
            ("v3-ink-comic", "Comic Page", "Published a comic page"),
            ("v3-pottery-sale", "Pottery Sale", "Sold pottery piece"),
            ("v3-beat-drop", "Beat Release", "Released an instrumental beat"),
            ("v3-cover-song", "Cover Song", "Published a cover performance"),
            ("v3-graffiti-legal", "Legal Mural Assist", "Assisted legal mural project"),
            ("v3-photo-print", "Photo Print Show", "Printed photos for show"),
            ("v3-screenplay", "Screenplay Draft", "Finished screenplay draft"),
            ("v3-story-public", "Story Published", "Published short story"),
            ("v3-ui-kit", "UI Kit Free", "Released free UI kit"),
            ("v3-crochet-gift", "Crochet Gift", "Crocheted gift collection"),
            ("v3-film-score", "Film Score", "Scored a short film"),
            ("v3-typography", "Type Specimen", "Published a typography specimen"),
            ("v3-motion-reel", "Motion Reel", "Published motion design reel"),
        ],
    ),
    (
        "life",
        "life",
        "explore",
        [
            ("v3-first-plant-kill", "Plant Redemption", "Revived a dying plant"),
            ("v3-birthday-surprise", "Surprise Party", "Pulled off surprise party"),
            ("v3-roadtrip-playlist", "Road Playlist", "Made legendary road playlist"),
            ("v3-thrift-wedding", "Thrift Fit", "Thrifted event outfit"),
            ("v3-learn-parent-recipe", "Parent Recipe", "Cooked parent recipe from memory"),
            ("v3-fix-appliance", "Appliance Fix", "Fixed appliance yourself"),
            ("v3-build-ikea-solo", "IKEA Solo", "Built IKEA furniture solo"),
            ("v3-mailbox-upgrade", "Mailbox Glow", "Upgraded curb appeal mailbox"),
            ("v3-balcony-lights", "Balcony Lights", "Strung balcony lights"),
            ("v3-rainy-walk", "Rain Walk", "Walked happily in rain"),
            ("v3-meteor-shower", "Meteor Night", "Watched meteor shower"),
            ("v3-local-tourist", "Local Tourist", "Tourist in own city for day"),
            ("v3-declutter-car", "Clean Car", "Deep cleaned car"),
            ("v3-friendship-bracelet", "Friend Bracelets", "Made friendship bracelets"),
            ("v3-voice-memo", "Voice Memo Diary", "Kept voice memo diary month"),
            ("v3-houseplant-wall", "Plant Wall", "Built an indoor plant wall"),
            ("v3-morning-routine", "Morning Routine", "Held morning routine sixty days"),
            ("v3-digital-photo-album", "Photo Album", "Built a curated digital album"),
            ("v3-neighbor-tool-lend", "Tool Lender", "Lent tools to neighbors regularly"),
            ("v3-weekend-unplug", "Weekend Unplug", "Unplugged full weekends a month"),
        ],
    ),
]


def existing_ids() -> set[str]:
    ids: set[str] = set()
    for path in EXISTING:
        if path.exists():
            ids.update(re.findall(r"id: '([^']+)'", path.read_text()))
    return ids


def main() -> None:
    ids = existing_ids()
    lines = [
        "import '../models/achievement.dart';",
        "",
        "/// Third-wave catalog seeds (v3 milestones).",
        "const List<Achievement> bulkAchievementSeedsV3 = [",
    ]
    added = 0
    for cat, prefix, icon, templates in WAVES:
        for i, (slug, title, desc) in enumerate(templates):
            aid = f"{prefix}-seed-{slug}"
            if aid in ids:
                continue
            xp = 35 + i * 12 + (25 if cat in ("finance", "travel") else 0)
            if cat == "funny":
                xp = 15 + i * 6
            lines.append("  Achievement(")
            lines.append(f"    id: '{aid}',")
            lines.append(f"    category: AchievementCategory.{cat},")
            lines.append(f"    title: '{title.replace(chr(39), chr(92) + chr(39))}',")
            lines.append(
                f"    description: '{desc.replace(chr(39), chr(92) + chr(39))}',"
            )
            lines.append(f"    xpValue: {xp},")
            if cat == "funny":
                lines.append("    isFunny: true,")
            lines.append(f"    icon: '{icon}',")
            lines.append("  ),")
            ids.add(aid)
            added += 1
    lines.append("];")
    lines.append("")
    OUT.write_text("\n".join(lines))
    print(f"Wrote {OUT.name} with {added} achievements")


if __name__ == "__main__":
    main()
