#!/usr/bin/env python3
'''
Convert SyRI-formatted synteny blocks to ntSynt-formatted blocks
Annotation types used: INV, TRANS, SYN, INVTR
'''
import argparse

def convert_syri_format(blocks_filename, query, target, min_size):
    "Convert supplied syri synteny blocks to ntSynt format"
    block_id = 0

    same_strand_types = {"TRANS", "SYN"}
    diff_strand_types = {"INV", "INVTR"}

    with open(blocks_filename, 'r', encoding="utf-8") as fin:
        for line in fin:
            line = line.strip().split("\t")
            target_chrom, target_start, target_end = line[:3]
            query_chrom, query_start, query_end = line[5:8]
            annotation = line[10]
            if annotation not in same_strand_types and annotation not in diff_strand_types:
                continue
            target_start, target_end, query_start, query_end = map(int, [target_start, target_end,
                                                                         query_start, query_end])
            assert query_end - query_start > 0
            assert target_end - target_start > 0
            if query_end - query_start < min_size or \
                target_end - target_start < min_size:
                continue
            if annotation in same_strand_types:
                print(block_id, target, target_chrom, target_start, target_end, "+", "NA", "NA", sep="\t")
                print(block_id, query, query_chrom, query_start, query_end, "+", "NA", "NA", sep="\t")
                block_id += 1
            elif annotation in diff_strand_types:
                print(block_id, target, target_chrom, target_start, target_end, "+", "NA", "NA", sep="\t")
                print(block_id, query, query_chrom, query_start, query_end, "-", "NA", "NA", sep="\t")
                block_id += 1


def main():
    "Convert SyRI-formatted synteny blocks to ntSynt format"
    parser = argparse.ArgumentParser(description="Convert SyRI-formatted synteny blocks to ntSynt format")
    parser.add_argument("SYRI", help="SyRI-formatted blocks (syri.out)",
                        type=str)
    parser.add_argument("--query", help="Query assembly name", required=True, type=str)
    parser.add_argument("--target", help="Reference assembly file name", required=True, type=str)
    parser.add_argument("-b", "--min_size", help="Minimum block size (bp)", default=5000, type=int)
    args = parser.parse_args()

    convert_syri_format(args.SYRI, args.query, args.target, args.min_size)


if __name__ == "__main__":
    main()
