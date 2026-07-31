import Foundation

/// The single source of truth for the app's medical disclaimer.
///
/// It appears in two places — the final onboarding page and Settings ->
/// Information & Help — and those had drifted into two separately worded
/// strings that made different claims. Only one of them said the app does not
/// replace professional care.
///
/// This wording is legally and medically load-bearing for a fetal-movement
/// app, so it is defined once. If it is revised, both screens change together
/// and no user can be shown a weaker version than another.
enum MedicalDisclaimer {
    static let body = """
        Littletaps is an informational wellness tool. It is not a medical \
        device, does not diagnose conditions, and does not replace \
        professional care. Contact your healthcare provider if movements \
        change abruptly, slow down, or stop, if you cannot feel 10 movements \
        in 2 hours, or if you have any concerns.
        """

    /// Heading used on the onboarding page, which states the key point up
    /// front rather than burying it in the body.
    static let onboardingTitle = "Not a medical device"

    /// Heading used for the Information & Help section.
    static let infoSectionTitle = "Important"
}
