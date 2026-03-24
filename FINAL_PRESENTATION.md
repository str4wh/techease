# TechEase — AI-Powered IT Support Ticketing System

Final Year Project II Presentation Report

Student Name: Thuo Schola Nyambura  
Registration Number: 23/06105  
Institution: KCA University, School of Technology  
Supervisor: Isaac Okola

## Chapter One

### Background

Organizations across Kenya continue to manage internal IT incidents through email threads and phone calls that do not provide standardized case handling or traceable service history. This practice causes weak visibility of issue progress, inconsistent prioritization, and reduced accountability when incidents move between support personnel. TechEase addresses this operational gap by providing a centralized digital ticketing platform that combines structured issue reporting with automated first-line troubleshooting support. The system applies artificial intelligence through an n8n webhook that analyzes user-submitted issue details and returns immediate troubleshooting guidance before escalation. This architecture supports faster response, cleaner documentation, and clearer ownership of support tasks within institutions and organizations.

[SCREENSHOT: Landing page introducing TechEase and role-based access]

### Problem Statement

The existing IT support process in many organizations remains reactive and fragmented, which means recurring technical problems are frequently handled without a consistent record or formal categorization. Users often provide incomplete issue details through unstructured communication channels, which slows triage and causes support teams to spend additional time collecting context before they begin resolution. Engineers therefore receive requests with limited diagnostic value, while management lacks live visibility into ticket volume, status distribution, and service performance trends. TechEase solves this problem by implementing a structured three-step ticket creation process, AI-assisted quick fix recommendations, and a real-time dashboard experience that preserves the full lifecycle of each ticket from creation to closure.

[SCREENSHOT: Comparative workflow image showing manual support process versus TechEase workflow]

### Objectives

The project objective is to design and develop an AI-assisted IT helpdesk platform that supports reliable ticket submission, intelligent first-line troubleshooting, and role-based escalation management. The system enables end users to submit incidents using a guided data capture workflow that standardizes title, category, priority, and description fields for better triage quality. The platform then invokes an n8n webhook to generate quick fix recommendations that users can apply immediately, which reduces unnecessary escalations for solvable issues. When issues remain unresolved, the system escalates complete ticket records to engineers through a dedicated operational dashboard that supports search, filtering, status updates, and timeline-based collaboration. The project also delivers real-time analytics and ticket statistics for both users and engineers through live Firestore listeners that refresh information without page reload.

[SCREENSHOT: Three-step ticket creation workflow diagram]

### Significance of Project

TechEase is significant because it transforms IT support from informal communication into a structured service process with traceable outcomes and measurable performance. The platform reduces first-line workload by resolving simple incidents through AI-generated guidance before engineer intervention becomes necessary. It improves accountability by maintaining a chronological timeline of ticket activity and notes, which creates a dependable record for audits, review, and service improvement. It also strengthens operational decision-making by presenting real-time dashboard statistics for open, in-progress, and resolved tickets, allowing teams to prioritize effort based on live demand. The project therefore contributes practical value to organizations that need scalable support operations with improved transparency and faster response cycles.

[SCREENSHOT: User dashboard with real-time statistics and recent tickets]

## Chapter Two

### 2.1 Literature Review

Contemporary IT service management literature emphasizes that structured incident workflows and centralized records improve resolution speed, service consistency, and institutional learning across repeated issues. Digital helpdesk systems are widely recognized for introducing standard classification and prioritization models that replace ad hoc support communication with controlled service pipelines. Research on AI-enhanced support systems further indicates that automated recommendation engines can reduce the burden on technical teams by addressing recurring low-complexity issues at the point of first contact. In the TechEase context, this principle is implemented through an n8n AI webhook that processes user-provided issue details and returns contextual quick fixes before escalation. Studies in real-time collaborative systems also highlight that live data synchronization improves situational awareness and reduces response latency, which aligns with the use of Cloud Firestore listeners in this project for immediate dashboard and ticket state updates.

[SCREENSHOT: Literature synthesis diagram linking ITSM, AI support, and real-time systems]

### 2.2 Systems Requirements Specifications

