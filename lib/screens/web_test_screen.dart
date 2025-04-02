import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UrlLauncherTest(),
    );
  }
}

class UrlLauncherTest extends StatelessWidget {
  UrlLauncherTest({super.key});

  final Uri _url = Uri.parse(
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_Amount=5000000&vnp_Command=pay&vnp_CreateDate=20250402200742&vnp_CurrCode=VND&vnp_IpAddr=127.0.0.1&vnp_Locale=vn&vnp_OrderInfo=Thanh+to%C3%A1n+cho+%C4%91%C6%A1n+%C4%91%E1%BA%B7t+ph%C3%B2ng%3A+344&vnp_OrderType=other&vnp_ReturnUrl=https%3A%2F%2F1e71-2402-800-631c-7e3b-a4ba-adcb-10dc-b031.ngrok-free.app%2Fapi%2Fpayment%2Fvnpay-callback&vnp_TmnCode=1RK2YH4I&vnp_TxnRef=638792212627787999&vnp_Version=2.1.0&vnp_SecureHash=02e45c4bb6d4539c61d1e43343657571fa95624f9d209463fd826024ecf164de1106db43c4673e2590a82956d51f5ae8efaf7466080d8bbc72256973ce57e353');

  Future<void> _launchUrl() async {
    if (!await launchUrl(_url)) {
      // if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Không thể mở URL: $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test URL Launcher')),
      body: Center(
        child: ElevatedButton(
          onPressed: _launchUrl,
          child: const Text('Mở Google'),
        ),
      ),
    );
  }
}
