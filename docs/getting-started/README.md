# Getting started

Tutorials for a working local app. For day-to-day git/CI workflow, see [guides/development-workflow.md](../guides/development-workflow.md).

| Doc | Contents |
|-----|----------|
| [local-setup.md](local-setup.md) | `.env`, Firebase sync, iOS/Android dev & release scripts |

**Minimum path:**

```bash
git clone https://github.com/Immabe96/Vertiege.git
cd Vertiege && git checkout develop
cp .env.template .env
flutter pub get
flutter run
```
