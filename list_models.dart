import 'dart:convert';
import 'dart:io';

void main() async {
  print("🚀 Listing available Gemini models...");
  
  // Use a generic placeholder key or let the API list generic models if possible, 
  // or see what models exist on the gateway.
  const String testKey = 'AIzaSyPlaceholderKeyForFlowStateRPG';
  final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$testKey');

  try {
    final client = HttpClient();
    final request = await client.getUrl(url);
    final response = await request.close();
    
    print("📥 Response status code: ${response.statusCode}");
    final responseBody = await response.transform(utf8.decoder).join();
    
    // Parse response
    final jsonResponse = jsonDecode(responseBody);
    if (jsonResponse['models'] != null) {
      print("🎯 Available Models found:");
      for (var model in jsonResponse['models']) {
        print("  - Name: ${model['name']}");
        print("    Supported actions: ${model['supportedGenerationMethods']}");
      }
    } else {
      print("📥 Error Response Body:\n$responseBody");
    }
  } catch (e) {
    print("❌ Failed to list models: $e");
  }
}
