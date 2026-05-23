import '../config/tiers.dart';
import '../models/world.dart';

class WorldFoundation {
  final String premise;
  final List<String> focus;
  final List<String> culture;
  final String entryPrompt;
  final String? safetyDisclaimer;

  const WorldFoundation({
    required this.premise,
    required this.focus,
    required this.culture,
    this.entryPrompt =
        'Introduce yourself with what you are building, learning, or looking for.',
    this.safetyDisclaimer,
  });
}

WorldFoundation foundationForWorld(World world) {
  final key = world.slug.isNotEmpty ? world.slug : world.id;
  return _foundations[key] ??
      WorldFoundation(
        premise:
            '${world.name} is a resident-led dominion shaped by its sovereign and active members.',
        focus: const [
          'Establish the world purpose before promoting it.',
          'Use roles to make expectations visible.',
          'Move casual conversation to #general once the foundation is clear.',
        ],
        culture: const [
          'Default to useful context.',
          'Reward residents who build repeatable value.',
          'Keep rules explicit and moderation predictable.',
        ],
        entryPrompt:
            'Introduce yourself with the world you want to build and the kind of residents who should join you.',
      );
}

List<({String title, String description, String channel})>
orientationStepsForWorld(World world) {
  final foundation = foundationForWorld(world);
  return [
    (
      title: 'Read the charter',
      description: 'Start with the world premise, focus, and culture.',
      channel: 'info',
    ),
    (
      title: 'Learn the standard',
      description: 'Review rules before posting or inviting others.',
      channel: 'rules',
    ),
    (
      title: 'Know your standing',
      description: 'Understand roles, council expectations, and progression.',
      channel: 'roles',
    ),
    (
      title: 'Enter the room',
      description: foundation.entryPrompt,
      channel: 'general',
    ),
  ];
}

String foundationMarkdownForChannel({
  required World world,
  required String channelName,
}) {
  final normalized = channelName.toLowerCase();
  final foundation = foundationForWorld(world);
  return switch (normalized) {
    'info' => _infoMarkdown(world, foundation),
    'rules' => _rulesMarkdown(world, foundation),
    'roles' => _rolesMarkdown(world),
    _ => '',
  };
}

String _infoMarkdown(World world, WorldFoundation foundation) {
  final access = world.requiredProfession != null
      ? 'Verified ${world.requiredProfession} residents'
      : 'Tier ${world.requiredTier} ${tierNames[world.requiredTier] ?? 'residents'}';
  final focus = foundation.focus.map((item) => '- $item').join('\n');
  final culture = foundation.culture.map((item) => '- $item').join('\n');

  return '''
## ${world.name}

${foundation.premise}

**Access:** $access  
**Sovereign:** ${world.sovereignName}  
**Prestige:** ${world.prestige}

### What Belongs Here
$focus

### Culture
$culture

### First Steps
- Read #rules before posting.
- Check #roles to understand standing and permissions.
- Open #general when you are ready to participate.

### First Post Prompt
${foundation.entryPrompt}
''';
}

String _rulesMarkdown(World world, WorldFoundation foundation) {
  final disclaimer = foundation.safetyDisclaimer;
  final disclaimerBlock = disclaimer != null
      ? '\n### 7. Safety Disclaimer\n$disclaimer\n'
      : '';
  return '''
## ${world.name} Rules

### 1. Bring Signal
Post with context, evidence, examples, or a clear ask. Low-effort flexing, spam, and vague bait lower the quality of the world.

### 2. Respect the Gate
Do not coach people around tier, profession, payment, or verification gates. Access is part of the world structure.

### 3. Keep Claims Accountable
If you make a professional, financial, medical, legal, or technical claim, label uncertainty and avoid pretending opinion is proof.

### 4. Protect Residents
No harassment, doxxing, hate, sexual exploitation, threats, or targeted humiliation. Report issues instead of escalating them.

### 5. Use the Right Room
Use #info for orientation, #roles for standing and permissions, and #general for live discussion. Sovereigns may add specialized rooms over time.

### 6. Council Standard
Council and sovereign actions should be visible, consistent, and boringly fair. Moderation exists to protect the world, not personal status.
$disclaimerBlock''';
}

