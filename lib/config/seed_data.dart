import '../models/post.dart';
import '../models/resident.dart';

const List<Post> seedPosts = [
  Post(
    id: 'seed-1',
    worldId: 'neon-district',
    residentId: 'resident-architect',
    residentName: 'The Architect',
    residentAvatar: 'https://via.placeholder.com/150',
    content: 'Welcome to the Neon District. This is where your journey begins.',
    timestamp: 0,
    tierAtPosting: ResidentTier.apex,
    reactions: {'fire': 42, 'diamond': 28, 'trophy': 15, 'clap': 33},
    comments: [],
  ),
  Post(
    id: 'seed-2',
    worldId: 'sovereign-city',
    residentId: 'resident-vale',
    residentName: 'Chancellor Vale',
    residentAvatar: 'https://via.placeholder.com/150',
    content: 'Sovereign City thrives on order and ambition. Rise through the ranks.',
    timestamp: 1000,
    tierAtPosting: ResidentTier.apex,
    reactions: {'fire': 55, 'diamond': 40, 'trophy': 22, 'clap': 18},
    comments: [],
  ),
  Post(
    id: 'seed-3',
    worldId: 'medical-nexus',
    residentId: 'resident-hippocrates',
    residentName: 'Dean Hippocrates',
    residentAvatar: 'https://via.placeholder.com/150',
    content: 'The Medical Nexus welcomes all healers. Your skills save lives.',
    timestamp: 2000,
    tierAtPosting: ResidentTier.oldMoney,
    reactions: {'clap': 67, 'fire': 30, 'trophy': 45},
    comments: [],
  ),
];
