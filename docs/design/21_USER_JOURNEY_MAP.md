# ArmSphere User Journey Mapping
**End-to-End Competitor, Official & Federation Workflows**
**Document Version**: 1.0.0
**Status**: APPROVED & LOCKED

---

## 1. Journey 1: First-Time Athlete Registration & Onboarding

```
[Cold App Open] ──> [Splash Logo Seal (800ms)] ──> [Welcome Landing (/welcome)]
       │
       ▼ Tap "Create your account"
[Register Form (/register)] ──> Email, Password, Terms Checkbox
       │
       ▼ Tap "Sign Up" (200 OK)
[Role Intent (/role-intent)] ──> Select "Compete as Athlete"
       │
       ▼ Tap "Continue"
[Onboarding Step 1 (/onboarding)] ──> Ring Name, DOB, Gender
       │
       ▼ Tap "Next" (Horizontal Slide)
[Onboarding Step 2] ──> Province (Punjab), City (Lahore)
       │
       ▼ Tap "Next" (Horizontal Slide)
[Onboarding Step 3] ──> Weight (84kg), Height (180cm), Reach (182cm), Arm (Right)
       │
       ▼ Tap "Finish & Enter ArmSphere"
[Athlete Dashboard (/home)] ──> Initial ELO 1000, Welcome Toast!
```

---

## 2. Journey 2: Tournament Discovery, Entry & Stripe Payment

```
[Main Shell: Tab 2 (Competitions)] ──> Browse upcoming sanctioned events
       │
       ▼ Tap "Pakistan National Championship 2026"
[Tournament Details (/tournament/:id)] ──> Review Prize, Dates, Weight Classes
       │
       ▼ Tap sticky CTA "Register for Event"
[Event Registration (/tournament/:id/register)]
       │ • Division: Senior
       │ • Weight Class: -85kg
       │ • Arm Choice: Right Arm
       │ • Entry Fee: CAD $25.00 (or PKR 1,500)
       ▼ Tap "Confirm & Pay Entry Fee"
[Stripe Native Payment Sheet] ──> Enter Card or Google Pay
       │
       ▼ Payment Succeeded (200 OK webhook)
[Ticket Confirmation Modal] ──> Digital Ticket Barcode generated
       │
       ▼ Tap "View My Tickets"
[My Tickets Screen (/settings/tickets)] ──> Ready for Tournament Weigh-in!
```

---

## 3. Journey 3: Live Tournament Table Call & Match Officiating

```
[Tournament Desk: Weigh-in Passed] ──> Operator approves -85kg bracket slot
       │
       ▼ Operator calls Match #14 to Table 1
[Push Alert + In-App Callout] ──> "Match #14 Called: Muhammad Ali vs Tariq Khan (Table 1)"
       │
       ▼ Referee opens Table 1 Scorepad
[Official Scorepad Screen (/referee/submit-scorepad)]
       │ • Round 1: Ali pins Khan ──> Tap "Ali +1" (Vibration tick)
       │ • Round 2: Khan elbow foul ──> Tap "Foul Khan"
       │ • Round 2 restart: Ali flash pin ──> Tap "Ali +1"
       │ • Round 3: Ali top-roll pin ──> Tap "Ali +1" (Set Won 3-0!)
       ▼ Tap "Submit Official Result"
[Result Processing Screen] ──> Server recalculates ELO ratings
       │
       ▼ Audio Cue: match_won.mp3 + Green Victory Toast
[Live Bracket Updated] ──> Ali advances to Winners Quarter-Finals!
```

---

## 4. Journey 4: Formal Dispute Filing & Governance Review

```
[Match Concluded with Disputed Foul Call]
       │
       ▼ Athlete taps "Dispute Match"
[Submit Complaint Screen (/governance/submit-complaint)]
       │ • Select Event & Disputed Match
       │ • Violation: "Referee missed opponent elbow lift before pin"
       │ • Attach Video Clip / Slow-Mo Evidence
       ▼ Tap "File Formal Complaint"
[Dispute Registered: Case #1042] ──> Status: OPEN
       │
       ▼ Compliance Officer logs into Governance Dashboard (/governance)
[Dispute Detail Review Screen (/governance/dispute/1042)]
       │ • Inspects uploaded video evidence
       │ • Reads referee statement
       │ • Issues Ruling: "Upheld - Rematch Ordered" or "Rejected"
       ▼ Case Status: RESOLVED
[Both Athletes Notified via In-App Alert]
```