The system requires a cross-platform client application built with Flutter and Dart so that a single codebase serves web, Android, and desktop targets while preserving consistent user experience. It requires secure identity and access control through Firebase Authentication to enforce role-based separation between Users and Engineers from login to dashboard operations. Persistent ticket and collaboration data requires Cloud Firestore collections and subcollections that support low-latency reads, real-time listeners, and robust document indexing for search and filtering behavior. The application requires an external webhook endpoint in n8n that accepts ticket payloads containing category and description fields, executes AI-based processing, and returns structured troubleshooting recommendations for presentation in Step 2 of ticket creation. Functional requirements include registration and sign-in for both roles, guided three-step ticket creation, AI quick fix display, escalation to engineer queues, ticket detail timelines, notes exchange, and status tracking with color-coded badges. Non-functional requirements include responsive performance across supported platforms, reliable real-time updates, clear interface usability, secure role enforcement, and maintainable component structure for future feature extension.

[SCREENSHOT: System architecture diagram showing Flutter, Firebase Authentication, Firestore, and n8n integration]

## Chapter Three

### 3.1 Data Collection Methods

The project uses a requirements-driven data collection approach that combines problem-context analysis with operational workflow modeling for IT support environments. Information is collected from the practical challenges observed in organizations that rely on manual support handling, where issue categorization, progress tracking, and accountability records are commonly insufficient. Functional requirements are derived from target user interactions that include account onboarding, ticket submission, troubleshooting review, escalation, engineer processing, and notes-based communication. Data structure requirements are captured through entity-field mapping for users, tickets, and ticket notes, ensuring each transaction stores sufficient context for lifecycle tracking. Test-relevant data scenarios are further generated from typical support cases across categories and priorities to validate dashboard statistics, filters, timeline rendering, and real-time state synchronization.

[SCREENSHOT: Requirements elicitation and data mapping workflow]

### 3.2 Systems Design Specifications

TechEase adopts a modular client-cloud architecture that separates presentation logic, authentication, ticket persistence, and AI assistance into interoperable layers. The interface layer includes a landing page, authentication views, role-specific dashboards, ticket creation stages, and detailed ticket timelines so that each user action follows a coherent process path. The application layer enforces workflow transitions from ticket drafting to AI recommendation to escalation decision while preserving data integrity between steps. The data layer uses a Users collection that stores name, email, role, and creation timestamp, and a Tickets collection that stores title, category, priority, description, status, createdBy, assignedTo, createdAt, and updatedAt fields. Each ticket document includes a Notes subcollection containing author name, content, and timestamp records to preserve communication history in chronological sequence. Integration design includes a webhook request from Step 1 to n8n that returns a structured quick-fix response to Step 2, after which unresolved issues are persisted to Firestore for engineer action.

[SCREENSHOT: Entity relationship view of Users, Tickets, and Notes data model]

[SCREENSHOT: Sequence diagram for Step 1 to n8n AI response to Step 2 display]

### 3.3 Test Plan

The test plan validates the complete operational scope of the system from identity handling to ticket lifecycle completion under normal and edge-case conditions. Authentication testing verifies successful registration and sign-in for both User and Engineer roles while confirming proper role-based redirection to the relevant dashboard view. Workflow testing verifies the three-step ticket creation process by confirming that Step 1 captures required fields, Step 2 displays webhook-generated AI recommendations, and Step 3 presents accurate review data before submission. Integration testing confirms that unresolved ticket escalation creates Firestore records that appear on the Engineer Dashboard with correct metadata and searchable attributes. Functional testing verifies filter behavior by status, priority, and category together with keyword search responsiveness on engineer ticket lists. Collaboration testing verifies note submission and timeline ordering to ensure all ticket activities appear chronologically with proper attribution. Real-time testing verifies that ticket status changes and metric updates propagate instantly across dashboards without manual refresh. Error-handling tests verify expected system responses during authentication failure, invalid credentials, and interrupted network scenarios.

[SCREENSHOT: Test execution matrix overview for authentication, workflow, and integration]

### 3.4 Implementation Plan

