# IT Helpdesk System User Manual

## 1. Overview

The IT Helpdesk System is a comprehensive support ticket management platform designed to streamline IT support operations. The system provides an intelligent, AI-assisted workflow for reporting, tracking, and resolving technical issues. Built with Firebase backend integration and real-time data synchronization, the platform enables efficient communication between end users and support engineers.

The application features a three-step ticket creation process with AI-powered solution recommendations, real-time status tracking, comprehensive filtering and search capabilities, and role-based access control for users and support engineers.

## 2. Target Audience

### 2.1 Primary Users

**End Users** are employees, students, or organizational members who experience IT-related issues and need technical support. These users can:

- Submit support tickets for technical issues
- Track the status of their submitted tickets
- View AI-generated quick fixes and recommendations
- Communicate with support engineers through ticket notes
- Access their personal dashboard with ticket statistics
- Receive notifications about ticket updates

### 2.2 System Administrators

**Support Engineers** are IT professionals responsible for managing and resolving support tickets. These users can:

- View and manage all tickets across the organization
- Filter tickets by status, priority, and category
- Search for specific tickets by keywords
- Assign tickets and update ticket status
- Monitor real-time ticket statistics and metrics
- Add notes and communicate with ticket creators
- Track resolution progress and performance metrics

## 3. Getting Started

### 3.1 System Requirements

**Minimum System Requirements:**

- **Platform**: Web browser (Chrome, Firefox, Safari, Edge), Windows, macOS, Linux, iOS, or Android
- **Internet Connection**: Stable broadband connection (minimum 1 Mbps)
- **Screen Resolution**: 1024x768 or higher (responsive design supports mobile devices from 320px width)
- **Browser Requirements**: Latest version of modern web browsers with JavaScript enabled
- **Storage**: Minimal local storage required
- **Firebase Services**: Active internet connection for cloud database synchronization

**Recommended Specifications:**

- High-speed internet connection for optimal real-time updates
- Screen resolution of 1920x1080 or higher for desktop use
- Modern multi-core processor for smooth performance

### 3.2 Installing the Application

**Web Application Access:**

The IT Helpdesk System is primarily accessed through web browsers and does not require traditional installation.

1. Navigate to the application URL provided by your organization
2. Bookmark the page for quick future access
3. The application will load automatically with responsive design adapting to your device

**Mobile/Desktop Application Installation:**

If your organization provides native applications:

1. Download the application installer from the official distribution channel
2. For Android: Install the APK from Google Play Store or provided source
3. For iOS: Download from the App Store
4. For Windows/macOS/Linux: Download and run the platform-specific installer
5. Launch the application after installation completes

**Firebase Configuration:**

The system requires active Firebase backend services (pre-configured by administrators). No end-user configuration is needed.

## 4. Logging into the System

**First-Time Registration:**

1. Navigate to the application landing page
2. Click the **Sign Up** button in the top-right navigation bar
3. Complete the registration form with the following information:
   - Full Name (minimum 2 characters)
   - Email Address (valid email format required)
   - Password (minimum 8 characters)
   - Confirm Password (must match the password field)
   - Role Selection: Choose **User** or **Engineer** based on your access level
4. Click **Sign Up** to create your account
5. Upon successful registration, you will be automatically redirected to your respective dashboard

**Returning User Sign In:**

1. From the landing page, click **Sign In**
2. Enter your registered email address
3. Enter your password
4. Click **Sign In** to access the system
5. The system will automatically redirect you to:
   - **User Dashboard** if registered as a regular user
   - **Engineer Dashboard** if registered as a support engineer

**Navigation Between Pages:**

- Use the **Back to home** link on the authentication page to return to the landing page
- The landing page displays the application logo (headset icon) and branding

## 5. Core Features & How to Use Them

### For Regular Users

**Dashboard Overview:**

Upon signing in, users are presented with a personalized dashboard displaying:

- **Welcome Message**: Personalized greeting with your first name
- **Statistics Cards**: Visual metrics showing:
  - Total tickets created
  - Open tickets
  - In Progress tickets
  - Resolved tickets
- **Recent Tickets Section**: List of your most recently submitted tickets with status indicators
- **Quick Actions**: "Create Ticket" button for immediate ticket submission