String _rolesMarkdown(World world) {
  return '''
## Roles and Standing

Standing is earned inside each world through useful participation. Higher standing unlocks more responsibility.

### Visitor
- Can read the world and learn the standards.
- Best first move: understand the culture before posting.

### Member
- Can participate in normal discussion.
- Expected to be respectful, specific, and on-topic.

### Contributor
- Trusted to add richer material such as images, polls, and deeper posts.
- Expected to help newcomers understand the world.

### Veteran
- Recognized regular with stronger local reputation.
- Helps keep #general useful and points people toward the right rooms.

### Elder
- Unlocks vault-level participation when the world supports it.
- Expected to preserve institutional memory and raise the quality bar.

### Patron
- Trusted enough for invite-level responsibility.
- Should bring in residents who match the world culture, not just friends.

### Council
- Governance tier. Can help moderate, pin important material, and protect the world standard.
- Should explain decisions clearly and avoid private favoritism.

### Sovereign
- Founder or elected leader of the world.
- Owns the foundation: channels, rules, role design, and long-term direction.

### This World's Gate
${world.requiredProfession != null ? '- Profession gate: ${world.requiredProfession} verification.' : '- Wealth tier gate: Tier ${world.requiredTier} ${tierNames[world.requiredTier] ?? ''}.'}
- Prestige: ${world.prestige}
- Sovereign: ${world.sovereignName}
''';
}

