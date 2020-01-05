#!/bin/sh
# (C 2002) GPL 
# Gunstick/Unlimited Matricks
#
# reverse engineered hardware scroller gerator
# based on the printed output of the original script

# output is like this:
# 0$ 0
# 0$ 0=0000 0000 0000 0000 0000 0000    0   0   0   0   0   0   0
# 0$ 0=0001 1001 1001 1010 1010 1010   44  70  70  24  24  24  -1
# 0$ 0=0010 1001 1001 1001 1010 1010   -2  70  70  70  24  24  -1
# 1$ 2
# 1$ 2=0000 1001 1001 1001 1010 1010    0  70  70  70  24  24  -1
# 1$ 2=0001 0001 0010 0010 0010 1100   44  44  -2  -2  -2 -80   0
# etc...
# |  |  |                        |      |                       |
# |  |  |                        |      |                 modulo 256 adjustment
# |  |  |                        |      1st to 6th line length adjustments
# |  |  |                        |      from 160 byte standard length
# |  |  |                        6th line swithes
# |  |  on/off switches for 1st hwscroll line
# |  switch number
# for later sorting

# switches explanation
# 0001 = we open the right border, line gets 44 bytes longer
# 0010 = we *close* the right border earlier, line gets 2 bytes shorter
# 0100 = we close the line in middle of screen, line gets 106 bytes shorter
# 1000 = we open the left border, adding 26 bytes

# this gives combinations like 1010 = +26-2 = +24
# of course things like this are not permitted: 0011 because the border
# is closed, we can't open it again after, so there are only 8 possibilities

# now we could create all combinations possible, this gives about 262144
# possibilities, where 1 2 2 3 3 4 is diffrent than 1 2 3 4 3 2
# but the resulting offset is the same, so we need to remove those
# permutation duplicates. Easiest done with special loop
# this gives 1716 combinations. but the original had 1632 ???
# Because in the first line, only 0xxx is possible, which removes half
lines=5  # missing: 1, 14, 27, 40, 53, 62, 63, 76, 89, 102, 106, 115
         # 5 lines is usable for vertical hardscoll without overscan
lines=6  # all possibilities
if [ "$1" != "" ]
then
  lines=$1
fi

i=2
looping=""
while [ $i -le $lines ]
do
  looping="$looping for(scanline[$i]=scanline[$((i-1))];scanline[$i]<=8;scanline[$i]++) "
  i=$((i+1))
done

awk -v lines=$lines '
BEGIN { 
        switches[1]="0000";offset[1]=0;s++
        switches[2]="0001";offset[2]=44;s++
        switches[3]="0010";offset[3]=-2;s++
        switches[4]="0100";offset[4]=-106;s++
        switches[5]="1000";offset[5]=26;s++
        switches[6]="1001";offset[6]=26+44;s++
        switches[7]="1010";offset[7]=26-2;s++
        switches[8]="1100";offset[8]=26-106;
for (i=1;i<=lines;i++)
{
scanline[i]=1;
}
scanline[lines+1]=1;

for (i=0;i<=127;i++)
{
  printf "%3d$%2x\n",i,i*2
}

# now the main loop
for(scanline[1]=1;scanline[1]<=4;scanline[1]++)
'"$looping"'
 {
  offs=0
  for (i=1;i<=lines;i++) # calculate offset
  {
    offs+=offset[scanline[i]]
  }
 #  printf "offset=%2d ",offs 
  printf "%3d$%2x=",(offs+5*256)%256/2,(offs+5*256)%256
  ok[(offs+5*256)%256]=1
  for (i=1;i<=lines;i++)
  {
    printf "%s ",switches[scanline[i]]
  }
  for (i=1;i<=lines;i++)
  {
    printf "%4d",offset[scanline[i]]
  }
  if (offs >= 0)
  {
    printf" %2d",-int(offs/256)
  } else {
    printf" %2d",-(int(offs/256)-1)
  }
  print ""
 } 
print "256   0 1 2 3 4 5 6 7 8 9 a b c d e f"
for (i=0;i<=15;i++)
{
  printf "999 %x ",i
  for (j=0;j<=15;j++)
    if (ok[i*16+j]==1)
      printf "%02x",i*16+j
    else
      printf "  "
  print ""
}
}
'| sort -n