**Creating a New Support Ticket:**

The ticket creation process follows a three-step guided workflow:

**Step 1: Describe Your Issue**

1. Click **Create Ticket** from the dashboard or navigation menu
2. Fill out the issue details form:
   - **Issue Title** (required): Brief summary of your problem
   - **Category** (required): Select from:
     - Network Issues
     - Software Problems
     - Hardware Issues
     - Account & Access
     - Other
   - **Priority** (optional, default: Medium): Select severity level:
     - Low
     - Medium
     - High
     - Critical
   - **Detailed Description** (required): Comprehensive explanation including:
     - What you were doing when the issue occurred
     - Any error messages received
     - Steps to reproduce the problem
     - Impact on your work
3. Click **Continue** to proceed

**Step 2: AI-Generated Quick Fixes**

The system analyzes your issue and displays:

- **Recommended Solutions**: AI-generated troubleshooting steps specific to your issue
- **Next Steps**: Guided actions to attempt resolution
- **Estimated Resolution Time**: Expected timeframe for issue resolution

Choose one of the following options:

- **Issue Resolved**: Click this button if the AI recommendations solved your problem (ticket will be marked resolved)
- **Still Need Help**: Click this button to proceed with ticket submission to support engineers
- **Back**: Return to Step 1 to modify your issue description

**Step 3: Review & Submit**

1. Review all ticket details:
   - Title
   - Category
   - Priority
   - Description
2. Verify information accuracy
3. Click **Back** to make changes, or
4. Click **Submit Ticket** to finalize submission
5. Upon successful submission, receive confirmation and ticket reference number

**Viewing Ticket Details:**

1. From your dashboard, click on any ticket from the Recent Tickets list
2. The Ticket Detail page displays:
   - **Header Section**: Ticket title, status badge, priority indicator, category, and creation date
   - **Description Section**: Full problem description
   - **Timeline Section**: Chronological activity log including:
     - Ticket creation
     - Status changes
     - Engineer assignments
     - Notes and communications
   - **Details Sidebar**: Metadata including:
     - Created By
     - Assigned To
     - Creation Date
     - Last Updated Date
3. **Add a Note**: Communicate with support engineers by typing in the note field and clicking **Send Note**

### For Support Engineers

**Engineer Dashboard Overview:**

The engineer dashboard provides comprehensive ticket management capabilities:

**Summary Cards:**

Real-time metrics displayed at the top:

- **Open Tickets**: Count of unassigned/new tickets
- **In Progress**: Tickets currently being worked on
- **Resolved Today**: Count of tickets resolved in the current day
- **Total Tickets**: Overall ticket count across all statuses

**Search and Filter Tools:**

1. **Search Bar**: Enter keywords to search ticket titles and descriptions
2. **Status Filter**: Dropdown to filter by:
   - All
   - Open
   - In Progress
   - Resolved
3. **Priority Filter**: Dropdown to filter by:
   - All
   - Critical
   - High
   - Medium
   - Low
4. **Category Filter**: Dropdown to filter by:
   - All
   - Network Issues
   - Software Problems
   - Hardware Issues
   - Account & Access
   - Other

**Ticket List View:**

Each ticket card displays:

- Ticket title and ID
- Creation timestamp
- Creator information
- Status badge (color-coded)
- Priority indicator
- Category label

**Managing Individual Tickets:**

1. Click on any ticket to open the detailed view
2. Review ticket information and timeline
3. Add internal notes or communicate with the user
4. Update ticket status by adding resolution notes
5. Use the **Back** button to return to the dashboard

**Refreshing Data:**

Click the **Refresh** icon in the top-right corner to manually refresh ticket data (note: real-time updates occur automatically via Firebase listeners).

## 6. Step-by-Step User Workflows

### Workflow 1: Submitting a New Ticket (End User)

1. Log in to the IT Helpdesk System
2. From your dashboard, locate and click the **Create Ticket** button
3. In Step 1 (Describe Your Issue):
   - Enter a clear, concise issue title (e.g., "Cannot connect to WiFi network")
   - Select the appropriate category (e.g., "Network Issues")
   - Choose the priority level based on impact
   - Provide a detailed description including any error messages
   - Click **Continue**
