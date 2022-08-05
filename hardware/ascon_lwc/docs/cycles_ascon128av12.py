'''
Notation:

Na, Nm, Nc, Nh : the number of complete blocks of associated data, plaintext, ciphertext, and hash message, respectively

Ina, Inm, Inc, Inh : binary variables equal to 1 if the last block of the respective data type is incomplete, and 0 otherwise

Bla, Blm, Blc, Blh : the number of bytes in the incomplete block of associated data, plaintext, ciphertext, and hash message, respectively.

'''
CCW = 32 # same as CCSW, either 8, 16, or 32
UROL = 1 # permutation rounds per cycle; needs to evenly divide 8

Na = 0
Nm = 0
Nc = 0

Bla = 0
Blm = 0
Blc = 0

# do not touch
Ina = 1 if Bla > 0 else 0
Inm = 1 if Blm > 0 else 0
Inc = 1 if Blc > 0 else 0

# ascon128av12
PA = 12
PB = 8
R = 128

# encryption:
cycles_enc = 128//CCW                                       # store key
cycles_enc += 128//CCW                                      # store nonce
cycles_enc += 1                                             # init state setup
cycles_enc += PA//UROL                                      # init process
cycles_enc += 1                                             # init key add
cycles_enc += (PB//UROL+R//CCW)*Na                          # absorb + process complete AD blocks
cycles_enc += Ina*(int(((Bla*8+CCW-8)/CCW)) + PB//UROL)     # absorb + process incomplete AD blocks
cycles_enc += ((Na>0)|(Nm>0)|(Inm>0))*(Ina==0)              # absorb empty AD block with padding if required
cycles_enc += 1                                             # domain seperation
cycles_enc += (PB//UROL+R//CCW)*Nm                          # absorb + process complete MSG blocks
cycles_enc += Inm*(int(((Blm*8+CCW-8)/CCW)) + PB//UROL)     # absorb + process incomplete MSG blocks
cycles_enc += (Inm==0)                                      # absorb empty MSG block with pad
cycles_enc += 1                                             # final key add 1
cycles_enc += PA//UROL                                      # final process
cycles_enc += 1                                             # final key add 2
cycles_enc += 128//CCW                                      # extract tag / verify tag

print('encryption cycles: ' + str(cycles_enc))

# decryption:
cycles_dec = 128//CCW                                       # store key
cycles_dec += 128//CCW                                      # store nonce
cycles_dec += 1                                             # init state setup
cycles_dec += PA//UROL                                      # init process
cycles_dec += 1                                             # init key add
cycles_dec += (PB//UROL+R//CCW)*Na                          # absorb + process complete AD blocks
cycles_dec += Ina*(int(((Bla*8+CCW-8)/CCW)) + PB//UROL)     # absorb + process incomplete AD blocks
cycles_dec += ((Na>0)|(Nc>0)|(Inc>0))*(Ina==0)              # absorb empty AD block with padding if required
cycles_dec += 1                                             # domain seperation
cycles_dec += (PB//UROL+R//CCW)*Nc                          # absorb + process complete MSG blocks
cycles_dec += Inc*(int(((Blm*8+CCW-8)/CCW)) + PB//UROL)     # absorb + process incomplete MSG blocks
cycles_dec += (Inc==0)                                      # absorb empty MSG block with pad
cycles_dec += 1                                             # final key add 1
cycles_dec += PA//UROL                                      # final process
cycles_dec += 1                                             # final key add 2
cycles_dec += 128//CCW                                      # extract tag / verify tag
cycles_dec += 1                                             # wait ack (only decryption)

print('decryption cycles: ' + str(cycles_dec))

# asconhashav12
PA = 12
PB = 8
R = 64

cycles_hash = PA//UROL                                      # initialization
cycles_hash += Na*PB//UROL + Na*(R//CCW)                    # absorb + process complete AD blocks  
cycles_hash += Ina*(int(((Bla*8+CCW-8)/CCW)) + PB//UROL)    # absorb + process incomplete AD blocks
cycles_hash += (Ina==0)*PA//UROL                            # absorb empty AD block with padding
cycles_hash += (Ina==1)*(PA-PB)//UROL                       # last process before squeeze has PA rounds
cycles_hash += 64//CCW*4                                    # Squeeze Hash
cycles_hash += PB//UROL*3

print('cycles_hash: ' + str(cycles_hash))
