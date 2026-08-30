// The allowlist.
//
// Every screen the Cobrowse agent is permitted to see is named here, and
// nowhere else. Deleting a line hides that screen; there is no line to add that
// hides one, because hidden is what a screen already is.
//
// Nothing in the views themselves takes part in this. A screen does not opt in
// from its own body, and a pushed destination is no different from any other
// screen — `HostingRootRedaction` works out which view a destination is showing
// and asks this file about it.

// MARK: - SwiftUI screens

extension JourneyBView: ApprovedForCobrowse {}

extension MakePaymentView: ApprovedForCobrowse {}
extension MakePaymentPathView: ApprovedForCobrowse {}
extension ExplainMyBillView: ApprovedForCobrowse {}
extension ContactUsView: ApprovedForCobrowse {}
//
// Deliberately absent, and worth reading as the point of the demo:
//
//   PaymentDetailsView  — card number, expiry, CVV, cardholder name
//   JourneyAView        — never classified by anyone
//   ExplainMyBillView   — was approved; removed, to watch it go black
//   ContactUsView       — harmless content, never approved, so never shown

// MARK: - UIKit screens

//extension ViewController: ApprovedForCobrowse {}