const _foundations = <String, WorldFoundation>{
  'neon-district': WorldFoundation(
    premise:
        'Neon District is the on-ramp: fast experiments, first wins, useful hustle, and public momentum.',
    focus: [
      'Early-stage money moves, tools, offers, and execution logs.',
      'Practical advice for residents climbing from idea to traction.',
      'Fast feedback without pretending every shortcut is wisdom.',
    ],
    culture: [
      'Move quickly, but show receipts.',
      'Respect beginners who are doing the work.',
      'No fake guru energy.',
    ],
    entryPrompt:
        'Share your current hustle, the next measurable milestone, and one useful lesson you can offer.',
  ),
  'crystal-shore': WorldFoundation(
    premise:
        'Crystal Shore is the calmer beginner wealth world: fundamentals, habits, and clean starts.',
    focus: [
      'Budgeting, savings, first investments, and financial clarity.',
      'Beginner questions answered without status games.',
      'Repeatable habits over dramatic wins.',
    ],
    culture: [
      'Clarity beats hype.',
      'Teach the step you actually know.',
      'Small progress still counts.',
    ],
    entryPrompt:
        'Share the financial habit you are improving and the next small win you are working toward.',
  ),
  'azure-coast': WorldFoundation(
    premise:
        'Azure Coast is for High Rollers refining taste, leverage, and opportunity selection.',
    focus: [
      'Deal flow, capital allocation, luxury operations, and network leverage.',
      'Better questions around risk, timing, and reputation.',
      'Signals that separate quality from noise.',
    ],
    culture: [
      'Calm confidence over loud proof.',
      'Discuss risk before upside.',
      'Protect reputation like capital.',
    ],
    entryPrompt:
        'Share an opportunity you are studying, the risk you see, and the signal you want from others.',
  ),
  'crimson-court': WorldFoundation(
    premise:
        'Crimson Court is a velvet room for strategy, negotiation, and high-context social leverage.',
    focus: [
      'Influence, negotiation, status dynamics, and private-market etiquette.',
      'Case studies of strategy without exposing private people.',
      'Reading rooms, incentives, and second-order effects.',
    ],
    culture: [
      'Discretion is status.',
      'Sharp analysis, no cheap cruelty.',
      'Make power legible without worshiping it.',
    ],
    entryPrompt:
        'Share a strategic question, negotiation lesson, or room-reading insight without exposing private people.',
  ),
  'sovereign-city': WorldFoundation(
    premise:
        'Sovereign City is the capital layer: leadership, systems, ownership, and durable institutions.',
    focus: [
      'Operating companies, teams, governance, and strategic decision-making.',
      'How elite residents build systems that outlive effort.',
      'Leadership lessons with clear tradeoffs.',
    ],
    culture: [
      'Think in systems.',
      'Respect operators over commentators.',
      'Make decisions inspectable.',
    ],
    entryPrompt:
        'Share the system you are building, leading, or trying to repair.',
  ),
  'golden-estate': WorldFoundation(
    premise:
        'Golden Estate is for stewardship: legacy, preservation, family offices, and long-horizon wealth.',
    focus: [
      'Estate thinking, preservation, philanthropy, and patient capital.',
      'Lifestyle systems that protect focus and privacy.',
      'Lessons from long-term compounding.',
    ],
    culture: [
      'Long term is the house style.',
      'Elegance means restraint.',
      'Privacy and trust come first.',
    ],
    entryPrompt:
        'Share a long-horizon principle, stewardship question, or compounding lesson.',
  ),
  'aetheria': WorldFoundation(
    premise:
        'Aetheria is the apex mythic realm: rare access, big vision, and the architecture of legacy.',
    focus: [
      'Category-defining work, civilization-scale ideas, and apex networks.',
      'Reflections from residents with unusual leverage.',
      'The cost, duty, and design of being at the top.',
    ],
    culture: [
      'Myth is earned through substance.',
      'No smallness disguised as critique.',
      'Leave things better than you found them.',
    ],
    entryPrompt:
        'Share the legacy-scale problem, idea, or obligation currently occupying your attention.',
  ),
  'nova-station': WorldFoundation(
    premise:
        'Nova Station is the frontier wealth world: exploration, asymmetric bets, and high-conviction futures.',
    focus: [
      'Frontier markets, space, deep tech, and high-risk/high-reward thinking.',
      'Scenario planning and asymmetric opportunity maps.',
      'How to stay sane while operating near uncertainty.',
    ],
    culture: [
      'Speculate clearly.',
      'Separate vision from delusion.',
      'Respect builders at the edge.',
    ],
    entryPrompt:
        'Share a frontier thesis, why it might fail, and what evidence would change your mind.',
  ),
  'aviation-heights': WorldFoundation(
    premise:
        'Aviation Heights is for pilots, aerospace builders, and people who understand disciplined risk.',
    focus: [
      'Flight operations, aerospace innovation, safety culture, and career paths.',
      'Lessons from checklists, systems, and crew resource management.',
      'Professional questions from verified aviation residents.',
    ],
    culture: [
      'Safety is competence.',
      'Precision matters.',
      'Debrief without ego.',
    ],
    entryPrompt:
        'Share your aviation context, a safety lesson, or a technical question with enough detail to debrief.',
    safetyDisclaimer:
        'Aviation Heights is for peer learning and simulation-style discussion—not flight instruction, operator procedures, or authority requirements. Treat posts as conversation starters; confirm anything operational with your CFI, company manuals, and regulator.',
  ),
  'medical-nexus': WorldFoundation(
    premise:
        'Medical Nexus is a professional world for healthcare craft, ethics, and clinical excellence.',
    focus: [
      'Clinical learning, healthcare systems, research, and professional growth.',
      'Clear disclaimers when discussing medical topics.',
      'Support for verified practitioners without patient-identifying details.',
    ],
    culture: [
      'Protect patients first.',
      'Evidence beats ego.',
      'Compassion and rigor belong together.',
    ],
    entryPrompt:
        'Share your healthcare lane, a systems observation, or a learning question without patient-identifying details.',
    safetyDisclaimer:
        'Medical Nexus is educational peer discussion, not diagnosis or treatment. Do not post identifiable patient details. For your own care, work with a licensed clinician; treat channel posts as a fictional learning space, not clinical guidance.',
  ),
  'financial-district': WorldFoundation(
    premise:
        'Financial District is for capital markets, analysis, and disciplined financial operators.',
    focus: [
      'Markets, banking, private equity, portfolio thinking, and risk.',
      'Thesis-driven analysis with assumptions visible.',
      'Career and execution lessons from finance professionals.',
    ],
    culture: [
      'Show the model behind the opinion.',
      'Respect risk.',
      'No pump-and-dump behavior.',
    ],
    entryPrompt:
        'Share a market, deal, or finance question with your assumptions and risk view.',
    safetyDisclaimer:
        'Financial District is for markets discussion and role-play analysis—not investment, tax, or personalized advice. Past results and hot takes are not guarantees. Verify assumptions yourself and use licensed professionals before real money or filings.',
  ),
  'tech-sprawl': WorldFoundation(
    premise:
        'Tech Sprawl is a dense builder world for software, startups, systems, and product judgment.',
    focus: [
      'Engineering craft, product thinking, AI, infrastructure, and startup execution.',
      'Build logs, architecture reviews, and practical debugging.',
      'Career leverage for serious technologists.',
    ],
    culture: [
      'Ship and explain.',
      'Prefer working demos over manifestos.',
      'Be kind to beginners and ruthless with vague thinking.',
    ],
    entryPrompt:
        'Share what you are building, the hard technical tradeoff, and what feedback would help.',
  ),
  'legal-plaza': WorldFoundation(
    premise:
        'Legal Plaza is for legal professionals discussing judgment, precedent, and institutional design.',
    focus: [
      'Legal craft, career paths, regulation, negotiation, and ethics.',
      'General education, not personalized legal advice.',
      'How law shapes business, society, and power.',
    ],
    culture: [
      'Precision over performance.',
      'Cite jurisdiction and uncertainty.',
      'Professional restraint is valued.',
    ],
    entryPrompt:
        'Share your legal context, jurisdiction if relevant, and the general principle you want to discuss.',
    safetyDisclaimer:
        'Legal Plaza covers general legal education and professional debate—not advice for your situation. Rules and ethics differ by jurisdiction. Treat posts as simulation; retain counsel before acting on anything discussed here.',
  ),
  'arts-pavilion': WorldFoundation(
    premise:
        'Arts Pavilion is a creative world for taste, craft, critique, and making work that lasts.',
    focus: [
      'Creative process, portfolio growth, art markets, and collaboration.',
      'Constructive critique with respect for the artist.',
      'The business and discipline behind beauty.',
    ],
    culture: [
      'Taste is trained.',
      'Critique the work, not the person.',
      'Make beauty practical.',
    ],
    entryPrompt:
        'Share what you are making, the kind of critique you want, and one influence behind the work.',
  ),
  'quantum-core': WorldFoundation(
    premise:
        'Quantum Core is for engineers and frontier technical thinkers solving hard systems problems.',
    focus: [
      'Engineering, quantum concepts, hardware, research, and technical rigor.',
      'Deep questions with enough context for useful answers.',
      'Bridging theory, experiments, and real-world constraints.',
    ],
    culture: [
      'State assumptions.',
      'Respect complexity.',
      'Good explanations are engineering work.',
    ],
    entryPrompt:
        'Share the technical problem, your current model, and where the uncertainty lives.',
    safetyDisclaimer:
        'Quantum Core is technical discussion and thought experiments—not certified design review or safety approval. Validate models, codes, and test data with qualified engineers and applicable standards before building or deploying for real.',
  ),
  'silver-page': WorldFoundation(
    premise:
        'Silver Page is the quieter world for writers, storytellers, editors, and language craft.',
    focus: [
      'Writing practice, publishing, narrative design, and creative discipline.',
      'Excerpts, feedback requests, and process notes.',
      'Turning vague taste into precise revision.',
    ],
    culture: [
      'Read generously.',
      'Edit specifically.',
      'Protect the quiet needed to make things.',
    ],
    entryPrompt:
        'Share what you are writing, the reader effect you want, and the feedback you are ready for.',
  ),
};

/// Maps Gate interests to recommended world slugs
String? matchWorldSlugForInterest(String interestName) {
  return switch (interestName) {
    'execute' => 'neon-district',
    'foundation' => 'crystal-shore',
    'craft' => 'tech-sprawl',
    'capital' => 'azure-coast',
    'governance' => 'sovereign-city',
    _ => null,
  };
}

/// Returns a world description for the matched interest
String worldDescriptionForInterest(String interestName) {
  return switch (interestName) {
    'execute' => 'Neon District — fast experiments, first wins, useful hustle.',
    'foundation' => 'Crystal Shore — fundamentals, habits, and clean starts.',
    'craft' => 'Tech Sprawl — engineering craft, product thinking, and startup execution.',
    'capital' => 'Azure Coast — deal flow, capital allocation, and network leverage.',
    'governance' => 'Sovereign City — leadership, systems, ownership, and durable institutions.',
    _ => 'Neon District — your starting point for exploration.',
  };
}