4. Wait for AI analysis to complete (loading dialog displays)
5. In Step 2 (Quick Fixes):
   - Review the AI-generated recommendations carefully
   - Attempt the suggested troubleshooting steps
   - If resolved: Click **Issue Resolved** to close the ticket
   - If not resolved: Click **Still Need Help** to continue
6. In Step 3 (Review & Submit):
   - Double-check all entered information
   - Make corrections by clicking **Back** if needed
   - Click **Submit Ticket** to send to support engineers
7. Receive confirmation message with ticket details
8. You will be redirected to your dashboard where the new ticket appears

### Workflow 2: Tracking Ticket Status (End User)

1. From your dashboard, locate the **Recent Tickets** section
2. Identify your ticket by title or date
3. Note the status badge (Open, In Progress, or Resolved)
4. Click on the ticket to view full details
5. Review the **Timeline** section for all activities and updates
6. Check the **Assigned To** field to see which engineer is handling your issue
7. Add a note if you need to provide additional information
8. Use the browser's back button or navigation to return to the dashboard
9. Check the notification bell icon for any updates or messages

### Workflow 3: Managing Tickets (Support Engineer)

1. Log in to the Engineer Dashboard
2. Review the summary cards to prioritize workload
3. Use filters to focus on specific ticket types:
   - Set Status to "Open" to see new tickets
   - Set Priority to "Critical" or "High" for urgent issues
4. Use the search bar to find specific tickets by keyword
5. Click on a ticket to open the detailed view
6. Review the issue description and any AI-generated analysis
7. Investigate and work on resolving the issue
8. Add notes to document troubleshooting steps and findings
9. When resolved, add a final note explaining the resolution
10. The ticket status updates to "Resolved" automatically
11. Return to the dashboard to select the next ticket

### Workflow 4: Resolving Issues with AI Assistance

1. User submits a ticket through the creation workflow
2. System sends ticket data to AI analysis webhook
3. AI processes the issue and generates:
   - Recommended solutions based on the category and description
   - Step-by-step troubleshooting instructions
   - Estimated resolution time
4. User reviews AI recommendations in Step 2
5. If solutions are effective:
   - User clicks "Issue Resolved"
   - Ticket is marked as resolved without engineer assignment
   - System resources are conserved for complex issues
6. If AI solutions are insufficient:
   - User proceeds to submit the ticket
   - Support engineer receives the ticket with AI analysis attached
   - Engineer uses AI recommendations as starting point for investigation

### Workflow 5: Communication Through Ticket Notes

1. Navigate to the ticket detail page (available to both users and engineers)
2. Scroll to the **Add a Note** section at the bottom
3. Type your message in the text field (supports multi-line input)
4. Click **Send Note**
5. The note is immediately added to the ticket timeline with:
   - Your name
   - Timestamp
   - Note content
6. The other party receives the update in their timeline view
7. All notes are preserved in chronological order for reference

## 7. System Status & Notifications

**Notification System:**

The system provides real-time notifications through the notification bell icon in the top navigation bar.

**Notification Indicator:**

- Red badge displays the count of unread notifications
- Current implementation shows a sample count of "2"
- Click the bell icon to view notification details

**Notification Types:**

Users receive notifications for:

- Ticket status changes (Open → In Progress → Resolved)
- Engineer assignment to tickets
- New notes or messages from support engineers
- Ticket updates and modifications
- System announcements (if applicable)

**Status Indicators:**

Throughout the application, visual indicators communicate system and ticket status:

- **Status Badges**:
  - **Open** (Blue): Ticket submitted, awaiting engineer action
  - **In Progress** (Amber/Orange): Engineer actively working on the ticket
  - **Resolved** (Green): Issue successfully resolved

- **Priority Indicators**:
  - **Low** (Green): Minor issues with minimal impact
  - **Medium** (Blue): Standard issues requiring attention
  - **High** (Amber): Significant issues affecting productivity
  - **Critical** (Red): Urgent issues requiring immediate resolution

**Real-Time Updates:**

The system uses Firebase real-time database listeners to provide:

- Automatic dashboard refresh when ticket data changes
- Instant ticket status updates without page reload
- Live statistics updates on dashboard cards
- Immediate reflection of new notes and communications

**Connection Status:**

