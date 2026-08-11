#!/usr/bin/env python3
"""Minimal ISO9660 (Level 2) writer, stdlib only.

Exists so building the per-VM autounattend ISO does not require xorriso,
genisoimage, mkisofs or hdiutil to be installed. The payload is two small
files at the volume root, which is well inside what a flat, single-directory
ISO9660 image can express.

Windows Setup scans the root of every mounted volume for autounattend.xml and
matches case-insensitively, so plain ISO9660 with uppercase 8.3-violating
(Level 2) names is read correctly by the CDFS driver.

    build:   mkiso.py -o out.iso -V LABEL file [file ...]
    verify:  mkiso.py --verify out.iso
"""

import argparse
import datetime
import hashlib
import os
import struct
import sys

SECTOR = 2048


def both16(v):
    return struct.pack("<H", v) + struct.pack(">H", v)


def both32(v):
    return struct.pack("<I", v) + struct.pack(">I", v)


def dt7(when):
    """7-byte directory-record timestamp."""
    return bytes([
        when.year - 1900, when.month, when.day,
        when.hour, when.minute, when.second, 0,
    ])


def dt17(when):
    """17-byte volume-descriptor timestamp."""
    return ("%04d%02d%02d%02d%02d%02d00" % (
        when.year, when.month, when.day,
        when.hour, when.minute, when.second)).encode("ascii") + b"\x00"


def pad_to(buf, size):
    if len(buf) > size:
        raise ValueError("field overflow: %d > %d" % (len(buf), size))
    return buf + b"\x00" * (size - len(buf))


def ascii_field(text, size, fill=b" "):
    raw = text.encode("ascii", "replace")[:size]
    return raw + fill * (size - len(raw))


def iso_name(filename):
    """ISO9660 Level 2 identifier: uppercase, ';1' version suffix."""
    name = os.path.basename(filename).upper()
    allowed = set("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.")
    name = "".join(c if c in allowed else "_" for c in name)
    if len(name) > 30:
        raise ValueError("name too long for ISO9660 Level 2: %s" % name)
    return (name + ";1").encode("ascii")


def dir_record(ident, extent, length, is_dir, when):
    """Assemble one directory record; length is always even."""
    body = bytearray()
    body += b"\x00"                       # record length, filled in below
    body += b"\x00"                       # extended attribute length
    body += both32(extent)
    body += both32(length)
    body += dt7(when)
    body += bytes([0x02 if is_dir else 0x00])
    body += b"\x00"                       # file unit size
    body += b"\x00"                       # interleave gap
    body += both16(1)                     # volume sequence number
    body += bytes([len(ident)])
    body += ident
    if len(body) % 2:
        body += b"\x00"
    body[0] = len(body)
    return bytes(body)


