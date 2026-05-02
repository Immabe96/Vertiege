// Seed avatars
const AVATAR_1 = require('./avatar-1.png');
const AVATAR_2 = require('./avatar-2.png');
const AVATAR_3 = require('./avatar-3.png');
const AVATAR_MARCUS = require('./avatar-marcus.png');
const AVATAR_ALISTAIR = require('./avatar-alistair.png');
const AVATAR_ELENA = require('./avatar-elena.png');

export const SEED_AVATARS: Record<string, number> = {
  'seed-julian': AVATAR_1,
  'seed-clara': AVATAR_2,
  'seed-sora': AVATAR_3,
  'seed-marcus': AVATAR_MARCUS,
  'seed-alistair': AVATAR_ALISTAIR,
  'seed-elena': AVATAR_ELENA,
};

export const WORLD_IMAGES: Record<string, number> = {
  'neon-district': require('./world-neon-district.jpg'),
  'crystal-shore': require('./world-crystal-shore.jpg'),
  'azure-coast': require('./world-azure-coast.jpg'),
  'crimson-court': require('./world-crimson-court.jpg'),
  'sovereign-city': require('./world-sovereign-city.jpg'),
  'golden-estate': require('./world-golden-estate.jpg'),
  aetheria: require('./world-aetheria.jpg'),
  'nova-station': require('./world-nova-station.jpg'),
  'aviation-heights': require('./world-aviation-heights.jpg'),
  'medical-nexus': require('./world-medical-nexus.jpg'),
  'financial-district': require('./world-financial-district.jpg'),
  'tech-sprawl': require('./world-tech-sprawl.jpg'),
  'legal-plaza': require('./world-legal-plaza.jpg'),
  'arts-pavilion': require('./world-arts-pavilion.jpg'),
  'quantum-core': require('./world-quantum-core.jpg'),
  'silver-page': require('./world-silver-page.jpg'),
};

export const THEME_ASSETS: Record<string, number> = {
  splash: require('./bg-splash.jpg'),
  onboarding: require('./bg-onboarding.jpg'),
  emptyNotifications: require('./empty-notifications.jpg'),
};

export const ACHIEVEMENT_ICONS: Record<string, number> = {
  education: require('./ach-education.png'),
  career: require('./ach-career.png'),
  relationships: require('./ach-relationships.png'),
  health: require('./ach-health.png'),
  skills: require('./ach-skills.png'),
  travel: require('./ach-travel.png'),
  finance: require('./ach-finance.png'),
  community: require('./ach-community.png'),
  funny: require('./ach-funny.png'),
  creative: require('./ach-creative.png'),
};

export const BADGE_IMAGES: Record<string, number> = {
  'badge-marathon': require('./badge-marathon.png'),
  'badge-author': require('./badge-author.png'),
  'badge-founder': require('./badge-founder.png'),
  'badge-explorer': require('./badge-explorer.png'),
  'badge-debtfree': require('./badge-debtfree.png'),
  'badge-leader': require('./badge-leader.png'),
  'badge-polyglot': require('./badge-polyglot.png'),
  'badge-doctor': require('./badge-doctor.png'),
  'badge-engineer': require('./badge-engineer.png'),
  'badge-attorney': require('./badge-attorney.png'),
  'badge-finance': require('./badge-finance.png'),
  'badge-artist': require('./badge-artist.png'),
  'badge-pilot': require('./badge-pilot.png'),
};

export const PROFESSION_IMAGES: Record<string, number> = {
  Doctor: require('./prof-doctor.png'),
  Engineer: require('./prof-engineer.png'),
  Attorney: require('./prof-attorney.png'),
  Finance: require('./prof-finance.png'),
  Artist: require('./prof-artist.png'),
  Pilot: require('./prof-pilot.png'),
};

export const TIER_MEDALS: Record<string, number> = {
  Bronze: require('./tier-bronze.png'),
  Silver: require('./tier-silver.png'),
  Gold: require('./tier-gold.png'),
  Diamond: require('./tier-diamond.png'),
};
