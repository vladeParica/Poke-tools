/* Busca en TODO el ciclo del RNG (2^32) encuentros salvajes Method H-1 shiny
 * para una partida, con naturaleza e IVs minimos, y que caigan en un hueco
 * (slot) de la tabla de encuentros que sea la especie buscada.
 * Imprime: estado_inicial PID naturaleza PS At Df AtE DfE Vel slot k
 * (estado_inicial = estado del RNG justo antes de la llamada del slot;
 *  k = pares de PID rechazados por no coincidir con la naturaleza).
 * Luego usa seeds_near_target.py con estado_inicial para sacar semillas.
 * Compilar:  gcc -O2 -o wild wild_h1_search.c  [-DTID=.. -DSID=.. -DNAT1=.. -DNAT2=.. -DMASK=..]
 * Naturalezas: indice = PID % 25 (3 Adamant, 10 Timid, 13 Jolly, 15 Modest, 23 Careful...)
 * MASK: bit N = slot N valido (Torre Pokemon 3F-6F: todos menos 7 y 9 = 0xD7F;
 *       Tunel Roca: slots 0 y 4 = 0x011; Cueva Alterada: 0xFFF). */
#include <stdio.h>
#ifndef TID
#define TID 39422
#endif
#ifndef SID
#define SID 4042
#endif
#ifndef NAT1
#define NAT1 10
#endif
#ifndef NAT2
#define NAT2 15
#endif
#ifndef MASK
#define MASK 0xD7F
#endif
/* filtro de IVs: editar a gusto */
#define IV_OK(hp,at,df,sa,sd,sp) ((hp)>=26 && (sa)>=29 && (sp)>=29)
#include <stdint.h>
#define NX(s) ((s)*0x41C64E6Du+0x6073u)
#define PV(s) ((s)*0xEEB9EB65u+0x0A3561A1u)
static int slotOf(int r){int t[12]={20,40,50,60,70,80,85,90,94,98,99,100};for(int i=0;i<12;i++)if(r<t[i])return i;return 11;}
int main(){uint32_t tsv=TID^SID;uint32_t s=0;
 for(uint64_t i=0;i<4294967296ULL;i++,s++){
  uint32_t s2=NX(s);uint32_t lo=s>>16,hi=s2>>16;
  if((lo^hi^tsv)>=8)continue;
  uint32_t pid=(hi<<16)|lo;int nat=pid%25;if(nat!=NAT1&&nat!=NAT2)continue;
  uint32_t s3=NX(s2),s4=NX(s3);uint32_t a=s3>>16,b=s4>>16;
  int hp=a&31,at=(a>>5)&31,df=(a>>10)&31,sp=b&31,sa=(b>>5)&31,sd=(b>>10)&31;
  if(!IV_OK(hp,at,df,sa,sd,sp))continue;
  uint32_t back[30];back[0]=s;for(int j=1;j<30;j++)back[j]=PV(back[j-1]);
  for(int k=0;k<12;k++){
    uint32_t N=back[2*k+1];if(((N>>16)%25)!=(uint32_t)nat)continue;
    int ok=1;for(int j=1;j<=k;j++){uint32_t p=((back[2*j-1]>>16)<<16)|(back[2*j]>>16);if(p%25==(uint32_t)nat){ok=0;break;}}
    if(!ok)continue;
    int slot=slotOf((back[2*k+3]>>16)%100);
    if(!((MASK>>slot)&1))continue;
    printf("%08X %08X %s %d %d %d %d %d %d slot%d k%d\n",back[2*k+4],pid,nat==NAT1?"NAT1":"NAT2",hp,at,df,sa,sd,sp,slot,k);
  }
 }}