def build(out_path, label, files):
    when = datetime.datetime.now()

    for path in files:
        if not os.path.isfile(path):
            raise SystemExit("mkiso: not a file: %s" % path)

    # --- layout -------------------------------------------------------------
    # 0-15 system area | 16 PVD | 17 terminator | 18 L-path | 19 M-path
    # 20 root directory | 21+ file extents, each sector-aligned
    pvd_lba, term_lba, lpath_lba, mpath_lba, root_lba = 16, 17, 18, 19, 20

    sizes = [os.path.getsize(p) for p in files]
    extents, cursor = [], root_lba + 1
    for size in sizes:
        extents.append(cursor)
        cursor += max(1, (size + SECTOR - 1) // SECTOR)
    total_sectors = cursor

    # --- root directory -----------------------------------------------------
    root = bytearray()
    root += dir_record(b"\x00", root_lba, SECTOR, True, when)   # .
    root += dir_record(b"\x01", root_lba, SECTOR, True, when)   # ..
    for path, size, extent in zip(files, sizes, extents):
        root += dir_record(iso_name(path), extent, size, False, when)
    if len(root) > SECTOR:
        raise SystemExit("mkiso: too many files for a single-sector root")
    root = pad_to(bytes(root), SECTOR)

    # --- path tables (root only) -------------------------------------------
    def path_table(endian):
        rec = bytearray()
        rec += bytes([1, 0])                                     # len_di, ext_attr
        rec += struct.pack(endian + "I", root_lba)
        rec += struct.pack(endian + "H", 1)                      # parent index
        rec += b"\x00"                                           # identifier
        rec += b"\x00"                                           # pad to even
        return bytes(rec)

    lpath, mpath = path_table("<"), path_table(">")
    path_size = len(lpath)

    # --- primary volume descriptor -----------------------------------------
    pvd = bytearray()
    pvd += b"\x01" + b"CD001" + b"\x01" + b"\x00"
    pvd += ascii_field("", 32)                                   # system id
    pvd += ascii_field(label.upper(), 32)                        # volume id
    pvd += b"\x00" * 8
    pvd += both32(total_sectors)
    pvd += b"\x00" * 32
    pvd += both16(1)                                             # volume set size
    pvd += both16(1)                                             # volume sequence
    pvd += both16(SECTOR)
    pvd += both32(path_size)
    pvd += struct.pack("<I", lpath_lba)
    pvd += struct.pack("<I", 0)
    pvd += struct.pack(">I", mpath_lba)
    pvd += struct.pack(">I", 0)
    pvd += dir_record(b"\x00", root_lba, SECTOR, True, when)     # root record, 34B
    pvd += ascii_field("", 128)                                  # volume set id
    pvd += ascii_field("", 128)                                  # publisher
    pvd += ascii_field("", 128)                                  # data preparer
    pvd += ascii_field("GOAD-VBOX MKISO", 128)                   # application
    pvd += ascii_field("", 37)                                   # copyright file
    pvd += ascii_field("", 37)                                   # abstract file
    pvd += ascii_field("", 37)                                   # bibliographic
    pvd += dt17(when) + dt17(when)                               # created, modified
    pvd += b"0" * 16 + b"\x00"                                   # expires: never
    pvd += dt17(when)                                            # effective
    pvd += b"\x01" + b"\x00"                                     # structure version
    pvd = pad_to(bytes(pvd), SECTOR)

    term = pad_to(b"\xff" + b"CD001" + b"\x01", SECTOR)

    # --- emit ---------------------------------------------------------------
    with open(out_path, "wb") as iso:
        iso.write(b"\x00" * SECTOR * 16)
        iso.write(pvd)
        iso.write(term)
        iso.write(pad_to(lpath, SECTOR))
        iso.write(pad_to(mpath, SECTOR))
        iso.write(root)
        for path, extent in zip(files, extents):
            iso.seek(extent * SECTOR)
            with open(path, "rb") as src:
                iso.write(src.read())
        iso.truncate(total_sectors * SECTOR)

    return total_sectors


def verify(iso_path):
    """Re-parse the image and print what a reader would actually see."""
    with open(iso_path, "rb") as iso:
        data = iso.read()

    if len(data) % SECTOR:
        raise SystemExit("verify: size %d is not a sector multiple" % len(data))

    pvd = data[16 * SECTOR:17 * SECTOR]
    if pvd[0:1] != b"\x01" or pvd[1:6] != b"CD001":
        raise SystemExit("verify: no primary volume descriptor at sector 16")

    label = pvd[40:72].decode("ascii").rstrip()
    total = struct.unpack("<I", pvd[80:84])[0]
    if total * SECTOR != len(data):
        raise SystemExit("verify: PVD says %d sectors, file has %d"
                         % (total, len(data) // SECTOR))

    root_rec = pvd[156:190]
    root_lba = struct.unpack("<I", root_rec[2:6])[0]
    root = data[root_lba * SECTOR:(root_lba + 1) * SECTOR]

    print("volume label : %s" % label)
    print("image size   : %d sectors (%d bytes)" % (total, len(data)))
    print("root extent  : LBA %d" % root_lba)
    print("contents:")

    offset, found = 0, 0
    while offset < len(root):
        rec_len = root[offset]
        if rec_len == 0:
            break
        rec = root[offset:offset + rec_len]
        extent = struct.unpack("<I", rec[2:6])[0]
        length = struct.unpack("<I", rec[10:14])[0]
        is_dir = bool(rec[25] & 0x02)
        ident_len = rec[32]
        ident = rec[33:33 + ident_len]
        if not is_dir:
            payload = data[extent * SECTOR:extent * SECTOR + length]
            digest = hashlib.sha256(payload).hexdigest()[:16]
            print("  %-24s %7d bytes  LBA %-5d sha256:%s"
                  % (ident.decode("ascii"), length, extent, digest))
            found += 1
        offset += rec_len

    if not found:
        raise SystemExit("verify: no files in root directory")
    print("OK: %d file(s) readable" % found)


def main():
    ap = argparse.ArgumentParser(description="minimal ISO9660 writer")
    ap.add_argument("files", nargs="*", help="files to place at the volume root")
    ap.add_argument("-o", "--output", help="output .iso path")
    ap.add_argument("-V", "--label", default="UNATTEND", help="volume label")
    ap.add_argument("--verify", metavar="ISO", help="re-parse an image instead of building")
    args = ap.parse_args()

    if args.verify:
        verify(args.verify)
        return

    if not args.output:
        ap.error("--output is required when building")
    if not args.files:
        ap.error("no input files")

    sectors = build(args.output, args.label, args.files)
    print("wrote %s (%d sectors, %d bytes)"
          % (args.output, sectors, sectors * SECTOR), file=sys.stderr)


if __name__ == "__main__":
    main()
