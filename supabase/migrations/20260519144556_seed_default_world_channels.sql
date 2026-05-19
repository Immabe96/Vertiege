-- Seed durable starter channels for every built-in world.
-- Idempotent for existing projects and compatible with the current app model.

ALTER TABLE public.channels
  ADD COLUMN IF NOT EXISTS foundation_markdown TEXT,
  ADD COLUMN IF NOT EXISTS foundation_version TEXT NOT NULL DEFAULT 'v1';

UPDATE public.worlds
SET is_default = slug IN ('neon-district', 'crystal-shore')
WHERE slug IN ('neon-district', 'crystal-shore');

WITH world_foundations(slug, info_md, rules_md, roles_md) AS (
  VALUES
    ('neon-district',
     '## Neon District\n\nWelcome to the entry realm for ambitious residents. Share first posts, meet crews, and learn how Vertiege worlds work before branching into higher-prestige spaces.',
     '## Neon District Rules\n\nKeep introductions welcoming, avoid spam or pressure tactics, and help newcomers find the right channel. Challenges are fine; harassment and status baiting are not.',
     '## Neon District Roles\n\nNewcomers start as Residents. Guides help first-time posters, Scouts surface useful worlds, and Wardens keep the starter experience clean.'),
    ('crystal-shore',
     '## Crystal Shore\n\nA calm newcomer coast for low-pressure introductions, exploration notes, and reflective conversation. This is the soft landing for residents who want slower discovery.',
     '## Crystal Shore Rules\n\nBe patient, credit inspiration, avoid aggressive recruiting, and keep critique gentle unless someone asks for depth.',
     '## Crystal Shore Roles\n\nResidents explore at their pace. Tidekeepers welcome new people, Cartographers collect discoveries, and Stewards protect the peaceful tone.'),
    ('azure-coast',
     '## Azure Coast\n\nA high-roller coastal economy for luxury culture, trading etiquette, and reputation-aware deals.',
     '## Azure Coast Rules\n\nNo scams, fake guarantees, or pressure sales. Disclose conflicts, respect deal boundaries, and keep negotiation records clear.',
     '## Azure Coast Roles\n\nBrokers discuss opportunities, Curators spotlight premium finds, and Harbor Masters moderate trade conduct.'),
    ('crimson-court',
     '## Crimson Court\n\nA realm of social intrigue, alliances, reputation, and careful public moves.',
     '## Crimson Court Rules\n\nPlay the social game without doxxing, threats, brigading, or real-world harassment. Keep rivalries fictional and consent-based.',
     '## Crimson Court Roles\n\nCourtiers build alliances, Envoys coordinate diplomacy, and Regents enforce reputation boundaries.'),
    ('sovereign-city',
     '## Sovereign City\n\nAn elite civic realm for governance, influence, policy debates, and formal proposals.',
     '## Sovereign City Rules\n\nDebate policy, not people. Cite claims, avoid vote manipulation, and keep civic conduct formal.',
     '## Sovereign City Roles\n\nCitizens propose ideas, Councillors review initiatives, and Chancellors guide governance process.'),
    ('golden-estate',
     '## Golden Estate\n\nAn old-money legacy world centered on patronage, stewardship, collections, and long-term reputation.',
     '## Golden Estate Rules\n\nRespect provenance, avoid flex spam, credit collaborators, and treat patronage as stewardship rather than entitlement.',
     '## Golden Estate Roles\n\nPatrons support projects, Archivists preserve history, and Stewards maintain estate etiquette.'),
    ('aetheria',
     '## Aetheria\n\nA mythic apex realm for legends, ceremonial achievements, and high-prestige worldbuilding.',
     '## Aetheria Rules\n\nKeep ceremonies meaningful, avoid impersonation, and reserve mythic claims for earned or clearly fictional context.',
     '## Aetheria Roles\n\nLorekeepers maintain canon, Oracles guide rituals, and Ascendants represent top-tier achievement.'),
    ('nova-station',
     '## Nova Station\n\nA frontier space outpost for missions, exploration logs, crew coordination, and new discoveries.',
     '## Nova Station Rules\n\nKeep mission briefs clear, mark speculation, and prioritize crew safety and coordination in collaborative threads.',
     '## Nova Station Roles\n\nCadets join missions, Navigators map routes, Engineers solve systems, and Captains coordinate crews.'),
    ('aviation-heights',
     '## Aviation Heights\n\nA pilots and aerospace realm for flight culture, safety-first discussion, and squadron coordination.',
     '## Aviation Heights Rules\n\nSafety comes first. No reckless advice, illegal flight guidance, or unverified technical claims presented as fact.',
     '## Aviation Heights Roles\n\nPilots share experience, Ground Crew support logistics, Instructors teach basics, and Marshals enforce safety norms.'),
    ('medical-nexus',
     '## Medical Nexus\n\nA healthcare knowledge realm for clinical discussion, health systems, research literacy, and professional support.',
     '## Medical Nexus Rules\n\nNo diagnosis guarantees or unsafe medical advice. Encourage qualified care, cite credible sources, and protect privacy.',
     '## Medical Nexus Roles\n\nClinicians add field context, Researchers review evidence, Advocates support patients, and Moderators remove unsafe claims.'),
    ('financial-district',
     '## Financial District\n\nA capital and markets world for analysis, business models, and economic discussion.',
     '## Financial District Rules\n\nNo scams, pump groups, or personalized financial advice. Label speculation, disclose conflicts, and cite data when possible.',
     '## Financial District Roles\n\nAnalysts share research, Builders discuss ventures, Auditors challenge assumptions, and Marshals watch for fraud.'),
    ('tech-sprawl',
     '## Tech Sprawl\n\nA builder realm for code, product, systems, AI, and practical engineering craft.',
     '## Tech Sprawl Rules\n\nNo exploit sharing for harm, credential leaks, or unsupported vendor claims. Keep critique technical and useful.',
     '## Tech Sprawl Roles\n\nBuilders ship work, Reviewers improve designs, Architects map systems, and Operators keep projects running.'),
    ('legal-plaza',
     '## Legal Plaza\n\nA law and civic debate realm for legal literacy, policy, contracts, and public reasoning.',
     '## Legal Plaza Rules\n\nDo not present discussion as guaranteed legal advice. Cite jurisdictions, avoid confidential details, and stay civil.',
     '## Legal Plaza Roles\n\nAdvocates explain arguments, Clerks organize references, Mediators cool disputes, and Stewards enforce boundaries.'),
    ('arts-pavilion',
     '## Arts Pavilion\n\nA creative realm for critique, showcases, process notes, and artistic collaboration.',
     '## Arts Pavilion Rules\n\nCredit sources, respect commissions and licenses, ask before heavy critique, and do not pass others work off as your own.',
     '## Arts Pavilion Roles\n\nCreators share work, Curators collect themes, Critics offer thoughtful feedback, and Patrons support projects.'),
    ('quantum-core',
     '## Quantum Core\n\nA research and engineering lab for experimental rigor, deep systems, and frontier technical ideas.',
     '## Quantum Core Rules\n\nSeparate evidence from hypothesis, show methods, avoid hype-as-proof, and keep lab debate precise.',
     '## Quantum Core Roles\n\nResearchers test ideas, Engineers prototype, Reviewers challenge claims, and Lab Leads coordinate investigations.'),
    ('silver-page',
     '## Silver Page\n\nA writing and storytelling realm for drafts, lore, critique circles, and editorial craft.',
     '## Silver Page Rules\n\nRespect authorship, mark spoilers, ask before line edits, and make critique specific enough to help the writer revise.',
     '## Silver Page Roles\n\nWriters draft, Editors refine, Lorekeepers track canon, and Readers offer response notes.')
),
channel_seed(name, description, channel_type, position) AS (
  VALUES
    ('info', 'Start here for this world purpose, culture, and key links.', 'announcement', 0),
    ('rules', 'Standards, boundaries, and moderation expectations.', 'announcement', 1),
    ('roles', 'Rank, role, and permission guidance for residents.', 'announcement', 2),
    ('general', 'General discussion for all residents.', 'text', 3)
),
expanded AS (
  SELECT
    w.id AS world_id,
    w.slug,
    cs.name,
    cs.description,
    cs.channel_type,
    cs.position,
    CASE cs.name
      WHEN 'info' THEN wf.info_md
      WHEN 'rules' THEN wf.rules_md
      WHEN 'roles' THEN wf.roles_md
      ELSE ''
    END AS foundation_markdown
  FROM public.worlds w
  JOIN world_foundations wf ON wf.slug = w.slug
  CROSS JOIN channel_seed cs
)
INSERT INTO public.channels (
  id,
  world_id,
  name,
  description,
  channel_type,
  position,
  is_default,
  foundation_markdown,
  foundation_version
)
SELECT
  world_id || '-' || name,
  world_id,
  name,
  description,
  channel_type,
  position,
  true,
  foundation_markdown,
  'v1'
FROM expanded
ON CONFLICT (id) DO UPDATE SET
  description = EXCLUDED.description,
  channel_type = EXCLUDED.channel_type,
  position = EXCLUDED.position,
  is_default = EXCLUDED.is_default,
  foundation_markdown = EXCLUDED.foundation_markdown,
  foundation_version = EXCLUDED.foundation_version;

CREATE INDEX IF NOT EXISTS idx_channels_world_default_name
  ON public.channels(world_id, is_default, name);
