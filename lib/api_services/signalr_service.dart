import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import '../utils/constants.dart';

class SignalRService {
  final String hubUrl = "${Constants.baseUrl}slotHub";
  HubConnection? _hubConnection;

  Function(dynamic)? onSlotHeld;
  Function(dynamic)? onSlotReleased;
  Function(dynamic)? onBookingCreated;

  SignalRService() {
    _initHubConnection();
  }

  void _initHubConnection() {
    _hubConnection =
        HubConnectionBuilder().withUrl(hubUrl).withAutomaticReconnect().build();

    _hubConnection?.on("SlotHeld", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        print("SlotHeld received: ${arguments[0]}"); // Debug payload
        onSlotHeld?.call(arguments[0]);
      } else {
        print("SlotHeld received but arguments empty or null");
      }
    });

    _hubConnection?.on("SlotReleased", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        print("SlotReleased received: ${arguments[0]}"); // Debug payload
        onSlotReleased?.call(arguments[0]);
      } else {
        print("SlotReleased received but arguments empty or null");
      }
    });

    _hubConnection?.on("BookingCreated", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        print("BookingCreated received: ${arguments[0]}"); // Debug payload
        onBookingCreated?.call(arguments[0]);
      } else {
        print("BookingCreated received but arguments empty or null");
      }
    });
  }

  Future<void> startConnection() async {
    if (_hubConnection?.state != HubConnectionState.Connected) {
      try {
        print("Connecting to: $hubUrl");
        await _hubConnection?.start();
        print("SignalR connected successfully");
      } catch (e) {
        print("Error connecting to SignalR: $e");
        rethrow;
      }
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection?.state != HubConnectionState.Disconnected) {
      try {
        await _hubConnection?.stop();
        print("SignalR disconnected");
      } catch (e) {
        print("Error disconnecting SignalR: $e");
      }
    }
  }

  Future<void> dispose() async {
    await stopConnection();
    _hubConnection = null;
  }
}