Implementation proceeds through iterative phases that prioritize foundational access control, core ticket workflow, AI integration, and operational monitoring features. The first phase establishes Flutter project structure and role-based authentication with Firebase so that secure user onboarding and dashboard routing are stable. The second phase implements ticket data schemas and user dashboard statistics through Firestore queries and listeners to ensure baseline ticket visibility. The third phase delivers the guided three-step creation flow and connects Step 1 payload submission to the n8n webhook for AI quick fix generation in Step 2. The fourth phase implements escalation persistence and engineer dashboard controls that include searching, filtering, and status progression handling. The fifth phase introduces ticket detail timelines and notes communication to complete end-to-end case documentation. Final implementation cycles focus on cross-platform validation, usability refinement, and reliability testing so that the production-ready system demonstrates consistent behavior across supported environments.

[SCREENSHOT: Implementation roadmap timeline]

## Chapter Four

### 4.1 Graphical User Interface Test Results

Graphical interface testing confirms that the core user journey remains clear, responsive, and consistent across major application screens and role pathways. The landing page presents accessible sign-up and sign-in options that direct users to the correct authentication flow with minimal ambiguity. The user dashboard displays live statistics cards and recent tickets in a readable layout that supports quick status awareness and immediate ticket creation actions. The ticket creation sequence presents clear progression from data input to AI guidance to final review, and each stage preserves entered context accurately. The engineer dashboard presents organizational ticket metrics and a comprehensive listing interface that supports practical workload management through search and filters. The ticket detail view successfully renders timeline events and notes interactions in chronological order, which supports traceability and communication quality during issue resolution.

[SCREENSHOT: User dashboard GUI test capture showing statistics cards and recent tickets]

[SCREENSHOT: Engineer dashboard GUI test capture showing filters and searchable ticket list]

[SCREENSHOT: Ticket detail GUI test capture showing timeline and notes panel]

### 4.2 Database Test Cases

Database test cases validate schema integrity, document creation, field consistency, and real-time synchronization behavior within Cloud Firestore collections and subcollections. User registration tests confirm that each account writes a Users document containing name, email, role, and creation timestamp, and that records remain retrievable for role-based authorization checks. Ticket creation tests confirm that escalated tickets write complete documents to the Tickets collection with expected fields for title, category, priority, description, status, createdBy, assignedTo, createdAt, and updatedAt values. Note submission tests confirm that each comment creates a new document in the target ticket Notes subcollection with author name, content, and timestamp fields. Real-time listener tests confirm that updates in ticket status and notes content propagate to active dashboard and detail views without requiring manual page reload. Query behavior tests confirm that filter and search operations return expected result sets without schema mismatch or missing field exceptions.

[SCREENSHOT: Firestore Users collection sample records]

[SCREENSHOT: Firestore Tickets collection sample records]

[SCREENSHOT: Firestore Notes subcollection sample records under a ticket]

### 4.3 System Output Test Cases

System output test cases confirm that each critical process returns expected visual and data outcomes from authentication through ticket lifecycle completion. Successful role login produces correct dashboard redirection and displays personalized metrics for user accounts and aggregate metrics for engineer accounts. Ticket creation outputs show that user-entered Step 1 details are passed to the n8n webhook and that structured AI quick fixes are returned and rendered in Step 2 without formatting loss. Escalation output confirms that selecting unresolved status creates a persistent Firestore ticket and exposes the new case immediately in the engineer queue. Engineer actions on status updates produce immediate badge color transitions and corresponding metric updates in dashboards that reflect open, in-progress, and resolved states. Timeline and notes outputs confirm that each ticket event is rendered chronologically with author attribution and timestamps, which supports transparent case progression.

[SCREENSHOT: AI Quick Fixes output displayed in Step 2 after webhook response]

[SCREENSHOT: Escalated ticket appearing in Engineer Dashboard in real time]

[SCREENSHOT: Status badge transition output from Open to In Progress to Resolved]

## Chapter Five

### 5.1 Conclusions

