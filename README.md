# Snapshot Performance

As part of https://github.com/groue/GRDB.swift/issues/619...

Shows the difference between rebuilding a database snapshot vs. updating the
existing snapshot to the latest transaction.

See [Example.swift](/GRDBDatabaseSnapshotExample/Example.swift) for the interesting code.

**Rebuilding snapshot**
![Rebuilding snapshot](/images/rebuilding_snapshot.png)

**Fast forwarding snapshot**
![Fast forwarding snapshot](/images/fast_forwarding_snapshot.png)