- The application requires constant internet connectivity
- If connection is lost, some features may become unavailable
- Automatic reconnection occurs when network is restored
- Unsaved data may be lost during disconnection

## 8. Administrator Functions

### 8.1 Managing Records/Entries

**Ticket Management (Engineer Role):**

Support engineers have administrative capabilities to manage tickets:

**Viewing All Tickets:**

- Access comprehensive list of all organizational tickets regardless of creator
- View tickets across all users and departments
- No restriction on ticket visibility based on assignment

**Filtering and Searching:**

- Use multiple filters simultaneously (status + priority + category)
- Search functionality scans both ticket titles and descriptions
- Filters apply instantly without page reload
- Clear filters by selecting "All" in each dropdown

**Updating Ticket Status:**

While explicit status change buttons are not present in the current implementation, tickets transition status through notes:

- Adding a resolution note automatically marks tickets as "Resolved"
- Ticket status changes are logged in the timeline
- Status changes are visible to both engineers and end users

**Bulk Operations:**

The current implementation focuses on individual ticket management. Bulk operations are not available in this version.

### 8.2 Managing System Settings

**User Profile Management:**

Both regular users and engineers can access profile settings:

1. Click on the user avatar/profile button in the top-right navigation
2. Select **Profile** from the dropdown menu (feature access point established)
3. Select **Settings** to view system preferences (feature access point established)

**Role Assignment:**

- User roles are assigned during account registration
- Role selection determines dashboard access and permissions
- Role changes require administrator intervention at the database level

**Account Security:**

- Password requirements: Minimum 8 characters
- Email validation: Standard email format enforcement
- No password reset functionality visible in current implementation

### 8.3 Viewing Reports & Results

**Dashboard Statistics:**

**For End Users:**

The user dashboard provides personal ticket metrics:

- Total number of tickets created
- Breakdown by status (Open, In Progress, Resolved)
- Visual representation through color-coded cards
- Real-time statistics via Firebase streaming

**For Support Engineers:**

The engineer dashboard provides organizational metrics:

- Total open tickets requiring attention
- In-progress ticket count across all engineers
- Resolved tickets for the current day
- Overall ticket count across all statuses and time periods

**Ticket Timeline Reports:**

Each ticket's detail page provides a complete audit trail:

- Chronological list of all activities
- Timestamp for each event
- User attribution for every action
- Automatic logging of status changes and notes

**Performance Insights:**

Current visible metrics include:

- Resolution volume per day (Resolved Today count)
- Ticket distribution by status
- Priority distribution across tickets
- Category-based ticket grouping

**Export Capabilities:**

No explicit export functionality (PDF, Excel, CSV) is visible in the current implementation. Data resides in Firebase Firestore and can be accessed via database queries.

## 9. Frequently Asked Questions (FAQ)

**Q1: What should I do if I forget my password?**

A: The current implementation does not display a password reset feature on the sign-in page. Contact your system administrator or IT support team directly to reset your password through the Firebase authentication console.

**Q2: How long does it typically take to get a response to my ticket?**

A: The AI analysis provides an estimated resolution time when you submit a ticket. Generally, support engineers review new tickets within business hours, with critical priority tickets receiving immediate attention.

**Q3: Can I delete or edit a ticket after submission?**

A: The current system does not provide ticket deletion or editing features for end users. If you need to modify information, add a note to the ticket with the correct details or create a new ticket.

**Q4: What priority level should I select for my issue?**

A:

- **Low**: Minor inconveniences that do not significantly impact your work
- **Medium**: Standard issues that reduce productivity but have workarounds
- **High**: Significant problems affecting your ability to work effectively
- **Critical**: Urgent issues completely blocking your work or affecting multiple users

**Q5: Can I reopen a resolved ticket?**

A: The system does not currently display a reopen function. If your issue recurs after resolution, submit a new ticket and reference the previous ticket number in the description.

**Q6: How do I know if an engineer has been assigned to my ticket?**

A: Open the ticket detail page and check the "Assigned To" field in the Details sidebar. The timeline also shows when an engineer is assigned to your ticket.

**Q7: What if the AI recommendations don't solve my problem?**

A: Click the "Still Need Help" button in Step 2 to proceed with submitting your ticket to support engineers. Engineers will have access to the AI analysis and can build upon those recommendations.

