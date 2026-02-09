#!/usr/bin/env python3
'''
Determine orders of assemblies.
Always perform rotations on draft cladogram to ensure the --target-genome (if specified) is at the top of the orders.
If --tree specified, fully respect the orders.
If --tree NOT specified, then ensure that haplotypes are together, choosing a representatiive location
if they are not together in the cladogram.
'''
import argparse
import shlex
import subprocess
from typing import Optional


def generate_initial_orders(nwk: str, prefix: str, target: Optional[str], tree: Optional[bool]) -> None:
    "Generate the initial orders"
    cmd = f"ntsynt_viz_distance_cladogram.R --nwk {nwk} -p {prefix}"
    if target:
        cmd += f" --target {target}"
    if not tree:
        cmd += " --update_nwk"
    subprocess.check_call(shlex.split(cmd))

def adjust_orders(prefix: str, tree: bool, haplotypes: Optional[str]) -> None:
    "Make adjustments to initial orders to ensure that haplotypes are together, if applicable"
    orders = {} # Dictionary of assembly name -> index in order
    line_num = 0

    # Read in initial orders
    with open(f"{prefix}.order_tmp.tsv", 'r', encoding="utf-8") as fin:
        for line in fin:
            asm = line.strip()
            orders[asm] = line_num
            line_num += 1

    if not tree and haplotypes:
        # Read in haplotype TSV, adjust if needed
        with open(haplotypes, 'r', encoding="utf-8") as fin:
            for line in fin:
                asm1, asm2 = line.strip().split("\t")
                if abs(orders[asm1] - orders[asm2]) > 1:
                    print(f"WARNING: Adjusting orders for {asm1} and {asm2} to ensure "
                          f"that specified haplotypes are together")
                    if orders[asm1] > orders[asm2]:
                        orders[asm1] = orders[asm2] + 0.1
                    else:
                        orders[asm2] = orders[asm1] + 0.1

    # Write adjusted orders
    with open(f"{prefix}.order.tsv", 'w', encoding="utf-8") as fout:
        for asm in sorted(orders.keys(), key=lambda x: orders[x]):
            fout.write(f"{asm}\n")


def main():
    "Output the orders for assemblies in ribbon plots"
    parser = argparse.ArgumentParser(description="Output the orders for assemblies in ribbon plots")
    parser.add_argument("--nwk", help="Newick file", required=True, type=str)
    parser.add_argument("-p", "--prefix", help="Output prefix for file ordering [ntsynt_orders]",
                        required=False, default="ntsynt_orders")
    parser.add_argument("--target", help="Target genome to rotate to the top", required=False)
    parser.add_argument("--haplotypes", help="Haplotypes TSV", required=False, type=str)
    parser.add_argument("--tree", help="A tree has been supplied to the ntSynt-viz pipeline", action="store_true")

    args = parser.parse_args()

    # First, run the R script to get the initial orders
    generate_initial_orders(args.nwk, args.prefix, args.target, args.tree)

    # Make adjustments to initial orders to ensure that haplotypes are together - only if --tree NOT specified
    adjust_orders(args.prefix, args.tree, args.haplotypes)

if __name__ == "__main__":
    main()
