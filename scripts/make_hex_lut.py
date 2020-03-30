def main():
  entries = []
  
  with open("/home/parallels/aos-final/CascadeIn/dnnweaver/norm_lut.mif", "r") as fin:
    for line in fin:
      entry_val = int(line, 2)
      hstr = '%0*x' % ((len(line) + 3) // 4, int(line,2)) + "\n"
      #entry = hex(entry_val)
      #entry_str = str(entry)[2:]
      #print(entry_str)
      entries.append(hstr)


  with open("/home/parallels/aos-final/scripts/norm_lut_mif_hex.txt", "w+") as fout:
    for entry in entries:
      fout.write(entry)

main()
