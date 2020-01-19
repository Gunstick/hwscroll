#!/bin/sh
# (C 2002) GPL 
# Gunstick/Unlimited Matricks
#
# reverse engineered hardware scroller gerator
# based on the printed output of the original script

# output is like this:
# 0$ 0
# 0$ 0=00000 00000 00000 00000 00000 00000    0   0   0   0   0   0   0
# 0$ 0=00001 10001 10001 10010 10010 10010   44  70  70  24  24  24  -1
# 0$ 0=00010 10001 10001 10001 10010 10010   -2  70  70  70  24  24  -1
# 1$ 2
# 1$ 2=00000 10001 10001 10001 10010 10010    0  70  70  70  24  24  -1
# 1$ 2=00001 00001 00010 00010 00010 10100   44  44  -2  -2  -2 -80   0
# etc...
# |  |  |                              |      |                       |
# |  |  |                              |      |                 modulo 256 adjustment
# |  |  |                              |      1st to 6th line length adjustments
# |  |  |                              |      from 160 byte standard length
# |  |  |                              6th line swithes
# |  |  on/off switches for 1st hwscroll line
# |  switch number
# for later sorting

# switches explanation
# 000001 = we open the right border, line gets 44 bytes longer
# 000010 = we *close* the right border earlier, line gets 2 bytes shorter
# 000100 = we close the line in middle of screen, line gets 106 bytes shorter
# 010000 = we open the left border, adding 26 bytes
# 001000 = we start left screen earlier, line gets 2 bytes longer
# 100000 = we clode the full line, line gets 160 bytes shorter (0 bytes line)

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
lines=4  # 4 lines full hardscroll with all possibile line lengths
linelengths=13  # length 13 (0 bytes long) is tricky to use in practice
eclocksync="on"
while [ $# -gt 0 ]
do
  key="$1"
  case "$key" in
    --lines)
      lines="$2"
      shift;shift;
    ;;
    --lengths)
      linelengths="$2"
      shift;shift;
    ;;
    --eclocksync)
      if [ "$2" = "on" ] || [ "$2" = "off" ]
      then
        eclocksync="$2"
      else
        echo "on or off?"
        exit
      fi
      shift;shift;
    ;;
    *)
    echo "usage: $0 [--lines n] [--lengths n] [--eclocksync {on|off}"
    echo "default: 4 lines, 13 lengthsi, with eclocksync"
    echo "13: includes 0 byte line"
    echo "9-12: includes 2 byte longer line"
    echo "8: the ULM hardscroll on 6 lines"
    exit
    ;;
  esac
done
i=2
looping=""
while [ $i -le $lines ]
do
  looping="$looping for(scanline[$i]=scanline[$((i-1))];scanline[$i]<=linelengths;scanline[$i]++) "
  i=$((i+1))
done
if [ "$eclocksync" = "on" ]
then
  eclocksync=$linelengths
else
  eclocksync=4 # first line only can have switches after left start
fi
awk -v lines=$lines -v linelengths=$linelengths -v eclocksync=$eclocksync '
BEGIN { 
        switches[1]= "000000";offset[1]=0;s++
        switches[2]= "000001";offset[2]=44;s++
        switches[3]= "000010";offset[3]=-2;s++
        switches[4]= "000100";offset[4]=-106;s++
        switches[5]= "010000";offset[5]=26;s++
        switches[6]= "010001";offset[6]=26+44;s++
        switches[7]= "010010";offset[7]=26-2;s++
        switches[8]= "010100";offset[8]=26-106;s++
        switches[9]= "001000";offset[9]=2;s++
        switches[10]="001100";offset[10]=2-106;s++
        switches[11]="001010";offset[11]=2-2;s++
        switches[12]="001001";offset[12]=2+44;s++
        switches[13]="100000";offset[13]=-160;
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
for(scanline[1]=1;scanline[1]<=eclocksync;scanline[1]++)   # first line can have any switches with e-clock hbl sync
'"$looping"'
 {
  offs=0
  for (i=1;i<=lines;i++) # calculate offset
  {
    offs+=offset[scanline[i]]
  }
 #  printf "offset=%2d ",offs 
  printf "%4d$%3x=",(offs+5*256)%256/2,(offs+5*256)%256
  ok[(offs+5*256)%256]=1
  for (i=1;i<=lines;i++)
  {
    printf " %s ",switches[scanline[i]]
  }
  for (i=1;i<=lines;i++)
  {
    printf " %4d",offset[scanline[i]]
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
