# TechEase — Project Overview

---

## 1. What Problem Does Your Project Fix?

Most organizations handle IT support through informal channels — emails, phone calls, and walk-ins. This creates a cascade of issues:

- **No structured incident tracking** — issues get lost, forgotten, or duplicated.
- **Inconsistent prioritization** — critical problems may sit beside trivial ones with no clear ordering.
- **Zero visibility** — users have no idea what is happening with their reported issue after they submit it.
- **Weak accountability** — when a ticket moves between staff members, context and ownership evaporate.
- **Slow first-line response** — engineers waste time on simple, repetitive issues that users could self-resolve with guidance.
- **No performance data** — IT management cannot measure response times, ticket volumes, or workload distribution.

**TechEase fixes all of this** by providing a centralized, AI-assisted IT helpdesk platform that:

- Enforces structured ticket submission (category, priority, description) through a guided 3-step workflow.
- Automatically delivers AI-generated troubleshooting steps at the moment of submission, so users can attempt self-resolution before escalating.
- Gives end users real-time visibility into their ticket status (Open → In Progress → Resolved).
- Gives engineers a live, filterable queue of all tickets across the organization.
- Maintains a full activity timeline on every ticket — who did what, and when.

---

## 2. What Is Unique About Your Project?

TechEase is not a plain ticketing form. Several design decisions set it apart:

### AI Quick-Fix at Submission Time
Before a ticket ever reaches an engineer, TechEase sends the ticket details to an AI pipeline (via n8n webhook) and returns:
- **Recommended Solutions** — step-by-step troubleshooting.
- **Next Steps** — guided actions if initial steps fail.
- **Estimated Resolution Time** — realistic expectation setting.

The user can then mark the issue resolved on the spot, without any engineer involvement. This reduces first-line support workload significantly.

### Three-Step Guided Ticket Creation
Instead of a blank text box, users are walked through:
1. **Step 1** — Describe the issue (title, category, priority, description).
2. **Step 2** — Review AI-generated quick fixes and attempt self-resolution.
3. **Step 3** — Confirm all details before final submission.

This ensures complete, accurate data reaches engineers — no more vague "my computer is broken" tickets.

### Multi-Format AI Response Parsing
The AI integration handles multiple JSON response structures (structured arrays, nested JSON, raw text) through a 4-level fallback parsing strategy, making it robust against inconsistent AI output formats.

### Real-Time Dashboards (No Refresh Needed)
Both the user and engineer dashboards use Firestore StreamBuilder listeners, meaning every metric card updates instantly the moment any ticket is created, updated, or resolved — without any page refresh.

### Role-Based Dual-Dashboard Architecture
- **End Users** see only their own tickets, their stats, and self-service tools.
- **Engineers** see the full ticket queue with advanced multi-dimensional filtering (status + priority + category + keyword search simultaneously).

Two completely separate dashboard experiences built from the same authentication system.

### Fully Cross-Platform
Built in Flutter, TechEase runs identically on Web, Android, iOS, Windows, macOS, and Linux — from a single codebase. Responsive breakpoints (mobile < 600px, tablet 600–1024px, desktop ≥ 1024px) ensure a consistent, optimized experience on every device.

### Activity Timeline Per Ticket
Every ticket carries a chronological log of all events: creation, status changes, engineer assignments, and notes — each stamped with the person's name and timestamp. This creates a complete audit trail with no extra effort.

---

## 3. How Can a Company Benefit From Your Project?

### Operational Benefits

| Benefit | How TechEase Delivers It |
|---|---|
| Reduced first-line support cost | AI quick-fixes resolve simple issues before they reach engineers |
| Faster mean time to resolution | Structured submissions mean engineers start with complete information |
| No dropped tickets | Every issue is logged, tracked, and visible until resolved |
| Scalable support operations | One engineer dashboard handles any volume with real-time filtering |
| Accountability and traceability | Timeline logs every action and every person involved |
| Data-driven IT management | Live metrics on open, in-progress, and resolved tickets |

### Who Benefits Most

**Mid-size to large organizations (50–5,000+ employees)** with internal IT departments gain the most — specifically:

- **Technology companies** managing distributed engineering teams.
- **Financial institutions** requiring secure, traceable incident handling.
- **Healthcare facilities** where system downtime has direct operational consequences.
- **Educational institutions** (universities, colleges) with large user bases and thin IT staff.
- **Government agencies** needing audit trails and structured support workflows.
- **Manufacturing companies** where equipment and software downtime halts production.

### Cost Justification
Even a modest 20–30% reduction in tier-1 support escalations (through AI self-resolution) translates directly into fewer engineer-hours spent on repetitive issues, lower support staffing costs, and faster resolution for genuinely complex problems.