The project demonstrates that an AI-assisted ticketing platform can significantly improve structure, traceability, and response efficiency in organizational IT support operations. TechEase successfully combines guided incident capture, automated troubleshooting recommendations, and role-based escalation into a coherent workflow that addresses deficiencies in manual support channels. The integration of Firebase Authentication and Cloud Firestore provides secure access control and reliable real-time data behavior that supports operational awareness for both users and engineers. The implemented timeline and notes model strengthens accountability by preserving complete support histories for every case. Overall, the system meets the intended objective of delivering a practical, scalable, and context-rich support management solution for modern institutions.

[SCREENSHOT: End-to-end workflow summary image from issue submission to resolution]

### 5.2 Contributions

This project contributes a production-oriented reference implementation of an AI-powered helpdesk platform built with modern cloud-native and cross-platform technologies. It contributes a structured three-step ticket creation model that improves issue data quality at submission time and reduces triage ambiguity for support teams. It contributes an n8n-based AI integration pattern that demonstrates how external automation pipelines can enrich user-facing decision support without complex backend overhead. It contributes a role-aware dashboard design that combines live metrics, filtering capabilities, and ticket-level collaboration to support daily support operations. It also contributes a documented Firestore data model for users, tickets, and notes that supports real-time synchronization and lifecycle transparency.

[SCREENSHOT: Project contribution map linking features to operational impact]

### 5.3 Recommendations

Future enhancement should include advanced analytics modules that track resolution time trends, category-based recurrence rates, and engineer workload balancing to support management planning. The platform should include configurable service level targets and automated escalation rules so that unresolved incidents trigger priority workflows based on elapsed response windows. The AI recommendation component should evolve through domain-specific prompt optimization and feedback loops that learn from successful resolutions and improve suggestion relevance. Security enhancements should include deeper audit tooling and policy-based access checks for sensitive operational contexts. A future deployment stage should also include broader institutional pilots that evaluate adoption behavior, user satisfaction, and long-term service quality improvements under sustained usage conditions.

[SCREENSHOT: Proposed future architecture showing analytics, SLA automation, and AI feedback loop]

## References

This report references core concepts in IT service management, real-time cloud databases, and authentication-driven role control that are implemented through Flutter, Firebase, and n8n technologies in the TechEase solution context. It also aligns with contemporary guidance on structured incident handling, workflow-driven support systems, and AI-assisted user self-service in operational environments. Official technical documentation for Flutter, Firebase Authentication, Cloud Firestore, and n8n provides implementation standards that inform system architecture, integration patterns, and reliability considerations throughout development and testing.

[SCREENSHOT: Reference materials and documentation evidence snapshot]

## Appendices

The appendices provide supplementary implementation evidence that supports reproducibility, examiner review, and stakeholder understanding of system operation. They include user training documentation, representative source code extracts, and selected output captures that validate functional behavior across major workflow stages.

[SCREENSHOT: Appendices index page preview]

### Appendix IV: User Training Manual

The user training manual guides new users and engineers through account access, dashboard interpretation, ticket creation, escalation, and collaborative note usage within the TechEase environment. It presents practical walkthroughs that explain each screen transition and clarifies expected actions at each workflow stage so that users can perform support activities confidently. The manual also explains status badge meanings and timeline interpretation to ensure consistent understanding of case progress across roles.

[SCREENSHOT: User manual section showing role-based onboarding instructions]

### Appendix V: Sample System Code

Sample system code illustrates key implementation areas that include authentication flow setup, Firestore ticket document creation, webhook request handling for AI quick fixes, and real-time listener updates for dashboards. The selected snippets demonstrate how application components coordinate to enforce role-aware logic while preserving data consistency between interface and cloud storage layers. The code evidence supports verification of architectural claims presented in earlier chapters.

[SCREENSHOT: Source code excerpt for ticket submission and Firestore write operation]

[SCREENSHOT: Source code excerpt for n8n webhook integration and AI response handling]

### Appendix VI: Sample Outputs

Sample outputs provide representative evidence of successful system execution from user authentication through ticket escalation and engineer resolution. The output set includes dashboard statistics views, AI quick fix responses, timeline activity records, and status transitions that demonstrate end-to-end workflow integrity. These outputs confirm that the platform delivers functional behavior that aligns with the defined objectives, requirements, and testing criteria.

[SCREENSHOT: Consolidated output gallery of dashboards, AI recommendations, and ticket lifecycle states]