**Q8: Can I submit a ticket on behalf of someone else?**

A: Yes, you can submit tickets for others. Include the affected person's name and contact information in the ticket description. The ticket will be associated with your account.

**Q9: Are there any file attachment options for tickets?**

A: The current implementation does not display file attachment functionality. Describe your issue in text, or contact your IT department for alternative methods to share files.

**Q10: How do I receive notifications when my ticket is updated?**

A: Notifications appear in the notification bell icon (top navigation bar). The red badge displays the count of new notifications. Click the bell to view details.

**Q11: What categories should I choose for common issues?**

A:

- **Network Issues**: WiFi connection, VPN access, internet connectivity
- **Software Problems**: Application crashes, software installation issues, license problems
- **Hardware Issues**: Computer problems, printer issues, peripheral device failures
- **Account & Access**: Login problems, password issues, permission requests
- **Other**: Issues not fitting the above categories

**Q12: Can support engineers see all my tickets or just the current one?**

A: Support engineers have access to view all tickets across the organization for management and coordination purposes. However, ticket access is governed by professional responsibility and organizational policies.

## 10. System Messages and Their Meanings

| Message                                                                 | Type                 | Meaning                                             | Recommended Action                                 |
| ----------------------------------------------------------------------- | -------------------- | --------------------------------------------------- | -------------------------------------------------- |
| "Email is required"                                                     | Validation Error     | Email field was left empty during authentication    | Enter your email address in the email field        |
| "Enter a valid email address"                                           | Validation Error     | Email format is incorrect (missing @, domain, etc.) | Check email format: example@domain.com             |
| "Password is required"                                                  | Validation Error     | Password field was left empty                       | Enter your password                                |
| "Password must be at least 8 characters"                                | Validation Error     | Password is too short (sign up only)                | Create a password with at least 8 characters       |
| "Full name is required"                                                 | Validation Error     | Name field empty during sign up                     | Enter your full name                               |
| "Name must be at least 2 characters"                                    | Validation Error     | Name too short                                      | Enter your complete name                           |
| "Please select your role"                                               | Validation Error     | No role selected during sign up                     | Choose either User or Engineer role                |
| "Passwords do not match"                                                | Validation Error     | Password and Confirm Password fields differ         | Ensure both password fields contain identical text |
| "Password is too weak. Use a stronger password."                        | Authentication Error | Firebase rejected weak password                     | Add complexity: uppercase, numbers, symbols        |
| "An account with this email already exists."                            | Authentication Error | Email already registered in system                  | Use sign in instead, or use different email        |
| "No account found with this email."                                     | Authentication Error | Sign in attempted with unregistered email           | Verify email spelling or create new account        |
| "Incorrect password. Please try again."                                 | Authentication Error | Wrong password entered                              | Re-enter correct password or reset password        |
| "Invalid email address format."                                         | Authentication Error | Email format rejected by Firebase                   | Verify email format correctness                    |
| "This account has been disabled."                                       | Authentication Error | Account administratively locked                     | Contact system administrator                       |
| "Too many attempts. Please try again later."                            | Authentication Error | Excessive failed login attempts detected            | Wait several minutes before retrying               |
| "Authentication is currently disabled."                                 | System Error         | Firebase authentication service unavailable         | Contact system administrator                       |
| "Authentication failed: [details]"                                      | General Error        | Unhandled authentication error                      | Note error details and contact support             |
| "An unexpected error occurred. Please try again."                       | General Error        | Non-Firebase exception occurred                     | Retry action; contact support if persistent        |
| "Please enter an issue title"                                           | Validation Error     | Ticket title field empty                            | Enter a descriptive title for your issue           |
| "Please select a category"                                              | Validation Error     | Category not selected in ticket form                | Choose appropriate category from dropdown          |
| "Please provide a detailed description"                                 | Validation Error     | Description field empty                             | Enter comprehensive issue description              |
| "IT helpdesk is looking for a solution to your problem. Please wait..." | Information          | AI analysis in progress                             | Wait for analysis to complete (up to 30 seconds)   |
| "Issue Resolved" Button Response                                        | Success              | User confirmed AI recommendations solved issue      | Ticket marked resolved and redirected to dashboard |
| "Submitting..."                                                         | Processing           | Ticket submission in progress                       | Wait for confirmation message                      |
| "Note added successfully"                                               | Success              | Note posted to ticket timeline                      | Note visible in ticket timeline                    |
| "Error adding note: [details]"                                          | Error                | Note submission failed                              | Check connection and retry                         |
| "Ticket not found"                                                      | Error                | Invalid ticket ID or deleted ticket                 | Verify ticket exists; return to dashboard          |
| "Unable to retrieve AI solutions at this time..."                       | Warning              | AI webhook failed or timed out                      | Proceed with ticket submission to engineers        |

