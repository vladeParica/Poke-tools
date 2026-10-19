/* Busca en TODO el ciclo del RNG posiciones Method 1 (estaticos, regalos,
 * iniciales) shiny para una partida, con naturaleza e IVs minimos.
 * Imprime: estado(s1 = llamada del PID bajo) PID naturaleza PS At Df AtE DfE Vel total
 * Para semillas: seeds_near_target.py con el estado ANTERIOR a s1.
 * Compilar:  gcc -O2 -o static static_search.c
 * Editar tsv, naturalezas (3 Adamant, 23 Careful) y el total minimo abajo. */
#include <stdio.h>
#include <stdint.h>
int main(){ uint32_t tsv=39422^4042; uint32_t s=0;
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
