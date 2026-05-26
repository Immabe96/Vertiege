# Onboarding funnel

**Order (product):** Profile → join world → Nexus → achievement proof (`4>1>3>2`)

## Surfaces

| Step | Where tracked | UI |
|------|----------------|-----|
| Identity | Always after onboarding | `FirstStepsCard` on Identity tab |
| Open world | `OnboardingFunnelPrefs.markOpenedWorld()` on world detail | Checklist row + onboarding CTA |
| Open Nexus | `markOpenedNexus()` on Nexus tab | Checklist row + welcome toast after onboarding |
| Submit proof | `OnboardingFunnel.hasSubmittedProof()` | `/achievements/submit` |

## Prefs (`lib/services/onboarding_funnel_prefs.dart`)

- `onboarding_funnel_dismissed` — hide Identity checklist
- `onboarding_funnel_opened_world` / `opened_nexus` — progress flags
- `onboarding_just_finished` — one-shot Nexus welcome message

## Onboarding completion (`OnboardingScreen` step 3)

- Dynamic copy for starter world names
- Primary CTA: **Open Nexus**
- Secondary: **Visit your world**, **Submit proof**
