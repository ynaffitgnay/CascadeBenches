def main():
  in_entries = []
  enc_entries = []
  dec_entries = []

  i = 0
  e = 0
  d = 0
  with open("/home/parallels/aos-final/CascadeIn/adpcm/test_in_bin.txt", "r") as fin:
    for line in fin:
      entry = "    inBuf[" + str(i) + "] = 256'h" + line.strip() + ";\n"

      in_entries.append(entry)
      
      i += 1

  with open("/home/parallels/aos-final/CascadeIn/adpcm/test_enc_bin.txt", "r") as fin:
    for line in fin:
      entry = "    encBuf[" + str(e) + "] = 256'h" + line.strip() + ";\n"

      enc_entries.append(entry)
      
      e += 1

  with open("/home/parallels/aos-final/CascadeIn/adpcm/test_dec_bin.txt", "r") as fin:
    for line in fin:
      entry = "    decBuf[" + str(d) + "] = 256'h" + line.strip()  + ";\n"

      dec_entries.append(entry)
      
      d += 1



  with open("/home/parallels/aos-final/scripts/arrays_out.txt", "w+") as fout:
    for entry in in_entries:
      fout.write(entry)

    fout.write("\n\n\n\n\n")

    for entry in enc_entries:
      fout.write(entry)

    fout.write("\n\n\n\n\n")
    for entry in dec_entries:
      fout.write(entry)
          
main()
