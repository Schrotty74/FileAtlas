//
//  ZipArchiver.swift
//  FileAtlas
//
//  In-Process-ZIP-Writer ohne externe Abhängigkeiten.
//  - Kompression: DEFLATE via `Compression`
//  - Optionale Verschlüsselung: WinZip AES-256 (AE-2) via CommonCrypto
//    (PBKDF2-HMAC-SHA1 → AES-256-CTR → HMAC-SHA1-Auth)
//  - Zip64 für Archive/Dateien > 4 GB
//
//  Ergebnis ist ein Standard-ZIP, das mit Keka/7-Zip/WinZip (verschlüsselt) bzw.
//  jedem Programm (unverschlüsselt) entpackt werden kann.
//

import Foundation
import Compression
import CommonCrypto
import Security

nonisolated struct ZipArchiver {

    enum ZipError: Error { case cannotCreateFile, cancelled }

    private static let zip64Threshold: UInt64 = 0xFFFF_FFFF

    /// Erstellt ein ZIP aus `sourceFolder` unter `destination`.
    /// - Parameter password: nil = unverschlüsselt, sonst AES-256 (WinZip AE-2).
    static func create(
        sourceFolder: URL,
        destination: URL,
        password: String?,
        shouldCancel: () -> Bool = { false },
        progress: (_ bytesProcessed: Int64, _ filesProcessed: Int) -> Void = { _, _ in }
    ) throws {
        let files = regularFiles(in: sourceFolder)

        FileManager.default.createFile(atPath: destination.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: destination) else {
            throw ZipError.cannotCreateFile
        }
        defer { try? handle.close() }

        var central = Data()
        var offset: UInt64 = 0
        var entryCount: UInt64 = 0
        var bytesProcessed: Int64 = 0

        for (index, file) in files.enumerated() {
            if shouldCancel() { throw ZipError.cancelled }

            let name = relativePath(of: file, base: sourceFolder)
            let raw = (try? Data(contentsOf: file)) ?? Data()
            let crc = crc32(raw)
            let (payload, method) = compress(raw)

            // Optional verschlüsseln (WinZip AE-2).
            let fileData: Data
            let storedMethod: UInt16
            let aesExtra: Data?
            if let password, !password.isEmpty {
                fileData = encryptAES(payload, password: password)
                storedMethod = 99                                   // AES
                aesExtra = aesExtraField(actualMethod: method)
            } else {
                fileData = payload
                storedMethod = method
                aesExtra = nil
            }

            let uncompSize = UInt64(raw.count)
            let compSize = UInt64(fileData.count)
            let headerCRC: UInt32 = (aesExtra != nil) ? 0 : crc      // AE-2: CRC = 0
            let (dosTime, dosDate) = dosDateTime(for: file)
            let localOffset = offset

            let needsZip64 = uncompSize >= zip64Threshold
                || compSize >= zip64Threshold
                || localOffset >= zip64Threshold

            // ----- Local File Header -----
            let nameBytes = Data(name.utf8)
            var local = Data()
            local.le(UInt32(0x04034b50))
            local.le(UInt16(needsZip64 ? 45 : (storedMethod == 99 ? 51 : 20)))   // version needed
            local.le(UInt16(0x0800))                                              // flags: UTF-8 names
            local.le(storedMethod)
            local.le(dosTime)
            local.le(dosDate)
            local.le(headerCRC)
            local.le(UInt32(needsZip64 ? 0xFFFFFFFF : UInt32(compSize)))
            local.le(UInt32(needsZip64 ? 0xFFFFFFFF : UInt32(uncompSize)))
            local.le(UInt16(nameBytes.count))

            var localExtra = Data()
            if needsZip64 { localExtra.append(zip64LocalExtra(uncomp: uncompSize, comp: compSize)) }
            if let aesExtra { localExtra.append(aesExtra) }
            local.le(UInt16(localExtra.count))
            local.append(nameBytes)
            local.append(localExtra)

            handle.write(local)
            handle.write(fileData)
            offset += UInt64(local.count) + compSize

            // ----- Central Directory Record -----
            var cd = Data()
            cd.le(UInt32(0x02014b50))
            cd.le(UInt16(needsZip64 ? 45 : 51))                                   // version made by
            cd.le(UInt16(needsZip64 ? 45 : (storedMethod == 99 ? 51 : 20)))       // version needed
            cd.le(UInt16(0x0800))
            cd.le(storedMethod)
            cd.le(dosTime)
            cd.le(dosDate)
            cd.le(headerCRC)
            cd.le(UInt32(compSize >= zip64Threshold ? 0xFFFFFFFF : UInt32(compSize)))
            cd.le(UInt32(uncompSize >= zip64Threshold ? 0xFFFFFFFF : UInt32(uncompSize)))
            cd.le(UInt16(nameBytes.count))

            var centralExtra = Data()
            if needsZip64 {
                centralExtra.append(zip64CentralExtra(uncomp: uncompSize, comp: compSize, offset: localOffset))
            }
            if let aesExtra { centralExtra.append(aesExtra) }
            cd.le(UInt16(centralExtra.count))
            cd.le(UInt16(0))                                                      // comment length
            cd.le(UInt16(0))                                                      // disk number start
            cd.le(UInt16(0))                                                      // internal attrs
            cd.le(UInt32(0))                                                      // external attrs
            cd.le(UInt32(localOffset >= zip64Threshold ? 0xFFFFFFFF : UInt32(localOffset)))
            cd.append(nameBytes)
            cd.append(centralExtra)
            central.append(cd)

            entryCount += 1
            bytesProcessed += Int64(raw.count)
            progress(bytesProcessed, index + 1)
        }

        // ----- Central Directory + (Zip64) EOCD -----
        let centralOffset = offset
        let centralSize = UInt64(central.count)
        handle.write(central)

        let needsZip64EOCD = centralOffset >= zip64Threshold
            || centralSize >= zip64Threshold
            || entryCount >= 0xFFFF

        if needsZip64EOCD {
            let zip64EOCDOffset = centralOffset + centralSize
            handle.write(zip64EOCD(entryCount: entryCount, centralSize: centralSize, centralOffset: centralOffset))
            handle.write(zip64Locator(zip64EOCDOffset: zip64EOCDOffset))
        }

        var eocd = Data()
        eocd.le(UInt32(0x06054b50))
        eocd.le(UInt16(0))                                                        // disk number
        eocd.le(UInt16(0))                                                        // disk with central dir
        eocd.le(UInt16(entryCount >= 0xFFFF ? 0xFFFF : UInt16(entryCount)))
        eocd.le(UInt16(entryCount >= 0xFFFF ? 0xFFFF : UInt16(entryCount)))
        eocd.le(UInt32(centralSize >= zip64Threshold ? 0xFFFFFFFF : UInt32(centralSize)))
        eocd.le(UInt32(centralOffset >= zip64Threshold ? 0xFFFFFFFF : UInt32(centralOffset)))
        eocd.le(UInt16(0))                                                        // comment length
        handle.write(eocd)
    }

    // MARK: - Dateiliste

    /// Alle regulären Dateien (rekursiv) relativ zu `folder`.
    static func regularFiles(in folder: URL) -> [URL] {
        let scoped = folder.startAccessingSecurityScopedResource()
        defer { if scoped { folder.stopAccessingSecurityScopedResource() } }

        guard let en = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: []
        ) else { return [] }
        var result: [URL] = []
        for case let url as URL in en {
            if (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true {
                result.append(url)
            }
        }
        return result
    }

    /// Gesamtgröße aller regulären Dateien in `folder`.
    static func totalSize(of folder: URL) -> Int64 {
        regularFiles(in: folder).reduce(Int64(0)) {
            $0 + Int64((try? $1.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        }
    }

    private static func relativePath(of url: URL, base: URL) -> String {
        let basePath = base.path(percentEncoded: false)
        let full = url.path(percentEncoded: false)
        var rel = full.hasPrefix(basePath) ? String(full.dropFirst(basePath.count)) : full
        while rel.hasPrefix("/") { rel.removeFirst() }
        return rel
    }

    // MARK: - Kompression

    private static func compress(_ data: Data) -> (payload: Data, method: UInt16) {
        guard !data.isEmpty else { return (Data(), 0) }
        let cap = data.count
        var dst = Data(count: cap)
        let n = dst.withUnsafeMutableBytes { d -> Int in
            data.withUnsafeBytes { s -> Int in
                compression_encode_buffer(
                    d.bindMemory(to: UInt8.self).baseAddress!, cap,
                    s.bindMemory(to: UInt8.self).baseAddress!, data.count,
                    nil, COMPRESSION_ZLIB)
            }
        }
        if n == 0 || n >= data.count { return (data, 0) }   // nicht komprimierbar → speichern
        dst.removeSubrange(n..<dst.count)
        return (dst, 8)
    }

    // MARK: - WinZip AES-256 (AE-2)

    private static func aesExtraField(actualMethod: UInt16) -> Data {
        var f = Data()
        f.le(UInt16(0x9901))            // AES extra tag
        f.le(UInt16(7))                 // data size
        f.le(UInt16(2))                 // vendor version (AE-2)
        f.append(contentsOf: [0x41, 0x45])  // "AE"
        f.append(UInt8(3))              // strength: 3 = AES-256
        f.le(actualMethod)              // actual compression method
        return f
    }

    private static func encryptAES(_ payload: Data, password: String) -> Data {
        let salt = randomBytes(16)                                   // AES-256 → 16-Byte-Salt
        let dk = pbkdf2(password: password, salt: salt, rounds: 1000, length: 2 * 32 + 2)
        let encKey = dk.subdata(in: 0..<32)
        let authKey = dk.subdata(in: 32..<64)
        let pv = dk.subdata(in: 64..<66)                             // password verification value

        let cipher = aesCTR(payload, key: encKey)
        let mac = hmacSHA1(key: authKey, data: cipher).prefix(10)

        var out = Data()
        out.append(salt)
        out.append(pv)
        out.append(cipher)
        out.append(contentsOf: mac)
        return out
    }

    /// AES-256 im CTR-Modus mit 128-Bit-Little-Endian-Zähler ab 1 (WinZip-Konvention).
    private static func aesCTR(_ data: Data, key: Data) -> Data {
        guard !data.isEmpty else { return Data() }
        let blocks = (data.count + 15) / 16
        var counters = Data(count: blocks * 16)
        counters.withUnsafeMutableBytes { buf in
            let p = buf.bindMemory(to: UInt8.self).baseAddress!
            for i in 0..<blocks {
                let v = UInt64(i + 1)
                for b in 0..<8 { p[i * 16 + b] = UInt8((v >> (8 * b)) & 0xFF) }
            }
        }
        let keystream = aesECB(counters, key: key)
        var out = Data(count: data.count)
        out.withUnsafeMutableBytes { o in
            data.withUnsafeBytes { d in
                keystream.withUnsafeBytes { k in
                    let op = o.bindMemory(to: UInt8.self).baseAddress!
                    let dp = d.bindMemory(to: UInt8.self).baseAddress!
                    let kp = k.bindMemory(to: UInt8.self).baseAddress!
                    for i in 0..<data.count { op[i] = dp[i] ^ kp[i] }
                }
            }
        }
        return out
    }

    private static func aesECB(_ data: Data, key: Data) -> Data {
        var out = Data(count: data.count + kCCBlockSizeAES128)
        var moved = 0
        let status = out.withUnsafeMutableBytes { o in
            data.withUnsafeBytes { d in
                key.withUnsafeBytes { k in
                    CCCrypt(
                        CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionECBMode),
                        k.baseAddress, key.count, nil,
                        d.baseAddress, data.count,
                        o.baseAddress, o.count, &moved)
                }
            }
        }
        guard status == kCCSuccess else { return Data(count: data.count) }
        out.removeSubrange(moved..<out.count)
        return out
    }

    private static func pbkdf2(password: String, salt: Data, rounds: Int, length: Int) -> Data {
        var out = Data(count: length)
        let pw = Array(password.utf8)
        let status = out.withUnsafeMutableBytes { o in
            salt.withUnsafeBytes { s in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pw.map { Int8(bitPattern: $0) }, pw.count,
                    s.bindMemory(to: UInt8.self).baseAddress, salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), UInt32(rounds),
                    o.bindMemory(to: UInt8.self).baseAddress, length)
            }
        }
        return status == kCCSuccess ? out : Data(count: length)
    }

    private static func hmacSHA1(key: Data, data: Data) -> Data {
        var mac = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
        mac.withUnsafeMutableBytes { m in
            key.withUnsafeBytes { k in
                data.withUnsafeBytes { d in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
                           k.baseAddress, key.count,
                           d.baseAddress, data.count,
                           m.baseAddress)
                }
            }
        }
        return mac
    }

    private static func randomBytes(_ count: Int) -> Data {
        var d = Data(count: count)
        _ = d.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!) }
        return d
    }

    // MARK: - Zip64-Hilfen

    private static func zip64LocalExtra(uncomp: UInt64, comp: UInt64) -> Data {
        var d = Data()
        d.le(UInt16(0x0001))
        d.le(UInt16(16))
        d.le(uncomp)
        d.le(comp)
        return d
    }

    private static func zip64CentralExtra(uncomp: UInt64, comp: UInt64, offset: UInt64) -> Data {
        var body = Data()
        if uncomp >= zip64Threshold { body.le(uncomp) }
        if comp >= zip64Threshold { body.le(comp) }
        if offset >= zip64Threshold { body.le(offset) }
        var d = Data()
        d.le(UInt16(0x0001))
        d.le(UInt16(body.count))
        d.append(body)
        return d
    }

    private static func zip64EOCD(entryCount: UInt64, centralSize: UInt64, centralOffset: UInt64) -> Data {
        var d = Data()
        d.le(UInt32(0x06064b50))
        d.le(UInt64(44))                    // size of remainder of this record
        d.le(UInt16(45))                    // version made by
        d.le(UInt16(45))                    // version needed
        d.le(UInt32(0))                     // disk number
        d.le(UInt32(0))                     // disk with central dir
        d.le(entryCount)                    // entries on this disk
        d.le(entryCount)                    // total entries
        d.le(centralSize)
        d.le(centralOffset)
        return d
    }

    private static func zip64Locator(zip64EOCDOffset: UInt64) -> Data {
        var d = Data()
        d.le(UInt32(0x07064b50))
        d.le(UInt32(0))                     // disk with zip64 EOCD
        d.le(zip64EOCDOffset)
        d.le(UInt32(1))                     // total disks
        return d
    }

    // MARK: - CRC-32 / DOS-Datum

    private static let crcTable: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1 != 0) ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
        return c
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        data.withUnsafeBytes { buf in
            for byte in buf.bindMemory(to: UInt8.self) {
                crc = crcTable[Int((crc ^ UInt32(byte)) & 0xFF)] ^ (crc >> 8)
            }
        }
        return crc ^ 0xFFFFFFFF
    }

    private static func dosDateTime(for url: URL) -> (time: UInt16, date: UInt16) {
        let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?
            .contentModificationDate ?? Date(timeIntervalSince1970: 315532800)  // 1980-01-01
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = max(1980, c.year ?? 1980) - 1980
        let dosDate = UInt16((year << 9) | ((c.month ?? 1) << 5) | (c.day ?? 1))
        let dosTime = UInt16(((c.hour ?? 0) << 11) | ((c.minute ?? 0) << 5) | ((c.second ?? 0) / 2))
        return (dosTime, dosDate)
    }
}

// MARK: - Little-Endian-Anhänge

private extension Data {
    nonisolated mutating func le(_ v: UInt16) {
        append(UInt8(v & 0xFF)); append(UInt8((v >> 8) & 0xFF))
    }
    nonisolated mutating func le(_ v: UInt32) {
        for i in 0..<4 { append(UInt8((v >> (8 * i)) & 0xFF)) }
    }
    nonisolated mutating func le(_ v: UInt64) {
        for i in 0..<8 { append(UInt8(UInt64(v >> (8 * UInt64(i))) & 0xFF)) }
    }
}
