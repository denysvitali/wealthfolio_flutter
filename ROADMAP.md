# Wealthfolio Flutter - Implementation Roadmap

Flutter mobile/web client for [Wealthfolio](https://github.com/afadil/wealthfolio), connecting to the Wealthfolio web server REST API (`/api/v1`).

## Architecture

Based on the [argocd_flutter](https://github.com/denysvitali/argocd_flutter) project pattern:
- **State management**: Single `AppController` (ChangeNotifier), no external packages
- **HTTP client**: Dio with per-request instances
- **Storage**: `flutter_secure_storage` (token) + `shared_preferences` (preferences)
- **Navigation**: Imperative `Navigator.push()` with callback threading
- **UI**: Material 3, Flexoki-inspired warm color palette (matching Wealthfolio frontend)
- **Fonts**: Inter (body), Space Grotesk (display) — bundled
- **Testing**: Hand-written fakes, golden tests

## UI Style

Matching the Wealthfolio React frontend:
- Warm, earthy Flexoki color palette (paper white `#fffcf0`, near-black `#100f0f`)
- Bottom navigation bar (mobile) with 5 tabs: Dashboard, Holdings, Activities, Performance, Settings
- Dashboard hero section: large balance + gain/loss + history chart
- Card-based layouts with subtle borders, 10px radius
- Responsive grid layouts

---

## Phase 1: Foundation [CURRENT]

### Step 1.1: Project Scaffolding
- [x] `devenv.nix` — Flutter + JDK21 dev environment
- [x] `.github/workflows/ci.yml` — Analyze, test, build (APK + web + GitHub Pages)
- [x] `pubspec.yaml` — Dependencies (dio, flutter_secure_storage, shared_preferences)
- [x] `analysis_options.yaml` — Strict mode, single quotes
- [x] Base Flutter project structure (android, ios, web, linux, macos, windows)
- [x] Font assets (Inter, Space Grotesk)
- [x] `CLAUDE.md` — Developer instructions
- [x] Git init + first push

### Step 1.2: Core Layer — Models
- [x] `lib/core/models/session.dart` — Server URL + auth token
- [x] `lib/core/models/account.dart` — Account model
- [x] `lib/core/models/activity.dart` — Activity model
- [x] `lib/core/models/asset.dart` — Asset model
- [x] `lib/core/models/holding.dart` — Holding model
- [x] `lib/core/models/quote.dart` — Quote/price model
- [x] `lib/core/models/settings.dart` — App settings model
- [x] `lib/core/models/goal.dart` — Financial goal model
- [x] `lib/core/models/exchange_rate.dart` — Exchange rate model
- [x] `lib/core/models/net_worth.dart` — Net worth response models
- [x] `lib/core/models/performance.dart` — Performance metrics models
- [x] `lib/core/models/income_summary.dart` — Income summary model
- [x] `lib/core/models/contribution_limit.dart` — Contribution limit model
- [x] `lib/core/models/portfolio_allocation.dart` — Allocation models

### Step 1.3: Core Layer — API Client
- [x] `lib/core/api/wealthfolio_api.dart` — Abstract API interface + NetworkWealthfolioApi
  - [x] Auth: `verifyServer()`, `signIn()`, `getAuthStatus()`
  - [x] Accounts: `fetchAccounts()`, `createAccount()`, `updateAccount()`, `deleteAccount()`
  - [x] Holdings: `fetchHoldings()`, `fetchHolding()`, `fetchHoldingsByAsset()`
  - [x] Activities: `searchActivities()`, `createActivity()`, `updateActivity()`, `deleteActivity()`
  - [x] Performance: `fetchPerformanceHistory()`, `fetchPerformanceSummary()`, `fetchSimplePerformance()`
  - [x] Net Worth: `fetchNetWorth()`, `fetchNetWorthHistory()`
  - [x] Settings: `fetchSettings()`, `updateSettings()`
  - [x] Portfolio: `updatePortfolio()`, `recalculatePortfolio()`
  - [x] Goals: `fetchGoals()`, `createGoal()`, `updateGoal()`, `deleteGoal()`
  - [x] Exchange Rates: `fetchExchangeRates()`, `addExchangeRate()`, `updateExchangeRate()`, `deleteExchangeRate()`
  - [x] Income: `fetchIncomeSummary()`
  - [x] Market Data: `searchSymbol()`, `syncMarketData()`
  - [x] Assets: `fetchAssets()`, `fetchAssetProfile()`
  - [x] Allocations: `fetchAllocations()`, `fetchAllocationHoldings()`

### Step 1.4: Core Layer — Services
- [x] `lib/core/services/app_controller.dart` — Central state (ChangeNotifier)
- [x] `lib/core/services/session_storage.dart` — Secure token + prefs storage
- [x] `lib/core/services/theme_controller.dart` — Light/dark theme persistence
- [x] `lib/core/utils/json_parsing.dart` — Defensive JSON helpers
- [x] `lib/core/utils/currency_format.dart` — Currency formatting helpers

---

## Phase 2: UI Shell & Auth

### Step 2.1: UI Foundation
- [x] `lib/ui/app_colors.dart` — Flexoki color palette
- [x] `lib/ui/design_tokens.dart` — Spacing, radius, opacity, elevation
- [x] `lib/ui/app_root.dart` — MaterialApp, themes, HomeShell, bottom nav
- [x] `lib/ui/shared_widgets.dart` — StatusChip, SectionCard, SummaryTile, etc.

### Step 2.2: Auth / Connection Screen
- [x] `lib/features/auth/connect_screen.dart` — Server URL + optional login form

---

## Phase 3: Main Screens

### Step 3.1: Dashboard
- [x] `lib/features/dashboard/dashboard_screen.dart`
  - [x] Hero section: total balance + gain/loss
  - [x] Portfolio history chart (fl_chart)
  - [x] Accounts summary cards
  - [x] Top holdings list

### Step 3.2: Holdings
- [x] `lib/features/holdings/holdings_screen.dart` — Holdings list with search/filter
- [x] `lib/features/holdings/holding_detail_screen.dart` — Individual holding detail

### Step 3.3: Activities
- [x] `lib/features/activities/activities_screen.dart` — Activity list with pagination
- [x] `lib/features/activities/activity_form_screen.dart` — Create/edit activity

### Step 3.4: Performance
- [x] `lib/features/performance/performance_screen.dart` — Performance charts + metrics

### Step 3.5: Settings
- [x] `lib/features/settings/settings_screen.dart`
  - [x] General: base currency, theme
  - [x] Accounts management
  - [x] Connection management (server URL, sign out)
  - [x] About

---

## Phase 4: Secondary Features [COMPLETE]

### Step 4.1: Income
- [x] `lib/features/income/income_screen.dart` — Income summary + charts

### Step 4.2: Goals
- [x] `lib/features/goals/goals_screen.dart` — Goal tracking cards
- [x] `lib/features/goals/goal_form_screen.dart` — Create/edit goal

### Step 4.3: Net Worth
- [x] `lib/features/net_worth/net_worth_screen.dart` — Net worth history chart

### Step 4.4: Allocations / Insights
- [x] `lib/features/insights/insights_screen.dart` — Portfolio allocation breakdown

---

## Phase 5: Advanced Features

### Step 5.1: Market Data
- [ ] Symbol search
- [ ] Quote history viewer

### Step 5.2: Health Monitoring
- [ ] Health status dashboard
- [ ] Issue management

### Step 5.3: FIRE Planning
- [ ] FIRE settings
- [ ] Projection calculator
- [ ] Monte Carlo simulation

### Step 5.4: Exchange Rates
- [ ] Rate management screen

### Step 5.5: Contribution Limits
- [ ] Limit tracking + deposit calculation

### Step 5.6: Taxonomies
- [ ] Taxonomy/category management

---

## Phase 6: Polish

- [ ] Pull-to-refresh on all list screens
- [ ] Offline indicators
- [ ] Error retry patterns
- [ ] Golden tests for all screens
- [ ] Integration tests
- [ ] Sentry error tracking
- [ ] GitHub Pages deployment

---

## API Coverage Tracker

| Domain | Endpoints | Implemented | Notes |
|--------|-----------|-------------|-------|
| Auth | 6 | 6 | verifyServer, signIn, getAuthStatus, getMe, logout |
| Accounts | 4 | 4 | CRUD |
| Activities | 17 | 4 | Search, CRUD (import later) |
| Holdings | 13 | 3 | Core holdings (snapshots later) |
| Portfolio | 3 | 2 | Update, recalculate (SSE later) |
| Performance | 4 | 3 | Simple, history, summary |
| Income | 1 | 1 | Summary |
| Net Worth | 2 | 2 | Current + history |
| Settings | 4 | 2 | Get + update |
| Goals | 6 | 4 | CRUD (allocations later) |
| Exchange Rates | 4 | 4 | CRUD |
| Market Data | 14 | 2 | Search + sync (rest later) |
| Assets | 6 | 2 | List + profile |
| Allocations | 2 | 2 | Allocations + holdings by category |
| Contribution Limits | 5 | 0 | Phase 5 |
| Taxonomies | 16 | 0 | Phase 5 |
| Health | 8 | 0 | Phase 5 |
| AI Chat | 10 | 0 | Future |
| AI Providers | 4 | 0 | Future |
| Addons | 16 | 0 | Future |
| FIRE | 8 | 0 | Phase 5 |
| Secrets | 3 | 0 | Future |
| Custom Providers | 5 | 0 | Future |
| Connect/Sync | 59 | 0 | Future (feature-gated) |
| **Total** | **~200** | **~41** | **~20% for MVP** |
