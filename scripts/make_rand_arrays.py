import random

def C_LOG_2(n):
  return (0 if ((n) <= (1<<0))  else 1 if ((n) <= (1<<1))\
  else 2 if ((n) <= (1<<2)) else 3 if ((n) <= (1<<3))\
  else 4 if ((n) <= (1<<4)) else 5 if ((n) <= (1<<5))\
  else 6 if ((n) <= (1<<6)) else 7 if ((n) <= (1<<7))\
  else 8 if ((n) <= (1<<8)) else 9 if ((n) <= (1<<9))\
  else 10 if ((n) <= (1<<10)) else 11 if ((n) <= (1<<11))\
  else 12 if ((n) <= (1<<12)) else 13 if ((n) <= (1<<13))\
  else 14 if ((n) <= (1<<14)) else 15 if ((n) <= (1<<15))\
  else 16 if ((n) <= (1<<16)) else 17 if ((n) <= (1<<17))\
  else 18 if ((n) <= (1<<18)) else 19 if ((n) <= (1<<19))\
  else 20 if ((n) <= (1<<20)) else 21 if ((n) <= (1<<21))\
  else 22 if ((n) <= (1<<22)) else 23 if ((n) <= (1<<23))\
  else 24 if ((n) <= (1<<24)) else 25 if ((n) <= (1<<25))\
  else 26 if ((n) <= (1<<26)) else 27 if ((n) <= (1<<27))\
  else 28 if ((n) <= (1<<28)) else 29 if ((n) <= (1<<29))\
  else 30 if ((n) <= (1<<30)) else 31 if ((n) <= (1<<31)) else 32)

def main():
  NEGEDGE_RANDS = 1000
  POSEDGE_RANDS = NEGEDGE_RANDS + 1

  rd_req_size_urands = []
  rd_req_pu_id_urands = []
  rd_req_d_type_urands = []

  inbuf_empty_rands = []
  buffer_full_rands = []
  stream_full_rands = []

  rd_req_size_strs = []
  rd_req_pu_id_strs = []
  rd_req_d_type_strs = []

  inbuf_empty_strs = []
  buffer_full_strs = []
  stream_full_strs = []

  #print(C_LOG_2(1) + 1)


  for i in range(NEGEDGE_RANDS):
    rd_req_size_urands.append(random.getrandbits(32))
    rd_req_pu_id_urands.append(random.getrandbits(32))
    rd_req_d_type_urands.append(random.getrandbits(32))

  for i in range(POSEDGE_RANDS):
    inbuf_empty_rands.append(random.getrandbits(1))
    buffer_full_rands.append(random.getrandbits(1))
    stream_full_rands.append(random.getrandbits(1))
    
  
  # Correct read_req_size_urands with x%10 + 1
  for i in range(NEGEDGE_RANDS):
    #print("Original rd_req_size_urands[", i, "]: ", rd_req_size_urands[i], end="\t\t")
    rd_req_size_urands[i] = rd_req_size_urands[i] % 10 + 1
    #print("New rd_req_size_urands[", i, "]: ", rd_req_size_urands[i])

    rd_req_size_strs.append("    read_req_size_urands[" + str(i) + "]" + ( "    " if (i < 10) else "   " if (i < 100) else "  " if (i < 1000) else " ") + "= 20'd" + str(rd_req_size_urands[i]) + ";\n")
    
  for entry in rd_req_size_strs:
    print(entry, end="")
  print()

  
  # Don't correct read_req_pu_id with %1 because you're just going to replace the random array with a 0.
  # Just keeping this in case NUM_PU changes
  for i in range(NEGEDGE_RANDS):
    #print("Original rd_req_pu_id_urands[", i, "]: ", rd_req_pu_id_urands[i]) #, end="\t\t")
    #rd_req_pu_id_urands[i] = rd_req_pu_id_urands[i];
    #print("New rd_req_pu_id_urands[", i, "]: ", rd_req_pu_id_urands[i])

    rd_req_pu_id_strs.append("    read_req_pu_id_urands[" + str(i) + "]" + ( "    " if (i < 10) else "   " if (i < 100) else "  " if (i < 1000) else " ") + "= 32'd" + str(rd_req_pu_id_urands[i]) + ";\n")
    
  for entry in rd_req_pu_id_strs:
    print(entry, end="")
  print()


  # Correct read_req_d_type_urands with x%10 + 1
  for i in range(NEGEDGE_RANDS):
    #print("Original rd_req_d_type_urands[", i, "]: ", rd_req_d_type_urands[i], end="\t\t")
    rd_req_d_type_urands[i] = rd_req_d_type_urands[i] % 2
    #print("New rd_req_d_type_urands[", i, "]: ", rd_req_d_type_urands[i])

    rd_req_d_type_strs.append("    read_req_d_type_urands[" + str(i) + "]" + ( "    " if (i < 10) else "   " if (i < 100) else "  " if (i < 1000) else " ") + "= 1'b" + str(rd_req_d_type_urands[i]) + ";\n")
    
  for entry in rd_req_d_type_strs:
    print(entry, end="")
  print()


  # Get strs for inbuf_empty_rands
  for i in range(POSEDGE_RANDS):
    #print("Original inbuf_empty_rands[", i, "]: ", inbuf_empty_rands[i])

    inbuf_empty_strs.append("    inbuf_empty_rands[" + str(i) + "]" + ( "    " if (i < 10) else "   " if (i < 100) else "  " if (i < 1000) else " ") + "= 1'b" + str(inbuf_empty_rands[i]) + ";\n")
      
    
  for entry in inbuf_empty_strs:
    print(entry, end="")
  print()
  
    
  # Get strs for stream_full_rands
  for i in range(POSEDGE_RANDS):
    #print("Original stream_full_rands[", i, "]: ", stream_full_rands[i])
    
    stream_full_strs.append("    stream_full_rands[" + str(i) + "]" + ( "    " if (i < 10) else "   " if (i < 100) else "  " if (i < 1000) else " ") + "= 1'b" + str(stream_full_rands[i]) + ";\n")
    
  for entry in stream_full_strs:
    print(entry, end="")
  print()


  # Get strs for buffer_full_rands
  for i in range(POSEDGE_RANDS):
    #print("Original buffer_full_rands[", i, "]: ", buffer_full_rands[i])
    
    buffer_full_strs.append("    buffer_full_rands[" + str(i) + "]" + ( "    " if (i < 10) else "   " if (i < 100) else "  " if (i < 1000) else " ") + "= 1'b" + str(buffer_full_rands[i]) + ";\n")
    
  for entry in buffer_full_strs:
    print(entry, end="")
  print()

  with open("/home/parallels/aos-final/scripts/rand_arrays_out.txt", "w+") as fout:
    for entry in rd_req_size_strs:
      fout.write(entry)
    fout.write("\n\n\n\n\n")

    for entry in rd_req_pu_id_strs:
      fout.write(entry)
    fout.write("\n\n\n\n\n")

    for entry in rd_req_d_type_strs:
      fout.write(entry)
    fout.write("\n\n\n\n\n")

    for entry in inbuf_empty_strs:
      fout.write(entry)
    fout.write("\n\n\n\n\n")

    for entry in buffer_full_strs:
      fout.write(entry)
    fout.write("\n\n\n\n\n")

    for entry in stream_full_strs:
      fout.write(entry)

main()
