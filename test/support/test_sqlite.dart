import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';

/// Runs real SQLite transactions through Node's built-in SQLite on Windows.
class TestSqlite implements Database, Transaction {
  TestSqlite._(this.process) {
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      final reply = jsonDecode(line) as Map;
      final completer = pending.removeAt(0);
      if (reply['error'] != null) {
        completer.completeError(StateError(reply['error'] as String));
      } else {
        completer.complete(reply['value']);
      }
    });
    process.stderr.drain<void>();
  }
  final Process process;
  final pending = <Completer<dynamic>>[];
  static Future<TestSqlite> open(String path) async => TestSqlite._(
      await Process.start('node', ['test/support/sqlite_bridge.cjs', path]));
  Future<dynamic> run(String kind, String sql, [List<Object?>? args]) {
    final c = Completer<dynamic>();
    pending.add(c);
    process.stdin
        .writeln(jsonEncode({'kind': kind, 'sql': sql, 'args': args ?? []}));
    return c.future;
  }

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    await run('execute', sql, arguments);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
          [List<Object?>? arguments]) async =>
      (await run('query', sql, arguments) as List)
          .map((r) => Map<String, Object?>.from(r as Map))
          .toList();
  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async =>
      await run('insert', sql, arguments) as int;
  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async =>
      await run('update', sql, arguments) as int;
  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) =>
      rawUpdate(sql, arguments);
  @override
  Future<List<Map<String, Object?>>> query(String table,
          {bool? distinct,
          List<String>? columns,
          String? where,
          List<Object?>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset}) =>
      rawQuery(
          'SELECT ${distinct == true ? 'DISTINCT ' : ''}${columns?.join(',') ?? '*'} FROM $table${where == null ? '' : ' WHERE $where'}${orderBy == null ? '' : ' ORDER BY $orderBy'}${limit == null ? '' : ' LIMIT $limit'}',
          whereArgs);
  @override
  Future<int> insert(String table, Map<String, Object?> values,
          {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) =>
      rawInsert(
          'INSERT ${conflictAlgorithm == ConflictAlgorithm.replace ? 'OR REPLACE ' : conflictAlgorithm == ConflictAlgorithm.ignore ? 'OR IGNORE ' : ''}INTO $table (${values.keys.join(',')}) VALUES (${List.filled(values.length, '?').join(',')})',
          values.values.toList());
  @override
  Future<int> update(String table, Map<String, Object?> values,
          {String? where,
          List<Object?>? whereArgs,
          ConflictAlgorithm? conflictAlgorithm}) =>
      rawUpdate(
          'UPDATE $table SET ${values.keys.map((k) => '$k = ?').join(',')}${where == null ? '' : ' WHERE $where'}',
          [...values.values, ...?whereArgs]);
  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) =>
      rawDelete('DELETE FROM $table${where == null ? '' : ' WHERE $where'}',
          whereArgs);
  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive}) async {
    await execute('BEGIN');
    try {
      final value = await action(this);
      await execute('COMMIT');
      return value;
    } catch (_) {
      await execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await process.stdin.close();
    await process.exitCode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