## 11. Troubleshooting

**Problem: Cannot log in with correct credentials**

Possible Causes:

- Network connectivity issues preventing Firebase authentication
- Browser cookies or cache corruption
- Account disabled by administrator
- Caps Lock enabled during password entry

Solutions:

1. Verify internet connection is stable and active
2. Check Caps Lock key is off
3. Clear browser cache and cookies for the application domain
4. Try accessing from a different browser or incognito/private mode
5. Wait 15 minutes if "too many attempts" error appears
6. Contact system administrator if issue persists

---

**Problem: Ticket submission fails or times out**

Possible Causes:

- Poor internet connection
- AI webhook service unavailable (localhost:5678)
- Firestore database connection issues
- Firebase services temporarily down

Solutions:

1. Check your internet connection strength and stability
2. Verify all required fields are completed correctly
3. Try submitting again after a few minutes
4. If AI analysis loading persists beyond 60 seconds, refresh the page and try again
5. Contact IT administrator to verify Firebase service status
6. Check browser console for specific error messages (F12 Developer Tools)

---

**Problem: Dashboard does not show my tickets**

Possible Causes:

- Tickets not yet created
- Firebase query filter excluding your tickets
- Real-time listener not established
- User ID mismatch in database

Solutions:

1. Verify you have created tickets while logged in with this account
2. Refresh the browser page (Ctrl+F5 or Cmd+Shift+R)
3. Log out and log back in to reset Firebase listeners
4. Clear browser cache and reload application
5. Verify correct user account is signed in (check profile menu)
6. Contact administrator to verify ticket data in Firestore database

---

**Problem: Status badges or statistics not updating**

Possible Causes:

- Real-time listener disconnected
- Stale data in browser
- Firebase rules preventing read access
- Network latency or intermittent connection

Solutions:

1. Click the Refresh button in the engineer dashboard (if available)
2. Reload the entire page to re-establish listeners
3. Check internet connection stability
4. Log out and log back in
5. Try accessing from a different device to verify data exists
6. Contact administrator to check Firebase security rules

---

**Problem: AI recommendations not appearing**

Possible Causes:

