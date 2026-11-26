import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App language (English or Nepali). The choice is saved on the phone.
///
/// Screens call [tr] with the English text. When Nepali is selected and a
/// translation exists in [_ne], the Nepali text is returned. Any text that has
/// no translation stays in English, so a missing entry can never break a screen.
abstract final class AppLang {
  static final ValueNotifier<String> notifier = ValueNotifier<String>('en');

  static String get code => notifier.value;
  static bool get isNepali => code == 'ne';

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_lang');
      if (saved == 'en' || saved == 'ne') notifier.value = saved!;
    } catch (_) {
      // Keep English if the saved value cannot be read.
    }
  }

  static Future<void> set(String code) async {
    if (code != 'en' && code != 'ne') return;
    notifier.value = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_lang', code);
    } catch (_) {
      // The language still changes for this session.
    }
  }
}

/// Returns [en] or its Nepali translation, depending on the selected language.
String tr(String en) => AppLang.isNepali ? (_ne[en] ?? en) : en;

/// Rebuilds [builder] whenever the language changes.
class LangBuilder extends StatelessWidget {
  const LangBuilder({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLang.notifier,
      builder: (context, _, __) => builder(context),
    );
  }
}

const Map<String, String> _ne = {
  // Navigation
  'Home': 'गृहपृष्ठ',
  'My Farms': 'मेरा फार्महरू',
  'Market': 'बजार',
  'Profile': 'प्रोफाइल',
  'Back': 'पछाडि',

  // Sign up / log in
  'Create your account': 'आफ्नो खाता बनाउनुहोस्',
  'Join as a farmer or a buyer.': 'किसान वा खरिदकर्ताको रूपमा सामेल हुनुहोस्।',
  'Farmer': 'किसान',
  'Buyer': 'खरिदकर्ता',
  'Full name': 'पूरा नाम',
  'Your full name': 'तपाईंको पूरा नाम',
  'Country': 'देश',
  'Nepal': 'नेपाल',
  'India': 'भारत',
  'Email': 'इमेल',
  'Enter your existing gmail': 'तपाईंको चलिरहेको इमेल लेख्नुहोस्',
  'Password': 'पासवर्ड',
  'Confirm password': 'पासवर्ड पुष्टि गर्नुहोस्',
  'At least 8 characters': 'कम्तीमा ८ वर्ण',
  'Both passwords match': 'दुवै पासवर्ड मेल खानुपर्छ',
  'Create account': 'खाता बनाउनुहोस्',
  'Already have an account?': 'पहिले नै खाता छ?',
  'Log in': 'लगइन गर्नुहोस्',
  'Welcome back': 'फेरि स्वागत छ',
  'Log in with your email address and password.':
      'इमेल र पासवर्डबाट लगइन गर्नुहोस्।',
  'Forgot password?': 'पासवर्ड बिर्सनुभयो?',
  'New to FasalMitra?': 'FasalMitra मा नयाँ हुनुहुन्छ?',
  'Reset password': 'पासवर्ड रिसेट गर्नुहोस्',
  'Enter your email address. We will send you a reset link.':
      'इमेल ठेगाना लेख्नुहोस्। हामी रिसेट लिंक पठाउँछौं।',
  'Enter your email address. We will send you a 6-digit code.':
      'इमेल ठेगाना लेख्नुहोस्। हामी ६ अङ्कको कोड पठाउँछौं।',
  'Send reset link': 'रिसेट लिंक पठाउनुहोस्',
  'Send code': 'कोड पठाउनुहोस्',
  'Back to log in': 'लगइनमा फर्कनुहोस्',
  'Log in with your phone number.': 'फोन नम्बरबाट लगइन गर्नुहोस्।',
  'Phone (with country code)': 'फोन (देश कोडसहित)',
  '6-digit code': '६ अङ्कको कोड',
  'Verify code': 'कोड प्रमाणित गर्नुहोस्',
  'Use a different number': 'अर्को नम्बर प्रयोग गर्नुहोस्',
  'Use phone number instead': 'बरु फोन नम्बर प्रयोग गर्नुहोस्',
  'Use email and password instead': 'बरु इमेल र पासवर्ड प्रयोग गर्नुहोस्',
  'Passwords do not match': 'पासवर्ड मेल खाएन',
  'Enter your email and password': 'इमेल र पासवर्ड लेख्नुहोस्',
  'Enter your email first': 'पहिले इमेल लेख्नुहोस्',
  'Code must be 6 digits': 'कोड ६ अङ्कको हुनुपर्छ',
  'Code sent. Check your SMS.': 'कोड पठाइयो। आफ्नो SMS हेर्नुहोस्।',
  'Account created. Check your email to confirm, then log in.':
      'खाता बन्यो। इमेल खोलेर पुष्टि गर्नुहोस्, अनि लगइन गर्नुहोस्।',
  'Reset link sent. Open it on this phone.':
      'रिसेट लिंक पठाइयो। यही फोनमा खोल्नुहोस्।',
  'Could not connect. Check your internet and try again.':
      'जोडिन सकेन। इन्टरनेट जाँचेर फेरि प्रयास गर्नुहोस्।',

  // Email code screen
  'Verify your email': 'इमेल प्रमाणित गर्नुहोस्',
  'We sent a 6-digit code to': '६ अङ्कको कोड पठाइएको इमेल:',
  'Code': 'कोड',
  'Verify': 'प्रमाणित गर्नुहोस्',
  'Resend code': 'कोड फेरि पठाउनुहोस्',
  'Resend code in': 'कोड फेरि पठाउन बाँकी:',
  'A new code was sent to your email address.':
      'तपाईंको इमेलमा नयाँ कोड पठाइयो।',
  'Account created': 'खाता बनाइयो',
  'Welcome': 'स्वागत छ',
  'Continue': 'जारी राख्नुहोस्',

  // Onboarding
  'Skip': 'छोड्नुहोस्',
  'Next': 'अर्को',
  'Get started': 'सुरु गर्नुहोस्',
  'Scan & Check Crop Leaves': 'बालीको पात स्क्यान र जाँच',
  'Snap a photo of any plant leaf to get instant AI-assisted health insights and helpful next steps.': 'कुनै पनि बिरुवाको पातको फोटो खिच्नुहोस् र एआईको सहयोगमा तुरुन्तै स्वास्थ्य जानकारी र अर्को कदम पाउनुहोस्।',
  'Daily Mandi Rates & Tips': 'दैनिक मण्डी भाउ र सुझाव',
  'Check updated local market prices and find the right crops for your soil, season, and water.': 'स्थानीय बजारको नयाँ मूल्य हेर्नुहोस् र आफ्नो माटो, मौसम र पानी अनुसार सही बाली खोज्नुहोस्।',
  'Direct Farm to Buyer Selling': 'किसानबाट सिधै खरिदकर्तालाई बिक्री',
  'List your fresh harvest in seconds and connect directly with buyers without middlemen.': 'आफ्नो ताजा उब्जनी केही सेकेन्डमै सूचीकृत गर्नुहोस् र बिचौलिया बिना सिधै खरिदकर्तासँग जोडिनुहोस्।',

  // Home
  'Namaste,': 'नमस्ते,',
  'Farm overview': 'फार्मको सारांश',
  'View farms': 'फार्महरू हेर्नुहोस्',
  'Farms': 'फार्महरू',
  'Total area': 'कुल क्षेत्रफल',
  'No farms added yet.': 'अहिलेसम्म कुनै फार्म थपिएको छैन।',
  'Add your first farm': 'आफ्नो पहिलो फार्म थप्नुहोस्',
  'AI Crop Scan': 'एआई बाली स्क्यान',
  'Market Prices': 'बजार मूल्य',
  'Sell Produce': 'उपज बेच्नुहोस्',
  'Agricultural Shop': 'कृषि पसल',
  'Tutorials': 'ट्युटोरियल',
  'Short videos in English, Hindi and Nepali.':
      'अङ्ग्रेजी, हिन्दी र नेपालीमा छोटा भिडियोहरू।',
  'No tutorials yet': 'अहिलेसम्म कुनै ट्युटोरियल छैन',
  'Videos will appear here when they are added.':
      'भिडियो थपिएपछि यहाँ देखिनेछन्।',
  'Videos in': 'भिडियोहरू:',
  'Could not load tutorials. Check your internet and try again.':
      'ट्युटोरियल लोड भएन। इन्टरनेट जाँचेर फेरि प्रयास गर्नुहोस्।',
  'This video has no link yet.': 'यो भिडियोको लिङ्क छैन।',
  'Could not open the video link.': 'भिडियोको लिङ्क खोल्न सकिएन।',
  'This video cannot be played inside the app.':
      'यो भिडियो एपभित्र चल्दैन।',
  'Open in YouTube': 'YouTube मा खोल्नुहोस्',
  'Recent activity': 'हालका गतिविधि',
  'No recent activity.': 'हालसम्म कुनै गतिविधि छैन।',
  'Farming information': 'खेती सम्बन्धी जानकारी',
  'No information available right now.': 'अहिले कुनै जानकारी उपलब्ध छैन।',
  'Crop Guide': 'बाली मार्गदर्शन',
  'Price Prediction': 'मूल्य अनुमान',
  'Could not load farms. Check your internet.':
      'फार्महरू लोड हुन सकेन। इन्टरनेट जाँच्नुहोस्।',
  'Retry': 'फेरि प्रयास गर्नुहोस्',

  // My farms
  'Crop guide': 'बाली मार्गदर्शन',
  'Crop information and suggestions': 'बालीको जानकारी र सुझाव',
  'Add a farm': 'फार्म थप्नुहोस्',

  // Profile
  'Edit profile': 'प्रोफाइल सम्पादन गर्नुहोस्',
  'My listings': 'मेरा सूचीहरू',
  'Notifications': 'सूचनाहरू',
  'Support': 'सहायता',
  'Log out': 'लगआउट गर्नुहोस्',
  'Delete my account': 'मेरो खाता मेटाउनुहोस्',
  'Delete account?': 'खाता मेटाउने?',
  'This will permanently delete your account and all your farm profiles. This cannot be undone.': 'यसले तपाईंको खाता र सबै फार्म प्रोफाइल सधैंका लागि मेटाउँछ। यसलाई फेरि पूर्वावस्थामा फर्काउन सकिँदैन।',
  'Cancel': 'रद्द गर्नुहोस्',
  'Delete': 'मेटाउनुहोस्',
  'Could not load your profile. Check your internet.':
      'तपाईंको प्रोफाइल लोड हुन सकेन। इन्टरनेट जाँच्नुहोस्।',

  // AI Scan
  'Scan your crop':
      'आफ्नो बाली स्क्यान गर्नुहोस्',
  'History':
      'इतिहास',
  'Camera view':
      'क्यामेराको दृश्य',
  'Photo tips':
      'फोटो खिच्ने सुझाव',
  'Fill the frame with one leaf.':
      'फ्रेम भरिने गरी एउटा पात राख्नुहोस्।',
  'Use daylight and avoid shadows.':
      'दिनको उज्यालो प्रयोग गर्नुहोस् र छाया पर्न नदिनुहोस्।',
  'Hold the camera steady until it is sharp.':
      'फोटो स्पष्ट नभएसम्म क्यामेरा स्थिर राख्नुहोस्।',
  'Include both healthy and affected parts.':
      'स्वस्थ र प्रभावित दुवै भाग समावेश गर्नुहोस्।',
  'Take photo':
      'फोटो खिच्नुहोस्',
  'Upload from gallery':
      'ग्यालरीबाट अपलोड गर्नुहोस्',
  'Camera not working? See camera help':
      'क्यामेरा चलेन? क्यामेरा सहायता हेर्नुहोस्',
  'Camera access is off':
      'क्यामेरा पहुँच बन्द छ',
  'FasalMitra needs camera permission to scan your crops. Turn it on in your phone settings, or upload a photo instead.':
      'तपाईंको बाली स्क्यान गर्न FasalMitra लाई क्यामेराको अनुमति चाहिन्छ। फोनको सेटिङमा गएर अनुमति खोल्नुहोस्, वा बरु फोटो अपलोड गर्नुहोस्।',
  'Open settings':
      'सेटिङ खोल्नुहोस्',
  'Back to home':
      'गृहपृष्ठमा फर्कनुहोस्',
  'Check your photo':
      'आफ्नो फोटो जाँच्नुहोस्',
  'Make sure the leaf is sharp and fills the frame.':
      'पात स्पष्ट छ र फ्रेम भरिएको छ भन्ने सुनिश्चित गर्नुहोस्।',
  'Analyze photo':
      'फोटो विश्लेषण गर्नुहोस्',
  'Retake':
      'फेरि खिच्नुहोस्',
  'Analyzing your photo…':
      'तपाईंको फोटो विश्लेषण गर्दै…',
  'This can take a few seconds.':
      'यसमा केही सेकेन्ड लाग्न सक्छ।',
  'Scan result':
      'स्क्यान नतिजा',
  'Detected issue':
      'पत्ता लागेको समस्या',
  'Confidence':
      'विश्वासको स्तर',
  'What we found':
      'हामीले के फेला पार्यौँ',
  'Recommended action':
      'सिफारिस गरिएको कदम',
  'Save to history':
      'इतिहासमा सुरक्षित गर्नुहोस्',
  'Saved to history':
      'इतिहासमा सुरक्षित भयो',
  'Scan another crop':
      'अर्को बाली स्क्यान गर्नुहोस्',
  'DEMO RESULT: this layout is a sample, not a real diagnosis.':
      'डेमो नतिजा: यो ढाँचा नमुना मात्र हो, वास्तविक निदान होइन।',
  "We're not sure about this result. Try a clearer photo.":
      'यो नतिजाबारे हामी पक्का छैनौँ। अझ स्पष्ट फोटो प्रयास गर्नुहोस्।',
  'Result unclear':
      'नतिजा स्पष्ट छैन',
  'Possible issue':
      'सम्भावित समस्या',
  'What to do next':
      'अब के गर्ने',
  'Retake the photo in daylight, closer to the affected leaf.':
      'दिनको उज्यालोमा प्रभावित पातको नजिकबाट फोटो फेरि खिच्नुहोस्।',
  'Retake photo':
      'फोटो फेरि खिच्नुहोस्',
  'Upload a different photo':
      'अर्को फोटो अपलोड गर्नुहोस्',
  'Scan failed':
      'स्क्यान असफल भयो',
  "We couldn't analyze this photo. Check your connection and try again.":
      'हामीले यो फोटो विश्लेषण गर्न सकेनौँ। आफ्नो इन्टरनेट जडान जाँचेर फेरि प्रयास गर्नुहोस्।',
  'Try again':
      'फेरि प्रयास गर्नुहोस्',
  'Back to scan':
      'स्क्यानमा फर्कनुहोस्',
  'Scan history':
      'स्क्यान इतिहास',
  'No scans yet':
      'अहिलेसम्म कुनै स्क्यान छैन',
  'Scan a crop and its result will appear here.':
      'बाली स्क्यान गर्नुहोस्, नतिजा यहाँ देखिनेछ।',
  'Scan a crop':
      'बाली स्क्यान गर्नुहोस्',
  'Could not load history':
      'इतिहास लोड हुन सकेन',
  'Could not load history. Check your internet.':
      'इतिहास लोड हुन सकेन। इन्टरनेट जाँच्नुहोस्।',
  'High confidence':
      'उच्च विश्वास',
  'Medium confidence':
      'मध्यम विश्वास',
  'Low confidence':
      'कम विश्वास',
  'Leaf blight (sample)':
      'पातको डढुवा (नमुना)',
  'Brown spots with yellow edges on the leaf. This is sample text to show the layout.':
      'पातमा पहेँलो किनारासहित खैरा थोप्लाहरू। यो ढाँचा देखाउन राखिएको नमुना पाठ हो।',
  'Remove affected leaves and keep the leaves dry. Ask a local agricultural expert before using any spray.':
      'प्रभावित पातहरू हटाउनुहोस् र पातहरू सुख्खा राख्नुहोस्। कुनै स्प्रे प्रयोग गर्नुअघि स्थानीय कृषि विज्ञसँग सोध्नुहोस्।',
  'Ask a local agricultural expert before using any treatment.':
      'कुनै उपचार प्रयोग गर्नुअघि स्थानीय कृषि विज्ञसँग सोध्नुहोस्।',
  'No known problem matched':
      'कुनै ज्ञात समस्या मेल खाएन',
  'Unspecified problem':
      'अनिर्दिष्ट समस्या',
  'Nutrient deficiency':
      'पोषक तत्वको कमी',
  'No disease detected':
      'कुनै रोग फेला परेन',
  'No treatment needed. Keep monitoring your crop.':
      'उपचार आवश्यक छैन। आफ्नो बालीको निगरानी जारी राख्नुहोस्।',
  'No summary available.':
      'सारांश उपलब्ध छैन।',
  'Growth stage':
      'वृद्धि चरण',
  'Treatment plan':
      'उपचार योजना',
  'Dosage guidance':
      'मात्रा सम्बन्धी सुझाव',
  'Organic alternatives':
      'जैविक विकल्पहरू',
  'Prevention':
      'रोकथाम',
  'Estimated recovery time':
      'अनुमानित निको हुने समय',
  'More inquiry':
      'थप सोधपुछ',
  'This is an AI estimate, not a confirmed diagnosis. For serious or persistent problems, consult a local agricultural expert.':
      'यो AI को अनुमान मात्र हो, पुष्टि गरिएको निदान होइन। गम्भीर वा लगातार समस्या भएमा स्थानीय कृषि विज्ञसँग परामर्श गर्नुहोस्।',
  'This photo is too large. Use a photo under 5 MB.':
      'यो फोटो धेरै ठूलो छ। ५ MB भन्दा सानो फोटो प्रयोग गर्नुहोस्।',
  'Could not read this photo. Please try another one.':
      'यो फोटो पढ्न सकिएन। कृपया अर्को फोटो प्रयोग गर्नुहोस्।',
  'Could not open the camera. Try uploading a photo instead.':
      'क्यामेरा खोल्न सकिएन। बरु फोटो अपलोड गरेर हेर्नुहोस्।',
  'AI Scan is not set up yet.':
      'AI स्क्यान अहिलेसम्म तयार भएको छैन।',
  'The daily scan limit has been reached. Please try again tomorrow.':
      'आजको स्क्यान सीमा पुगिसक्यो। कृपया भोलि फेरि प्रयास गर्नुहोस्।',
  'This photo type is not supported. Use a JPG or PNG photo.':
      'यो फोटोको प्रकार समर्थित छैन। JPG वा PNG फोटो प्रयोग गर्नुहोस्।',
  'The scan service did not respond. Please try again.':
      'स्क्यान सेवाले जवाफ दिएन। कृपया फेरि प्रयास गर्नुहोस्।',
  'Could not complete this request. Check your internet and try again.':
      'अनुरोध पूरा हुन सकेन। इन्टरनेट जाँचेर फेरि प्रयास गर्नुहोस्।',
};
