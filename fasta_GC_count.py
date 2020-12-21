import sys
from Bio import SeqIO

out_file = open(sys.argv[2], 'w')

for rec in SeqIO.parse(open(sys.argv[1]), 'fasta'):
    print >> out_file, rec.id, len(rec.seq), (rec.seq.count("C") + rec.seq.count("G") + rec.seq.count("c") + rec.seq.count("g")) / float(len(rec.seq))

out_file.close()
