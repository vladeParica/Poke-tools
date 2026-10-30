/* Searches the WHOLE RNG cycle for shiny Method 1 positions (statics, gifts,
 * starters) for a save, with minimum nature and IVs.
 * Prints: state(s1 = PID-low call) PID nature HP Atk Def SpA SpD Spe total
 * For seeds: seeds_near_target.py with the state BEFORE s1.
 * Build:  gcc -O2 -o static static_search.c -DTID=<your TID> -DSID=<your SID>
 * Edit the natures (3 Adamant, 23 Careful) and the minimum total below. */
#include <stdio.h>
#include <stdint.h>
#if !defined(TID) || !defined(SID)
#error "Compila con -DTID=<tu TID> -DSID=<tu SID>"
#endif
int main(){ uint32_t tsv=TID^SID; uint32_t s=0;
 for(uint64_t i=0;i<4294967296ULL;i++,s++){
  uint32_t s2=s*0x41C64E6Du+0x6073u; uint32_t lo=s>>16, hi=s2>>16;
  if(((lo^hi^tsv))>=8) continue;
  uint32_t pid=(hi<<16)|lo, n=pid%25; if(n!=3&&n!=23) continue;
  uint32_t s3=s2*0x41C64E6Du+0x6073u, s4=s3*0x41C64E6Du+0x6073u;
  uint32_t a=s3>>16,b=s4>>16;
  int hp=a&31,at=(a>>5)&31,df=(a>>10)&31,sp=b&31,sa=(b>>5)&31,sd=(b>>10)&31;
  int tot=hp+at+df+sp+sa+sd;
  if(tot<160) continue;
  printf("%08X %08X %s %d %d %d %d %d %d %d\n",s,pid,n==3?"Adamant":"Careful",hp,at,df,sa,sd,sp,tot);
 } }