---

## 4. What Reports Does It Produce?

TechEase currently generates the following live and on-demand reports:

### 4.1 User Dashboard Report
**Location:** User dashboard (home screen after login)
**Metrics Displayed:**
- Total Open tickets (user's own).
- Pending Response tickets (In Progress status).
- Resolved This Month count (filtered to current calendar month).
- Recent Tickets list — chronological view of the user's most recent submissions with status badges.

**Data source:** Real-time Firestore stream filtered to the authenticated user's UID.

---

### 4.2 Engineer Operations Report
**Location:** Engineer dashboard (home screen after engineer login)
**Metrics Displayed:**
- Open Tickets — total count across all users.
- In Progress — total active tickets being worked on.
- Resolved Today — tickets resolved within the current calendar day.
- Total Tickets — full count of all tickets in the system.

**Data source:** Real-time Firestore stream of the full tickets collection.

---

### 4.3 Filtered Ticket Queue Report
**Location:** Engineer dashboard ticket list
**Capabilities:**
- Filter by Status: All / Open / In Progress / Resolved.
- Filter by Priority: All / Critical / High / Medium / Low.
- Filter by Category: All / Network Issues / Software Problems / Hardware Issues / Account & Access / Other.
- Keyword search across ticket title and description (case-insensitive).
- Filters combine — e.g., show only "Critical + Open + Network Issues" tickets simultaneously.

**Display per ticket card:** Title, description preview, status badge, priority, category, creator name, creation timestamp.

---

### 4.4 Ticket Detail Report
**Location:** Individual ticket page (accessible by both users and engineers)
**Sections:**
- Full problem description.
- Metadata — creator, assigned engineer, creation date, last updated date.
- Activity Timeline — chronological log of all events (creation, status changes, notes, assignments) with person name and timestamp.
- AI Recommendations — the solutions generated at submission time (if available).
- Notes — ability to add comments that append to the timeline.

---

### 4.5 AI Recommendations Report
**Location:** Step 2 of the ticket creation workflow
**Content:**
- Recommended Solutions (step-by-step troubleshooting).
- Next Steps (follow-up actions).
- Estimated Resolution Time.

**Generated by:** n8n AI webhook using the ticket's title, category, priority, and description as inputs.

---

## 5. What Computations Does It Do?

### User Dashboard Computations
```
Open Tickets        = count of user's tickets WHERE status == "Open"
Pending Response    = count of user's tickets WHERE status == "In Progress"
Resolved This Month = count of user's tickets WHERE status == "Resolved"
                      AND updatedAt.year == currentYear
                      AND updatedAt.month == currentMonth
```

### Engineer Dashboard Computations
```
Open Tickets    = count of ALL tickets WHERE status == "Open"
In Progress     = count of ALL tickets WHERE status == "In Progress"
Resolved Today  = count of ALL tickets WHERE status == "Resolved"
                  AND updatedAt.year == today.year
                  AND updatedAt.month == today.month
                  AND updatedAt.day == today.day
Total Tickets   = count of ALL tickets (no filter)
```

### Multi-Dimensional Filter Algorithm
Applied in real time on the engineer ticket list:
```
For each ticket:
  EXCLUDE if selectedStatus  != "All" AND ticket.status   != selectedStatus
  EXCLUDE if selectedPriority != "All" AND ticket.priority != selectedPriority
  EXCLUDE if selectedCategory != "All" AND ticket.category != selectedCategory
  EXCLUDE if searchQuery is not empty
             AND ticket.title.toLowerCase() does not contain searchQuery
             AND ticket.description.toLowerCase() does not contain searchQuery
  Otherwise INCLUDE
```

### AI Payload Construction
At ticket creation (Step 1 → Step 2), the system constructs and dispatches:
```json
{
  "title":         "<user input>",
  "category":      "<selected category>",
  "priority":      "<selected priority>",
  "description":   "<user input>",
  "createdBy":     "<display name>",
  "createdByEmail":"<email>",
  "timestamp":     "<ISO 8601 datetime>"
}
```
This is sent to the n8n webhook (POST, 30-second timeout) and the response is parsed through a 4-level fallback strategy to extract solutions, next steps, and estimated time.

### Form Validation Computations
- Name length ≥ 2 characters.
- Email matches regex pattern for valid email format.
- Password length ≥ 8 characters (sign-up only).
- Password === confirm password (sign-up only).
- Ticket title and description must not be empty before step progression.

### Responsive Layout Computations
```
screenWidth < 600    → mobile layout
screenWidth 600–1024 → tablet layout
screenWidth > 1024   → desktop layout
```
Typography, spacing, and column counts are computed from these breakpoints throughout the app.

---

## 6. Features Not Yet Achieved — Suggested Additions

The following capabilities are partially scaffolded in the codebase (UI elements exist but callbacks are empty) or entirely absent. Here is how each could be added:

---

### 6.1 Analytics & Trend Reports (Missing)
**Current gap:** There is no historical trend analysis, date-range filtering, or performance charting.

**Suggested addition:** Add an Analytics page to the engineer navigation with:
- **Average resolution time** per category/priority — compute `resolvedAt - createdAt` for all resolved tickets.
- **Ticket volume trend** — group ticket counts by week/month and plot a line chart.
- **Category breakdown** — pie or bar chart of tickets by category.
- **Engineer workload** — count of tickets assigned to each engineer.
- **SLA compliance rate** — percentage of tickets resolved within target time by priority.

Use the `fl_chart` Flutter package (MIT licensed, minimal setup) to render charts. All data is already in Firestore.

---

### 6.2 Ticket Assignment Workflow (Partially Missing)
**Current gap:** Tickets have `assignedTo` and `assignedToName` fields in Firestore, but no UI exists for engineers to claim or assign tickets.

**Suggested addition:**
- Add an "Assign to Me" button on ticket detail pages (visible to engineers only).
- Add a dropdown to assign to any engineer (fetch from `users` collection where `role == "engineer"`).
- Write `assignedTo` (UID) and `assignedToName` to Firestore on assignment.
- Append a timeline entry: `"Assigned to [engineer name]"`.

---

### 6.3 Notifications System (Scaffolded, Not Implemented)
**Current gap:** Notification bell with badge "2" exists in the UI but `onPressed` is empty.

**Suggested addition:**
- Create a `notifications` Firestore subcollection per user.
- Write a notification document when: a ticket is assigned, a status changes, or a note is added.
- Display a dropdown list on bell press using a `PopupMenuButton` or `OverlayEntry`.
- Mark notifications as read on view; update badge count dynamically.
- Use Firebase Cloud Messaging (FCM) for push notifications on mobile/desktop.

---

### 6.4 Status Update Controls for Engineers (Partially Missing)
**Current gap:** Engineers can only change status indirectly (adding a note auto-sets status to Resolved). There is no explicit status control.

**Suggested addition:** On the ticket detail page (engineer view), add a status selector:
- Dropdown or segmented button: Open → In Progress → Resolved.
- On change, update `status` and `updatedAt` in Firestore.
- Append timeline entry: `"Status changed to [new status] by [engineer name]"`.

---

### 6.5 Profile & Settings Pages (Scaffolded, Not Implemented)
**Current gap:** Profile and Settings are in navigation menus but have empty callbacks.

**Suggested addition:**
- **Profile page:** Display and allow editing of name and email. Update `users/{uid}` in Firestore and `FirebaseAuth.currentUser`.
- **Settings page:** Allow toggling notification preferences. Store settings in `users/{uid}/settings` subdocument.

---

### 6.6 File Attachments on Tickets (Missing)
**Current gap:** No file upload capability exists — users cannot attach screenshots or logs.

**Suggested addition:**
- Add a file picker button on ticket creation Step 1 using the `file_picker` Flutter package.
- Upload files to Firebase Storage under `tickets/{ticketId}/attachments/`.
- Store download URLs in the ticket document as an `attachments` array.
- Display attached files (images inline, others as download links) on the ticket detail page.

---

### 6.7 Automatic Priority Escalation / SLA Warnings (Missing)
**Current gap:** No time-based escalation logic exists.

**Suggested addition:**
- Define SLA targets per priority (e.g., Critical = 4h, High = 8h, Medium = 24h, Low = 72h).
- In the engineer dashboard, compute `elapsedTime = now - ticket.createdAt`.
- If `elapsedTime > SLA target`, highlight the ticket card in red and surface it at the top of the queue.
- Optionally, use Firebase Cloud Functions (scheduled trigger) to send escalation notifications.

---

### 6.8 Exportable Reports (Missing)
**Current gap:** All reports are visual on-screen only — no way to download or share data.

**Suggested addition:**
- Add an "Export to CSV" button on the engineer dashboard ticket list.
- Build a CSV string from the filtered ticket list and trigger a browser download using the `dart:html` `AnchorElement` API (Flutter Web) or the `path_provider` + `share_plus` packages on mobile.
- Fields to export: Ticket ID, Title, Category, Priority, Status, Created By, Assigned To, Created Date, Resolved Date, Resolution Time (hours).

---

*Generated April 2026 — based on full codebase analysis of TechEase (Flutter + Firebase + n8n).*
