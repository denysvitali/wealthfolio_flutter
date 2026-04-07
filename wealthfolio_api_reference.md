# Wealthfolio Complete API Reference

> Source: https://github.com/afadil/wealthfolio (monorepo)
> Architecture: Tauri desktop app (Rust backend + React/TypeScript frontend) with optional Axum web server mode
> All REST endpoints are prefixed with `/api/v1`

---

## Table of Contents

1. [Server REST API Endpoints](#server-rest-api-endpoints)
2. [Tauri IPC Commands](#tauri-ipc-commands)
3. [Frontend UI Structure (Pages/Views)](#frontend-ui-structure)
4. [Data Models](#data-models)

---

## Server REST API Endpoints

All protected routes require authentication (when auth is enabled). Base prefix: `/api/v1`

### System & Auth

| Method | Path | Description |
|--------|------|-------------|
| GET | `/healthz` | Health check |
| GET | `/readyz` | Readiness check |
| GET | `/auth/status` | Auth status |
| GET | `/auth/me` | Current user info |
| POST | `/auth/login` | Login (rate-limited: 5/60s) |
| POST | `/auth/logout` | Logout |
| GET | `/openapi.json` | OpenAPI specification |

### Accounts

| Method | Path | Description |
|--------|------|-------------|
| GET | `/accounts` | List accounts (query: `include_archived`) |
| POST | `/accounts` | Create account |
| PUT | `/accounts/{id}` | Update account |
| DELETE | `/accounts/{id}` | Delete account |

Mobile payload notes:
- The REST API expects camelCase fields such as `accountType`, `isDefault`, `isActive`, and `trackingMode`.
- `trackingMode` must be one of `TRANSACTIONS`, `HOLDINGS`, or `NOT_SET`.
- `currency` is required on create and immutable on update in the web app contract.

### Activities

| Method | Path | Description |
|--------|------|-------------|
| POST | `/activities/search` | Search activities (paginated, filterable) |
| POST | `/activities` | Create activity |
| PUT | `/activities` | Update activity |
| POST | `/activities/bulk` | Bulk create/update/delete activities |
| DELETE | `/activities/{id}` | Delete activity |
| POST | `/activities/import/check` | Validate activities before import |
| POST | `/activities/import/assets/preview` | Preview asset resolution for import |
| POST | `/activities/import` | Import activities |
| POST | `/activities/import/parse` | Parse CSV file |
| GET | `/activities/import/mapping` | Get account import mapping |
| POST | `/activities/import/mapping` | Save account import mapping |
| GET | `/activities/import/templates` | List import templates |
| POST | `/activities/import/templates` | Save import template |
| DELETE | `/activities/import/templates` | Delete import template |
| GET | `/activities/import/templates/item` | Get single import template |
| POST | `/activities/import/templates/link` | Link account to template |
| POST | `/activities/import/check-duplicates` | Check for duplicate activities |

Mobile payload notes:
- The REST API expects camelCase fields such as `accountId`, `activityType`, `activityDate`, `unitPrice`, `fxRate`, and `needsReview`.
- Asset-backed activities should send a nested `symbol` object, for example `{ "symbol": "AAPL", "exchangeMic": "XNAS" }`.
- Cash and income-style activities rely on `amount`; if the UI only captures quantity and unit price, the client should derive `amount = quantity * unitPrice`.
- Deletes use `DELETE /activities/{id}` rather than a query-string `id`.

### Assets

| Method | Path | Description |
|--------|------|-------------|
| GET | `/assets` | List all assets |
| POST | `/assets` | Create asset |
| DELETE | `/assets/{id}` | Delete asset |
| GET | `/assets/profile` | Get asset profile |
| PUT | `/assets/profile/{id}` | Update asset profile |
| PUT | `/assets/pricing-mode/{id}` | Update asset quote/pricing mode |

### Holdings & Valuations

| Method | Path | Description |
|--------|------|-------------|
| GET | `/holdings` | Get holdings (query: `account_id`) |
| GET | `/holdings/item` | Get single holding |
| GET | `/holdings/by-asset` | Get holdings by asset |
| GET | `/valuations/history` | Historical account valuations |
| GET | `/valuations/latest` | Latest account valuations |
| GET | `/allocations` | Portfolio allocations |
| GET | `/allocations/holdings` | Holdings by allocation category |
| GET | `/snapshots` | List snapshots |
| POST | `/snapshots` | Save manual holdings snapshot |
| DELETE | `/snapshots` | Delete snapshot |
| GET | `/snapshots/holdings` | Get snapshot holdings by date |
| POST | `/snapshots/import` | Import holdings from CSV |
| POST | `/snapshots/import/check` | Validate holdings import |

### Portfolio

| Method | Path | Description |
|--------|------|-------------|
| POST | `/portfolio/update` | Update portfolio calculations |
| POST | `/portfolio/recalculate` | Full portfolio recalculation |
| GET | `/events/stream` | SSE stream for portfolio events |

### Performance & Income

| Method | Path | Description |
|--------|------|-------------|
| POST | `/performance/accounts/simple` | Simple performance for accounts |
| POST | `/performance/history` | Detailed performance history |
| POST | `/performance/summary` | Performance summary |
| GET | `/income/summary` | Income summary (query: `account_id`) |

### Net Worth

| Method | Path | Description |
|--------|------|-------------|
| GET | `/net-worth` | Current net worth (query: `date`) |
| GET | `/net-worth/history` | Net worth history (query: `startDate`, `endDate`) |

### Alternative Assets

| Method | Path | Description |
|--------|------|-------------|
| POST | `/alternative-assets` | Create alternative asset |
| PUT | `/alternative-assets/{id}/valuation` | Update valuation |
| DELETE | `/alternative-assets/{id}` | Delete alternative asset |
| POST | `/alternative-assets/{id}/link-liability` | Link liability |
| DELETE | `/alternative-assets/{id}/link-liability` | Unlink liability |
| PUT | `/alternative-assets/{id}/metadata` | Update metadata |
| GET | `/alternative-holdings` | List alternative holdings |

### Goals

| Method | Path | Description |
|--------|------|-------------|
| GET | `/goals` | List goals |
| POST | `/goals` | Create goal |
| PUT | `/goals` | Update goal |
| DELETE | `/goals/{id}` | Delete goal |
| GET | `/goals/allocations` | Get goal allocations |
| POST | `/goals/allocations` | Update goal allocations |

### Settings & Utilities

| Method | Path | Description |
|--------|------|-------------|
| GET | `/settings` | Get settings |
| PUT | `/settings` | Update settings |
| GET | `/settings/auto-update-enabled` | Check auto-update setting |
| GET | `/app/info` | App info (version, etc.) |
| GET | `/app/check-update` | Check for app updates |
| POST | `/utilities/database/backup` | Backup database |
| POST | `/utilities/database/backup-to-path` | Backup to specific path |
| POST | `/utilities/database/restore` | Restore database |

### Exchange Rates

| Method | Path | Description |
|--------|------|-------------|
| GET | `/exchange-rates/latest` | Get latest exchange rates |
| PUT | `/exchange-rates` | Update exchange rate |
| POST | `/exchange-rates` | Add exchange rate |
| DELETE | `/exchange-rates/{id}` | Delete exchange rate |

### Market Data

| Method | Path | Description |
|--------|------|-------------|
| GET | `/exchanges` | List exchanges |
| GET | `/providers` | List market data providers |
| GET | `/providers/settings` | Get provider settings |
| PUT | `/providers/settings` | Update provider settings |
| GET | `/market-data/search` | Search symbols |
| GET | `/market-data/resolve-currency` | Resolve symbol quote |
| GET | `/market-data/quotes/history` | Quote history |
| POST | `/market-data/quotes/latest` | Get latest quotes |
| PUT | `/market-data/quotes/{symbol}` | Update quote |
| DELETE | `/market-data/quotes/id/{id}` | Delete quote |
| POST | `/market-data/quotes/check` | Validate quote import |
| POST | `/market-data/quotes/import` | Import quotes from CSV |
| POST | `/market-data/sync/history` | Sync historical quotes |
| POST | `/market-data/sync` | Sync market data |

### Contribution Limits

| Method | Path | Description |
|--------|------|-------------|
| GET | `/limits` | List contribution limits |
| POST | `/limits` | Create contribution limit |
| PUT | `/limits/{id}` | Update contribution limit |
| DELETE | `/limits/{id}` | Delete contribution limit |
| GET | `/limits/{id}/deposits` | Calculate deposits for limit |

### Taxonomies & Classifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/taxonomies` | List taxonomies |
| POST | `/taxonomies` | Create taxonomy |
| PUT | `/taxonomies` | Update taxonomy |
| GET | `/taxonomies/{id}` | Get taxonomy with categories |
| DELETE | `/taxonomies/{id}` | Delete taxonomy |
| POST | `/taxonomies/categories` | Create category |
| PUT | `/taxonomies/categories` | Update category |
| DELETE | `/taxonomies/{taxonomyId}/categories/{categoryId}` | Delete category |
| POST | `/taxonomies/categories/move` | Move/reorder category |
| POST | `/taxonomies/import` | Import taxonomy from JSON |
| GET | `/taxonomies/{id}/export` | Export taxonomy to JSON |
| GET | `/taxonomies/assignments/asset/{assetId}` | Get asset taxonomy assignments |
| POST | `/taxonomies/assignments` | Assign asset to category |
| DELETE | `/taxonomies/assignments/{id}` | Remove assignment |
| GET | `/taxonomies/migration/status` | Legacy migration status |
| POST | `/taxonomies/migration/run` | Run legacy migration |

### Secrets

| Method | Path | Description |
|--------|------|-------------|
| POST | `/secrets` | Set secret |
| GET | `/secrets` | Get secret |
| DELETE | `/secrets` | Delete secret |

### Custom Market Data Providers

| Method | Path | Description |
|--------|------|-------------|
| GET | `/custom-providers` | List custom providers |
| POST | `/custom-providers` | Create custom provider |
| PUT | `/custom-providers/{id}` | Update custom provider |
| DELETE | `/custom-providers/{id}` | Delete custom provider |
| POST | `/custom-providers/test-source` | Test provider source |

### AI Chat

| Method | Path | Description |
|--------|------|-------------|
| POST | `/ai/chat/stream` | Stream AI chat (NDJSON) |
| GET | `/ai/threads` | List threads (query: `cursor`, `limit`, `search`) |
| GET | `/ai/threads/{id}` | Get thread |
| PUT | `/ai/threads/{id}` | Update thread |
| DELETE | `/ai/threads/{id}` | Delete thread |
| GET | `/ai/threads/{id}/messages` | Get thread messages |
| GET | `/ai/threads/{id}/tags` | Get thread tags |
| POST | `/ai/threads/{id}/tags` | Add tag |
| DELETE | `/ai/threads/{id}/tags/{tag}` | Remove tag |
| PATCH | `/ai/tool-result` | Update tool result |

### AI Providers

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ai/providers` | List AI providers |
| PUT | `/ai/providers/settings` | Update provider settings |
| POST | `/ai/providers/default` | Set default provider |
| GET | `/ai/providers/{provider_id}/models` | List provider models |

### Health Monitoring

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health/status` | Get health status |
| POST | `/health/check` | Run health checks |
| POST | `/health/dismiss` | Dismiss health issue |
| POST | `/health/restore` | Restore dismissed issue |
| GET | `/health/dismissed` | List dismissed issues |
| POST | `/health/fix` | Execute health fix action |
| GET | `/health/config` | Get health config |
| PUT | `/health/config` | Update health config |

### Addons

| Method | Path | Description |
|--------|------|-------------|
| GET | `/addons/installed` | List installed addons |
| POST | `/addons/install-zip` | Install addon from zip |
| POST | `/addons/toggle` | Enable/disable addon |
| DELETE | `/addons/{id}` | Uninstall addon |
| GET | `/addons/runtime/{id}` | Load addon for runtime |
| GET | `/addons/enabled-on-startup` | Get startup-enabled addons |
| POST | `/addons/extract` | Extract addon zip |
| GET | `/addons/store/listings` | Fetch addon store listings |
| POST | `/addons/store/ratings` | Submit addon rating |
| GET | `/addons/store/ratings` | Get addon ratings |
| POST | `/addons/store/check-update` | Check single addon update |
| POST | `/addons/store/check-all` | Check all addon updates |
| POST | `/addons/store/update` | Update addon from store |
| POST | `/addons/store/staging/download` | Download addon to staging |
| POST | `/addons/store/install-from-staging` | Install from staging |
| DELETE | `/addons/store/staging` | Clear addon staging |

Mobile support note:
- The backend exposes addon management and runtime endpoints, but the Flutter app does not currently implement the Wealthfolio addon runtime, routing, or settings UI. Addons showing up in the web/Tauri app but not in Flutter is expected with the current mobile client.

### Wealthfolio Connect (Feature-gated: `connect-sync` or `device-sync`)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/connect/session` | Store sync session |
| DELETE | `/connect/session` | Clear sync session |
| GET | `/connect/session/status` | Session status |
| GET | `/connect/session/restore` | Restore session |
| GET | `/connect/connections` | List broker connections |
| GET | `/connect/accounts` | List broker accounts |
| POST | `/connect/sync` | Sync broker data |
| POST | `/connect/sync/connections` | Sync broker connections |
| POST | `/connect/sync/accounts` | Sync broker accounts |
| POST | `/connect/sync/activities` | Sync broker activities |
| GET | `/connect/synced-accounts` | Get synced accounts |
| GET | `/connect/platforms` | List platforms |
| GET | `/connect/sync-states` | Get broker sync states |
| GET | `/connect/import-runs` | Get import runs |
| GET | `/connect/broker-sync-profile` | Get broker sync profile |
| POST | `/connect/broker-sync-profile` | Save broker sync profile rules |
| GET | `/connect/plans` | Get subscription plans |
| GET | `/connect/plans/public` | Get public plans |
| GET | `/connect/user` | Get user info |
| GET | `/connect/device/sync-state` | Device sync state |
| POST | `/connect/device/enable` | Enable device sync |
| DELETE | `/connect/device/sync-data` | Clear device sync data |
| POST | `/connect/device/reinitialize` | Reinitialize device sync |
| GET | `/connect/device/engine-status` | Sync engine status |
| GET | `/connect/device/pairing-source-status` | Pairing source status |
| GET | `/connect/device/bootstrap-overwrite-check` | Bootstrap overwrite check |
| POST | `/connect/device/reconcile-ready-state` | Reconcile ready state |
| POST | `/connect/device/bootstrap-snapshot` | Bootstrap from snapshot |
| POST | `/connect/device/trigger-cycle` | Trigger sync cycle |
| POST | `/connect/device/start-background` | Start background engine |
| POST | `/connect/device/stop-background` | Stop background engine |
| POST | `/connect/device/generate-snapshot` | Generate snapshot |
| POST | `/connect/device/cancel-snapshot` | Cancel snapshot upload |

### Device Sync (Feature-gated: `device-sync`)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/sync/device/register` | Register device |
| GET | `/sync/device/current` | Get current device |
| GET | `/sync/devices` | List devices |
| GET | `/sync/device/{device_id}` | Get device |
| PATCH | `/sync/device/{device_id}` | Update device |
| DELETE | `/sync/device/{device_id}` | Delete device |
| POST | `/sync/device/{device_id}/revoke` | Revoke device |
| POST | `/sync/keys/initialize` | Initialize team keys |
| POST | `/sync/keys/initialize/commit` | Commit key initialization |
| POST | `/sync/keys/rotate` | Rotate team keys |
| POST | `/sync/keys/rotate/commit` | Commit key rotation |
| POST | `/sync/team/reset` | Reset team sync |
| POST | `/sync/pairing` | Create pairing |
| GET | `/sync/pairing/{pairing_id}` | Get pairing |
| POST | `/sync/pairing/{pairing_id}/approve` | Approve pairing |
| POST | `/sync/pairing/{pairing_id}/complete` | Complete pairing |
| POST | `/sync/pairing/{pairing_id}/cancel` | Cancel pairing |
| POST | `/sync/pairing/claim` | Claim pairing |
| GET | `/sync/pairing/{pairing_id}/messages` | Get pairing messages |
| POST | `/sync/pairing/{pairing_id}/confirm` | Confirm pairing |
| POST | `/sync/pairing/complete-with-transfer` | Complete with transfer |
| POST | `/sync/pairing/confirm-with-bootstrap` | Confirm with bootstrap |
| POST | `/sync/pairing/flow/begin` | Begin pairing flow |
| POST | `/sync/pairing/flow/state` | Get pairing flow state |
| POST | `/sync/pairing/flow/approve-overwrite` | Approve overwrite |
| POST | `/sync/pairing/flow/cancel` | Cancel pairing flow |

### Sync Crypto (Feature-gated: `device-sync`)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/sync/crypto/generate-root-key` | Generate root key |
| POST | `/sync/crypto/derive-dek` | Derive data encryption key |
| POST | `/sync/crypto/generate-keypair` | Generate ephemeral keypair |
| POST | `/sync/crypto/compute-shared-secret` | Compute shared secret |
| POST | `/sync/crypto/derive-session-key` | Derive session key |
| POST | `/sync/crypto/encrypt` | Encrypt data |
| POST | `/sync/crypto/decrypt` | Decrypt data |
| POST | `/sync/crypto/generate-pairing-code` | Generate pairing code |
| POST | `/sync/crypto/hash-pairing-code` | Hash pairing code |
| POST | `/sync/crypto/hmac-sha256` | HMAC-SHA256 |
| POST | `/sync/crypto/compute-sas` | Compute SAS |
| POST | `/sync/crypto/generate-device-id` | Generate device ID |

---

## Tauri IPC Commands

These are invoked from the frontend via `invoke("command_name", { params })`.

### Account Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_accounts` | `include_archived?: bool` | `Vec<Account>` |
| `create_account` | `account: NewAccount` | `Account` |
| `update_account` | `account_update: AccountUpdate` | `Account` |
| `delete_account` | `account_id: String` | `()` |

### Activity Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `search_activities` | `page, page_size, account_id_filter?, activity_type_filter?, asset_id_keyword?, sort?, needs_review_filter?, date_from?, date_to?, instrument_type_filter?` | `ActivitySearchResponse` |
| `create_activity` | `activity: NewActivity` | `Activity` |
| `update_activity` | `activity: ActivityUpdate` | `Activity` |
| `delete_activity` | `activity_id: String` | `Activity` |
| `save_activities` | `request: ActivityBulkMutationRequest` | `ActivityBulkMutationResult` |
| `get_account_import_mapping` | `account_id, context_kind` | `ImportMappingData` |
| `save_account_import_mapping` | `mapping: ImportMappingData` | `ImportMappingData` |
| `link_account_template` | `account_id, template_id, context_kind` | `()` |
| `list_import_templates` | (none) | `Vec<ImportTemplateData>` |
| `get_import_template` | `id: String` | `ImportTemplateData` |
| `save_import_template` | `template: ImportTemplateData` | `ImportTemplateData` |
| `delete_import_template` | `id: String` | `()` |
| `check_activities_import` | `activities: Vec<ActivityImport>` | `Vec<ActivityImport>` |
| `preview_import_assets` | `candidates: Vec<ImportAssetCandidate>` | `Vec<ImportAssetPreviewItem>` |
| `import_activities` | `activities: Vec<ActivityImport>` | `ImportActivitiesResult` |
| `check_existing_duplicates` | `idempotency_keys: Vec<String>` | `HashMap<String, String>` |
| `parse_csv` | `content: Vec<u8>, config: ParseConfig` | `ParsedCsvResult` |

### Portfolio & Holdings Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `recalculate_portfolio` | (none) | `()` |
| `update_portfolio` | (none) | `()` |
| `get_holdings` | `account_id: String` | `Vec<Holding>` |
| `get_holding` | `account_id, asset_id` | `Option<Holding>` |
| `get_asset_holdings` | `asset_id: String` | `Vec<Holding>` |
| `get_portfolio_allocations` | `account_id: String` | `PortfolioAllocations` |
| `get_holdings_by_allocation` | `account_id, taxonomy_id, category_id` | `AllocationHoldings` |
| `get_historical_valuations` | `account_id, start_date?, end_date?` | `Vec<DailyAccountValuation>` |
| `get_latest_valuations` | `account_ids: Vec<String>` | `Vec<DailyAccountValuation>` |
| `get_income_summary` | `account_id?: String` | `Vec<IncomeSummary>` |
| `calculate_accounts_simple_performance` | `account_ids: Vec<String>` | `Vec<SimplePerformanceMetrics>` |
| `calculate_performance_history` | `item_type, item_id, start_date?, end_date?, tracking_mode?` | `PerformanceMetrics` |
| `calculate_performance_summary` | `item_type, item_id, start_date?, end_date?, tracking_mode?` | `PerformanceMetrics` |
| `save_manual_holdings` | `account_id, holdings: Vec<HoldingInput>, cash_balances, snapshot_date?` | `()` |
| `check_holdings_import` | `account_id, snapshots: Vec<HoldingsSnapshotInput>` | `CheckHoldingsImportResult` |
| `import_holdings_csv` | `account_id, snapshots: Vec<HoldingsSnapshotInput>` | `ImportHoldingsCsvResult` |
| `get_snapshots` | `account_id, date_from?, date_to?` | `Vec<SnapshotInfo>` |
| `get_snapshot_by_date` | `account_id, date` | `Vec<Holding>` |
| `delete_snapshot` | `account_id, date` | `()` |

### Asset Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_asset_profile` | `asset_id: String` | `Asset` |
| `get_assets` | (none) | `Vec<Asset>` |
| `update_asset_profile` | `id, payload: UpdateAssetProfile` | `Asset` |
| `update_quote_mode` | `id, quote_mode` | `Asset` |
| `create_asset` | `payload: NewAsset` | `Asset` |
| `delete_asset` | `id: String` | `()` |

### Goal Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_goals` | (none) | `Vec<Goal>` |
| `create_goal` | `goal: NewGoal` | `Goal` |
| `update_goal` | `goal: Goal` | `Goal` |
| `delete_goal` | `goal_id: String` | `usize` |
| `update_goal_allocations` | `allocations: Vec<GoalsAllocation>` | `usize` |
| `load_goals_allocations` | (none) | `Vec<GoalsAllocation>` |

### Settings & Exchange Rate Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_settings` | (none) | `Settings` |
| `is_auto_update_check_enabled` | (none) | `bool` |
| `update_settings` | `settings_update: SettingsUpdate` | `Settings` |
| `update_exchange_rate` | `rate: ExchangeRate` | `ExchangeRate` |
| `get_latest_exchange_rates` | (none) | `Vec<ExchangeRate>` |
| `add_exchange_rate` | `new_rate: NewExchangeRate` | `ExchangeRate` |
| `delete_exchange_rate` | `rate_id: String` | `()` |

### Market Data Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `search_symbol` | `query: String` | `Vec<SymbolSearchResult>` |
| `sync_market_data` | `asset_ids?: Vec<String>, refetch_all: bool, refetch_recent_days?: i64` | `()` |
| `update_quote` | `quote: Quote` | `()` |
| `delete_quote` | `id: String` | `()` |
| `get_quote_history` | `symbol: String` | `Vec<Quote>` |
| `get_latest_quotes` | `asset_ids: Vec<String>` | `HashMap<String, LatestQuoteSnapshot>` |
| `get_market_data_providers` | (none) | `Vec<ProviderInfo>` |
| `check_quotes_import` | `content: Vec<u8>, has_header_row: bool` | `Vec<QuoteImport>` |
| `import_quotes_csv` | `quotes: Vec<QuoteImport>, overwrite_existing: bool` | `Vec<QuoteImport>` |
| `resolve_symbol_quote` | `symbol, exchange_mic?, instrument_type?` | `ResolvedQuote` |
| `get_exchanges` | (none) | `Vec<ExchangeInfo>` |
| `fetch_yahoo_dividends` | `symbol: String` | `Vec<YahooDividend>` |
| `get_market_data_providers_settings` | (none) | `Vec<ProviderInfo>` |
| `update_market_data_provider_settings` | `provider_id, priority: i32, enabled: bool` | `()` |

### FIRE Planning Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_fire_settings` | (none) | `Option<FireSettings>` |
| `save_fire_settings` | `settings: FireSettings` | `()` |
| `calculate_fire_projection` | `settings: FireSettings, current_portfolio: f64` | `FireProjection` |
| `run_fire_monte_carlo` | `settings: FireSettings, current_portfolio: f64, n_sims?: u32` | `MonteCarloResult` |
| `run_fire_scenario_analysis` | `settings: FireSettings, current_portfolio: f64` | `Vec<ScenarioResult>` |
| `run_fire_sorr` | `settings: FireSettings, portfolio_at_fire: f64` | `Vec<SorrScenario>` |
| `run_fire_sensitivity` | `settings: FireSettings, current_portfolio: f64` | `SensitivityResult` |
| `run_fire_strategy_comparison` | `settings: FireSettings, current_portfolio: f64, n_sims?: u32` | `StrategyComparisonResult` |

### Health Monitoring Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_health_status` | `client_timezone?: String` | `HealthStatus` |
| `run_health_checks` | `client_timezone?: String` | `HealthStatus` |
| `dismiss_health_issue` | `issue_id, data_hash` | `()` |
| `restore_health_issue` | `issue_id: String` | `()` |
| `get_dismissed_health_issues` | (none) | `Vec<String>` |
| `execute_health_fix` | `action: FixAction` | `()` |
| `get_health_config` | (none) | `HealthConfig` |
| `update_health_config` | `config: HealthConfig` | `()` |

### Contribution Limits Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_contribution_limits` | (none) | `Vec<ContributionLimit>` |
| `create_contribution_limit` | `new_limit: NewContributionLimit` | `ContributionLimit` |
| `update_contribution_limit` | `id, updated_limit: NewContributionLimit` | `ContributionLimit` |
| `delete_contribution_limit` | `id: String` | `()` |
| `calculate_deposits_for_contribution_limit` | `limit_id: String` | `DepositsCalculation` |

### Taxonomy Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_taxonomies` | (none) | `Vec<Taxonomy>` |
| `get_taxonomy` | `id: String` | `Option<TaxonomyWithCategories>` |
| `create_taxonomy` | `taxonomy: NewTaxonomy` | `Taxonomy` |
| `update_taxonomy` | `taxonomy: Taxonomy` | `Taxonomy` |
| `delete_taxonomy` | `id: String` | `usize` |
| `create_category` | `category: NewCategory` | `Category` |
| `update_category` | `category: Category` | `Category` |
| `delete_category` | `taxonomy_id, category_id` | `usize` |
| `move_category` | `taxonomy_id, category_id, new_parent_id?, position: i32` | `Category` |
| `import_taxonomy_json` | `json_str: String` | `Taxonomy` |
| `export_taxonomy_json` | `id: String` | `String` |
| `get_asset_taxonomy_assignments` | `asset_id: String` | `Vec<AssetTaxonomyAssignment>` |
| `assign_asset_to_category` | `assignment: NewAssetTaxonomyAssignment` | `AssetTaxonomyAssignment` |
| `remove_asset_taxonomy_assignment` | `id: String` | `usize` |
| `get_migration_status` | (none) | `MigrationStatus` |
| `migrate_legacy_classifications` | (none) | `MigrationResult` |

### Addon Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `install_addon_zip` | `zip_data: Vec<u8>, enable_after_install?: bool` | `AddonManifest` |
| `list_installed_addons` | (none) | `Vec<InstalledAddon>` |
| `toggle_addon` | `addon_id: String, enabled: bool` | `()` |
| `uninstall_addon` | `addon_id: String` | `()` |
| `load_addon_for_runtime` | `addon_id: String` | `ExtractedAddon` |
| `get_enabled_addons_on_startup` | (none) | `Vec<ExtractedAddon>` |
| `extract_addon_zip` | `zip_data: Vec<u8>` | `ExtractedAddon` |
| `check_addon_update` | `addon_id, current_version` | `AddonUpdateCheckResult` |
| `check_all_addon_updates` | (none) | `Vec<AddonUpdateCheckResult>` |
| `update_addon_from_store_by_id` | `addon_id: String` | `AddonManifest` |
| `fetch_addon_store_listings` | (none) | `Vec<serde_json::Value>` |
| `download_addon_to_staging` | `addon_id: String` | `ExtractedAddon` |
| `install_addon_from_staging` | `addon_id, enable_after_install?: bool` | `AddonManifest` |
| `clear_addon_staging` | `addon_id?: String` | `()` |
| `submit_addon_rating` | `addon_id, rating: u8, review?: String` | `serde_json::Value` |

### AI Chat Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `stream_ai_chat` | `request: SendMessageRequest, on_event: Channel<AiStreamEvent>` | `()` |
| `list_ai_threads` | `cursor?, limit?: u32, search?: String` | `ThreadPage` |
| `get_ai_thread` | `thread_id: String` | `Option<ChatThread>` |
| `get_ai_thread_messages` | `thread_id: String` | `Vec<ChatMessage>` |
| `update_ai_thread` | `request: UpdateThreadRequest` | `ChatThread` |
| `delete_ai_thread` | `thread_id: String` | `()` |
| `add_ai_thread_tag` | `thread_id, tag` | `()` |
| `remove_ai_thread_tag` | `thread_id, tag` | `()` |
| `get_ai_thread_tags` | `thread_id: String` | `Vec<String>` |
| `update_tool_result` | `request: UpdateToolResultRequest` | `ChatMessage` |

### AI Provider Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_ai_providers` | (none) | `AiProvidersResponse` |
| `update_ai_provider_settings` | `request: UpdateProviderSettingsRequest` | `()` |
| `set_default_ai_provider` | `request: SetDefaultProviderRequest` | `()` |
| `list_ai_models` | `provider_id: String` | `ListModelsResponse` |

### Alternative Asset & Net Worth Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `create_alternative_asset` | `CreateAlternativeAssetRequest` | `CreateAlternativeAssetResponse` |
| `update_alternative_asset_valuation` | `id, UpdateValuationRequest` | `UpdateValuationResponse` |
| `update_alternative_asset_metadata` | `id, notes?, metadata, icon?` | `()` |
| `delete_alternative_asset` | `id: String` | `()` |
| `link_liability` | `id, LinkLiabilityRequest` | `()` |
| `unlink_liability` | `id: String` | `()` |
| `get_alternative_holdings` | (none) | `Vec<AlternativeHoldingResponse>` |
| `get_net_worth` | `date?: String` | `NetWorthResponse` |
| `get_net_worth_history` | `start_date, end_date` | `Vec<NetWorthHistoryPoint>` |

### Custom Provider Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_custom_providers` | (none) | `Vec<CustomProviderWithSources>` |
| `create_custom_provider` | `payload: NewCustomProvider` | `CustomProviderWithSources` |
| `update_custom_provider` | `provider_id, payload: UpdateCustomProvider` | `CustomProviderWithSources` |
| `delete_custom_provider` | `provider_id: String` | `()` |
| `test_custom_provider_source` | `payload: TestSourceRequest` | `TestSourceResult` |

### Secrets Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `set_secret` | `secret_key, secret` | `()` |
| `get_secret` | `secret_key: String` | `Option<String>` |
| `delete_secret` | `secret_key: String` | `()` |

### Platform Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_platform` | (none) | `PlatformInfo` |
| `is_mobile` | (none) | `bool` |
| `is_desktop` | (none) | `bool` |

### Utility Commands
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_app_info` | (none) | `AppInfo` |
| `check_for_updates` | (none) | `Option<serde_json::Value>` |
| `install_app_update` | (none) | `()` |
| `backup_database` | (none) | `(String, Vec<u8>)` |
| `backup_database_to_path` | `backup_dir: String` | `String` |
| `restore_database` | `backup_file_path: String` | `()` |

### Broker Sync Commands (Feature: `connect-sync`)
| Command | Parameters | Returns |
|---------|-----------|---------|
| `sync_broker_data` | (none) | `()` |
| `broker_ingest_run` | (none) | `()` |
| `get_synced_accounts` | (none) | `Vec<Account>` |
| `get_platforms` | (none) | `Vec<Platform>` |
| `list_broker_connections` | (none) | `Vec<BrokerConnection>` |
| `list_broker_accounts` | (none) | `Vec<BrokerAccount>` |
| `get_subscription_plans` | (none) | `PlansResponse` |
| `get_subscription_plans_public` | (none) | `PlansResponse` |
| `get_user_info` | (none) | `UserInfo` |
| `get_broker_sync_states` | (none) | `Vec<BrokerSyncState>` |
| `get_broker_ingest_states` | (none) | `Vec<BrokerSyncState>` |
| `get_import_runs` | `run_type?, limit?, offset?` | `Vec<ImportRun>` |
| `get_data_import_runs` | `run_type?, limit?, offset?` | `Vec<ImportRun>` |
| `get_broker_sync_profile` | `account_id, source_system` | `BrokerSyncProfileData` |
| `save_broker_sync_profile_rules` | `request: SaveBrokerSyncProfileRulesRequest` | `BrokerSyncProfileData` |

### Connect Session Commands (Feature: `connect-sync` or `device-sync`)
| Command | Parameters | Returns |
|---------|-----------|---------|
| `store_sync_session` | `refresh_token?: String` | `()` |
| `clear_sync_session` | (none) | `()` |
| `restore_sync_session` | (none) | `RestoreSyncSessionResponse` |

### Device Enrollment Commands (Feature: `device-sync`)
| Command | Parameters | Returns |
|---------|-----------|---------|
| `get_device_sync_state` | (none) | `SyncStateResult` |
| `enable_device_sync` | (none) | `EnableSyncResult` |
| `clear_device_sync_data` | (none) | `()` |
| `reinitialize_device_sync` | (none) | `EnableSyncResult` |

### Sync Crypto Commands (Feature: `device-sync`)
| Command | Parameters | Returns |
|---------|-----------|---------|
| `sync_generate_root_key` | (none) | `String` |
| `sync_derive_dek` | `root_key, version: u32` | `String` |
| `sync_generate_keypair` | (none) | `EphemeralKeyPair` |
| `sync_compute_shared_secret` | `our_secret, their_public` | `String` |
| `sync_derive_session_key` | `shared_secret, context` | `String` |
| `sync_encrypt` | `key, plaintext` | `String` |
| `sync_decrypt` | `key, ciphertext` | `String` |
| `sync_generate_pairing_code` | (none) | `String` |
| `sync_hash_pairing_code` | `code: String` | `String` |
| `sync_hmac_sha256` | `key, data` | `String` |
| `sync_compute_sas` | `shared_secret: String` | `String` |
| `sync_generate_device_id` | (none) | `String` |

---

## Frontend UI Structure

### Route Map

```
/                           -> Dashboard (redirects to /dashboard)
/auth/callback              -> Auth callback
/onboarding                 -> Onboarding flow

/dashboard                  -> Dashboard / Portfolio overview
/activities                 -> Activity list
/activities/manage          -> Activity management
/import                     -> Import activities
/holdings                   -> Holdings overview
/holdings-insights          -> Holdings insights
/holdings/:assetId          -> Individual asset detail
/accounts/:id              -> Individual account view
/income                     -> Income tracking
/performance               -> Performance analytics
/insights                  -> Portfolio insights
/health                    -> Health monitoring
/assistant                 -> AI assistant
/connect                   -> Wealthfolio Connect
/fire-planner              -> FIRE planning tools

/settings                  -> Settings layout
/settings/general          -> General settings
/settings/accounts         -> Account settings
/settings/goals            -> Goal management
/settings/appearance       -> Theme/appearance
/settings/about            -> About page
/settings/exports          -> Data export
/settings/contribution-limits -> Contribution limits
/settings/fire-planner     -> FIRE settings
/settings/market-data      -> Market data settings
/settings/market-data/import -> Market data import
/settings/securities       -> Securities management
/settings/taxonomies       -> Taxonomy management
/settings/connect          -> Connect settings
/settings/ai-providers     -> AI provider configuration
/settings/addons           -> Addon management

*                          -> 404 Not Found
```

### Frontend Pages Directory

| Page Directory | Purpose |
|---------------|---------|
| `account/` | Individual account views |
| `activity/` | Activity listing and management |
| `ai-assistant/` | AI chat assistant |
| `asset/` | Asset detail views |
| `auth/` | Authentication (callback) |
| `dashboard/` | Main dashboard |
| `fire-planner/` | FIRE independence planning |
| `health/` | Portfolio health monitoring |
| `holdings/` | Holdings overview and details |
| `income/` | Income tracking and visualization |
| `insights/` | Portfolio insights and analytics |
| `layouts/` | Shared layout components (AppLayout, SettingsLayout) |
| `net-worth/` | Net worth tracking |
| `onboarding/` | Initial setup wizard |
| `performance/` | Performance analytics |
| `settings/` | Settings pages (multiple sub-pages) |
| `not-found.tsx` | 404 page |

### Frontend Feature Modules

| Feature | Purpose |
|---------|---------|
| `ai-assistant/` | AI-powered financial assistant |
| `devices-sync/` | Multi-device synchronization |
| `wealthfolio-connect/` | Broker connections and data sync |

### Frontend Adapter Layer

The frontend uses an adapter pattern to abstract the backend:
- `adapters/tauri/` - Tauri IPC invoke calls (desktop)
- `adapters/web/` - REST API fetch calls (web mode)
- `adapters/shared/` - Common adapter utilities
- `adapters/types.ts` - Adapter interface types

---

## Data Models

### Core Domain Models

#### Account
```
id: String
name: String
account_type: String (e.g., "SECURITIES", "CRYPTO", "CASH")
group: Option<String>
currency: String
is_default: bool
is_active: bool
is_archived: bool
tracking_mode: TrackingMode (Transactions | Holdings | NotSet)
created_at: NaiveDateTime
updated_at: NaiveDateTime
platform_id: Option<String>
account_number: Option<String>
meta: Option<String>
provider: Option<String>
provider_account_id: Option<String>
```

#### Activity
```
id: String
account_id: String
asset_id: String
activity_type: String (BUY, SELL, DIVIDEND, INTEREST, DEPOSIT, WITHDRAWAL, TRANSFER_IN, TRANSFER_OUT, FEE, TAX, SPLIT, CONVERSION_IN, CONVERSION_OUT, STAKE, UNSTAKE)
activity_date: String
quantity: number
unit_price: number
currency: String
fee: number
is_draft: bool
comment: Option<String>
created_at: String
updated_at: String
```

#### Asset
```
id: String
isin: Option<String>
name: String
asset_type: String
symbol: String
symbol_mapping: Option<String>
asset_class: Option<String>
asset_sub_class: Option<String>
comment: Option<String>
countries: Option<String>
categories: Option<String>
classes: Option<String>
attributes: Option<String>
currency: String
data_source: String
sectors: Option<String>
url: Option<String>
quote_mode: QuoteMode
```

#### Holding
```
id: String
account_id: String
asset_id: String
symbol: String
name: String
holding_type: HoldingType
quantity: number
market_value: number
book_value: number
average_cost: number
currency: String
base_currency: String
market_value_converted: number
book_value_converted: number
unrealized_gain: number
unrealized_gain_percent: number
day_change: number
day_change_percent: number
```

#### Quote
```
id: String
created_at: String
data_source: String
date: String
symbol: String
open: number
high: number
low: number
volume: number
close: number
adjclose: number
```

#### Settings
```
id: String
theme: String
font: String
base_currency: String
```

#### Goal
```
id: String
title: String
description: Option<String>
target_amount: number
is_achieved: bool
```

#### ExchangeRate
```
id: String
from_currency: String
to_currency: String
rate: number
source: String
created_at: String
updated_at: String
```

#### ContributionLimit
```
id: String
group_name: String
contribution_year: number
limit_amount: number
account_ids: Option<String>
```

#### Taxonomy
```
id: String
name: String
description: Option<String>
is_editable: bool
created_at: String
updated_at: String
```

#### TaxonomyCategory
```
id: String
taxonomy_id: String
name: String
parent_id: Option<String>
color: Option<String>
icon: Option<String>
sort_order: i32
description: Option<String>
```

#### HealthIssue
```
id: String
severity: HealthSeverity (error | warning | info)
category: HealthCategory
title: String
description: String
affected_items: Vec<AffectedItem>
fix_action: Option<FixAction>
data_hash: String
```

#### FireSettings
```
(settings for FIRE independence calculation including target amounts, withdrawal rates, etc.)
```

#### AI Models
```
ChatThread { id, title, created_at, updated_at, tags }
ChatMessage { id, thread_id, role, content, created_at }
AiProvidersResponse { providers: Vec<MergedProvider> }
MergedProvider { id, name, models, connection_fields, capabilities }
```

#### Net Worth Models
```
NetWorthResponse { total, assets_section: AssetsSection, liabilities_section: LiabilitiesSection }
NetWorthHistoryPoint { date, total, investments, cash, alternatives, liabilities }
AlternativeAssetHolding { id, name, kind, current_value, cost_basis, currency, ... }
```

### Enums

- **AccountType**: SECURITIES, CRYPTO, CASH
- **ActivityType**: BUY, SELL, DIVIDEND, INTEREST, DEPOSIT, WITHDRAWAL, TRANSFER_IN, TRANSFER_OUT, FEE, TAX, SPLIT, CONVERSION_IN, CONVERSION_OUT, STAKE, UNSTAKE
- **AssetKind**: Stock, ETF, MutualFund, Bond, Crypto, Cash, Commodity, Alternative
- **HoldingType**: Stock, ETF, MutualFund, Bond, Crypto, Cash, Commodity, Alternative
- **QuoteMode**: Auto, Manual, None
- **TrackingMode**: Transactions, Holdings, NotSet
- **HealthSeverity**: error, warning, info
- **AlternativeAssetKind**: RealEstate, Vehicle, Collectible, PreciousMetal, Other

### Rust Crate Organization

| Crate | Purpose |
|-------|---------|
| `crates/core` | Business logic, models, services, traits |
| `crates/storage-sqlite` | SQLite storage implementation |
| `crates/market-data` | Market data fetching (Yahoo Finance, etc.) |
| `crates/ai` | AI chat and provider integration |
| `crates/connect` | Broker connection sync |
| `crates/device-sync` | Multi-device synchronization |

### Core Modules (in `crates/core/src/`)

| Module | Purpose |
|--------|---------|
| `accounts/` | Account CRUD, models, validation |
| `activities/` | Activity CRUD, CSV import, idempotency |
| `addons/` | Addon management |
| `assets/` | Asset profiles and management |
| `custom_provider/` | Custom market data providers |
| `events/` | Domain event system |
| `fx/` | Foreign exchange rates |
| `goals/` | Financial goals |
| `health/` | Portfolio health checks |
| `limits/` | Contribution limits |
| `portfolio/` | Holdings, valuations, performance calculation |
| `quotes/` | Quote management |
| `secrets/` | Secret storage abstraction |
| `settings/` | App settings |
| `sync/` | Data synchronization |
| `taxonomies/` | Asset classification system |
| `utils/` | Utility functions |
