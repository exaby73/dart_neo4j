import 'package:dart_packstream/dart_packstream.dart';
import 'request_messages.dart';
import 'response_messages.dart';

/// Utility class for creating common Bolt messages.
class BoltMessageFactory {
  /// Creates a HELLO message for newer protocols (without authentication).
  ///
  /// [userAgent] - identifies the client application
  /// [boltAgent] - identifies the driver (optional)
  static BoltHelloMessage hello({
    required String userAgent,
    Map<String, String>? boltAgent,
  }) {
    final extra = <PsString, PsDataType>{
      PsString('user_agent'): PsString(userAgent),
    };

    // Add bolt agent if provided
    if (boltAgent != null) {
      final agentDict = <PsString, PsDataType>{};
      boltAgent.forEach((key, value) {
        agentDict[PsString(key)] = PsString(value);
      });
      extra[PsString('bolt_agent')] = PsDictionary(agentDict);
    }

    return BoltHelloMessage(PsDictionary(extra));
  }

  /// Creates a HELLO message with basic authentication (legacy protocols).
  ///
  /// [userAgent] - identifies the client application
  /// [username] - username for basic authentication (optional)
  /// [password] - password for basic authentication (optional)
  /// [boltAgent] - identifies the driver (optional)
  static BoltHelloMessage helloWithAuth({
    required String userAgent,
    String? username,
    String? password,
    Map<String, String>? boltAgent,
  }) {
    final extra = <PsString, PsDataType>{
      PsString('user_agent'): PsString(userAgent),
    };

    // Add authentication scheme
    if (username != null && password != null) {
      extra[PsString('scheme')] = PsString('basic');
      extra[PsString('principal')] = PsString(username);
      extra[PsString('credentials')] = PsString(password);
    } else {
      extra[PsString('scheme')] = PsString('none');
    }

    // Add bolt agent if provided
    if (boltAgent != null) {
      final agentDict = <PsString, PsDataType>{};
      boltAgent.forEach((key, value) {
        agentDict[PsString(key)] = PsString(value);
      });
      extra[PsString('bolt_agent')] = PsDictionary(agentDict);
    }

    return BoltHelloMessage(PsDictionary(extra));
  }

  /// Creates a LOGON message for authentication.
  ///
  /// [scheme] - authentication scheme ('basic', 'bearer', 'kerberos', 'none')
  /// [principal] - username or principal for authentication (optional)
  /// [credentials] - password or token for authentication (optional)
  /// [realm] - authentication realm (optional)
  static BoltLogonMessage logon({
    required String scheme,
    String? principal,
    String? credentials,
    String? realm,
  }) {
    final auth = <PsString, PsDataType>{
      PsString('scheme'): PsString(scheme),
    };

    if (principal != null) {
      auth[PsString('principal')] = PsString(principal);
    }

    if (credentials != null) {
      auth[PsString('credentials')] = PsString(credentials);
    }

    if (realm != null) {
      auth[PsString('realm')] = PsString(realm);
    }

    return BoltLogonMessage(PsDictionary(auth));
  }

  /// Creates a RUN message for executing a Cypher query.
  ///
  /// [query] - the Cypher query to execute
  /// [parameters] - parameters for the query (default: empty)
  /// [extra] - additional metadata like bookmarks, timeouts, etc.
  static BoltRunMessage run(
    String query, {
    Map<String, Object?>? parameters,
    Map<String, Object?>? extra,
  }) {
    final psParameters = <PsString, PsDataType>{};
    if (parameters != null) {
      parameters.forEach((key, value) {
        psParameters[PsString(key)] = PsDataType.fromValue(value);
      });
    }

    PsDictionary? psExtra;
    if (extra != null) {
      final extraDict = <PsString, PsDataType>{};
      extra.forEach((key, value) {
        extraDict[PsString(key)] = PsDataType.fromValue(value);
      });
      psExtra = PsDictionary(extraDict);
    }

    return BoltRunMessage(PsString(query), PsDictionary(psParameters), psExtra);
  }

