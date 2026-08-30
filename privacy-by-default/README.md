# PBD — private by default

A Cobrowse redaction example for UIKit and SwiftUI, focused on `NavigationStack`
and on whitelisting the destinations a stack pushes.

## The rule

**Everything is hidden. `Approvals.swift` is the only thing that reveals.**

A screen added next year is private the first time it is shown, with nobody
having remembered anything. No view in this app carries a redaction modifier —
`Approvals.swift` names every screen the agent may see, destinations included:

```swift
extension MakePaymentView: ApprovedForCobrowse {}
extension MakePaymentPathView: ApprovedForCobrowse {}
extension JourneyBView: ApprovedForCobrowse {}
```

```
RedactByDefaultDelegate  redacts every window; lifts that from a hosting
                         controller once HostingRootRedaction has decided

HostingRootRedaction     redacts a hosting controller's root IN SWIFTUI, or
                         leaves it revealed when the allowlist approves it
```

## Walkthrough

### The two questions

Everything reduces to two decisions, asked about different things at different
moments.

```
  RedactByDefaultDelegate                 HostingRootRedaction
  asked by the SDK, per redaction pass    runs on every layout pass
  ────────────────────────────────────    ─────────────────────────────────

  "which views are hidden?"               "is this root still redacted?"
      → every window                          yes → done. nothing else runs,
                                                    and this is the usual answer
  "which views are revealed?"                 no  → decide:
      → approved controllers                        redact unless the allowlist
                                                    clearly allows this view
```

The first is coarse — a whole window, a whole controller's view. The second is
what governs anything SwiftUI hosts, because the first cannot reach it.

The right-hand column runs often but rarely does much. A redacted view answers
the first question and stops there; the wrapper it already carries *is* the
stored verdict, so the allowlist is not consulted again while it stands. The
decision below it runs only when a view has never been judged, or when SwiftUI
has dropped the wrapper and it has to be judged afresh.

### What happens when a screen appears

```
  viewWillLayoutSubviews
          │
          ├── not a UIHostingController<AnyView> ──────────── nothing to do
          │      (the app made it; it kept its type)
          │
          └── erased root ─── may it show its content?
                                 │
                    ┌────────────┴────────────┐
                   yes                        no / cannot tell
                    │                             │
              leave it alone              wrap its root in
                                          .cobrowseRedacted()

  ── later, whenever the SDK recomputes ──

  cobrowseUnredactedViews(for: controller)
          │
          └── is it approved? ── yes ── hand back [controller.view]
                              └─ no ─── hand back nothing
```

### The decision, in pseudo-code

```
may this controller's view be revealed?          # RedactByDefaultDelegate

    if it still knows its root view's type       # the app hosted it
        → is that type in Approvals.swift?

    if its root is AnyView                       # SwiftUI hosted it
        → is it already redacted in SwiftUI, or clearly allowed to show?

    if it has children                           # a UIKit container
        → no; its view is an ancestor of theirs

    otherwise                                    # a UIKit leaf
        → is it in Approvals.swift?


may this SwiftUI root show its content?          # HostingRootRedaction

    which view does the nearest ancestor host?
        not approved            → no

    am I the first screen in my navigation stack?
        yes                     → yes, I am that approved screen's own content

    otherwise I am a destination — which view am I?
        exactly one named       → is it in Approvals.swift?
        several, or none        → cannot tell, so no
```

### A worked example

Three screens deep, in one stack, with the allowlist as it ships:

```
UINavigationController                                  container      → hidden
└── ViewController                          UIKit leaf, not listed     → hidden
    ↳ presented
      UIHostingController<MakePaymentView>  knows its type, listed     → SHOWN
        └── UIKitNavigationController                   container      → hidden
            ├── NavigationStackHosting…<AnyView>   first in stack,
            │                                      owner approved      → SHOWN
            ├── NavigationStackHosting…<AnyView>   destination,
            │                    names ExplainMyBillView, not listed   → hidden
            └── NavigationStackHosting…<AnyView>   destination,
            │                    names ContactUsView, not listed       → hidden
```

Read the middle column downward and the whole design is visible: the app's own
screen is answered by name, its stack's root screen is answered by its owner,
and each destination is answered by the view its erased root names.

### Where each screen's cover comes from

Not every hidden screen is hidden by the same thing, and the difference is the
subtlest part of the design.

```
  JourneyAView          the app hosted it, allowlist says no
                        → its view is never revealed, so THE WINDOW covers it

  ExplainMyBillView     SwiftUI hosted it, inside an approved screen
                        → that screen's view is revealed, and it is an ancestor,
                          so the window is already lifted here
                        → THE SWIFTUI REDACTION is the only cover
```

Which is why an identification that cannot be made has to redact rather than
abstain: for a destination there is nothing underneath to catch it.

## How a destination is identified

SwiftUI hosts each pushed destination in its own controller — so the SDK is
asked about it — but erases its root to `AnyView`. The type is still recoverable
from the erased value, and `_typeByName` resolves it back to a real metatype
which is then **conformance-tested**, not string-matched:

| The closure | What the erased root names | Answer |
|---|---|---|
| returns one view | `ExplainMyBillView` | that view |
| `switch` over routes | `PaymentDetailsView`, `ExplainMyBillView` | **decide nothing** |

The second row is a real constraint on how an app may declare navigation: a
`switch` over a route enum has the static type `_ConditionalContent<A, B>`, so
the erased root names every branch at once and nothing outside can say which is
showing. Such a destination stays black. `MakePaymentPathView` therefore
declares one destination per route.

Reading the *built value* would resolve the switch, and leaks: the value graph
retains views from pushes already dismissed, so a stale approved view answers
for the screen actually showing. Ambiguity has to stay unanswerable.

## Two timing facts, both measured

- **Redact at `viewWillLayoutSubviews`, not `viewDidLoad`.** At load a
  controller is not yet in its navigation stack, so a stack root cannot be told
  apart from a destination. Layout still runs before anything is drawn.
- **Check on every layout, not once.** SwiftUI reassigns `rootView` on its own
  updates and discards the wrapper, and there is no hook for it — a destination
  was once recorded as redacted while carrying no redaction at all.

## Screens

| Screen | Seen by the agent |
|---|---|
| `ViewController` | UIKit menu |
| `MakePaymentView` | yes — stack, boolean destinations |
| `MakePaymentPathView` | yes — stack, typed path, one destination per route |
| `JourneyBView` | yes |
| `ExplainMyBillView` | **no** — a destination, and taken off the list to watch it go black |
| `ContactUsView` | **no** — public support numbers, never approved, so never shown |
| `PaymentDetailsView` | **no** — card number, expiry, CVV |
| `JourneyAView` | **no** — never classified by anyone |

`ContactUsView` is the argument for redaction by default: nothing on it is
private, and it is hidden anyway, because hidden is what a screen is until
someone says otherwise.

It sits three deep — `MakePaymentView` → `ExplainMyBillView` → `ContactUsView` —
so approval can be watched changing from one screen to the next within a single
stack, rather than one screen at a time.

The amount field on both payment screens carries `cobrowseRedacted()`: the
screen around it is revealed, so the field says otherwise for itself. Those two
lines are the only Cobrowse modifiers in the whole app.

`MakePaymentPathView` is presented **without** `SwiftUIRouter`, deliberately —
nothing in the policy depends on it. A hosting controller made by hand keeps its
`rootView`'s type, which is all the allowlist needs.
