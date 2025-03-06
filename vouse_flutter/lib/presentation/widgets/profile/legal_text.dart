// lib/presentation/widgets/profile/legal_text.dart

/// A utility class that provides legal text content for the app.
///
/// This class contains static methods that return formatted strings for:
/// - Terms of Service
/// - Privacy Policy
class LegalText {
  /// Returns the terms of service text
  static String getTermsOfService() {
    return '''
Terms of Service

1. Acceptance of Terms
By accessing and using Vouse, you agree to be bound by these Terms of Service.

2. User Accounts
You are responsible for maintaining the security of your account and password. The app cannot and will not be liable for any loss or damage from your failure to comply with this security obligation.

3. Content Ownership
You retain ownership of any content you post through our service. By posting content, you grant us a non-exclusive license to use, display, and distribute your content.

4. Prohibited Activities
You agree not to use the app for any illegal purposes or to violate any laws in your jurisdiction.

5. Service Modifications
We reserve the right to modify or discontinue the service at any time.

6. Limitation of Liability
The app is provided "as is" without warranty of any kind.

7. Governing Law
These terms shall be governed by the laws of your country of residence.
''';
  }

  /// Returns the privacy policy text
  static String getPrivacyPolicy() {
    return '''
Privacy Policy

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, update your profile, or post content.

2. How We Use Information
We use your information to provide and improve our services, communicate with you, and personalize your experience.

3. Information Sharing
We do not sell your personal information to third parties. We may share information with third-party service providers who help us operate our services.

4. Security
We implement reasonable measures to help protect your personal information.

5. Data Retention
We store your information as long as necessary to provide our services or as required by law.

6. Your Rights
Depending on your location, you may have rights to access, correct, delete, or restrict the processing of your personal information.

7. Changes to This Policy
We may update this policy from time to time. We will notify you of any significant changes.
''';
  }
}
