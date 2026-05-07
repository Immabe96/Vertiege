import '../models/achievement.dart';
import '../models/resident.dart';

const Map<int, int> xpThresholds = {
  1: 0,
  2: 500,
  3: 2000,
  4: 10000,
  5: 50000,
};

ResidentTier getTierForXp(int totalXp) {
  if (totalXp >= 50000) return ResidentTier.apex;
  if (totalXp >= 10000) return ResidentTier.oldMoney;
  if (totalXp >= 2000) return ResidentTier.elite;
  if (totalXp >= 500) return ResidentTier.highRollers;
  return ResidentTier.hustlers;
}

const List<Achievement> achievements = [
  // Education (7)
  Achievement(id: 'edu-hs', category: AchievementCategory.education, title: 'High School Graduate', description: 'Graduated high school', xpValue: 50, icon: 'school'),
  Achievement(id: 'edu-college', category: AchievementCategory.education, title: 'College Graduate', description: 'Earned a bachelor\'s degree', xpValue: 200, icon: 'school'),
  Achievement(id: 'edu-masters', category: AchievementCategory.education, title: 'Master\'s Degree', description: 'Earned a master\'s degree', xpValue: 300, icon: 'school'),
  Achievement(id: 'edu-phd', category: AchievementCategory.education, title: 'Doctorate', description: 'Earned a PhD or equivalent', xpValue: 500, icon: 'school'),
  Achievement(id: 'edu-language', category: AchievementCategory.education, title: 'Bilingual', description: 'Learned a second language', xpValue: 100, icon: 'translate'),
  Achievement(id: 'edu-language2', category: AchievementCategory.education, title: 'Polyglot', description: 'Learned a third language', xpValue: 150, icon: 'translate'),
  Achievement(id: 'edu-cert', category: AchievementCategory.education, title: 'Certified', description: 'Earned a professional certification', xpValue: 100, icon: 'verified'),

  // Career (8)
  Achievement(id: 'car-first-job', category: AchievementCategory.career, title: 'First Job', description: 'Landed your first job', xpValue: 50, icon: 'work'),
  Achievement(id: 'car-promotion', category: AchievementCategory.career, title: 'Promotion', description: 'Got promoted', xpValue: 150, icon: 'trending_up'),
  Achievement(id: 'car-switch', category: AchievementCategory.career, title: 'Career Switch', description: 'Successfully switched careers', xpValue: 100, icon: 'swap_horiz'),
  Achievement(id: 'car-business', category: AchievementCategory.career, title: 'Business Owner', description: 'Started your own business', xpValue: 400, icon: 'store'),
  Achievement(id: 'car-f500', category: AchievementCategory.career, title: 'Fortune 500', description: 'Worked at a Fortune 500 company', xpValue: 200, icon: 'corporate_fare'),
  Achievement(id: 'car-raise', category: AchievementCategory.career, title: 'Big Raise', description: 'Received a significant salary increase', xpValue: 100, icon: 'payments'),
  Achievement(id: 'car-remote', category: AchievementCategory.career, title: 'Remote Worker', description: 'Landed a remote job', xpValue: 150, icon: 'home_work'),
  Achievement(id: 'car-retire', category: AchievementCategory.career, title: 'Early Retirement', description: 'Achieved financial independence', xpValue: 1000, icon: 'beach_access'),

  // Relationships (7)
  Achievement(id: 'rel-first-date', category: AchievementCategory.relationships, title: 'First Date', description: 'Went on a first date', xpValue: 30, icon: 'favorite'),
  Achievement(id: 'rel-1year', category: AchievementCategory.relationships, title: 'One Year Together', description: 'Celebrated one year together', xpValue: 100, icon: 'favorite'),
  Achievement(id: 'rel-5year', category: AchievementCategory.relationships, title: 'Five Years Strong', description: 'Celebrated five years together', xpValue: 300, icon: 'favorite'),
  Achievement(id: 'rel-marriage', category: AchievementCategory.relationships, title: 'Married', description: 'Got married', xpValue: 500, icon: 'ring_volume'),
  Achievement(id: 'rel-home', category: AchievementCategory.relationships, title: 'Homeowner', description: 'Bought a home together', xpValue: 400, icon: 'home'),
  Achievement(id: 'rel-child', category: AchievementCategory.relationships, title: 'Parent', description: 'Had a child', xpValue: 800, icon: 'child_care'),
  Achievement(id: 'rel-reconnect', category: AchievementCategory.relationships, title: 'Reconnected', description: 'Reconnected with an old friend', xpValue: 50, icon: 'people'),

  // Health (8)
  Achievement(id: 'health-5k', category: AchievementCategory.health, title: '5K Runner', description: 'Completed a 5K run', xpValue: 50, icon: 'directions_run'),
  Achievement(id: 'health-marathon', category: AchievementCategory.health, title: 'Marathon Finisher', description: 'Completed a marathon', xpValue: 300, icon: 'directions_run'),
  Achievement(id: 'health-weight', category: AchievementCategory.health, title: 'Goal Weight', description: 'Reached target weight', xpValue: 150, icon: 'monitor_weight'),
  Achievement(id: 'health-gym', category: AchievementCategory.health, title: 'Gym Rat', description: 'Worked out 100 times in a year', xpValue: 200, icon: 'fitness_center'),
  Achievement(id: 'health-swim', category: AchievementCategory.health, title: 'Swimmer', description: 'Learned to swim', xpValue: 80, icon: 'pool'),
  Achievement(id: 'health-tri', category: AchievementCategory.health, title: 'Triathlete', description: 'Completed a triathlon', xpValue: 400, icon: 'directions_bike'),
  Achievement(id: 'health-quit', category: AchievementCategory.health, title: 'Quit a Bad Habit', description: 'Overcame an unhealthy habit', xpValue: 250, icon: 'block'),
  Achievement(id: 'health-meditate', category: AchievementCategory.health, title: 'Zen Master', description: 'Meditated for 100 consecutive days', xpValue: 100, icon: 'self_improvement'),

  // Skills (7)
  Achievement(id: 'skill-code', category: AchievementCategory.skills, title: 'Coder', description: 'Learned to code', xpValue: 150, icon: 'code'),
  Achievement(id: 'skill-instrument', category: AchievementCategory.skills, title: 'Musician', description: 'Learned to play an instrument', xpValue: 100, icon: 'music_note'),
  Achievement(id: 'skill-cook', category: AchievementCategory.skills, title: 'Chef', description: 'Learned to cook 10 dishes', xpValue: 50, icon: 'restaurant'),
  Achievement(id: 'skill-license', category: AchievementCategory.skills, title: 'Licensed Driver', description: 'Got a driver\'s license', xpValue: 80, icon: 'directions_car'),
  Achievement(id: 'skill-surf', category: AchievementCategory.skills, title: 'Surfer', description: 'Learned to surf', xpValue: 120, icon: 'surfing'),
  Achievement(id: 'skill-speak', category: AchievementCategory.skills, title: 'Public Speaker', description: 'Gave a talk to 100+ people', xpValue: 100, icon: 'mic'),
  Achievement(id: 'skill-build', category: AchievementCategory.skills, title: 'Builder', description: 'Built something with your hands', xpValue: 200, icon: 'construction'),

  // Travel (6)
  Achievement(id: 'trv-country', category: AchievementCategory.travel, title: 'World Traveler', description: 'Visited a new country', xpValue: 100, icon: 'flight'),
  Achievement(id: 'trv-solo', category: AchievementCategory.travel, title: 'Solo Traveler', description: 'Traveled solo', xpValue: 200, icon: 'flight_takeoff'),
  Achievement(id: 'trv-abroad', category: AchievementCategory.travel, title: 'Lived Abroad', description: 'Lived in another country', xpValue: 500, icon: 'public'),
  Achievement(id: 'trv-7continents', category: AchievementCategory.travel, title: 'All 7 Continents', description: 'Visited all seven continents', xpValue: 1000, icon: 'language'),
  Achievement(id: 'trv-roadtrip', category: AchievementCategory.travel, title: 'Road Trip', description: 'Completed a cross-country road trip', xpValue: 200, icon: 'directions_car'),
  Achievement(id: 'trv-5star', category: AchievementCategory.travel, title: 'Luxury Traveler', description: 'Stayed at a 5-star resort', xpValue: 80, icon: 'star'),

  // Finance (6)
  Achievement(id: 'fin-save1k', category: AchievementCategory.finance, title: 'Saver', description: 'Saved first \$1,000', xpValue: 30, icon: 'savings'),
  Achievement(id: 'fin-invest', category: AchievementCategory.finance, title: 'Investor', description: 'Made first investment', xpValue: 100, icon: 'trending_up'),
  Achievement(id: 'fin-car', category: AchievementCategory.finance, title: 'Car Owner', description: 'Bought a car outright', xpValue: 200, icon: 'directions_car'),
  Achievement(id: 'fin-home', category: AchievementCategory.finance, title: 'Homeowner', description: 'Bought a home', xpValue: 1000, icon: 'home'),
  Achievement(id: 'fin-emergency', category: AchievementCategory.finance, title: 'Emergency Fund', description: 'Built a 6-month emergency fund', xpValue: 100, icon: 'shield'),
  Achievement(id: 'fin-debtfree', category: AchievementCategory.finance, title: 'Debt Free', description: 'Paid off all debt', xpValue: 500, icon: 'check_circle'),

  // Community (5)
  Achievement(id: 'com-volunteer', category: AchievementCategory.community, title: 'Volunteer', description: 'Volunteered 50+ hours', xpValue: 100, icon: 'volunteer_activism'),
  Achievement(id: 'com-blood', category: AchievementCategory.community, title: 'Blood Donor', description: 'Donated blood', xpValue: 75, icon: 'bloodtype'),
  Achievement(id: 'com-mentor', category: AchievementCategory.community, title: 'Mentor', description: 'Mentored someone for 6+ months', xpValue: 200, icon: 'diversity_3'),
  Achievement(id: 'com-tree', category: AchievementCategory.community, title: 'Tree Planter', description: 'Planted 10+ trees', xpValue: 50, icon: 'forest'),
  Achievement(id: 'com-event', category: AchievementCategory.community, title: 'Event Organizer', description: 'Organized a community event', xpValue: 300, icon: 'event'),

  // Funny (10)
  Achievement(id: 'fun-allnighter', category: AchievementCategory.funny, title: 'All-Nighter', description: 'Pulled an all-nighter for fun', xpValue: 10, isFunny: true, icon: 'nightlight'),
  Achievement(id: 'fun-reunion', category: AchievementCategory.funny, title: 'High School Reunion', description: 'Attended a high school reunion', xpValue: 20, isFunny: true, icon: 'groups'),
  Achievement(id: 'fun-pizza', category: AchievementCategory.funny, title: 'Pizza Champion', description: 'Ate an entire pizza alone', xpValue: 15, isFunny: true, icon: 'local_pizza'),
  Achievement(id: 'fun-lego', category: AchievementCategory.funny, title: 'Lego Builder', description: 'Built a 1000+ piece Lego set', xpValue: 50, isFunny: true, icon: 'toys'),
  Achievement(id: 'fun-cat', category: AchievementCategory.funny, title: 'Cat Person', description: 'Adopted a cat', xpValue: 25, isFunny: true, icon: 'pets'),
  Achievement(id: 'fun-hold', category: AchievementCategory.funny, title: 'Hold Music Survivor', description: 'Survived 30+ minutes on hold', xpValue: 20, isFunny: true, icon: 'phone_in_talk'),
  Achievement(id: 'fun-binge', category: AchievementCategory.funny, title: 'Binge Watcher', description: 'Watched an entire series in one weekend', xpValue: 30, isFunny: true, icon: 'tv'),
  Achievement(id: 'fun-edible', category: AchievementCategory.funny, title: 'Mystery Food', description: 'Ate something without asking what it was', xpValue: 20, isFunny: true, icon: 'question_mark'),
  Achievement(id: 'fun-pet', category: AchievementCategory.funny, title: 'Pet Whisperer', description: 'Taught a pet a trick', xpValue: 15, isFunny: true, icon: 'pets'),
  Achievement(id: 'fun-ikea', category: AchievementCategory.funny, title: 'IKEA Survivor', description: 'Assembled IKEA furniture without arguing', xpValue: 40, isFunny: true, icon: 'chair'),

  // Creative (5)
  Achievement(id: 'cre-book', category: AchievementCategory.creative, title: 'Author', description: 'Wrote a book', xpValue: 500, icon: 'menu_book'),
  Achievement(id: 'cre-art', category: AchievementCategory.creative, title: 'Artist', description: 'Created and sold artwork', xpValue: 100, icon: 'palette'),
  Achievement(id: 'cre-song', category: AchievementCategory.creative, title: 'Songwriter', description: 'Wrote and recorded a song', xpValue: 200, icon: 'lyrics'),
  Achievement(id: 'cre-yt', category: AchievementCategory.creative, title: 'YouTuber', description: 'Reached 1,000 subscribers', xpValue: 150, icon: 'play_circle'),
  Achievement(id: 'cre-perform', category: AchievementCategory.creative, title: 'Performer', description: 'Performed on stage', xpValue: 300, icon: 'theater_comedy'),

  // In-App / Platform (10)
  Achievement(id: 'pioneer-poster', category: AchievementCategory.inApp, title: 'Pioneer Poster', description: 'Published your first post', xpValue: 10, icon: 'edit_note'),
  Achievement(id: 'voice-of-realm', category: AchievementCategory.inApp, title: 'Voice of the Realm', description: 'Published 10 posts', xpValue: 50, icon: 'record_voice_over'),
  Achievement(id: 'chronicler', category: AchievementCategory.inApp, title: 'Chronicler', description: 'Published 50 posts', xpValue: 150, icon: 'history_edu'),
  Achievement(id: 'nexus-scribe', category: AchievementCategory.inApp, title: 'Nexus Scribe', description: 'Published 100 posts', xpValue: 300, icon: 'auto_stories'),
  Achievement(id: 'explorer', category: AchievementCategory.inApp, title: 'Explorer', description: 'Joined your first world', xpValue: 20, icon: 'explore'),
  Achievement(id: 'wayfarer', category: AchievementCategory.inApp, title: 'Wayfarer', description: 'Joined 3 worlds', xpValue: 60, icon: 'hiking'),
  Achievement(id: 'realm-wanderer', category: AchievementCategory.inApp, title: 'Realm Wanderer', description: 'Joined 5 worlds', xpValue: 150, icon: 'terrain'),
  Achievement(id: 'streak-3', category: AchievementCategory.inApp, title: 'Kindling', description: '3-day check-in streak', xpValue: 10, icon: 'local_fire_department'),
  Achievement(id: 'week-warrior', category: AchievementCategory.inApp, title: 'Week Warrior', description: '7-day check-in streak', xpValue: 50, icon: 'calendar_view_week'),
  Achievement(id: 'streak-14', category: AchievementCategory.inApp, title: 'Fortnight Flame', description: '14-day check-in streak', xpValue: 100, icon: 'whatshot'),
  Achievement(id: 'month-master', category: AchievementCategory.inApp, title: 'Month Master', description: '30-day check-in streak', xpValue: 200, icon: 'calendar_month'),
  Achievement(id: 'streak-60', category: AchievementCategory.inApp, title: 'Dual Moon', description: '60-day check-in streak', xpValue: 500, icon: 'nights_stay'),
  Achievement(id: 'season-sage', category: AchievementCategory.inApp, title: 'Season Sage', description: '90-day check-in streak', xpValue: 1000, icon: 'wb_sunny'),
  Achievement(id: 'streak-180', category: AchievementCategory.inApp, title: 'Half-Year Pyre', description: '180-day check-in streak', xpValue: 2500, icon: 'flood'),
  Achievement(id: 'streak-365', category: AchievementCategory.inApp, title: 'Realm Elder', description: '365-day check-in streak', xpValue: 5000, icon: 'auto_awesome'),

  // Profession badges (6)
  Achievement(id: 'prof-doctor', category: AchievementCategory.profession, title: 'Verified Doctor', description: 'Verified medical professional', xpValue: 200, icon: 'local_hospital'),
  Achievement(id: 'prof-engineer', category: AchievementCategory.profession, title: 'Verified Engineer', description: 'Verified engineering professional', xpValue: 200, icon: 'engineering'),
  Achievement(id: 'prof-attorney', category: AchievementCategory.profession, title: 'Verified Attorney', description: 'Verified legal professional', xpValue: 200, icon: 'gavel'),
  Achievement(id: 'prof-finance', category: AchievementCategory.profession, title: 'Verified Financier', description: 'Verified finance professional', xpValue: 200, icon: 'account_balance'),
  Achievement(id: 'prof-artist', category: AchievementCategory.profession, title: 'Verified Artist', description: 'Verified creative professional', xpValue: 200, icon: 'brush'),
  Achievement(id: 'prof-pilot', category: AchievementCategory.profession, title: 'Verified Pilot', description: 'Verified aviation professional', xpValue: 200, icon: 'flight'),
];

const Map<String, String> professionToAchievementId = {
  'Medical': 'prof-doctor',
  'Aviation': 'prof-pilot',
  'Finance': 'prof-finance',
  'Legal': 'prof-attorney',
  'Engineering': 'prof-engineer',
  'Technology': 'prof-engineer',
  'Arts': 'prof-artist',
};
