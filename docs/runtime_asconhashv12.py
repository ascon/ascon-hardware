'''
Notation:

Na, Nm, Nc, Nh : the number of complete blocks of associated data, plaintext, ciphertext, and hash message, respectively

Ina, Inm, Inc, Inh : binary variables equal to 1 if the last block of the respective data type is incomplete, and 0 otherwise

Bla, Blm, Blc, Blh : the number of bytes in the incomplete block of associated data, plaintext, ciphertext, and hash message, respectively

Urol : the number of permutation rounds performed per clock cycle
'''

Nh = 0

Inh = 0

Blh = 0

Urol = 1

# hashing 32-bit interface:
cycles = 0
cycles += 3                                # idle
cycles += 1                                # init hash
cycles += (12//Urol)                       # init process
cycles += (12//Urol+2)*Nh                  # absorb + process complete Hash blocks
cycles += Inh*((Blh+3)//4+(12//Urol))      # absorb + process incomplete Hash block
cycles += (Inh==0)*(12//Urol+1)            # absorb empty Hash block with padding
cycles += (36//Urol)+8                     # extract Hash

print('hashing cycles: ' + str(cycles))

cycle_start = 0
cycle_end = 0

print('diff: ' + str(cycle_end - cycle_start))