  /// Creates a PULL message to fetch records.
  ///
  /// [n] - number of records to fetch (-1 for all, default: -1)
  /// [qid] - query ID for explicit transactions (default: -1)
  static BoltPullMessage pull({int n = -1, int qid = -1}) {
    final extra = <PsString, PsDataType>{
      PsString('n'): PsInt.compact(n),
      PsString('qid'): PsInt.compact(qid),
    };
    return BoltPullMessage(PsDictionary(extra));
  }

  /// Creates a PULL message for older protocol versions (no parameters).
  static BoltPullMessage pullAll() {
    return BoltPullMessage();
  }

  /// Creates a DISCARD message to discard records.
  ///
  /// [n] - number of records to discard (-1 for all, default: -1)
  /// [qid] - query ID for explicit transactions (default: -1)
  static BoltDiscardMessage discard({int n = -1, int qid = -1}) {
    final extra = <PsString, PsDataType>{
      PsString('n'): PsInt.compact(n),
      PsString('qid'): PsInt.compact(qid),
    };
    return BoltDiscardMessage(PsDictionary(extra));
  }

  /// Creates a DISCARD message for older protocol versions (no parameters).
  static BoltDiscardMessage discardAll() {
    return BoltDiscardMessage();
  }

  /// Creates a BEGIN message to start an explicit transaction.
  ///
  /// [bookmarks] - list of bookmark strings
  /// [txTimeout] - transaction timeout in milliseconds
  /// [txMetadata] - transaction metadata
  /// [mode] - transaction mode ('r' for read, 'w' for write)
  /// [db] - database name
  static BoltBeginMessage begin({
    List<String>? bookmarks,
    int? txTimeout,
    Map<String, Object?>? txMetadata,
    String? mode,
    String? db,
  }) {
    final extra = <PsString, PsDataType>{};

    if (bookmarks != null && bookmarks.isNotEmpty) {
      extra[PsString('bookmarks')] = PsList(
        bookmarks.map((b) => PsString(b)).toList(),
      );
    }

    if (txTimeout != null) {
      extra[PsString('tx_timeout')] = PsInt.compact(txTimeout);
    }

    if (txMetadata != null) {
      final metadataDict = <PsString, PsDataType>{};
      txMetadata.forEach((key, value) {
        metadataDict[PsString(key)] = PsDataType.fromValue(value);
      });
      extra[PsString('tx_metadata')] = PsDictionary(metadataDict);
    }

    if (mode != null) {
      extra[PsString('mode')] = PsString(mode);
    }

    if (db != null) {
      extra[PsString('db')] = PsString(db);
    }

    return BoltBeginMessage(PsDictionary(extra));
  }

  /// Creates a COMMIT message.
  static BoltCommitMessage commit() => BoltCommitMessage();

  /// Creates a ROLLBACK message.
  static BoltRollbackMessage rollback() => BoltRollbackMessage();

  /// Creates a RESET message.
  static BoltResetMessage reset() => BoltResetMessage();

  /// Creates a GOODBYE message.
  static BoltGoodbyeMessage goodbye() => BoltGoodbyeMessage();

  /// Creates a SUCCESS message.
  ///
  /// [metadata] - metadata about the successful operation
  static BoltSuccessMessage success([Map<String, Object?>? metadata]) {
    if (metadata == null) return BoltSuccessMessage();

    final psMetadata = <PsString, PsDataType>{};
    metadata.forEach((key, value) {
      psMetadata[PsString(key)] = PsDataType.fromValue(value);
    });

    return BoltSuccessMessage(PsDictionary(psMetadata));
  }

  /// Creates a FAILURE message.
  ///
  /// [code] - error code
  /// [message] - error message
  static BoltFailureMessage failure(String code, String message) {
    final metadata = <PsString, PsDataType>{
      PsString('code'): PsString(code),
      PsString('message'): PsString(message),
    };
    return BoltFailureMessage(PsDictionary(metadata));
  }

  /// Creates an IGNORED message.
  static BoltIgnoredMessage ignored() => BoltIgnoredMessage();

  /// Creates a RECORD message.
  ///
  /// [data] - list of values for this record
  static BoltRecordMessage record(List<Object?> data) {
    final psData = data.map((value) => PsDataType.fromValue(value)).toList();
    return BoltRecordMessage(PsList(psData));
  }
}
