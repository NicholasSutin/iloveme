import Foundation
import SQLite3

// Reads cross-device Screen Time (incl. iPhone) from ScreenTimeAgent's cloud store.
// Run with --schema to dump table/column layout; otherwise emits usage rows as JSONL.
// Requires Full Disk Access for this binary.

let darwinDir = ProcessInfo.processInfo.environment["TMPDIR"]
    .map { URL(fileURLWithPath: $0).deletingLastPathComponent().path } ?? ""
let storeDir = "\(darwinDir)/0/com.apple.ScreenTimeAgent/Store"
let dbPath = "\(storeDir)/RMAdminStore-Cloud.sqlite"

func warn(_ msg: String) {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
}

func fail(_ msg: String, _ code: Int32) -> Never {
    warn(msg)
    exit(code)
}


// --diag: distinguish TCC denial (EPERM=1) from wrong path (ENOENT=2).
if CommandLine.arguments.contains("--diag") {
    for p in [dbPath, "\(NSHomeDirectory())/Library/Application Support/Knowledge/knowledgeC.db", "\(NSHomeDirectory())/Library/Safari/Bookmarks.plist"] {
        let fd = open(p, O_RDONLY)
        if fd >= 0 { print("OK      \(p)"); close(fd) }
        else { print("errno=\(errno) (\(String(cString: strerror(errno))))  \(p)") }
    }
    print("---")
}


if CommandLine.arguments.contains("--knowledge") {
    let kp = "\(NSHomeDirectory())/Library/Application Support/Knowledge/knowledgeC.db"
    let kt = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("k-\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: kt, withIntermediateDirectories: true)
    for ext in ["", "-wal", "-shm"] {
        try? FileManager.default.copyItem(atPath: kp + ext, toPath: kt.appendingPathComponent("k.db" + ext).path)
    }
    var kdb: OpaquePointer?
    if sqlite3_open_v2(kt.appendingPathComponent("k.db").path, &kdb, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
        fail("cannot open knowledgeC.db", 9)
    }
    func kq(_ s: String) -> [[String]] {
        var st: OpaquePointer?
        guard sqlite3_prepare_v2(kdb, s, -1, &st, nil) == SQLITE_OK else {
            warn("query err: \(String(cString: sqlite3_errmsg(kdb)))"); return []
        }
        defer { sqlite3_finalize(st) }
        var out: [[String]] = []
        while sqlite3_step(st) == SQLITE_ROW {
            var r: [String] = []
            for i in 0..<sqlite3_column_count(st) { r.append(sqlite3_column_text(st, i).map { String(cString: $0) } ?? "<null>") }
            out.append(r)
        }
        return out
    }
    print("== app-usage rows per source device ==")
    for r in kq("""
        SELECT COALESCE(s.ZDEVICEID,'<local/null>'), COUNT(*),
               datetime(MAX(o.ZSTARTDATE)+978307200,'unixepoch')
        FROM ZOBJECT o LEFT JOIN ZSOURCE s ON o.ZSOURCE = s.Z_PK
        WHERE o.ZSTREAMNAME='/app/usage' GROUP BY 1 ORDER BY 2 DESC
    """) { print("  device=\(r[0])  rows=\(r[1])  latest=\(r[2])") }
    print("== distinct streams (top 15) ==")
    for r in kq("SELECT ZSTREAMNAME, COUNT(*) FROM ZOBJECT GROUP BY 1 ORDER BY 2 DESC LIMIT 15") {
        print("  \(r[0])  \(r[1])")
    }
    try? FileManager.default.removeItem(at: kt)
    exit(0)
}

guard FileManager.default.isReadableFile(atPath: dbPath) else {
    fail("no read access to \(dbPath)\ngrant Full Disk Access to this binary, then re-run", 1)
}

let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("stpoll-\(UUID().uuidString)")
try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: tmp) }
for ext in ["", "-wal", "-shm"] {
    try? FileManager.default.copyItem(atPath: dbPath + ext, toPath: tmp.appendingPathComponent("s.sqlite" + ext).path)
}

var db: OpaquePointer?
guard sqlite3_open_v2(tmp.appendingPathComponent("s.sqlite").path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
    fail("sqlite open failed", 2)
}
defer { sqlite3_close(db) }

func query(_ sql: String) -> [[String]] {
    var st: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &st, nil) == SQLITE_OK else { return [] }
    defer { sqlite3_finalize(st) }
    var out: [[String]] = []
    while sqlite3_step(st) == SQLITE_ROW {
        var row: [String] = []
        for i in 0..<sqlite3_column_count(st) {
            row.append(sqlite3_column_text(st, i).map { String(cString: $0) } ?? "")
        }
        out.append(row)
    }
    return out
}

// --schema: dump layout so the exact usage query can be written against reality.
if CommandLine.arguments.contains("--schema") {
    for t in query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name") {
        let table = t[0]
        guard !table.hasPrefix("sqlite_") else { continue }
        let cols = query("PRAGMA table_info('\(table)')").map { $0[1] }
        let n = query("SELECT COUNT(*) FROM '\(table)'").first?.first ?? "?"
        print("\(table)  [\(n) rows]\n    \(cols.joined(separator: ", "))")
    }
    exit(0)
}

// Best-guess usage query per the documented RMAdminStore layout; --schema corrects it if wrong.
let appleEpoch = 978307200.0
let lookback = Double(CommandLine.arguments.dropFirst().first ?? "") ?? 7200
let cutoff = Date().timeIntervalSince1970 - appleEpoch - lookback
let sql = """
SELECT ti.ZBUNDLEIDENTIFIER, ti.ZTOTALTIMEINSECONDS, b.ZSTARTDATE, b.ZENDDATE, d.ZNAME, d.ZIDENTIFIER
FROM ZUSAGETIMEDITEM ti
JOIN ZUSAGECATEGORY c ON ti.ZCATEGORY = c.Z_PK
JOIN ZUSAGE u ON c.ZUSAGE = u.Z_PK
JOIN ZUSAGEBLOCK b ON u.ZUSAGEBLOCK = b.Z_PK
LEFT JOIN ZCOREDEVICE d ON b.ZDEVICE = d.Z_PK
WHERE b.ZSTARTDATE > \(cutoff)
ORDER BY b.ZSTARTDATE;
"""

var st: OpaquePointer?
guard sqlite3_prepare_v2(db, sql, -1, &st, nil) == SQLITE_OK else {
    fail("query failed — schema differs. Run: stpoll --schema\nsqlite: \(String(cString: sqlite3_errmsg(db)))", 3)
}
sqlite3_finalize(st)

let iso = ISO8601DateFormatter()
let polledAt = iso.string(from: Date())   // one timestamp per run, not per row
var n = 0
for r in query(sql) {
    let row: [String: Any] = [
        "bundle_id": r[0],
        "seconds": Int(r[1]) ?? 0,
        "block_start_utc": iso.string(from: Date(timeIntervalSince1970: (Double(r[2]) ?? 0) + appleEpoch)),
        "block_end_utc": iso.string(from: Date(timeIntervalSince1970: (Double(r[3]) ?? 0) + appleEpoch)),
        "device_name": r[4],
        "device_id": r[5],
        "polled_at": polledAt,
    ]
    if let d = try? JSONSerialization.data(withJSONObject: row), let s = String(data: d, encoding: .utf8) {
        print(s); n += 1
    }
}
warn("emitted \(n) rows")
