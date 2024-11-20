#!/usr/bin/env python3
'''
Convert the halSynteny PSL synteny block format to the ntSynt format
'''
import argparse
from collections import defaultdict

def load_chromosome_name_conversions(file_in: str) -> dict:
    "Load the chromosome name conversions per assembly into a dictionary"
    chrom_dict = defaultdict(dict)
    with open(file_in, 'r', encoding="utf-8") as fin:
        for line in fin:
            asm_file, chr_old, chr_new = line.strip().split("\t")
            chrom_dict[asm_file][chr_old] = chr_new
    return chrom_dict


def convert_psl(query_name: str, target_name: str, pslfile: str, conversion=None) -> None:
    "Convert the PSL file format"
    block_id = 0
    with open(pslfile, 'r', encoding="utf-8") as fin:
        for line in fin:
            line = line.strip().split("\t")
            strand = line[8]
            query_chrom, query_start, query_end = (line[9], *line[11:13])
            target_chrom, target_start, target_end = line[13], *line[15:17]
            if conversion is not None:
                query_chrom = conversion[query_name][query_chrom]
                target_chrom = conversion[target_name][target_chrom]
            print(block_id, query_name, query_chrom, query_start, query_end, strand[0], "NA", "NA", sep="\t")
            print(block_id, target_name, target_chrom, target_start, target_end, strand[1], "NA", "NA", sep="\t")
            block_id += 1

def main():
    "Convert the halSynteny PSL file format"
    parser = argparse.ArgumentParser(description="Convert the halSynteny PSL synteny block output to ntSynt format")
    parser.add_argument("--query", help="File name of query (earlier column in PSL file)", type=str, required=True)
    parser.add_argument("--target", help="File name of target", type=str, required=True)
    parser.add_argument("--convert", help="TSV file to convert the chromosome names. 3 column format: "
                                            "assembly, current name, new name",
                        required=False, type=str)
    parser.add_argument("PSL", help="PSL input file to convert")
    args = parser.parse_args()

    if args.convert:
        convert_dict = load_chromosome_name_conversions(args.convert)
        convert_psl(args.query, args.target, args.PSL, conversion=convert_dict)
    else:
        convert_psl(args.query, args.target, args.PSL)

if __name__ == "__main__":
    main()
