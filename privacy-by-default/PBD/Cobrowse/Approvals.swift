// The allowlist.
//
// Every screen the Cobrowse agent is permitted to see is named here, and
// nowhere else. Deleting a line hides that screen; there is no line to add that
// hides one, because hidden is what a screen already is.
//
// Nothing in the views themselves takes part in this. A screen does not opt in
// from its own body, and a pushed destination is no different from any other
// screen — `HostingControllerApproval` works out which view a destination is showing
// and asks this file about it.

// MARK: - SwiftUI screens

extension JourneyBView: ApprovedForCobrowse {}

extension MakePaymentView: ApprovedForCobrowse {}
extension MakePaymentPathView: ApprovedForCobrowse {}
extension ExplainMyBillView: ApprovedForCobrowse {}
extension ContactUsView: ApprovedForCobrowse {}
extension PaymentReviewView: ApprovedForCobrowse {}
extension ApprovedPresentationView: ApprovedForCobrowse {}

// MARK: - UIKit screens

//extension ViewController: ApprovedForCobrowse {}

//extension MakePaymentViewController: ApprovedForCobrowse {}
extension ApprovedPresentationViewController: ApprovedForCobrowse {}
//extension PaymentReviewViewController: ApprovedForCobrowse {}
