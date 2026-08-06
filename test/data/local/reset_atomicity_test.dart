// Every ResetDao reset is exactly one `@transaction` method grouping
// several deletes — Floor's generated wrapper runs that method body
// inside one native `sqflite.Database.transaction()` call (confirmed by
// reading the generated app_database.g.dart), and sqflite/sqlite
// guarantee a mid-transaction failure rolls back everything applied so
// far. This test proves that underlying guarantee holds in this exact
// app's sqflite/sqflite_common_ffi setup, so a failure partway through
// e.g. `ResetDao.resetEverything()` can never leave a partially-wiped
// database.

import 'package:floor/floor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('a mid-transaction failure rolls back every change made so far', () async {
    final db = await sqfliteDatabaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, value TEXT NOT NULL)');
        },
      ),
    );
    addTearDown(db.close);

    await db.insert('t', {'id': 1, 'value': 'seed'});

    Object? caught;
    try {
      await db.transaction((txn) async {
        await txn.delete('t', where: 'id = ?', whereArgs: [1]);
        await txn.insert('t', {'id': 2, 'value': 'never persisted'});
        throw StateError('simulated failure mid-reset');
      });
    } catch (e) {
      caught = e;
    }

    expect(caught, isA<StateError>());

    // Neither the delete nor the insert made it through — the seed row
    // is exactly as it was before the transaction started.
    final rows = await db.query('t');
    expect(rows, [
      {'id': 1, 'value': 'seed'},
    ]);
  });
}