- Webhook endpoint not accessible (http://localhost:5678)
- Network firewall blocking webhook requests
- AI service (n8n) not running
- Timeout during AI analysis (30-second limit)

Solutions:

1. Wait for the full 30-second timeout period
2. Continue with ticket submission using "Still Need Help" button
3. Engineers will still receive your ticket even without AI analysis
4. Contact IT administrator to verify webhook service status
5. Verify network allows connections to localhost:5678 (development environment)

---

**Problem: Notifications not appearing**

Possible Causes:

- Notification system UI is a static placeholder in current version
- Real-time notification listener not implemented
- Browser notification permissions denied

Solutions:

1. Note that notification count may be a UI placeholder
2. Manually check ticket detail pages for updates
3. Regularly refresh dashboard to see ticket status changes
4. Enable browser notifications if prompted
5. Check Firebase for notification implementation status

---

**Problem: Unable to add notes to tickets**

Possible Causes:

- Firebase Firestore write permissions issue
- Network disruption during note submission
- Authentication token expired
- Database rules restricting write access

Solutions:

1. Verify internet connection is active
2. Try logging out and logging back in
3. Check if note field has character limits or restrictions
4. Attempt from different browser or device
5. Contact administrator to verify Firestore security rules allow note creation

---

**Problem: Page layout appears broken or unresponsive**

Possible Causes:

- Browser compatibility issues
- JavaScript errors preventing proper rendering
- CSS not loading correctly
- Screen resolution too low

Solutions:

1. Ensure using a modern browser (Chrome, Firefox, Safari, Edge latest versions)
2. Enable JavaScript in browser settings
3. Clear browser cache and reload page (Ctrl+Shift+R)
4. Check browser console for JavaScript errors (F12)
5. Try accessing from different device or browser
6. Ensure minimum screen resolution of 1024x768
7. Disable browser extensions that may interfere with page rendering

---

**Problem: Engineer dashboard shows no tickets despite users submitting them**

Possible Causes:

- Filter settings hiding all tickets
- Firebase query limitations
- Tickets created in different Firebase project
- Database permissions preventing engineer access

Solutions:

1. Reset all filters to "All" (Status, Priority, Category)
2. Clear search field to remove keyword filters
3. Click Refresh button to manually reload data
4. Verify correct Firebase project is configured
5. Check Firebase console to confirm tickets exist in database
6. Verify engineer role is correctly assigned in user document
7. Contact administrator to review Firestore security rules

---

**Problem: Application performance is slow**

Possible Causes:

- Poor internet connection
- Large number of tickets in database causing query delays
- Firebase quota limitations
- Device hardware limitations

Solutions:

1. Test internet connection speed
2. Close unnecessary browser tabs and applications
3. Use filters to reduce number of tickets displayed
4. Clear browser cache and cookies
5. Restart browser application
6. Contact administrator about Firebase performance optimization
7. Consider upgrading internet connection or device hardware

## 12. Glossary

**AI Analysis** - Automated analysis of ticket content using artificial intelligence to generate solution recommendations, troubleshooting steps, and estimated resolution times.

**Assigned To** - The support engineer designated to investigate and resolve a specific ticket.

**Category** - Classification of tickets by issue type: Network Issues, Software Problems, Hardware Issues, Account & Access, or Other.

**Created By** - The user who originally submitted the ticket; visible in ticket details.

**Dashboard** - The main view after logging in that displays ticket statistics, recent activity, and quick action buttons. Variants include User Dashboard and Engineer Dashboard.

**Engineer Dashboard** - Administrative view for support engineers showing all tickets with advanced filtering, search, and management capabilities.

**Firebase** - Cloud-based backend platform providing authentication, real-time database (Firestore), and hosting services for the application.

**Firestore** - Firebase's NoSQL cloud database used to store tickets, user information, and system data with real-time synchronization.

**Landing Page** - The initial page users see before authentication, containing application branding and sign in/sign up buttons.

**Note** - A communication message added to a ticket's timeline by either the ticket creator or support engineer.

**Notification** - Real-time alerts about ticket updates, status changes, or messages, indicated by the bell icon with badge count.

**Priority** - Urgency classification for tickets: Low, Medium, High, or Critical, indicating the required response speed.

**Quick Fixes** - AI-generated troubleshooting solutions presented in Step 2 of the ticket creation workflow before formal submission.

**Real-time Updates** - Automatic data synchronization using Firebase listeners that update displays without requiring page refresh.

**Role** - User access level designated during registration: User (end user submitting tickets) or Engineer (IT support staff managing tickets).

**Status** - Current state of a ticket: Open (new/unworked), In Progress (actively being addressed), or Resolved (completed).

**Status Badge** - Color-coded visual indicator showing ticket status: Blue (Open), Amber (In Progress), Green (Resolved).

**Ticket** - A formal support request record containing issue details, communications, status, and resolution history.

**Ticket Detail Page** - Comprehensive view of an individual ticket showing description, timeline, notes, metadata, and communication interface.

**Ticket ID** - Unique identifier assigned to each ticket, used for tracking and reference purposes in the database.

**Timeline** - Chronological activity log within a ticket showing all events, status changes, assignments, and notes with timestamps.

**User Dashboard** - Personal view for end users displaying their own ticket statistics and recent ticket submissions.

**Webhook** - Automated HTTP endpoint (http://localhost:5678/...) that receives ticket data and returns AI-generated analysis and recommendations.

**Widget** - A UI component such as statistics cards, filter dropdowns, or status badges that provides specific functionality or information display.

---

_This manual is based on the IT Helpdesk System version 1.0.0. Features and functionality may be updated in future releases. For technical support or questions not covered in this manual, contact your organization's IT support team or system administrator._
