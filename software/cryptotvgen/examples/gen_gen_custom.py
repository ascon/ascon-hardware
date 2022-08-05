import random

lines = []

for a in [True, False]:
    for b in [True, False]:
        for c in range(25):
            for d in range(25):
                lines.append(str(str(a) + ', ' + str(b) + ', ' + str(c) + ', ' + str(d) + ', False:'))

random.shuffle(lines)

lines[-1] = lines[-1][:-1]

for l in lines:
    print(l)

