# Artha (अर्थ) — Offline Personal Finance & Wealth Tracker

> **Artha** is an elegant, offline-first personal finance management application built with Flutter. It runs smoothly on Android, iOS, Windows, macOS, Linux, and Flutter Web (deployable to GitHub Pages).

All user data is stored strictly on your local device / browser using strongly-typed local storage. **No backend servers, no cloud databases, no authentication, and zero network calls or telemetry are required.**

---

## 🌟 Key Features

### 1. 💵 Income & Expense Management
- Quick logging for everyday expenses (Food, Groceries, Shopping, Travel, Bills, etc.).
- Salary and miscellaneous income recording (Freelance, Bonuses, Debt returned, Gifts).
- Custom category creation with custom icons, colors, and type assignment.

### 2. 📱 EMI & Loan Installment Planner
- Track high-value purchases on 3, 6, 12, or 24-month installments.
- Computes monthly installment amounts, paid/remaining installments, remaining liability, and next due dates.
- One-tap status toggle (**Mark Paid** logs the cash outflow into your transaction history; **Mark Pending** safely removes it).
- Shows upcoming due installments right on the dashboard.

### 3. 🎯 Savings & Financial Goals
- Target-based goals (e.g. *Emergency Fund*, *Vacation*, *Gadget*).
- Visual progress meters and percentage indicators.
- Instant deposit modal with income-to-savings allocation ratio.

### 4. 🪙 Physical & Digital Gold Tracker
- Record physical coins, bars, jewelry, or digital gold.
- Accepts quantities in grams (`g`) or milligrams (`mg`).
- Calculates total accumulated gold weight, total money invested, and **average purchase price per gram**.
- Evaluated as an appreciating asset in your estimated net worth.

### 5. 📊 Category Budgets
- Monthly spending limits per category (e.g., Food: ₹5,000, Shopping: ₹3,000).
- Visual color-coded status:
  - 🟢 Normal spending (< 80%)
  - 🟡 Approaching limit (80% - 100%)
  - 🔴 Exceeded / Over-budget warning (> 100%)

### 6. 🔁 Automated Recurring Rules
- Automate monthly salary and recurring expenses (Rent, WiFi, Subscriptions).
- **Zero-duplicate generation guarantee**: Evaluates idempotency keys (`ruleId_year_month`) so multiple app launches never duplicate records.

### 7. 📈 Reports & Visual Analytics
- Monthly Income vs. Total Outflow comparison bar charts.
- Category expenditure donut / pie chart distribution.
- Gold accumulation and savings portfolio growth analytics.
- Real-time **Net Worth** calculation:
  $$\text{Net Worth} = \text{Available Cash} + \text{Savings Goals} + \text{Gold Portfolio}$$

### 8. 🛡️ Data Protection, Backup & Privacy
- **Full JSON Backup**: Copy or export your entire financial database at any time.
- **Restore / Import**: Paste or load your JSON backup to restore all data instantly.
- **CSV Export**: Export all transactions to CSV for Excel or Google Sheets.
- **Erase Confirmation**: Double-confirmation dialog to protect against accidental data loss.
- **Zero Telemetry**: No analytics, trackers, or cloud dependencies.

---

## 📐 Financial Calculation Rules

Artha maintains a clear distinction between **spent money** (lost cash) and **allocated money** (saved or invested cash):

$$\text{Available Balance} = \text{Income} - (\text{Expenses} + \text{EMI Payments} + \text{Savings} + \text{Gold Investments})$$

$$\text{Total Net Worth} = \text{Available Balance} + \text{Total Savings} + (\text{Total Gold (g)} \times \text{Avg Purchase Rate})$$

*Rule: Money moved into Savings or Gold reduces current spendable cash without being classified as an expense. This prevents accidental double-deductions.*

---

## 🏗️ Clean Project Architecture

```
lib/
├── app/
│   ├── app.dart                    # GetMaterialApp, theme configuration & routing
│   ├── routes/app_routes.dart      # Named route definitions
│   └── theme/app_theme.dart        # Material 3 Light & Dark themes
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         # Financial semantic palette (Green, Red, Blue, Gold, Orange)
│   │   └── app_constants.dart      # Storage keys and defaults
│   ├── utils/
│   │   ├── currency_formatter.dart # Indian numbering system (₹1,25,000) & multi-currency
│   │   └── date_formatter.dart     # Relative and short date formatting
│   └── widgets/
│       ├── metric_summary_card.dart# Metric stat cards
│       ├── quick_add_dialog.dart   # Universal bottom sheet for instant logging
│       └── transaction_tile.dart   # Swipeable transaction card
├── data/
│   ├── local/
│   │   └── local_storage_service.dart # SharedPreferences + JSON document collections
│   ├── models/
│   │   ├── app_settings_model.dart # Theme, currency, and init flags
│   │   ├── budget_model.dart       # Category monthly limits
│   │   ├── category_model.dart     # System and user categories
│   │   ├── emi_model.dart          # EMI plans & installment schedules
│   │   ├── gold_model.dart         # Gold purchases & weight normalization
│   │   ├── recurring_model.dart    # Rules with frequency & last-run tracking
│   │   ├── saving_model.dart       # Goals & deposit records
│   │   └── transaction_model.dart  # Unified transaction model
│   └── repositories/
│       └── finance_repository.dart # Reactive controller, calculations & caching
└── features/
    ├── budgets/views/              # Budgets view
    ├── dashboard/views/            # Monthly dashboard & cash balance
    ├── emi/views/                  # EMI installment planner
    ├── gold/views/                 # Gold investment portfolio
    ├── recurring/views/            # Recurring income & expense rules
    ├── reports/views/              # Charts & visual analytics
    ├── savings/views/              # Savings goals & deposits
    ├── settings/views/             # Backup, restore & theme settings
    ├── shell/views/                # Adaptive navigation (Bottom Nav / Sidebar)
    └── transactions/views/         # Searchable, filterable transaction log
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.24.0 or newer)
- Dart SDK (v3.5.0 or newer)

### 1. Clone the repository
```bash
git clone https://github.com/<your-username>/artha.git
cd artha
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run automated tests
```bash
flutter test
```

### 4. Run the application
- **Web**:
  ```bash
  flutter run -d chrome
  ```
- **Android / iOS**:
  ```bash
  flutter run
  ```
- **Desktop (Windows / macOS / Linux)**:
  ```bash
  flutter run -d windows # or macos / linux
  ```

---

## 🌐 GitHub Pages Deployment

Artha includes an automated GitHub Actions deployment workflow at `.github/workflows/deploy.yml`.

### How to deploy to GitHub Pages:
1. Push this repository to GitHub.
2. In your GitHub repository, navigate to **Settings** → **Pages**.
3. Under **Build and deployment** → **Source**, select **GitHub Actions**.
4. Push a commit to the `main` branch (or run the workflow manually under **Actions** → **Deploy Artha to GitHub Pages** → **Run workflow**).
5. Your application will be live at:
   `https://<your-username>.github.io/<repo-name>/`

---

## 🔒 Privacy & Security

- **Zero Network Transmission**: Financial numbers, balances, and records never leave your machine.
- **Offline Reliability**: The web application uses browser IndexedDB / LocalStorage, and mobile builds store data on internal application sandbox storage.
- **Backup**: Always remember to export a JSON backup before clearing your browser cookies or cache.

---

## 📄 License
This project is licensed under the MIT License.
