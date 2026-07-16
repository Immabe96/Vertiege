# Onboarding funnel

**Order (product):** Join world → Chat → achievement proof  
(Profile is created during onboarding; Nexus fills after activity.)

## Surfaces

| Step | Where tracked | UI |
|------|----------------|-----|
| Identity | After profile step | Sticky `FirstStepsCard` on You tab |
| Join / open world | `OnboardingFunnelPrefs.markOpenedWorld()` on world detail | Checklist + Worlds tab |
| Open Chat | Chat tab empty states | Primary post-Gate CTA when worlds exist |
| Submit proof | `OnboardingFunnel.hasSubmittedProof()` | `/achievements/submit` |

## Prefs (`lib/services/onboarding_funnel_prefs.dart`)

- `onboarding_funnel_dismissed` — hide You checklist
- `onboarding_funnel_opened_world` / `opened_nexus` — progress flags
- `onboarding_just_finished` — one-shot Nexus welcome message

## Onboarding completion (`OnboardingScreen` welcome step)

- Primary CTA: **Open Chat** (if starter worlds) or **Browse worlds**
- Secondary: Visit world / Submit proof
- Escape hatch: **Skip to Nexus**
- Default landing after Gate is `/chat` or `/worlds` — not Nexus
