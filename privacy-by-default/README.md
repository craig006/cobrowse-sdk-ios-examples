# PBD — private by default

A Cobrowse redaction example for UIKit and SwiftUI. Every screen is hidden from
the agent, and one file decides which ones are shown.

No view in this app carries a redaction modifier. Nothing in the examples knows
the policy exists.

## The rule

**Everything is hidden. `Approvals.swift` is the only thing that reveals.**

```swift
extension MakePaymentView: ApprovedForCobrowse {}
extension ExplainMyBillView: ApprovedForCobrowse {}
extension ContactUsView: ApprovedForCobrowse {}
```

A screen written next year is private the first time it is shown, with nobody
having remembered anything. Approving one is a line; forgetting to costs a black
rectangle.

The protocol is empty — the conformance *is* the statement, and it can be
written here without touching the type it approves.

## Running it

Every example carries two pills, bottom right: which framework drew it, and an
eye — green where the policy approves it, red and slashed where it does not.
Both are read from `Approvals.swift`, so a screen can never claim to be approved
while the policy denies it.

Watch the session from the agent side to see what is actually sent. The device
shows everything normally either way.

## How it works

Two questions, asked of every view controller, independently.

**What is covered** — `cobrowseRedactedViews(for:)` covers every screen in the
app's own window *without consulting approval*. There is no decision to get
wrong, so a screen nobody thought about is still covered.

A container is the exception: it contributes its bars rather than its own view,
because its view contains its children's. Covering it would cover them — and
would blank the screen through every transition, since a push puts views on
screen that belong to no controller and nothing reveals those. A container we
don't recognise covers itself, so an unfamiliar one is hidden rather than
skipped.

**What comes back** — `cobrowseUnredactedViews(for:)` reveals nothing but a
screen `Approvals.swift` names, and of that screen only its own view. A screen
never reveals its neighbours, its chrome, or anything presented over it.
Returning nothing leaves the cover standing, so silence is always safe.

Chrome is denied by default: a navigation title can name a screen the agent is
not meant to know about. Two commented blocks in `cobrowseUnredactedViews` turn
it back on.

## Naming a screen

The hard part is not the policy, it is working out **which screen a view
controller is showing**. `ViewType.swift` does that, and its surface is two
names: `viewType` is a fact read off the type system, `foundViewType` is a
search that can fail.

SwiftUI makes several controllers the app never asks for, and only one carries
the screen's type plainly:

```
UIHostingController<MakePaymentView>        the app hosted it — the type IS the screen
NavigationStackHostingController<AnyView>   a stack's root and each destination
PresentationHostingController<AnyView>      a sheet, cover or popover
TabHostingController                        hosts a SwiftUI-internal RootView
```

So three routes:

1. **Read the type.** Where the hosted content is not `AnyView`, it is the screen.
2. **Look inside the box.** For an erased view, reflect one hop — the storage's
   own type names what it wraps.
3. **Ask elsewhere.** A tab is named by its container's `Body` plus its index; a
   stack's root, which is never readable, counts as the screen containing it.

Every route fails closed. A screen that cannot be named stays hidden.

## Limitations

Measured on iOS 26.5 against SDK 3.19.2. **The first fails open**, the rest
fail closed.

### Content drawn around a container is visible

A screen that draws its own content *around* a `NavigationStack` or `TabView` —
a balance bar, a banner, a mini player, usually via `.overlay`,
`.safeAreaInset` or a wrapping stack — leaves that content **visible to the
agent**, even where the screen itself is not approved.

SwiftUI draws it into the same view that holds the stack, so there is nothing
separate to cover. Covering that view was measured and rejected: it did not hide
the content, and it brought the transition flicker back.

Put such content inside the screen it belongs to, where it is covered like any
other, or mark it with `.cobrowseRedacted()`.

**`ContainerBarDemoView` demonstrates it** — an unapproved screen whose balance
bar reaches the agent while the rest of it is black.

### These stay hidden — the screen cannot be named

- **A `switch` in a destination closure.** The static type names every branch, so
  nothing can say which is showing.
- **A destination declared with another screen's modifier attached** —
  `PaymentDetailsView().navigationDestination(item:) { PaymentReviewView() }` —
  names two views in one type. Declaring the destination inside the view's own
  `body`, or using a `NavigationPath`, avoids it.
- **A conditional tab.** `if flag { B() }` names a tab that may not exist, so the
  whole `TabView` becomes unidentifiable.
- **A screen defined in a third-party UI module.** Approval reads types from the
  app's own module; anything else is treated as a framework's.

### Windows above the app's own

The policy speaks only for the app's own window. The keyboard is redacted by the
SDK itself, and alerts turn out to live in the app's window — but an overlay
window an app creates for a toast or HUD would not be covered.

## Debugging

`HostDump` prints the live controller tree, what each controller hosts, and what
the policy managed to name:

```
🌳 UIHostingController<MakePaymentView>              hosts: MakePaymentView  found: MakePaymentView
🌳     UIKitNavigationController                     —  found: UNREADABLE
🌳         NavigationStackHostingController<AnyView> hosts: AnyView  found: MakePaymentView
```

A controller marked `⚠️ NEVER ASKED` is one the SDK does not track — no policy
can cover it. Enable it in `AppDelegate` and filter the console on 🌳.

## The other policy

`RedactedByRegexDelegate` is the contrast: it shows every screen and hides text
matching a pattern. Assign it in `AppDelegate` to compare.

It reads UIKit text only — SwiftUI does not draw through `UILabel`, which is why
UIKit twins of the payment screens exist. It is here to make the argument, not
as a recommendation: matching content is a poor substitute for knowing which
screen you are on.

## Notes

- `CobrowseIO.redactedViews` and `unredactedViews` take **class names** and must
  be set **before `start()`**. The list in `AppDelegate` names UIKit's own
  popover chrome — dimming, shadow and outline views that draw no app content.
- Only name views that can never be an **ancestor** of app content. An
  unredaction shields everything beneath it: naming a container there was
  measured to make unapproved screens visible.
