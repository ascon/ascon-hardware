'''
Notation:

Na, Nm, Nc, Nh : the number of complete blocks of associated data, plaintext, ciphertext, and hash message, respectively

Ina, Inm, Inc, Inh : binary variables equal to 1 if the last block of the respective data type is incomplete, and 0 otherwise

Bla, Blm, Blc, Blh : the number of bytes in the incomplete block of associated data, plaintext, ciphertext, and hash message, respectively

Urol : the number of permutation rounds performed per clock cycle
'''

Na = 0
Nm = 0
Nc = 0

Ina = 0
Inm = 0
Inc = 0

Bla = 0
Blm = 0
Blc = 0

Urol = 1

# encryption 32-bit interface:
cycles = 0
cycles += 4                                # idle
cycles += 4                                # store key
cycles += 6                                # store nonce (+ preprocessor delay)
cycles += 1                                # init state setup
cycles += 12//Urol                         # init process
cycles += 1                                # init key add
cycles += (6//Urol+2)*Na                   # absorb + process complete AD blocks
cycles += Ina*((Bla+3)//4+(6//Urol))       # absorb + process incomplete AD block
cycles += ((Na>0)|(Nm>0)|(Inm>0))*(Ina==0) # absorb empty AD block with padding realize / that there is no AD but MSG
cycles += 1                                # domain seperation
cycles += (6//Urol+2)*Nm                   # absorb + process complete MSG blocks
cycles += Inm*((Blm+3)//4)                 # absorb incomplete MSG block
cycles += (Inm==0)                         # absorb empty MSG block with padding
cycles += 1                                # final key add 1
cycles += (12//Urol)                       # final process
cycles += 1                                # final key add 2
cycles += 4                                # extract tag / verify tag

print('encryption cycles: ' + str(cycles))

# decryption 32-bit interface:
cycles = 0
cycles += 4                                # idle
cycles += 4                                # store key
cycles += 6                                # store nonce (+ preprocessor delay)
cycles += 1                                # init state setup
cycles += 12//Urol                         # init process
cycles += 1                                # init key add
cycles += (6//Urol+2)*Na                   # absorb + process complete AD blocks
cycles += Ina*((Bla+3)//4+(6//Urol))       # absorb + process incomplete AD block
cycles += ((Na>0)|(Nc>0)|(Inc>0))*(Ina==0) # absorb empty AD block with padding / realize that there is no AD but MSG
cycles += 1                                # domain seperation
cycles += (6//Urol+2)*Nc                   # absorb + process complete MSG blocks
cycles += Inc*((Blc+3)//4)                 # absorb incomplete MSG block
cycles += (Inc==0)                         # absorb empty MSG block with padding
cycles += 1                                # final key add 1
cycles += (12//Urol)                       # final process
cycles += 1                                # final key add 2
cycles += 4                                # extract tag / verify tag
cycles += 1                                # wait ack (only decryption)

print('decryption cycles: ' + str(cycles))

cycle_start = 0
cycle_end = 0

print('diff: ' + str(cycle_end - cycle_start))

