import 'package:dart_packstream/dart_packstream.dart';

// Import structure files
import 'structures/node.dart';
import 'structures/relationship.dart';
import 'structures/unbound_relationship.dart';
import 'structures/path.dart';
import 'structures/date.dart';
import 'structures/time.dart';
import 'structures/local_time.dart';
import 'structures/date_time.dart';
import 'structures/date_time_zone_id.dart';
import 'structures/local_date_time.dart';
import 'structures/duration.dart';
import 'structures/point_2d.dart';
import 'structures/point_3d.dart';
import 'structures/legacy_date_time.dart';
import 'structures/legacy_date_time_zone_id.dart';

// Import message files
import 'messages/request_messages.dart';
import 'messages/response_messages.dart';

/// Registers all Bolt structures and messages with the PackStream structure registry.
///
/// This function should be called before using any Bolt structures or messages for
/// serialization or deserialization. It's safe to call this function multiple times.
///
/// This registers:
/// - All Bolt graph structures (nodes, relationships, paths)
/// - All Bolt temporal structures (dates, times, durations)
/// - All Bolt spatial structures (2D/3D points)
/// - All Bolt legacy structures
/// - All Bolt request messages (HELLO, RUN, PULL, etc.)
/// - All Bolt response messages (SUCCESS, FAILURE, RECORD, etc.)
void registerBolt() {
  _registerBoltStructures();
  _registerBoltMessages();
}

/// Registers only Bolt structures with the PackStream structure registry.
///
/// This function is available for cases where you only need structure support
/// without message protocol support.
void registerBoltStructures() {
  _registerBoltStructures();
}

/// Registers only Bolt messages with the PackStream structure registry.
///
/// This function is available for cases where you only need message protocol
/// support without structure support.
void registerBoltMessages() {
  _registerBoltMessages();
}

void _registerBoltStructures() {
  // Graph structures
  PsStructureRegistry.register(0x4E, BoltNode.fromValues);
  PsStructureRegistry.register(0x52, BoltRelationship.fromValues);
  PsStructureRegistry.register(0x72, BoltUnboundRelationship.fromValues);
  PsStructureRegistry.register(0x50, BoltPath.fromValues);

  // Temporal structures
  PsStructureRegistry.register(0x44, BoltDate.fromValues);
  PsStructureRegistry.register(0x54, BoltTime.fromValues);
  PsStructureRegistry.register(0x74, BoltLocalTime.fromValues);
  PsStructureRegistry.register(0x49, BoltDateTime.fromValues);
  PsStructureRegistry.register(0x69, BoltDateTimeZoneId.fromValues);
  PsStructureRegistry.register(0x64, BoltLocalDateTime.fromValues);
  PsStructureRegistry.register(0x45, BoltDuration.fromValues);

  // Spatial structures
  PsStructureRegistry.register(0x58, BoltPoint2D.fromValues);
  PsStructureRegistry.register(0x59, BoltPoint3D.fromValues);

  // Legacy structures
  PsStructureRegistry.register(0x46, BoltLegacyDateTime.fromValues);
  PsStructureRegistry.register(0x66, BoltLegacyDateTimeZoneId.fromValues);
}

void _registerBoltMessages() {
  // Request messages
  PsStructureRegistry.register(0x01, BoltHelloMessage.fromValues);
  PsStructureRegistry.register(0x6A, BoltLogonMessage.fromValues);
  PsStructureRegistry.register(0x10, BoltRunMessage.fromValues);
  PsStructureRegistry.register(0x3F, BoltPullMessage.fromValues);
  PsStructureRegistry.register(0x2F, BoltDiscardMessage.fromValues);
  PsStructureRegistry.register(0x11, BoltBeginMessage.fromValues);
  PsStructureRegistry.register(0x12, BoltCommitMessage.fromValues);
  PsStructureRegistry.register(0x13, BoltRollbackMessage.fromValues);
  PsStructureRegistry.register(0x0F, BoltResetMessage.fromValues);
  PsStructureRegistry.register(0x02, BoltGoodbyeMessage.fromValues);

  // Response messages
  PsStructureRegistry.register(0x70, BoltSuccessMessage.fromValues);
  PsStructureRegistry.register(0x7F, BoltFailureMessage.fromValues);
  PsStructureRegistry.register(0x7E, BoltIgnoredMessage.fromValues);
  PsStructureRegistry.register(0x71, BoltRecordMessage.fromValues);
}
